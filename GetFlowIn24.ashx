<%@ WebHandler Language="C#" Class="GetFlowIn24" %>

using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Script.Serialization;

// 24hr Flow In：執行 EXEC GPTDB_EAS.dbo.UI_AMAS_FlowIn24 'TF','ENTITY'
// 依 ENTITY(第一層) → ARRV_PPID(第二層) 統計 FL_QTY 總和，並給每個 ENTITY 的總和。
public class GetFlowIn24 : IHttpHandler
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            // 保留 ENTITY 出現順序；每個 ENTITY 下保留 ARRV_PPID 出現順序
            var entOrder = new List<string>();
            var entPpidOrder = new Dictionary<string, List<string>>();
            var entPpidSum = new Dictionary<string, Dictionary<string, decimal>>();

            using (SqlConnection conn = new SqlConnection(ConnStr))
            using (SqlCommand cmd = new SqlCommand("EXEC GPTDB_EAS.dbo.UI_AMAS_FlowIn24 'TF', 'ENTITY'", conn))
            {
                cmd.CommandType = CommandType.Text;
                conn.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    int iEnt = ColIndex(r, "ENTITY");
                    int iPpid = ColIndex(r, "ARRV_PPID");
                    int iQty = ColIndex(r, "FL_QTY");
                    if (iEnt < 0 || iPpid < 0 || iQty < 0)
                    {
                        context.Response.StatusCode = 500;
                        WriteJson(context, new { ok = false, error = "結果缺少 ENTITY / ARRV_PPID / FL_QTY 欄位" });
                        return;
                    }

                    while (r.Read())
                    {
                        string ent = r.IsDBNull(iEnt) ? "" : r.GetValue(iEnt).ToString().Trim();
                        string ppid = r.IsDBNull(iPpid) ? "" : r.GetValue(iPpid).ToString().Trim();
                        decimal qty = r.IsDBNull(iQty) ? 0m : ToDec(r.GetValue(iQty));

                        if (!entPpidSum.ContainsKey(ent))
                        {
                            entOrder.Add(ent);
                            entPpidOrder[ent] = new List<string>();
                            entPpidSum[ent] = new Dictionary<string, decimal>();
                        }
                        if (!entPpidSum[ent].ContainsKey(ppid))
                        {
                            entPpidOrder[ent].Add(ppid);
                            entPpidSum[ent][ppid] = 0m;
                        }
                        entPpidSum[ent][ppid] += qty;
                    }
                }
            }

            var entities = new List<object>();
            foreach (string ent in entOrder)
            {
                decimal total = 0m;
                var ppids = new List<object>();
                foreach (string ppid in entPpidOrder[ent])
                {
                    decimal v = entPpidSum[ent][ppid];
                    total += v;
                    ppids.Add(new Dictionary<string, object> { { "ppid", ppid }, { "qty", v } });
                }
                entities.Add(new Dictionary<string, object> {
                    { "entity", ent }, { "total", total }, { "ppids", ppids }
                });
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
            if (string.Equals(r.GetName(i), name, StringComparison.OrdinalIgnoreCase)) return i;
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
