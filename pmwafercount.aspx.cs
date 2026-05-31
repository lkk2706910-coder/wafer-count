using System;
using System.Data.SqlClient;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class GPTPoCDB_SampleSite_NotesTable : System.Web.UI.Page
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    private const string ViewModeKey = "WaferCount_ViewMode";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            if (Session[ViewModeKey] == null)
            {
                Session[ViewModeKey] = "ENTITY";
            }
            BindTable();
        }
    }

    // 按機台分類：GROUP 只分 SACVD / NISACVD
    protected void btnByTool_Click(object sender, EventArgs e)
    {
        Session[ViewModeKey] = "TOOL";
        BindTable();
    }

    // Entity 分類：GROUP 用 HARP/SA/SMT/SIN/4DC/LTUSG
    protected void btnByEntity_Click(object sender, EventArgs e)
    {
        Session[ViewModeKey] = "ENTITY";
        BindTable();
    }

    private void UpdateButtonStyles(string mode)
    {
        bool byTool = string.Equals(mode, "TOOL", StringComparison.OrdinalIgnoreCase);
        btnByTool.CssClass = byTool ? "btn active" : "btn";
        btnByEntity.CssClass = byTool ? "btn" : "btn active";
    }

    // 共用條件：子機台 SACVD-B##[A-C] / NISACVD-B##[A-C]，METERTYPE = WET_CLEAN
    // EQPID 格式：TOOL-B + 兩碼數字 + 1碼字母(A/B/C)，例如 SACVD-B01A

    // 按機台分類：GROUP 只分 SACVD / NISACVD
    private static string BuildToolSql()
    {
        return @"
SELECT
    CASE WHEN x.EQPID LIKE 'SACVD-%' THEN 'SACVD' ELSE 'NISACVD' END AS [GROUP],
    x.EQPID,
    x.METERTYPE,
    x.DATA_VAL
FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
WHERE
    (
        x.EQPID LIKE 'SACVD-B[0-9][0-9][ABC]'
        OR x.EQPID LIKE 'NISACVD-B[0-9][0-9][ABC]'
    )
    AND x.METERTYPE = 'WET_CLEAN'
ORDER BY
    CASE WHEN x.EQPID LIKE 'SACVD-%' THEN 0 ELSE 1 END,
    x.EQPID";
    }

    // Entity 分類：GROUP 依母機號(去掉結尾字母)對到 HARP/SA/SMT/SIN/4DC/LTUSG，
    // 只保留有定義群組的資料，依群組順序 → EQPID 排序
    private static string BuildEntitySql()
    {
        return @"
SELECT
    g.[GROUP],
    s.EQPID,
    s.METERTYPE,
    s.DATA_VAL
FROM
(
    SELECT
        x.EQPID,
        x.METERTYPE,
        x.DATA_VAL,
        LEFT(x.EQPID, LEN(x.EQPID) - 1) AS MOM
    FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
    WHERE
        (
            x.EQPID LIKE 'SACVD-B[0-9][0-9][ABC]'
            OR x.EQPID LIKE 'NISACVD-B[0-9][0-9][ABC]'
        )
        AND x.METERTYPE = 'WET_CLEAN'
) s
CROSS APPLY
(
    SELECT
        CASE
            WHEN s.MOM IN ('SACVD-B01','SACVD-B04','SACVD-B06','SACVD-B08','SACVD-B09','SACVD-B10') THEN 'SACVD_HARP'
            WHEN s.MOM IN ('SACVD-B02','SACVD-B11','SACVD-B12','SACVD-B81') THEN 'SACVD_SA'
            WHEN s.MOM IN ('SACVD-B03','SACVD-B05','SACVD-B07') THEN 'SACVD_SMT'
            WHEN s.MOM IN ('NISACVD-B01','NISACVD-B06','NISACVD-B07','NISACVD-B08') THEN 'NISACVD_SIN'
            WHEN s.MOM IN ('NISACVD-B02','NISACVD-B04','NISACVD-B05','NISACVD-B09','NISACVD-B10','NISACVD-B11') THEN 'NISACVD_4DC'
            WHEN s.MOM IN ('NISACVD-B03','NISACVD-B12','NISACVD-B13','NISACVD-B14') THEN 'NISACVD_LTUSG'
            ELSE NULL
        END AS [GROUP],
        CASE
            WHEN s.MOM IN ('SACVD-B01','SACVD-B04','SACVD-B06','SACVD-B08','SACVD-B09','SACVD-B10') THEN 1
            WHEN s.MOM IN ('SACVD-B02','SACVD-B11','SACVD-B12','SACVD-B81') THEN 2
            WHEN s.MOM IN ('SACVD-B03','SACVD-B05','SACVD-B07') THEN 3
            WHEN s.MOM IN ('NISACVD-B01','NISACVD-B06','NISACVD-B07','NISACVD-B08') THEN 4
            WHEN s.MOM IN ('NISACVD-B02','NISACVD-B04','NISACVD-B05','NISACVD-B09','NISACVD-B10','NISACVD-B11') THEN 5
            WHEN s.MOM IN ('NISACVD-B03','NISACVD-B12','NISACVD-B13','NISACVD-B14') THEN 6
            ELSE 99
        END AS GRP_ORD
) g
WHERE g.[GROUP] IS NOT NULL
ORDER BY g.GRP_ORD, s.EQPID";
    }

    private void BindTable()
    {
        phTable.Controls.Clear();

        string mode = (Session[ViewModeKey] as string ?? "ENTITY").ToUpperInvariant();
        UpdateButtonStyles(mode);

        string sql = mode == "TOOL" ? BuildToolSql() : BuildEntitySql();

        using (SqlConnection conn = new SqlConnection(ConnStr))
        using (SqlCommand cmd = new SqlCommand(sql, conn))
        {
            conn.Open();
            using (SqlDataReader reader = cmd.ExecuteReader())
            {
                var sb = new StringBuilder(1024 * 8);
                sb.Append("<table id='dataTable'>");

                // 表頭
                sb.Append("<tr>");
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    sb.Append("<th>");
                    sb.Append(Server.HtmlEncode(reader.GetName(i)));
                    sb.Append("</th>");
                }
                sb.Append("</tr>");

                // 資料列
                int rowCount = 0;
                while (reader.Read())
                {
                    rowCount++;
                    sb.Append("<tr>");
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        sb.Append("<td>");
                        sb.Append(Server.HtmlEncode(reader[i].ToString()));
                        sb.Append("</td>");
                    }
                    sb.Append("</tr>");
                }

                sb.Append("</table>");

                if (rowCount == 0)
                {
                    phTable.Controls.Add(new Literal { Text = "<div class='noData'>No data.</div>" });
                }
                else
                {
                    phTable.Controls.Add(new Literal { Text = sb.ToString() });
                }
            }
        }

        // 右上角 update 日期時間
        lblUpdate.Text = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
    }
}
