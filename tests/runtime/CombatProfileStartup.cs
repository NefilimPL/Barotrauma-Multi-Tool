// Test-only startup hook for isolated real multiplayer clients. Never package.
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Threading;

public class StartupHook
{
    static Type game;
    static DateTime logged = DateTime.MinValue;
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
                type.GetMethods().First(m => m.Name == "Patch" && m.GetParameters().Length == 5)
                    .Invoke(instance, new object[] { game.GetMethod("Update", All), null, postfix, null, null });
                var drawPostfix = Activator.CreateInstance(hm, new object[] { typeof(StartupHook).GetMethod("DrawTick") });
                type.GetMethods().First(m => m.Name == "Patch" && m.GetParameters().Length == 5)
                    .Invoke(instance, new object[] { game.GetMethod("Draw", All), null, drawPostfix, null, null });
                File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), "Update hook installed\n");
            }
            catch (Exception e) { File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), e + "\n"); }
        });
        thread.IsBackground = true;
        thread.Start();
    }
    public static void DrawTick(object __instance)
    {
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
    public static void Tick(object __instance)
    {
        try
        {
            game.GetField("waitForKeyHit", All).SetValue(null, false);
            // Commands before content loading completes can corrupt native startup.
            if (!(bool)game.GetProperty("HasLoaded", All).GetValue(__instance, null)) return;
            var console = game.Assembly.GetType("Barotrauma.DebugConsole");
            var open = console.GetProperty("IsOpen", All);
            if (open != null) open.SetValue(null, false, null);
            string request = Path.Combine(Root, "vacuum-command.txt");
            if (File.Exists(request))
            {
                string command = File.ReadAllText(request);
                File.Delete(request);
                foreach (string line in command.Split(new[] { '\n' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    var parts = line.Split(new[] { '|' }, 2);
                    var clock = System.Diagnostics.Stopwatch.StartNew();
                    console.GetMethod("ExecuteCommand", All).Invoke(null, new object[] { parts.Length == 2 ? parts[1] : parts[0] });
                    clock.Stop();
                    if (parts.Length == 2) File.AppendAllText(Path.Combine(Root, "combat-native-profile.txt"),
                        parts[0] + ": " + clock.Elapsed.TotalMilliseconds.ToString("F3", System.Globalization.CultureInfo.InvariantCulture) + " ms\n");
                }
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
