using System.Diagnostics;
using System.IO.Compression;
using System.Net;
using System.Net.Http;
using System.Net.Sockets;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;

internal static class ProgramBrowser
{
    private const string PayloadResourceName = "Aetherwake.BrowserPayload.zip";

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBoxW(nint hWnd, string text, string caption, uint type);

    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            return RunAsync(args).GetAwaiter().GetResult();
        }
        catch (Exception ex)
        {
            MessageBoxW(
                0,
                "Aetherwake Browser Mode could not start.\n\n" + ex.Message,
                "Aetherwake - Browser Mode",
                0x10);
            return 1;
        }
    }

    private static async Task<int> RunAsync(string[] args)
    {
        var payloadHash = ComputePayloadHash();
        var runtimeRoot = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Aetherwake",
            "browser-runtime",
            payloadHash[..16].ToLowerInvariant());

        EnsureRuntime(runtimeRoot);

        var entrypoint = Path.Combine(runtimeRoot, "index-embedded.html");
        if (!File.Exists(entrypoint))
        {
            throw new InvalidDataException("Browser payload is missing index-embedded.html.");
        }

        var port = FindFreeLoopbackPort();
        var prefix = $"http://127.0.0.1:{port}/";
        using var listener = new HttpListener();
        listener.Prefixes.Add(prefix);
        listener.Start();

        using var stop = new CancellationTokenSource();
        var serverTask = RunServerAsync(listener, runtimeRoot, stop.Token);

        if (args.Contains("--self-test", StringComparer.OrdinalIgnoreCase))
        {
            try
            {
                using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(20) };
                var html = await client.GetStringAsync(prefix + "index-embedded.html");
                var runtime = await client.GetStringAsync(prefix + "aetherwake.js");
                var charCreate = await client.GetStringAsync(prefix + "modules/char-create.js");

                if (!html.Contains("aetherwake.js", StringComparison.Ordinal) ||
                    !runtime.Contains("Aetherwake", StringComparison.OrdinalIgnoreCase) ||
                    !charCreate.Contains("CharCreate", StringComparison.Ordinal))
                {
                    throw new InvalidDataException("Browser Mode self-test received incomplete game content.");
                }

                return 0;
            }
            finally
            {
                stop.Cancel();
                listener.Stop();
                try { await serverTask; } catch { }
            }
        }

        var gameUrl = prefix + "index-embedded.html";
        Process? browser = LaunchBrowserApp(gameUrl, payloadHash[..16].ToLowerInvariant());

        if (browser is null)
        {
            throw new InvalidOperationException("Windows could not open a browser for Aetherwake.");
        }

        try
        {
            // Browser Mode owns the private loopback server for as long as its
            // dedicated browser window/process remains alive.
            await browser.WaitForExitAsync();
        }
        finally
        {
            stop.Cancel();
            listener.Stop();
            try { await serverTask; } catch { }
        }

        return 0;
    }

    private static Process? LaunchBrowserApp(string url, string cacheId)
    {
        var edge = FindEdgeExecutable();
        if (edge is not null)
        {
            var profile = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Aetherwake",
                "browser-profile",
                cacheId);
            Directory.CreateDirectory(profile);

            var psi = new ProcessStartInfo(edge)
            {
                UseShellExecute = false,
            };
            psi.ArgumentList.Add("--app=" + url);
            psi.ArgumentList.Add("--user-data-dir=" + profile);
            psi.ArgumentList.Add("--no-first-run");
            psi.ArgumentList.Add("--no-default-browser-check");
            psi.ArgumentList.Add("--disable-background-mode");
            psi.ArgumentList.Add("--start-maximized");
            return Process.Start(psi);
        }

        return Process.Start(new ProcessStartInfo(url) { UseShellExecute = true });
    }

    private static string? FindEdgeExecutable()
    {
        var candidates = new[]
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                "Microsoft", "Edge", "Application", "msedge.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
                "Microsoft", "Edge", "Application", "msedge.exe"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Microsoft", "Edge", "Application", "msedge.exe"),
        };

        return candidates.FirstOrDefault(File.Exists);
    }

    private static int FindFreeLoopbackPort()
    {
        using var probe = new TcpListener(IPAddress.Loopback, 0);
        probe.Start();
        return ((IPEndPoint)probe.LocalEndpoint).Port;
    }

    private static async Task RunServerAsync(HttpListener listener, string root, CancellationToken cancellationToken)
    {
        var rootFull = Path.GetFullPath(root)
            .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
            + Path.DirectorySeparatorChar;

        while (!cancellationToken.IsCancellationRequested && listener.IsListening)
        {
            HttpListenerContext context;
            try
            {
                context = await listener.GetContextAsync();
            }
            catch (HttpListenerException) when (!listener.IsListening || cancellationToken.IsCancellationRequested)
            {
                break;
            }
            catch (ObjectDisposedException)
            {
                break;
            }

            _ = Task.Run(async () =>
            {
                try
                {
                    var relative = Uri.UnescapeDataString(context.Request.Url?.AbsolutePath ?? "/")
                        .TrimStart('/')
                        .Replace('/', Path.DirectorySeparatorChar);

                    if (string.IsNullOrWhiteSpace(relative))
                    {
                        relative = "index-embedded.html";
                    }

                    var target = Path.GetFullPath(Path.Combine(root, relative));
                    if (!target.StartsWith(rootFull, StringComparison.OrdinalIgnoreCase) || !File.Exists(target))
                    {
                        context.Response.StatusCode = 404;
                        context.Response.Close();
                        return;
                    }

                    context.Response.StatusCode = 200;
                    context.Response.ContentType = ContentTypeFor(target);
                    context.Response.Headers["Cache-Control"] = "no-store";
                    context.Response.Headers["X-Content-Type-Options"] = "nosniff";

                    if (string.Equals(context.Request.HttpMethod, "HEAD", StringComparison.OrdinalIgnoreCase))
                    {
                        context.Response.ContentLength64 = new FileInfo(target).Length;
                        context.Response.Close();
                        return;
                    }

                    await using var input = File.OpenRead(target);
                    context.Response.ContentLength64 = input.Length;
                    await input.CopyToAsync(context.Response.OutputStream);
                    context.Response.OutputStream.Close();
                }
                catch
                {
                    try
                    {
                        context.Response.StatusCode = 500;
                        context.Response.Close();
                    }
                    catch { }
                }
            }, cancellationToken);
        }
    }

    private static string ContentTypeFor(string path)
    {
        return Path.GetExtension(path).ToLowerInvariant() switch
        {
            ".html" => "text/html; charset=utf-8",
            ".js" => "text/javascript; charset=utf-8",
            ".css" => "text/css; charset=utf-8",
            ".json" => "application/json; charset=utf-8",
            ".svg" => "image/svg+xml",
            ".png" => "image/png",
            ".jpg" or ".jpeg" => "image/jpeg",
            ".gif" => "image/gif",
            ".ico" => "image/x-icon",
            ".ttf" => "font/ttf",
            ".woff" => "font/woff",
            ".woff2" => "font/woff2",
            ".wav" => "audio/wav",
            ".mp3" => "audio/mpeg",
            ".ogg" => "audio/ogg",
            _ => "application/octet-stream",
        };
    }

    private static Stream OpenPayload()
    {
        return Assembly.GetExecutingAssembly().GetManifestResourceStream(PayloadResourceName)
            ?? throw new InvalidOperationException("Embedded Aetherwake browser payload is missing.");
    }

    private static string ComputePayloadHash()
    {
        using var stream = OpenPayload();
        using var sha = SHA256.Create();
        return Convert.ToHexString(sha.ComputeHash(stream));
    }

    private static void EnsureRuntime(string runtimeRoot)
    {
        var entrypoint = Path.Combine(runtimeRoot, "index-embedded.html");
        if (File.Exists(entrypoint))
        {
            return;
        }

        var parent = Path.GetDirectoryName(runtimeRoot)
            ?? throw new InvalidOperationException("Browser runtime parent directory could not be resolved.");
        Directory.CreateDirectory(parent);

        using var mutex = new Mutex(false, "Local\\AetherwakeBrowserMode_" + Path.GetFileName(runtimeRoot));
        if (!mutex.WaitOne(TimeSpan.FromMinutes(2)))
        {
            throw new TimeoutException("Another Aetherwake Browser Mode launch is preparing the game.");
        }

        try
        {
            if (File.Exists(entrypoint))
            {
                return;
            }

            if (Directory.Exists(runtimeRoot))
            {
                Directory.Delete(runtimeRoot, true);
            }

            var tempRoot = runtimeRoot + ".extract-" + Guid.NewGuid().ToString("N");
            Directory.CreateDirectory(tempRoot);

            try
            {
                ExtractPayload(tempRoot);
                if (!File.Exists(Path.Combine(tempRoot, "index-embedded.html")))
                {
                    throw new InvalidDataException("Embedded browser payload did not contain index-embedded.html.");
                }
                Directory.Move(tempRoot, runtimeRoot);
            }
            catch
            {
                if (Directory.Exists(tempRoot))
                {
                    Directory.Delete(tempRoot, true);
                }
                throw;
            }
        }
        finally
        {
            mutex.ReleaseMutex();
        }
    }

    private static void ExtractPayload(string destination)
    {
        var destinationRoot = Path.GetFullPath(destination)
            .TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
            + Path.DirectorySeparatorChar;

        using var payload = OpenPayload();
        using var archive = new ZipArchive(payload, ZipArchiveMode.Read, leaveOpen: false);

        foreach (var entry in archive.Entries)
        {
            var targetPath = Path.GetFullPath(Path.Combine(destination, entry.FullName));
            if (!targetPath.StartsWith(destinationRoot, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidDataException("Embedded browser payload contains an unsafe path.");
            }

            if (string.IsNullOrEmpty(entry.Name))
            {
                Directory.CreateDirectory(targetPath);
                continue;
            }

            Directory.CreateDirectory(Path.GetDirectoryName(targetPath)!);
            entry.ExtractToFile(targetPath, overwrite: true);
        }
    }
}
