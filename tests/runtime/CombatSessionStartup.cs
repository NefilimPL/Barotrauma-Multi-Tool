// Test-only startup hook for isolated real multiplayer clients. Never package.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Diagnostics;
using System.Collections.Generic;
using System.Globalization;

public class StartupHook
{
    static Type game;
    static DateTime logged = DateTime.MinValue;
    static readonly List<double> frames = new List<double>();
    static readonly List<double> draws = new List<double>();
    static readonly List<double> updates = new List<double>();
    static string phase = "";
    static long phaseStarted, lastFrame;
    static DateTime phaseWrite;
    static bool awake;
    static double Ms(long ticks) { return ticks * 1000.0 / Stopwatch.Frequency; }
    const BindingFlags All = BindingFlags.Static | BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
    static string Root { get { return Environment.CurrentDirectory; } }
    public static void Initialize()
    {
        var thread = new Thread(delegate()
        {
            try
            {
                Assembly assembly = null;
                for (int i = 0; i < 240 && assembly == null; i++)
                {
                    assembly = AppDomain.CurrentDomain.GetAssemblies().FirstOrDefault(a => a.GetType("Barotrauma.GameMain") != null);
                    if (assembly == null) Thread.Sleep(250);
                }
                game = assembly.GetType("Barotrauma.GameMain");
                game.GetField("waitForKeyHit", All).SetValue(null, false);
                var harmony = Assembly.LoadFrom(Path.Combine(Root, "0Harmony.dll"));
                var type = harmony.GetType("HarmonyLib.Harmony");
                var hm = harmony.GetType("HarmonyLib.HarmonyMethod");
                var instance = Activator.CreateInstance(type, new object[] { "bmt.test.vacuum.network" });
                var postfix = Activator.CreateInstance(hm, new object[] { typeof(StartupHook).GetMethod("Tick") });
                var updatePrefix = Activator.CreateInstance(hm, new object[] { typeof(StartupHook).GetMethod("UpdateStart") });
                type.GetMethods().First(m => m.Name == "Patch" && m.GetParameters().Length == 5)
                    .Invoke(instance, new object[] { game.GetMethod("Update", All), updatePrefix, postfix, null, null });
                var drawPostfix = Activator.CreateInstance(hm, new object[] { typeof(StartupHook).GetMethod("DrawTick") });
                var drawPrefix = Activator.CreateInstance(hm, new object[] { typeof(StartupHook).GetMethod("DrawStart") });
                type.GetMethods().First(m => m.Name == "Patch" && m.GetParameters().Length == 5)
                    .Invoke(instance, new object[] { game.GetMethod("Draw", All), drawPrefix, drawPostfix, null, null });
                File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), "Update hook installed\n");
            }
            catch (Exception e) { File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), e + "\n"); }
        });
        thread.IsBackground = true;
        thread.Start();
    }
    public static void UpdateStart(out long __state) { __state = Stopwatch.GetTimestamp(); }
    public static void DrawStart(out long __state) { __state = Stopwatch.GetTimestamp(); }
    static bool Sampling(long now) { return phase.Length > 0 && phase != "done" && Ms(now - phaseStarted) >= 3000; }
    static string Stats(string name, List<double> values)
    {
        if (values.Count == 0) return "\"" + name + "_n\":0";
        var sorted = values.OrderBy(v => v).ToArray();
        Func<double, double> percentile = p => sorted[Math.Min(sorted.Length - 1, (int)Math.Ceiling(sorted.Length * p) - 1)];
        return string.Format(CultureInfo.InvariantCulture,
            "\"{0}_n\":{1},\"{0}_mean\":{2:F4},\"{0}_p50\":{3:F4},\"{0}_p95\":{4:F4},\"{0}_p99\":{5:F4},\"{0}_max\":{6:F4}",
            name, sorted.Length, sorted.Average(), percentile(.5), percentile(.95), percentile(.99), sorted[sorted.Length - 1]);
    }
    static void FinishPhase()
    {
        if (phase.Length == 0 || phase == "done") return;
        File.AppendAllText(Path.Combine(Root, "combat-session-metrics.jsonl"),
            "{\"phase\":\"" + phase + "\"," + Stats("frame_ms", frames) + "," + Stats("draw_ms", draws) + "," + Stats("update_ms", updates) +
            ",\"frames_over_33ms\":" + frames.Count(v => v > 33.333) + ",\"frames_over_50ms\":" + frames.Count(v => v > 50) + "}\n");
    }
    public static void DrawTick(object __instance, long __state)
    {
        long now = Stopwatch.GetTimestamp();
        if (Sampling(now))
        {
            draws.Add(Ms(now - __state));
            if (lastFrame != 0) frames.Add(Ms(now - lastFrame));
        }
        lastFrame = now;
        string request = Path.Combine(Root, "vacuum-capture.txt");
        if (!File.Exists(request)) return;
        try
        {
            string output = File.ReadAllText(request).Trim();
            File.Delete(request);
            var device = game.GetProperty("GraphicsDevice", All).GetValue(__instance, null);
            var pp = device.GetType().GetProperty("PresentationParameters").GetValue(device, null);
            int width = (int)pp.GetType().GetProperty("BackBufferWidth").GetValue(pp, null);
            int height = (int)pp.GetType().GetProperty("BackBufferHeight").GetValue(pp, null);
            byte[] pixels = new byte[width * height * 4];
            device.GetType().GetMethods().First(m => m.Name == "GetBackBufferData" && m.IsGenericMethodDefinition && m.GetParameters().Length == 1)
                .MakeGenericMethod(typeof(byte)).Invoke(device, new object[] { pixels });
            var textureType = device.GetType().Assembly.GetType("Microsoft.Xna.Framework.Graphics.Texture2D");
            var texture = Activator.CreateInstance(textureType, new object[] { device, width, height });
            try
            {
                textureType.GetMethods().First(m => m.Name == "SetData" && m.IsGenericMethodDefinition && m.GetParameters().Length == 1)
                    .MakeGenericMethod(typeof(byte)).Invoke(texture, new object[] { pixels });
                using (var stream = File.Create(output)) textureType.GetMethod("SaveAsPng").Invoke(texture, new object[] { stream, width, height });
            }
            finally { ((IDisposable)texture).Dispose(); }
        }
        catch (Exception e) { File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), e + "\n"); }
    }
    public static void Tick(object __instance, long __state)
    {
        try
        {
            game.GetField("waitForKeyHit", All).SetValue(null, false);
            // Commands before content loading completes can corrupt native startup.
            if (!(bool)game.GetProperty("HasLoaded", All).GetValue(__instance, null)) return;
            if (!awake)
            {
                game.GetProperty("InactiveSleepTime", All).SetValue(__instance, TimeSpan.Zero, null);
                awake = true;
            }
            long now = Stopwatch.GetTimestamp();
            if (Sampling(now)) updates.Add(Ms(now - __state));
            string phaseFile = Path.Combine(Root, "LocalMods", "MULTI-TOOL-V2", "combat-session-phase.txt");
            if (File.Exists(phaseFile) && File.GetLastWriteTimeUtc(phaseFile) != phaseWrite)
            {
                phaseWrite = File.GetLastWriteTimeUtc(phaseFile);
                string next = File.ReadAllText(phaseFile).Trim();
                if (next != phase)
                {
                    FinishPhase();phase = next;phaseStarted = now;lastFrame = 0;
                    frames.Clear();draws.Clear();updates.Clear();
                }
            }
            var console = game.Assembly.GetType("Barotrauma.DebugConsole");
            var open = console.GetProperty("IsOpen", All);
            if (open != null) open.SetValue(null, false, null);
            string request = Path.Combine(Root, "vacuum-command.txt");
            if (File.Exists(request))
            {
                string command = File.ReadAllText(request);
                File.Delete(request);
                console.GetMethod("ExecuteCommand", All).Invoke(null, new object[] { command });
            }
            if ((DateTime.UtcNow - logged).TotalSeconds >= 2)
            {
                logged = DateTime.UtcNow;
                var messages = (System.Collections.IEnumerable)console.GetField("Messages", All).GetValue(null);
                File.WriteAllLines(Path.Combine(Root, "vacuum-console.txt"), messages.Cast<object>()
                    .Select(m => Convert.ToString(m.GetType().GetField("Text", All).GetValue(m))).ToArray());
            }
        }
        catch (Exception e) { File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), e + "\n"); }
    }
}
