using System;
using System.Collections.Generic;
using System.Linq;
using StarrySky.WorldMap.Contracts;

internal static class Program
{
    private const double R = 6371.0; // Only a numeric test fixture, NOT canon.
    private static int _assertions;

    private static void Check(bool valid, string name)
    {
        _assertions++;
        if (!valid)
            throw new Exception("CS_WORLDMAP_CONTRACT_FAIL: " + name);
    }

    private static void Near(double actual, double expected, double tolerance, string name)
        => Check(double.IsFinite(actual) && Math.Abs(actual - expected) <= tolerance, name);

    private static void Reject<T>(Action call, string name) where T : Exception
    {
        _assertions++;
        try
        {
            call();
        }
        catch (T)
        {
            return;
        }
        throw new Exception("CS_WORLDMAP_CONTRACT_FAIL: missing rejection " + name);
    }

    private static void GeodesicChecks()
    {
        var origin = new PlanetPosition(0, 0);
        Near(new PlanetPosition(12, 540).LongitudeDegrees, -180, 1e-9, "canonical antimeridian");
        Near(new PlanetPosition(90, -75).LongitudeDegrees, 0, 1e-9, "pole longitude irrelevant");
        Near(new PlanetPosition(0, -360).LongitudeDegrees, 0, 1e-9, "360-degree wrap");
        Near(PlanetGeometry.AngularSeparationRadians(origin, origin), 0, 1e-14, "same-point angle");
        Near(PlanetGeometry.AngularSeparationRadians(origin, new PlanetPosition(0, 180)),
            Math.PI, 1e-9, "antipodal angle");
        Near(PlanetGeometry.SurfaceDistanceKm(new PlanetPosition(0, 179.9),
            new PlanetPosition(0, -179.9), R), 22.23898533, 0.001, "seam surface distance");
        var destination = PlanetGeometry.Destination(origin, 90, 100, R);
        Near(destination.LatitudeDegrees, 0, 1e-9, "eastbound equator latitude");
        Near(PlanetGeometry.SurfaceDistanceKm(origin, destination, R), 100, 1e-7, "distance roundtrip");
        Check(PlanetGeometry.TryInitialBearingDegrees(origin, destination, out double bearing),
            "bearing defined for eastbound step");
        Near(bearing, 90, 1e-8, "eastbound initial bearing");
        Check(!PlanetGeometry.TryInitialBearingDegrees(origin, origin, out _),
            "coincident bearing fails closed");
        Check(!PlanetGeometry.TryInitialBearingDegrees(origin, new PlanetPosition(0, 180), out _),
            "antipodal bearing fails closed");
        var crossing = PlanetGeometry.Destination(new PlanetPosition(1, 179.95, 4),
            90, 30, R);
        Check(crossing.LongitudeDegrees < -179, "destination crosses antimeridian");
        Near(crossing.AltitudeKm, 4, 1e-9, "destination preserves altitude");
        Near(PlanetGeometry.HorizonSurfaceDistanceKm(0, R), 0, 1e-9, "zero-altitude horizon");
        Check(PlanetGeometry.HorizonSurfaceDistanceKm(2, R) > 150
            && PlanetGeometry.HorizonSurfaceDistanceKm(2, R) < 170,
            "2 km fixture physical horizon bounded");
        Check(!PlanetGeometry.HasGeometricLineOfSight(
            new PlanetPosition(0, 0), new PlanetPosition(0, 2), R),
            "distant surface-only site hidden");
        Check(PlanetGeometry.HasGeometricLineOfSight(
            new PlanetPosition(0, 0, 2), new PlanetPosition(0, 1), R),
            "raised observer sees nearby site");
        Check(!PlanetGeometry.HasGeometricLineOfSight(
            new PlanetPosition(0, 0, 2), new PlanetPosition(0, 30), R),
            "horizon does not reveal whole planet");
        var rng = new Random(2047);
        for (int i = 0; i < 256; i++)
        {
            var start = new PlanetPosition(rng.NextDouble() * 178 - 89,
                rng.NextDouble() * 720 - 360, rng.NextDouble() * 20);
            double course = rng.NextDouble() * 360;
            double distance = rng.NextDouble() * 1500;
            var arrived = PlanetGeometry.Destination(start, course, distance, R);
            Near(PlanetGeometry.SurfaceDistanceKm(start, arrived, R), distance,
                0.00001, "seeded great-circle roundtrip " + i);
            Check(arrived.LatitudeDegrees >= -90 && arrived.LatitudeDegrees <= 90
                && arrived.LongitudeDegrees >= -180 && arrived.LongitudeDegrees < 180,
                "seeded bounded coordinates " + i);
            Check(arrived.AltitudeKm == start.AltitudeKm, "seeded altitude invariant " + i);
        }
    }

    private static void TileChecks()
    {
        var budget = new TileBudget(3, 5);
        var a = new TileId(CubeFace.PositiveX, 4, 0, 0);
        var b = new TileId(CubeFace.PositiveZ, 4, 1, 1);
        var c = new TileId(CubeFace.NegativeX, 4, 15, 15);
        var d = new TileId(CubeFace.PositiveY, 4, 14, 14);
        var tiles = TileAdmission.PrioritizedDistinct(new[] { a, b, a, c, d }, budget);
        Check(tiles.Count == 3 && tiles[0] == a && tiles[1] == b && tiles[2] == c,
            "prioritized distinct bounded tile admission");
        Check(TileAdmission.PrioritizedDistinct(Array.Empty<TileId>(), budget).Count == 0,
            "empty candidates safe");
        Check(TileAdmission.PrioritizedDistinct(new[] { a, a, a }, budget).Count == 1,
            "dedup before cutoff");
        Check(new TileId(CubeFace.PositiveZ, 12, 4095, 4095).Level == 12,
            "max address level supported");
        Check(new TileId(CubeFace.NegativeZ, 0, 0, 0).ToString()
            == "NegativeZ/0/0/0", "traceable stable tile ID");
        Reject<ArgumentOutOfRangeException>(() => _ = new TileId(CubeFace.PositiveX, 12, 4096, 1),
            "invalid final tile column");
        Reject<ArgumentOutOfRangeException>(() => _ = new TileId((CubeFace)99, 2, 1, 1),
            "unknown tile face");
        Reject<ArgumentOutOfRangeException>(() => _ = new TileId(CubeFace.PositiveX, 13, 1, 1),
            "unknown LOD");
        Reject<ArgumentOutOfRangeException>(() => _ = new TileBudget(0, 12),
            "zero active budget");
        Reject<ArgumentOutOfRangeException>(() => _ = new TileBudget(64, 32),
            "cache smaller than active budget");
        Reject<ArgumentNullException>(() => _ = TileAdmission.PrioritizedDistinct(null!, budget),
            "null tile set");
    }

    private static void RejectionChecks()
    {
        Reject<ArgumentOutOfRangeException>(() => _ = new PlanetPosition(91, 0),
            "latitude out of range");
        Reject<ArgumentOutOfRangeException>(() => _ = new PlanetPosition(0, double.NaN),
            "NaN longitude");
        Reject<ArgumentOutOfRangeException>(() => _ = new PlanetPosition(0, 0, double.PositiveInfinity),
            "infinite altitude");
        Reject<ArgumentOutOfRangeException>(() => PlanetGeometry.RequireRadius(-3),
            "negative planet radius");
        Reject<ArgumentOutOfRangeException>(() =>
            _ = PlanetGeometry.HorizonAngleRadians(-0.1, R),
            "negative observer altitude");
        Reject<ArgumentOutOfRangeException>(() =>
            _ = PlanetGeometry.Destination(new PlanetPosition(0, 0), 0, 10, 0),
            "zero radius");
        Reject<ArgumentOutOfRangeException>(() =>
            _ = PlanetGeometry.Destination(new PlanetPosition(0, 0), double.NaN, 10, R),
            "invalid heading");
        Reject<ArgumentOutOfRangeException>(() =>
            _ = PlanetGeometry.Destination(new PlanetPosition(0, 0), 20, Math.PI * R + 0.1, R),
            "ambiguous beyond-antipodal step");
    }

    private static int Main()
    {
        try
        {
            GeodesicChecks();
            TileChecks();
            RejectionChecks();
            Console.WriteLine($"CS_WORLDMAP_CONTRACT_PASS: {_assertions} deterministic assertions; no Godot runtime or canon admitted");
            Console.WriteLine("CS_WORLDMAP_GODOT_MONO_NATIVE=NOT_ESTABLISHED");
            Console.WriteLine("CS_WORLDMAP_VISUAL_ACCEPTANCE=NOT_ESTABLISHED");
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
    }
}
