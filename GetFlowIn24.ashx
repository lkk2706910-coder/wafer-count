<%@ WebHandler Language="C#" Class="GetFlowIn24" %>

using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web;
using System.Web.Script.Serialization;

// 24hr Flow In：對每個 ENTITY 群組各執行一次
//   EXEC GPTDB_EAS.dbo.UI_AMAS_FlowIn24 'TF', '<ENTITY群組>'
// 第一層 ENTITY(群組) → 第二層 ARRV_PPID 統計 FL_QTY 總和，並給每個 ENTITY 的總和。
public class GetFlowIn24 : IHttpHandler
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    // Flow In 用的 ENTITY 群組；NISACVD 改用 proc 認得的名稱(NISA_*)
    private static readonly string[] Entities = new string[] {
        "SACVD_HARP", "SACVD_SA", "SACVD_SMT",
        "NISA_SIN", "NISA_USG", "NISA_SIN4D4C"
    };

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            string site = (context.Request["site"] ?? "TF").Trim();
            List<object> entities = new List<object>();

            using (SqlConnection conn = new SqlConnection(ConnStr))
            {
                conn.Open();

                for (int gi = 0; gi < Entities.Length; gi++)
                {
                    string ent = Entities[gi];

                    // 該群組：ARRV_PPID -> FL_QTY 總和（保留出現順序）
                    List<string> ppidOrder = new List<string>();
                    Dictionary<string, decimal> ppidSum = new Dictionary<string, decimal>();

                    using (SqlCommand cmd = new SqlCommand("EXEC GPTDB_EAS.dbo.UI_AMAS_FlowIn24 @site, @entity", conn))
                    {
                        cmd.Parameters.AddWithValue("@site", site);
                        cmd.Parameters.AddWithValue("@entity", ent);

                        using (SqlDataReader r = cmd.ExecuteReader())
                        {
                            int iPpid = ColIndex(r, "ARRV_PPID");
                            int iQty = ColIndex(r, "FL_QTY");
                            if (iPpid >= 0 && iQty >= 0)
                            {
                                while (r.Read())
                                {
                                    string ppid = r.IsDBNull(iPpid) ? "" : r.GetValue(iPpid).ToString().Trim();
                                    decimal qty = r.IsDBNull(iQty) ? 0m : ToDec(r.GetValue(iQty));
                                    if (!ppidSum.ContainsKey(ppid))
                                    {
                                        ppidOrder.Add(ppid);
                                        ppidSum[ppid] = 0m;
                                    }
                                    ppidSum[ppid] = ppidSum[ppid] + qty;
                                }
                            }
                        }
                    }

                    decimal total = 0m;
                    List<object> ppids = new List<object>();
                    for (int p = 0; p < ppidOrder.Count; p++)
                    {
                        string ppid = ppidOrder[p];
                        decimal v = ppidSum[ppid];
                        total = total + v;
                        Dictionary<string, object> row = new Dictionary<string, object>();
                        row["ppid"] = ppid;
                        row["qty"] = v;
                        ppids.Add(row);
                    }

                    Dictionary<string, object> item = new Dictionary<string, object>();
                    item["entity"] = ent;
                    item["total"] = total;
                    item["ppids"] = ppids;
                    entities.Add(item);
                }
            }

            WriteJson(context, new { ok = true, entities = entities });
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            WriteJson(context, new { ok = false, error = ex.Message });
        }
    }

    private static int ColIndex(SqlDataReader r, string name)
    {
        for (int i = 0; i < r.FieldCount; i++)
        {
            if (string.Equals(r.GetName(i), name, StringComparison.OrdinalIgnoreCase)) return i;
        }
        return -1;
    }

    private static decimal ToDec(object o)
    {
        decimal d;
        if (decimal.TryParse(o.ToString(), out d)) return d;
        return 0m;
    }

    private static void WriteJson(HttpContext ctx, object obj)
    {
        ctx.Response.Write(new JavaScriptSerializer().Serialize(obj));
    }

    public bool IsReusable { get { return true; } }
}
