<%@ WebHandler Language="C#" Class="SaveTargetJson" %>

using System;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;

public class SaveTargetJson : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            if (!string.Equals(context.Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
            {
                context.Response.StatusCode = 405;
                WriteJson(context, new { ok = false, error = "Method not allowed" });
                return;
            }

            string tool = (context.Request["tool"] ?? string.Empty).Trim().ToUpperInvariant();
            string mode = (context.Request["mode"] ?? string.Empty).Trim().ToUpperInvariant();
            string json = context.Request["json"] ?? string.Empty;

            if (string.IsNullOrWhiteSpace(tool) || string.IsNullOrWhiteSpace(mode))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "tool/mode required" });
                return;
            }

            // validate json
            var ser = new JavaScriptSerializer();
            object obj = ser.DeserializeObject(string.IsNullOrWhiteSpace(json) ? "{}" : json);

            string appData = context.Server.MapPath("~/App_Data/");
            if (!Directory.Exists(appData)) Directory.CreateDirectory(appData);

            string safeTool = MakeSafeFilePart(tool);
            string safeMode = MakeSafeFilePart(mode);
            string path = Path.Combine(appData, "pmwafer_targets_" + safeTool + "_" + safeMode + ".json");

            // write atomically
            string tmp = path + ".tmp";
            File.WriteAllText(tmp, ser.Serialize(obj), new UTF8Encoding(false));
            if (File.Exists(path)) File.Delete(path);
            File.Move(tmp, path);

            context.Response.AddHeader("X-Last-UTC", DateTime.UtcNow.ToString("o"));
            WriteJson(context, new { ok = true });
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            WriteJson(context, new { ok = false, error = ex.Message });
        }
    }

    private static string MakeSafeFilePart(string s)
    {
        var sb = new StringBuilder();
        foreach (char c in s)
        {
            if (char.IsLetterOrDigit(c) || c == '-' || c == '_') sb.Append(c);
        }
        return sb.Length == 0 ? "X" : sb.ToString();
    }

    private static void WriteJson(HttpContext ctx, object obj)
    {
        var ser = new JavaScriptSerializer();
        ctx.Response.Write(ser.Serialize(obj));
    }

    public bool IsReusable { get { return true; } }

    // version: 2026-04-18-1
}
