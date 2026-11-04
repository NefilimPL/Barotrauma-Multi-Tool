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
                File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), "Update hook installed\n");
            }
            catch (Exception e) { File.AppendAllText(Path.Combine(Root, "vacuum-startup.log"), e + "\n"); }
        });
        thread.IsBackground = true;
        thread.Start();
    }
    public static void Tick()
    {
        try
        {
            game.GetField("waitForKeyHit", All).SetValue(null, false);
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
