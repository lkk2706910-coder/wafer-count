using System;
using System.Data.SqlClient;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class GPTPoCDB_SampleSite_NotesTable : System.Web.UI.Page
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    private const string ToolKey = "WaferCount_Tool";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            if (Session[ToolKey] == null)
            {
                Session[ToolKey] = "SACVD";
            }
            BindTable();
        }
    }

    protected void btnSACVD_Click(object sender, EventArgs e)
    {
        Session[ToolKey] = "SACVD";
        BindTable();
    }

    protected void btnNISACVD_Click(object sender, EventArgs e)
    {
        Session[ToolKey] = "NISACVD";
        BindTable();
    }

    private string CurrentTool()
    {
        string t = (Session[ToolKey] as string ?? "SACVD").ToUpperInvariant();
        return t == "NISACVD" ? "NISACVD" : "SACVD";
    }

    private void UpdateButtonStyles(string tool)
    {
        bool nis = string.Equals(tool, "NISACVD", StringComparison.OrdinalIgnoreCase);
        btnSACVD.CssClass = nis ? "btn" : "btn active";
        btnNISACVD.CssClass = nis ? "btn active" : "btn";
    }

    // 每個機台對應的 Entity：value 為完整群組名(對應 GROUP 欄)，label 為顯示用短名
    private static string[][] GetEntities(string tool)
    {
        if (string.Equals(tool, "NISACVD", StringComparison.OrdinalIgnoreCase))
        {
            return new string[][]
            {
                new string[] { "NISACVD_SIN", "SIN" },
                new string[] { "NISACVD_4DC", "4DC" },
                new string[] { "NISACVD_LTUSG", "LTUSG" },
            };
        }
        return new string[][]
        {
            new string[] { "SACVD_HARP", "HARP" },
            new string[] { "SACVD_SA", "SA" },
            new string[] { "SACVD_SMT", "SMT" },
        };
    }

    // Entity 分類查詢：限定單一機台，GROUP 依母機號對到 entity，依群組順序 → EQPID 排序
    // EQPID 格式：TOOL-B + 兩碼數字 + 1碼字母(A/B/C)，例如 SACVD-B01A；METERTYPE = WET_CLEAN
    private static string BuildEntitySql(string tool)
    {
        // tool 來自受控集合(SACVD/NISACVD)，直接內嵌 LIKE prefix
        string toolLike = string.Equals(tool, "NISACVD", StringComparison.OrdinalIgnoreCase)
            ? "NISACVD-%"
            : "SACVD-%";

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
        AND x.EQPID LIKE '" + toolLike + @"'
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

        string tool = CurrentTool();
        UpdateButtonStyles(tool);

        // 該機台的 Entity checkbox（預設全勾），前端 JS 依勾選即時過濾表格列
        var chk = new StringBuilder();
        foreach (string[] ent in GetEntities(tool))
        {
            string value = ent[0];
            string label = ent[1];
            chk.Append("<label class='chk'><input type='checkbox' class='entChk' value='");
            chk.Append(Server.HtmlEncode(value));
            chk.Append("' checked onchange='filterEntities()' /> ");
            chk.Append(Server.HtmlEncode(label));
            chk.Append("</label>");
        }
        phEntities.Controls.Clear();
        phEntities.Controls.Add(new Literal { Text = chk.ToString() });

        string sql = BuildEntitySql(tool);

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

                // 資料列：在 <tr> 加 data-entity（= GROUP 欄值），供前端依 checkbox 過濾
                int rowCount = 0;
                while (reader.Read())
                {
                    rowCount++;
                    string groupVal = reader[0].ToString();
                    sb.Append("<tr data-entity='");
                    sb.Append(Server.HtmlEncode(groupVal));
                    sb.Append("'>");
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        sb.Append("<td>");
                        sb.Append(Server.HtmlEncode(reader[i].ToString()));
                        sb.Append("</td>");
                    }
                    sb.Append("</tr>");
                }

                sb.Append("</table>");

                // 前端：依 Entity checkbox 顯示/隱藏資料列（不 postback）
                sb.Append(@"<script type='text/javascript'>
(function(){
  window.filterEntities = function(){
    var checks = document.querySelectorAll('.entChk');
    var on = {};
    for(var i=0;i<checks.length;i++){ on[checks[i].value] = checks[i].checked; }
    var rows = document.querySelectorAll('#dataTable tr[data-entity]');
    for(var j=0;j<rows.length;j++){
      var e = rows[j].getAttribute('data-entity');
      rows[j].style.display = on[e] ? '' : 'none';
    }
  };
  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', window.filterEntities);
  }else{
    window.filterEntities();
  }
})();
</script>");

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
