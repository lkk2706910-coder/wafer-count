<%@ WebHandler Language="C#" Class="GetAllPmSchedules" %>

using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Script.Serialization;

// 讀取 App_Data 下所有 pmschedule_YYYY-MM.json，合併成單一 { 日期: [PM...] } 回傳，
// 讓前端一次取得「所有月份」的已存排程（含過往月份），不再受單月限制。
public class GetAllPmSchedules : IHttpHandler
{
    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            string appData = context.Server.MapPath("~/App_Data/");
            var merged = new Dictionary<string, object>();
            var months = new List<string>();
            var ser = new JavaScriptSerializer();

            if (Directory.Exists(appData))
            {
                foreach (string file in Directory.GetFiles(appData, "pmschedule_*.json"))
                {
                    string name = Path.GetFileNameWithoutExtension(file);
                    Match m = Regex.Match(name, @"^pmschedule_(\d{4}-\d{2})$");
                    if (!m.Success) continue;
                    months.Add(m.Groups[1].Value);

                    string json = File.ReadAllText(file, Encoding.UTF8);
                    if (string.IsNullOrWhiteSpace(json)) continue;
                    var obj = ser.DeserializeObject(json) as Dictionary<string, object>;
                    if (obj == null) continue;
                    foreach (var kv in obj) merged[kv.Key] = kv.Value;  // 日期 -> 該日 PM 陣列
                }
            }

            WriteJson(context, new { ok = true, data = merged, months = months });
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            WriteJson(context, new { ok = false, error = ex.Message });
        }
    }

    private static void WriteJson(HttpContext ctx, object obj)
    {
        ctx.Response.Write(new JavaScriptSerializer().Serialize(obj));
    }

    public bool IsReusable { get { return true; } }
}
