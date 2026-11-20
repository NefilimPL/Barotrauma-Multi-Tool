// TEST ONLY. No game compile-time references; runs in isolated server/clients.
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
    const BindingFlags All = BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static | BindingFlags.Instance;
    static Type game;
    static bool server;
    static string phase = "";
    static long started, lastFrame, tickStart, nextPoll, nextConsole;
    static int markerEvents;
    static string pendingCapture;
    public sealed class SampleBuffer
    {
        struct Interval { public long Start, End; public double Value; }
        readonly List<Interval> pending = new List<Interval>();
        public readonly List<double> Values = new List<double>();
        public int PendingCount { get { return pending.Count; } }
        public void Record(long start, long end, double value)
        { pending.Add(new Interval { Start = start, End = end, Value = value }); }
        public void Flush(long lower, long upper)
        {
            foreach (var sample in pending)
                if (sample.Start >= lower && sample.End <= upper && sample.End >= sample.Start)
                    Values.Add(sample.Value);
            pending.Clear();
        }
        public void Clear() { pending.Clear(); Values.Clear(); }
    }
    static readonly SampleBuffer frames = new SampleBuffer();
    static readonly SampleBuffer draws = new SampleBuffer();
    static readonly SampleBuffer updates = new SampleBuffer();
    static readonly SampleBuffer ticks = new SampleBuffer();
    static string Root { get { return Environment.CurrentDirectory; } }
    static double Millis(long elapsed) { return elapsed * 1000.0 / Stopwatch.Frequency; }
    static bool Active { get { return phase.Length > 0 && phase != "done"; } }
    static void Flush(long upper)
    {
        long lower = started + Stopwatch.Frequency * 5;
        frames.Flush(lower, upper); draws.Flush(lower, upper); updates.Flush(lower, upper); ticks.Flush(lower, upper);
    }
    static Type Find(string name)
    {
        return AppDomain.CurrentDomain.GetAssemblies().Select(a => a.GetType(name)).FirstOrDefault(t => t != null);
    }
    public static void Initialize()
    {
        var worker = new Thread(delegate()
        {
            try
            {
                for (int i = 0; i < 240 && game == null; i++)
                {
                    game = Find("Barotrauma.GameMain");
                    if (game == null) Thread.Sleep(250);
                }
                if (game == null) throw new Exception("GameMain not loaded");
                // Startup can request a console key before the first Update.
                // This is a noninteractive disposable test process.
                var waitForKey = game.GetField("waitForKeyHit", All);
                if (waitForKey != null) waitForKey.SetValue(null, false);
                server = Assembly.GetEntryAssembly().GetName().Name == "DedicatedServer";
                var harmony = Assembly.LoadFrom(Path.Combine(Root, "0Harmony.dll"));
                var type = harmony.GetType("HarmonyLib.Harmony");
                var methodType = harmony.GetType("HarmonyLib.HarmonyMethod");
                var instance = Activator.CreateInstance(type, new object[] { "bmt.test.performance.native" });
                var patch = type.GetMethods().First(m => m.Name == "Patch" && m.GetParameters().Length == 5);
                Action<MethodInfo, string, string> install = (original, before, after) =>
                {
                    if (original == null) throw new Exception("Missing native method");
                    Func<string, object> hook = name => name == null ? null : Activator.CreateInstance(methodType,
                        new object[] { typeof(StartupHook).GetMethod(name) });
                    patch.Invoke(instance, new object[] { original, hook(before), hook(after), null, null });
                };
                install(typeof(File).GetMethod("WriteAllText", new Type[] { typeof(string), typeof(string) }), "MarkerWrite", null);
                if (server)
                {
                    // Full fixed-step body in GameMain.Run: console, screen/simulation,
                    // server/network, Steam/EOS, task pool, coroutine manager. Excludes sleep.
                    install(Find("Barotrauma.DebugConsole").GetMethods(All).Single(m => m.Name == "Update" && m.GetParameters().Length == 0), "ServerStart", null);
                    install(Find("Barotrauma.CoroutineManager").GetMethods(All).Single(m => m.Name == "Update" && m.GetParameters().Length == 2), null, "ServerEnd");
                }
                else
                {
                    install(game.GetMethod("Update", All), "Begin", "ClientUpdate");
                    install(game.GetMethod("Draw", All), "Begin", "ClientDraw");
                }
                File.WriteAllText(Path.Combine(Root, "bmt-perf-installed.txt"), server ? "server" : "client");
            }
            catch (Exception e) { File.AppendAllText(Path.Combine(Root, "bmt-perf-error.txt"), e + "\n"); }
        });
        worker.IsBackground = true;
        worker.Start();
    }
    public static void Begin(out long __state) { __state = Stopwatch.GetTimestamp(); }
    public static void MarkerWrite(string __0, string __1)
    {
        if (!__0.EndsWith("bmt-perf-phase.txt", StringComparison.OrdinalIgnoreCase)) return;
        string expected = Path.Combine(Root, "LocalMods", "MULTI-TOOL-V2", "bmt-perf-phase.txt");
        if (!string.Equals(Path.GetFullPath(__0), expected, StringComparison.OrdinalIgnoreCase)) return;
        markerEvents++;
        string next = __1.Trim();
        long boundary = Stopwatch.GetTimestamp();
        int separator = next.LastIndexOf('|');
        if (separator >= 0)
        {
            boundary = long.Parse(next.Substring(separator + 1), CultureInfo.InvariantCulture);
            next = next.Substring(0, separator);
        }
        Change(next, boundary);
    }
    public static void ServerStart() { tickStart = Stopwatch.GetTimestamp(); }
    public static void ServerEnd()
    {
        long now = Stopwatch.GetTimestamp();
        if (tickStart != 0 && Active) ticks.Record(tickStart, now, Millis(now - tickStart));
        tickStart = 0;
        Control(now, null);
    }
    public static void ClientUpdate(object __instance, long __state)
    {
        long now = Stopwatch.GetTimestamp();
        if (Active) updates.Record(__state, now, Millis(now - __state));
        Control(now, __instance);
    }
    public static void ClientDraw(object __instance, long __state)
    {
        long now = Stopwatch.GetTimestamp();
        if (Active)
        {
            draws.Record(__state, now, Millis(now - __state));
            if (lastFrame != 0) frames.Record(lastFrame, now, Millis(now - lastFrame));
        }
        lastFrame = now;
        if (pendingCapture != null)
        {
            string output = pendingCapture; pendingCapture = null;
            try
            {
                var device = game.GetProperty("GraphicsDevice", All).GetValue(__instance, null);
                var parameters = device.GetType().GetProperty("PresentationParameters").GetValue(device, null);
                int width = (int)parameters.GetType().GetProperty("BackBufferWidth").GetValue(parameters, null);
                int height = (int)parameters.GetType().GetProperty("BackBufferHeight").GetValue(parameters, null);
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
            catch (Exception e) { File.AppendAllText(Path.Combine(Root, "bmt-perf-error.txt"), e + "\n"); }
        }
    }
    static string Stats(string name, List<double> samples)
    {
        if (samples.Count == 0) return "\"" + name + "_n\":0";
        double[] sorted = samples.OrderBy(v => v).ToArray();
        Func<double, double> percentile = p => sorted[Math.Min(sorted.Length - 1, (int)Math.Ceiling(sorted.Length * p) - 1)];
        return string.Format(CultureInfo.InvariantCulture,
            "\"{0}_n\":{1},\"{0}_mean\":{2:F5},\"{0}_p50\":{3:F5},\"{0}_p95\":{4:F5},\"{0}_p99\":{5:F5},\"{0}_max\":{6:F5}",
            name, sorted.Length, sorted.Average(), percentile(.5), percentile(.95), percentile(.99), sorted[sorted.Length - 1]);
    }
    static void Change(string next, long now)
    {
        if (next == phase) return;
        if (Active)
        {
            Flush(now);
            string result = string.Format(CultureInfo.InvariantCulture,
                "{{\"phase\":\"{0}\",\"sample_seconds\":{1:F4},{2},{3},{4},{5},\"frames_over_33ms\":{6},\"frames_over_50ms\":{7},\"marker_events\":{8}}}\n",
                phase, Math.Max(0, Millis(now - started) / 1000 - 5), Stats("tick_ms", ticks.Values),
                Stats("frame_ms", frames.Values), Stats("draw_ms", draws.Values), Stats("update_ms", updates.Values),
                frames.Values.Count(v => v > 33.333), frames.Values.Count(v => v > 50), markerEvents);
            File.AppendAllText(Path.Combine(Root, "bmt-perf-metrics.jsonl"), result);
            File.WriteAllText(Path.Combine(Root, "LocalMods", "MULTI-TOOL-V2", "bmt-perf-stopped.txt"), phase);
        }
        phase = next; started = now; lastFrame = 0;
        frames.Clear(); draws.Clear(); updates.Clear(); ticks.Clear();
    }
    static void Control(long now, object instance)
    {
        if (now < nextPoll) return;
        nextPoll = now + Stopwatch.Frequency / 10;
        try
        {
            if (!server)
            {
                game.GetField("waitForKeyHit", All).SetValue(null, false);
                if (!(bool)game.GetProperty("HasLoaded", All).GetValue(instance, null)) return;
                game.GetProperty("InactiveSleepTime", All).SetValue(instance, TimeSpan.Zero, null);
            }
            string phaseFile = Path.Combine(Root, "LocalMods", "MULTI-TOOL-V2", "bmt-perf-phase.txt");
            if (File.Exists(phaseFile))
            {
                string marker = File.ReadAllText(phaseFile).Trim();
                int separator = marker.LastIndexOf('|');
                string next = separator < 0 ? marker : marker.Substring(0, separator);
                long boundary = now;
                if (separator >= 0 && !long.TryParse(marker.Substring(separator + 1), NumberStyles.Integer,
                    CultureInfo.InvariantCulture, out boundary)) throw new FormatException("Invalid phase QPC boundary");
                if (next != phase) Change(next, boundary);
                else if (Active) Flush(now);
            }
            string ready = Path.Combine(Root, "bmt-perf-ready.txt");
            if (!File.Exists(ready)) File.WriteAllText(ready, "ready");
            string request = Path.Combine(Root, "bmt-perf-command.txt");
            var console = Find("Barotrauma.DebugConsole");
            if (File.Exists(request))
            {
                string command = File.ReadAllText(request);
                File.Delete(request);
                console.GetMethod("ExecuteCommand", All).Invoke(null, new object[] { command });
                File.WriteAllText(Path.Combine(Root, "bmt-perf-command-done.txt"), command);
            }
            if (!server)
            {
                var open = console.GetProperty("IsOpen", All);
                if (open != null) open.SetValue(null, false, null);
                string capture = Path.Combine(Root, "bmt-perf-capture.txt");
                if (File.Exists(capture))
                {
                    pendingCapture = File.ReadAllText(capture).Trim();
                    File.Delete(capture);
                }
            }
            if (now >= nextConsole)
            {
                nextConsole = now + Stopwatch.Frequency * 2;
                var messages = (System.Collections.IEnumerable)console.GetField("Messages", All).GetValue(null);
                File.WriteAllLines(Path.Combine(Root, "bmt-perf-console.txt"), messages.Cast<object>()
                    .Select(m => Convert.ToString(m.GetType().GetField("Text", All).GetValue(m))).ToArray());
            }
        }
        catch (Exception e) { File.AppendAllText(Path.Combine(Root, "bmt-perf-error.txt"), e + "\n"); }
    }
}
