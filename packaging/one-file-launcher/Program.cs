using System.Diagnostics;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Cryptography;

internal static class Program
{
    private const string PayloadResourceName = "Aetherwake.Payload.zip";
    private const string InnerExecutableName = "Aetherwake.exe";

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBoxW(nint hWnd, string text, string caption, uint type);

    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            var payloadHash = ComputePayloadHash();
            var runtimeRoot = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "Aetherwake",
                "runtime",
                payloadHash[..16].ToLowerInvariant());

            var gameExecutable = Path.Combine(runtimeRoot, InnerExecutableName);
            EnsureRuntime(runtimeRoot, gameExecutable);

            var startInfo = new ProcessStartInfo(gameExecutable)
            {
                WorkingDirectory = runtimeRoot,
                UseShellExecute = true,
            };

            foreach (var arg in args)
            {
                startInfo.ArgumentList.Add(arg);
            }

            if (Process.Start(startInfo) is null)
            {
                throw new InvalidOperationException("Windows did not start the Aetherwake runtime.");
            }

            return 0;
        }
        catch (Exception ex)
        {
            MessageBoxW(
                0,
                "Aetherwake could not start.\n\n" + ex.Message +
                "\n\nThe launcher keeps its private game runtime under your local AppData folder.",
                "Aetherwake - The Last Solarpunk Airship",
                0x10);
            return 1;
        }
    }

    private static Stream OpenPayload()
    {
        return Assembly.GetExecutingAssembly().GetManifestResourceStream(PayloadResourceName)
            ?? throw new InvalidOperationException("Embedded Aetherwake runtime payload is missing.");
    }

    private static string ComputePayloadHash()
    {
        using var stream = OpenPayload();
        using var sha = SHA256.Create();
        return Convert.ToHexString(sha.ComputeHash(stream));
    }

    private static void EnsureRuntime(string runtimeRoot, string gameExecutable)
    {
        if (File.Exists(gameExecutable))
        {
            return;
        }

        var parent = Path.GetDirectoryName(runtimeRoot)
            ?? throw new InvalidOperationException("Runtime parent directory could not be resolved.");
        Directory.CreateDirectory(parent);

        using var mutex = new Mutex(false, "Local\\AetherwakeOneFile_" + Path.GetFileName(runtimeRoot));
        if (!mutex.WaitOne(TimeSpan.FromMinutes(3)))
        {
            throw new TimeoutException("Another Aetherwake launch is still preparing the runtime.");
        }

        try
        {
            if (File.Exists(gameExecutable))
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
                var extractedExecutable = Path.Combine(tempRoot, InnerExecutableName);
                if (!File.Exists(extractedExecutable))
                {
                    throw new InvalidDataException("Embedded runtime did not contain Aetherwake.exe.");
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
                throw new InvalidDataException("Embedded runtime contains an unsafe path.");
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
