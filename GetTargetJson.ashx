<%@ WebHandler Language="C#" Class="GetTargetJson" %>

using System;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Script.Serialization;

public class GetTargetJson : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            string tool = (context.Request["tool"] ?? string.Empty).Trim().ToUpperInvariant();
            string mode = (context.Request["mode"] ?? string.Empty).Trim().ToUpperInvariant();

            if (string.IsNullOrWhiteSpace(tool) || string.IsNullOrWhiteSpace(mode))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "tool/mode required" });
                return;
            }

            string appData = context.Server.MapPath("~/App_Data/");
            string safeTool = MakeSafeFilePart(tool);
            string safeMode = MakeSafeFilePart(mode);
            string path = Path.Combine(appData, "pmwafer_targets_" + safeTool + "_" + safeMode + ".json");

            if (!File.Exists(path))
            {
                WriteJson(context, new { ok = true, data = new { } });
                return;
            }

            string json = File.ReadAllText(path, Encoding.UTF8);
            object data;
            try
            {
                data = new JavaScriptSerializer().DeserializeObject(string.IsNullOrWhiteSpace(json) ? "{}" : json);
            }
            catch
            {
                data = new { };
            }

            context.Response.AddHeader("X-Last-UTC", File.GetLastWriteTimeUtc(path).ToString("o"));
            WriteJson(context, new { ok = true, data = data });
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
}

