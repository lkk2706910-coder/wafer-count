using System;
using System.Data.SqlClient;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class GPTPoCDB_SampleSite_NotesTable : System.Web.UI.Page
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    protected void Page_Load(object sender, EventArgs e)
    {
        BindTable();
    }

    private void BindTable()
    {
        phTable.Controls.Clear();

        // 只抓子機台 SACVD-B##[A-C] / NISACVD-B##[A-C]，且 METERTYPE = WET_CLEAN
        // EQPID 格式：TOOL-B + 兩碼數字 + 1碼字母(A/B/C)，例如 SACVD-B01A
        string sql = @"
SELECT
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
ORDER BY x.EQPID";

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
