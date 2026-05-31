<%@ WebHandler Language="C#" Class="SavePmSchedule" %>

using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;

public class SavePmSchedule : IHttpHandler
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

            string ym = (context.Request["ym"] ?? string.Empty).Trim();
            string json = context.Request["json"] ?? string.Empty;

            if (!Regex.IsMatch(ym, @"^\d{4}-\d{2}$"))
            {
                context.Response.StatusCode = 400;
                WriteJson(context, new { ok = false, error = "ym must be YYYY-MM" });
                return;
            }

            // validate json
            var ser = new JavaScriptSerializer();
            object obj = ser.DeserializeObject(string.IsNullOrWhiteSpace(json) ? "{}" : json);

            string appData = context.Server.MapPath("~/App_Data/");
            if (!Directory.Exists(appData)) Directory.CreateDirectory(appData);

            string safeYm = MakeSafeFilePart(ym);
            string path = Path.Combine(appData, "pmschedule_" + safeYm + ".json");

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
}
