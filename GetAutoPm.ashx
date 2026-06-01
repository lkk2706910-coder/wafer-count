<%@ WebHandler Language="C#" Class="GetAutoPm" %>

using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Web;
using System.Web.Script.Serialization;

// 自動排 PM：對 SACVD/NISACVD 每台機台(EQPID)算「預估剩餘天數」= floor((SPEC-現值)/Avg.move)，
// 每台取最小(最快到 spec)那一項；前端再用 today + days 算到期日排進月曆。
public class GetAutoPm : IHttpHandler
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    public void ProcessRequest(HttpContext context)
    {
        context.Response.ContentType = "application/json";
        context.Response.Charset = "utf-8";

        try
        {
            var items = new List<object>();
            using (SqlConnection conn = new SqlConnection(ConnStr))
            using (SqlCommand cmd = new SqlCommand(Sql, conn))
            {
                conn.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                {
                    while (r.Read())
                    {
                        items.Add(new
                        {
                            eqpid = r["DISP_EQPID"].ToString(),
                            group = r["GRP"].ToString(),
                            days = Convert.ToInt32(r["MIN_DAYS"])
                        });
                    }
                }
            }

            WriteJson(context, new { ok = true, items = items });
        }
        catch (Exception ex)
        {
            context.Response.StatusCode = 500;
            WriteJson(context, new { ok = false, error = ex.Message });
        }
    }

    private const string Sql = @"
SELECT
    d.DISP_EQPID,
    MIN(d.GRP) AS GRP,
    MIN(d.DAYS) AS MIN_DAYS
FROM
(
    SELECT
        b.EQPID,
        CASE WHEN b.ISMF = 1 THEN b.EQPID + '-MF' ELSE b.EQPID END AS DISP_EQPID,
        b.GRP,
        CASE
            WHEN sp.SPEC IS NULL OR mv.AVG_MOVE IS NULL OR mv.AVG_MOVE <= 0 THEN NULL
            ELSE
                CASE WHEN FLOOR((sp.SPEC - TRY_CONVERT(decimal(18,4), b.DATA_VAL)) / mv.AVG_MOVE) < 0
                     THEN 0
                     ELSE FLOOR((sp.SPEC - TRY_CONVERT(decimal(18,4), b.DATA_VAL)) / mv.AVG_MOVE) END
        END AS DAYS
    FROM
    (
        SELECT
            x.EQPID, x.METERTYPE, x.DATA_VAL,
            CASE WHEN x.EQPID LIKE '%[0-9]' THEN 1 ELSE 0 END AS ISMF,
            CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID
                 ELSE LEFT(x.EQPID, LEN(x.EQPID) - 1) END AS MOM,
            CASE
                WHEN (CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID ELSE LEFT(x.EQPID, LEN(x.EQPID)-1) END)
                     IN ('SACVD-B01','SACVD-B04','SACVD-B06','SACVD-B08','SACVD-B09','SACVD-B10') THEN 'SACVD_HARP'
                WHEN (CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID ELSE LEFT(x.EQPID, LEN(x.EQPID)-1) END)
                     IN ('SACVD-B02','SACVD-B11','SACVD-B12','SACVD-B81') THEN 'SACVD_SA'
                WHEN (CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID ELSE LEFT(x.EQPID, LEN(x.EQPID)-1) END)
                     IN ('SACVD-B03','SACVD-B05','SACVD-B07') THEN 'SACVD_SMT'
                WHEN (CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID ELSE LEFT(x.EQPID, LEN(x.EQPID)-1) END)
                     IN ('NISACVD-B01','NISACVD-B06','NISACVD-B07','NISACVD-B08') THEN 'NISACVD_SIN'
                WHEN (CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID ELSE LEFT(x.EQPID, LEN(x.EQPID)-1) END)
                     IN ('NISACVD-B02','NISACVD-B04','NISACVD-B05','NISACVD-B09','NISACVD-B10','NISACVD-B11') THEN 'NISACVD_4DC'
                WHEN (CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID ELSE LEFT(x.EQPID, LEN(x.EQPID)-1) END)
                     IN ('NISACVD-B03','NISACVD-B12','NISACVD-B13','NISACVD-B14') THEN 'NISACVD_LTUSG'
                ELSE NULL
            END AS GRP
        FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
        WHERE
            x.EQPID LIKE 'SACVD-B[0-9][0-9][ABC]' OR x.EQPID LIKE 'NISACVD-B[0-9][0-9][ABC]'
            OR x.EQPID LIKE 'SACVD-B[0-9][0-9]' OR x.EQPID LIKE 'NISACVD-B[0-9][0-9]'
    ) b
    OUTER APPLY
    (
        SELECT TOP 1 TRY_CONVERT(decimal(18,4), t.ALARM) AS SPEC
        FROM GPTPoCDB.dbo._MeterTarget_DB09 t
        WHERE t.EQCH = b.EQPID AND t.METERTYPE = b.METERTYPE
        ORDER BY t.LASTREADINGTIME DESC
    ) sp
    OUTER APPLY
    (
        SELECT AVG(CAST(u.MAXQ - u.MINQ AS decimal(18,4))) AS AVG_MOVE
        FROM GPTPoCDB.dbo._MeterUEDA_DB09 u
        WHERE u.EQCH = b.EQPID AND u.METERTYPE = b.METERTYPE
          AND u.TXNDATE >= DATEADD(MONTH, -1, CAST(GETDATE() AS date))
          AND u.TXNDATE <= CAST(GETDATE() AS date)
          AND (u.MAXQ - u.MINQ) <> 0
    ) mv
    WHERE b.GRP IS NOT NULL
      AND
      (
          -- 與 wafer count 相同的每台 METERTYPE 規則
          (b.ISMF = 0 AND b.EQPID LIKE 'SACVD-%' AND b.METERTYPE = 'WET_CLEAN')
          OR (b.ISMF = 1 AND b.EQPID LIKE 'SACVD-%' AND b.METERTYPE = 'BUFFER_WET_CLEAN')
          OR (b.ISMF = 0 AND b.MOM = 'NISACVD-B01' AND b.METERTYPE IN ('A-PM','B-PM'))
          OR (b.ISMF = 0 AND b.EQPID LIKE 'NISACVD-%' AND b.MOM <> 'NISACVD-B01' AND b.METERTYPE IN ('A-PM','WET_CLEAN'))
          OR (b.ISMF = 1 AND b.MOM IN ('NISACVD-B06','NISACVD-B07','NISACVD-B08') AND b.METERTYPE = 'BUFFER_WET_CLEAN')
          OR (b.ISMF = 1 AND b.EQPID LIKE 'NISACVD-%' AND b.MOM NOT IN ('NISACVD-B06','NISACVD-B07','NISACVD-B08') AND b.METERTYPE = 'BUFFER-PM')
      )
) d
WHERE d.DAYS IS NOT NULL
GROUP BY d.DISP_EQPID
ORDER BY MIN(d.DAYS), d.DISP_EQPID";

    private static void WriteJson(HttpContext ctx, object obj)
    {
        ctx.Response.Write(new JavaScriptSerializer().Serialize(obj));
    }

    public bool IsReusable { get { return true; } }
}
