using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class GPTPoCDB_SampleSite_NotesTable : System.Web.UI.Page
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    private const string FilterSessionKey = "WaferCount_EqpFilter";

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            // default to ULKCVD ALL DEP
            if (Session[FilterSessionKey] == null)
            {
                Session[FilterSessionKey] = "ULKCVD_ALL_DEP";
            }
            BindTable();
        }
    }

    protected void btnSearch_Click(object sender, EventArgs e)
    {
        BindTable();
    }

    protected void btnRefresh_Click(object sender, EventArgs e)
    {
        // Refresh without clearing filters/sort
        BindTable();
    }


    protected void btnFilter_Click(object sender, EventArgs e)
    {
        var btn = sender as Button;
        string arg = btn != null ? btn.CommandArgument : null;
        Session[FilterSessionKey] = arg;
        BindTable();
    }

    protected void btnSort_Click(object sender, EventArgs e)
    {
        var btn = sender as Button;
        string col = btn != null ? btn.CommandArgument : null;
        if (string.IsNullOrWhiteSpace(col)) col = "DATA_VAL";

        string prevCol = Session["WaferCount_SortCol"] as string;
        string prevDir = Session["WaferCount_SortDir"] as string;

        string nextDir = "ASC";
        if (string.Equals(prevCol, col, StringComparison.OrdinalIgnoreCase) && string.Equals(prevDir, "ASC", StringComparison.OrdinalIgnoreCase))
        {
            nextDir = "DESC";
        }

        Session["WaferCount_SortCol"] = col;
        Session["WaferCount_SortDir"] = nextDir;
        BindTable();
    }

    protected void btnClear_Click(object sender, EventArgs e)
    {
        txtEqp.Text = string.Empty;
        txtMeterType.Text = string.Empty;
        Session.Remove(FilterSessionKey);
        Session.Remove("WaferCount_SortCol");
        Session.Remove("WaferCount_SortDir");
        BindTable();
    }

    // 回傳 WHERE 條件片段（不含 AND），由 SQL 直接拼進去。
    // 這裡不使用參數化 LIKE pattern，因為 DEP 規則需要 OR 組合（B0%~B1% / B3%），直接回傳條件最直覺。
    private static string BuildEqpFilterWhere(string filterKey)
    {
        if (string.IsNullOrWhiteSpace(filterKey)) return null;

        string k = filterKey.Trim().ToUpperInvariant();

        // helper
        Func<string, string> dep = tool => "(" + tool + "-B0%" + "' OR x.EQPID LIKE '" + tool + "-B1%" + ")";

        switch (k)
        {
            // DEP: TOOL-B0% ~ TOOL-B1%（只要子機台，不含母機台 TOOL-B01/TOOL-B02...）
            // 子機台格式：TOOL-B + 兩碼數字 + 1碼字母，例如 B01A
            case "ULKCVD_DEP":
                return "((x.EQPID LIKE 'ULKCVD-B0%_' OR x.EQPID LIKE 'ULKCVD-B1%_') AND x.EQPID NOT LIKE 'ULKCVD-B__')";
            case "TEOSPE_DEP":
                return "((x.EQPID LIKE 'TEOSPE-B0%_' OR x.EQPID LIKE 'TEOSPE-B1%_') AND x.EQPID NOT LIKE 'TEOSPE-B__')";
            case "BLOKCVD_DEP":
                return "((x.EQPID LIKE 'BLOKCVD-B0%_' OR x.EQPID LIKE 'BLOKCVD-B1%_') AND x.EQPID NOT LIKE 'BLOKCVD-B__')";
            case "APF_DEP":
                return "((x.EQPID LIKE 'APF-B0%_' OR x.EQPID LIKE 'APF-B1%_') AND x.EQPID NOT LIKE 'APF-B__')";

            // CUR: TOOL-B3%（只要子機台，不含母機台 TOOL-B3x）
            case "ULKCVD_CUR":
                return "(x.EQPID LIKE 'ULKCVD-B3%_' AND x.EQPID NOT LIKE 'ULKCVD-B__')";

            // MF: TOOL-B__（只有母機台 ULKCVD-B01/B02...）
            case "ULKCVD_MF":
                return "x.EQPID LIKE 'ULKCVD-B__'";
            case "TEOSPE_MF":
                return "x.EQPID LIKE 'TEOSPE-B__'";
            case "BLOKCVD_MF":
                return "x.EQPID LIKE 'BLOKCVD-B__'";
            case "APF_MF":
                return "x.EQPID LIKE 'APF-B__'";

            // ALL 模式：沿用同樣規則，但 Pivot 輸出會用到（這裡不會進來）
            default:
                return null;
        }
    }

    private static bool IsAllMode(string filterKey)
    {
        return !string.IsNullOrWhiteSpace(filterKey) && filterKey.Trim().ToUpperInvariant().Contains("_ALL_");
    }

    private static string GetAllToolPrefix(string filterKey)
    {
        if (string.IsNullOrWhiteSpace(filterKey)) return null;
        string k = filterKey.Trim().ToUpperInvariant();
        if (k.StartsWith("ULKCVD_ALL_")) return "ULKCVD";
        if (k.StartsWith("TEOSPE_ALL_")) return "TEOSPE";
        if (k.StartsWith("BLOKCVD_ALL_")) return "BLOKCVD";
        if (k.StartsWith("APF_ALL_")) return "APF";
        return null;
    }

    private void BindTable()
    {
        phTable.Controls.Clear();

        string filterKey = Session[FilterSessionKey] as string;
        if (IsAllMode(filterKey))
        {
            BindPivotTable(filterKey);
            return;
        }

        // 1) 全部資料：拿掉 TOP 50
        // 2) 搜尋：兩個欄位 (EQPID / METERTYPE) 各自可做 contains 查詢
        // 3) 固定只抓指定機台群組：ULKCVD/TEOSPE/APF/BLOKCVD
        string filterWhere = BuildEqpFilterWhere(filterKey);
        string sortDir = (Session["WaferCount_SortDir"] as string) ?? "ASC";
        string sortCol = (Session["WaferCount_SortCol"] as string) ?? "EQPID";
        sortDir = string.Equals(sortDir, "DESC", StringComparison.OrdinalIgnoreCase) ? "DESC" : "ASC";
        sortCol = (sortCol ?? "EQPID").ToUpperInvariant();

        string orderBy;
        if (sortCol == "DATA_VAL")
        {
            // 避免 DATA_VAL 是 nvarchar 時的字串排序，改成 decimal 排序
            orderBy = "TRY_CONVERT(decimal(38,10), x.DATA_VAL) " + sortDir + ", x.EQPID, x.METERTYPE";
        }
        else if (sortCol == "METERTYPE")
        {
            orderBy = "x.METERTYPE " + sortDir + ", x.EQPID";
        }
        else
        {
            orderBy = "x.EQPID " + sortDir + ", x.METERTYPE";
        }

        string sql = @"
SELECT
    x.EQPID,
    x.METERTYPE,
    x.DATA_VAL
FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
WHERE
    (
        x.EQPID LIKE 'ULKCVD%'
        OR x.EQPID LIKE 'TEOSPE%'
        OR x.EQPID LIKE 'APF%'
        OR x.EQPID LIKE 'BLOKCVD%'
    )
" + (string.IsNullOrWhiteSpace(filterWhere) ? "" : ("    AND " + filterWhere + "\r\n")) +
@"    AND (@Eqp IS NULL OR x.EQPID LIKE '%' + @Eqp + '%')
    AND (@MeterType IS NULL OR x.METERTYPE LIKE '%' + @MeterType + '%')
ORDER BY " + orderBy + "\r\n";

        using (SqlConnection conn = new SqlConnection(ConnStr))
        using (SqlCommand cmd = new SqlCommand(sql, conn))
        {
            string eqp = ((txtEqp != null ? txtEqp.Text : string.Empty) ?? string.Empty).Trim();
            string meterType = ((txtMeterType != null ? txtMeterType.Text : string.Empty) ?? string.Empty).Trim();

            cmd.Parameters.AddWithValue("@Eqp", string.IsNullOrWhiteSpace(eqp) ? (object)DBNull.Value : eqp);
            cmd.Parameters.AddWithValue("@MeterType", string.IsNullOrWhiteSpace(meterType) ? (object)DBNull.Value : meterType);

            conn.Open();
            using (SqlDataReader reader = cmd.ExecuteReader())
            {
                var sb = new StringBuilder(1024 * 64);
                sb.Append("<table id='normalTable'>");

                // 表頭（EQPID / DATA_VAL 可點擊排序）
                string currentDir = (Session["WaferCount_SortDir"] as string) ?? "ASC";
                string currentCol = (Session["WaferCount_SortCol"] as string) ?? "EQPID";

                sb.Append("<tr>");
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    string colName = reader.GetName(i);
                    string colUpper = (colName ?? string.Empty).ToUpperInvariant();

                    if (colUpper == "EQPID" || colUpper == "DATA_VAL")
                    {
                        string indicator = string.Empty;
                        if (string.Equals(currentCol, colUpper, StringComparison.OrdinalIgnoreCase))
                        {
                            indicator = string.Equals(currentDir, "DESC", StringComparison.OrdinalIgnoreCase) ? " ▼" : " ▲";
                        }

                        string btnId = colUpper == "EQPID" ? btnSortEqpDummy.ClientID : btnSortDummy.ClientID;

                        sb.Append("<th>");
                        sb.Append("<a href='#' style='color:#fff; text-decoration:underline;' onclick=\"document.getElementById('");
                        sb.Append(Server.HtmlEncode(btnId));
                        sb.Append("').click(); return false;\">");
                        sb.Append(Server.HtmlEncode(colName));
                        sb.Append(Server.HtmlEncode(indicator));
                        sb.Append("</a>");
                        sb.Append("</th>");
                    }
                    else
                    {
                        sb.Append("<th>");
                        sb.Append(Server.HtmlEncode(colName));
                        sb.Append("</th>");
                    }
                }
                sb.Append("</tr>");

                // 第二列：EQPID / METERTYPE 欄位放搜尋框（前端 JS filter，不 postback）
                int eqpidIndex = -1;
                int meterTypeIndex = -1;
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    string name = reader.GetName(i);
                    if (eqpidIndex < 0 && string.Equals(name, "EQPID", StringComparison.OrdinalIgnoreCase)) eqpidIndex = i;
                    if (meterTypeIndex < 0 && string.Equals(name, "METERTYPE", StringComparison.OrdinalIgnoreCase)) meterTypeIndex = i;
                }

                if (eqpidIndex >= 0 || meterTypeIndex >= 0)
                {
                    sb.Append("<tr>");
                    for (int i = 0; i < reader.FieldCount; i++)
                    {
                        if (i == eqpidIndex)
                        {
                            sb.Append("<th><input id='eqpInline' placeholder='Search EQPID' style='width:95%;' onkeyup='filterNormal()' /></th>");
                        }
                        else if (i == meterTypeIndex)
                        {
                            sb.Append("<th><input id='mtInline' placeholder='Search METERTYPE' style='width:95%;' onkeyup='filterNormal()' /></th>");
                        }
                        else
                        {
                            sb.Append("<th></th>");
                        }
                    }
                    sb.Append("</tr>");
                }

                while (reader.Read())
                {
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

                // 前端過濾：只過濾 EQPID / METERTYPE 欄（並在 postback 後保留輸入值）
                sb.Append(@"<script type='text/javascript'>
(function(){
  function saveFilters(){
    try{
      var eqp = document.getElementById('eqpInline');
      var mt = document.getElementById('mtInline');
      if(eqp) sessionStorage.setItem('wc_eqp', eqp.value || '');
      if(mt) sessionStorage.setItem('wc_mt', mt.value || '');
    }catch(e){}
  }

  window.filterNormal = function(){
    var eqp = document.getElementById('eqpInline');
    var mt = document.getElementById('mtInline');
    var eqpFilter = (eqp && eqp.value) ? eqp.value.toUpperCase() : '';
    var mtFilter = (mt && mt.value) ? mt.value.toUpperCase() : '';

    saveFilters();

    var table = document.querySelector('#normalTable');
    if(!table) return;
    var rows = table.getElementsByTagName('tr');
    for(var i=2;i<rows.length;i++){
      var tds = rows[i].getElementsByTagName('td');
      if(!tds || tds.length < 2) continue;
      var eqpTxt = (tds[0].textContent || tds[0].innerText || '').toUpperCase();
      var mtTxt = (tds[1].textContent || tds[1].innerText || '').toUpperCase();
      var show = (eqpFilter === '' || eqpTxt.indexOf(eqpFilter) > -1) && (mtFilter === '' || mtTxt.indexOf(mtFilter) > -1);
      rows[i].style.display = show ? '' : 'none';
    }
  };

  function restoreFilters(){
    try{
      var eqp = document.getElementById('eqpInline');
      var mt = document.getElementById('mtInline');
      if(eqp){ eqp.value = sessionStorage.getItem('wc_eqp') || ''; }
      if(mt){ mt.value = sessionStorage.getItem('wc_mt') || ''; }
      if((eqp && eqp.value) || (mt && mt.value)){
        window.filterNormal();
      }
    }catch(e){}
  }

  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', restoreFilters);
  }else{
    restoreFilters();
  }
})();
</script>");

                phTable.Controls.Add(new Literal { Text = sb.ToString() });
            }
        }
    }

    private void BindPivotTable(string filterKey)
    {
        string tool = GetAllToolPrefix(filterKey);
        if (string.IsNullOrWhiteSpace(tool))
        {
            phTable.Controls.Add(new Literal { Text = "<div>Invalid ALL filter.</div>" });
            return;
        }

        // ALL 模式：把 METERTYPE 當 row，EQPID 當 column，DATA_VAL 當 value
        string eqpFilterWhere;
        string k = filterKey.Trim().ToUpperInvariant();
        if (k.EndsWith("_DEP") || k.EndsWith("_DEP_AL") || k.EndsWith("_DEP_CU"))
        {
            // DEP: B0%~B1% 子機台
            eqpFilterWhere = "((x.EQPID LIKE '" + tool + "-B0%_' OR x.EQPID LIKE '" + tool + "-B1%_') AND x.EQPID NOT LIKE '" + tool + "-B__')";

            // TEOSPE DEP 分群：AL / CU
            if (string.Equals(k, "TEOSPE_ALL_DEP_AL", StringComparison.OrdinalIgnoreCase))
            {
                // e.g. TEOSPE-B01A => B01
                eqpFilterWhere += " AND SUBSTRING(x.EQPID, 8, 3) IN ('B01','B03','B08','B12')";
            }
            else if (string.Equals(k, "TEOSPE_ALL_DEP_CU", StringComparison.OrdinalIgnoreCase))
            {
                eqpFilterWhere += " AND SUBSTRING(x.EQPID, 8, 3) IN ('B02','B04','B05','B06','B07','B09','B10','B11')";
            }
        }
        else if (k.EndsWith("_CUR"))
        {
            // CUR: B3% 子機台 (只有 ULKCVD 會有)
            // 另外排除 ULKCVD-B34 與其子機 (B34A/B34B/B34C)
            eqpFilterWhere = "(x.EQPID LIKE '" + tool + "-B3%_' AND x.EQPID NOT LIKE '" + tool + "-B__')";
            if (string.Equals(k, "ULKCVD_ALL_CUR", StringComparison.OrdinalIgnoreCase))
            {
                eqpFilterWhere += " AND x.EQPID NOT IN ('ULKCVD-B34','ULKCVD-B34A','ULKCVD-B34B','ULKCVD-B34C')";
            }
        }
        else if (k.EndsWith("_MF"))
        {
            // MF: 母機台
            eqpFilterWhere = "x.EQPID LIKE '" + tool + "-B__'";
        }
        else
        {
            phTable.Controls.Add(new Literal { Text = "<div>Invalid ALL filter.</div>" });
            return;
        }

        string eqp = ((txtEqp != null ? txtEqp.Text : string.Empty) ?? string.Empty).Trim();
        string meterTypeSearch = ((txtMeterType != null ? txtMeterType.Text : string.Empty) ?? string.Empty).Trim();

        // 特定模式: METERTYPE 只保留/排除指定清單
        string restrictedMeterTypeWhere = null;
        if (string.Equals(k, "ULKCVD_ALL_DEP", StringComparison.OrdinalIgnoreCase))
        {
            restrictedMeterTypeWhere = "x.METERTYPE IN ('WET_CLEAN','BLOK_PLATE','FACE_PLATE','MAINFOLD','PROCESS_KIT','SLIT_VALUE')";
        }
        else if (string.Equals(k, "TEOSPE_ALL_DEP", StringComparison.OrdinalIgnoreCase)
            || string.Equals(k, "TEOSPE_ALL_DEP_AL", StringComparison.OrdinalIgnoreCase)
            || string.Equals(k, "TEOSPE_ALL_DEP_CU", StringComparison.OrdinalIgnoreCase))
        {
            restrictedMeterTypeWhere = "x.METERTYPE IN ('WET_CLEAN','BLOK_PLATE','FACE_PLATE','FACE_PLATE_S2','GAS_POU','HEATER_BASE','LIQUID_POU','MAINFOLD','PROCESS_KIT','SLIT_VALUE','THROTTLE_VALVE')";
        }
        else if (string.Equals(k, "ULKCVD_ALL_CUR", StringComparison.OrdinalIgnoreCase))
        {
            // ULKCVD CUR: 不顯示指定 METERTYPE
            restrictedMeterTypeWhere = "x.METERTYPE NOT IN ('SLIT_VALVE','SLIT_VALVE_DOOR','LAMP','LIFT_PIN','MAGMENTRON')";
        }
        else if (string.Equals(k, "ULKCVD_ALL_MF", StringComparison.OrdinalIgnoreCase))
        {
            restrictedMeterTypeWhere = "x.METERTYPE IN ('ARM_SET','BUFF_BEARING','BUFFER_WET_CLEAN','LL_CLEAN','LL_OUT_DOOR','LOADPORT_UPTIME_1','LOADPORT_UPTIME_2','LOADPORT_UPTIME_3','LOADPORT_UPTIME_4','S1_SLIT_VALVE_ASSY','S2_SLIT_VALVE_ASSY','SLIT_VALVE_DOOR')";
        }

        // 先取出所有要當欄位的 EQPID（依序）
        List<string> eqpids = new List<string>();
        string sqlEqp = @"
SELECT DISTINCT x.EQPID
FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
WHERE " + eqpFilterWhere + @"
  AND (@Eqp IS NULL OR x.EQPID LIKE '%' + @Eqp + '%')
" + (string.IsNullOrWhiteSpace(restrictedMeterTypeWhere) ? "" : ("  AND " + restrictedMeterTypeWhere + "\r\n")) + @"
ORDER BY x.EQPID
";

        using (SqlConnection conn = new SqlConnection(ConnStr))
        using (SqlCommand cmdEqp = new SqlCommand(sqlEqp, conn))
        {
            conn.Open();
            cmdEqp.Parameters.AddWithValue("@Eqp", string.IsNullOrWhiteSpace(eqp) ? (object)DBNull.Value : eqp);

            using (SqlDataReader r = cmdEqp.ExecuteReader())
            {
                while (r.Read())
                {
                    eqpids.Add(r[0].ToString());
                }
            }

            if (eqpids.Count == 0)
            {
                phTable.Controls.Add(new Literal { Text = "<div>No data.</div>" });
                return;
            }

            // 取資料（長表）
            string sqlData = @"
SELECT x.METERTYPE, x.EQPID, x.DATA_VAL
FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
WHERE " + eqpFilterWhere + @"
  AND (@Eqp IS NULL OR x.EQPID LIKE '%' + @Eqp + '%')
  AND (@MeterType IS NULL OR x.METERTYPE LIKE '%' + @MeterType + '%')
" + (string.IsNullOrWhiteSpace(restrictedMeterTypeWhere) ? "" : ("  AND " + restrictedMeterTypeWhere + "\r\n")) + @"
ORDER BY x.METERTYPE, x.EQPID
";

            Dictionary<string, Dictionary<string, string>> pivot = new Dictionary<string, Dictionary<string, string>>(StringComparer.OrdinalIgnoreCase);

            using (SqlCommand cmdData = new SqlCommand(sqlData, conn))
            {
                cmdData.Parameters.AddWithValue("@Eqp", string.IsNullOrWhiteSpace(eqp) ? (object)DBNull.Value : eqp);
                cmdData.Parameters.AddWithValue("@MeterType", string.IsNullOrWhiteSpace(meterTypeSearch) ? (object)DBNull.Value : meterTypeSearch);

                using (SqlDataReader r2 = cmdData.ExecuteReader())
                {
                    while (r2.Read())
                    {
                        string meterType = r2[0].ToString();
                        string eqpid = r2[1].ToString();
                        string val = r2[2].ToString();

                    // ALL(Pivot) 數值格式化：MF 裡不顯示小數
                    // 另外維持你之前的需求：CUR 裡 UVLAMP 四項不顯示小數
                    bool isCur = k.EndsWith("_CUR");
                    bool isMf = k.EndsWith("_MF");

                    decimal d;
                    if (decimal.TryParse(val, out d))
                    {
                        if (isCur)
                        {
                            bool noDecimal = string.Equals(meterType, "SIDE1_UVLAMP_ONTIME", StringComparison.OrdinalIgnoreCase)
                                || string.Equals(meterType, "SIDE1_UVLAMP_STANDBY_ONTIME", StringComparison.OrdinalIgnoreCase)
                                || string.Equals(meterType, "SIDE2_UVLAMP_ONTIME", StringComparison.OrdinalIgnoreCase)
                                || string.Equals(meterType, "SIDE2_UVLAMP_STANDBY_ONTIME", StringComparison.OrdinalIgnoreCase);

                            if (noDecimal)
                            {
                                val = decimal.Truncate(d).ToString();
                            }
                            else
                            {
                                // CUR 其它數值：維持原樣（不強制改 1 位小數）
                                val = d.ToString();
                            }
                        }
                        else if (isMf)
                        {
                            // MF：不顯示小數
                            val = decimal.Truncate(d).ToString();
                        }
                    }
                    else
                    {
                        if (isMf)
                        {
                            int dot = val.IndexOf('.');
                            if (dot >= 0)
                            {
                                val = val.Substring(0, dot);
                            }
                        }
                        else if (isCur)
                        {
                            bool noDecimal = string.Equals(meterType, "SIDE1_UVLAMP_ONTIME", StringComparison.OrdinalIgnoreCase)
                                || string.Equals(meterType, "SIDE1_UVLAMP_STANDBY_ONTIME", StringComparison.OrdinalIgnoreCase)
                                || string.Equals(meterType, "SIDE2_UVLAMP_ONTIME", StringComparison.OrdinalIgnoreCase)
                                || string.Equals(meterType, "SIDE2_UVLAMP_STANDBY_ONTIME", StringComparison.OrdinalIgnoreCase);

                            if (noDecimal)
                            {
                                int dot = val.IndexOf('.');
                                if (dot > 0) val = val.Substring(0, dot);
                            }
                        }
                    }

                    Dictionary<string, string> row;
                    if (!pivot.TryGetValue(meterType, out row))
                    {
                        row = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                        pivot[meterType] = row;
                    }
                    row[eqpid] = val;
                    }
                }
            }

            // 輸出 HTML table (Pivot)
            string html = "<table id='pivotTable'>";
            html += "<tr><th>METERTYPE</th><th>TARGET</th>";
            foreach (string eqpid in eqpids)
            {
                string header = eqpid;
                // ALL 模式欄位不要顯示 TOOL prefix，例如 ULKCVD- / TEOSPE-
                int dash = header.IndexOf('-');
                if (dash >= 0 && dash + 1 < header.Length)
                {
                    header = header.Substring(dash + 1);
                }
                html += "<th>" + Server.HtmlEncode(header) + "</th>";
            }
            html += "</tr>";


            // 第二列：METERTYPE 欄位的搜尋框（前端 JS filter，不 postback）
            // TARGET 欄位：編輯/儲存按鈕
            html += "<tr>";
            html += "<th><input id='mtFilter' placeholder='Search METERTYPE' style='width:95%;' onkeyup='filterPivot()' /></th>";
            html += "<th>" +
                    "<button type='button' class='btn secondary' style='height:26px; padding:0 10px;' onclick='setTargetEdit(true)'>編輯</button> " +
                    "<button type='button' class='btn' style='height:26px; padding:0 10px;' onclick='saveTargets()'>儲存</button>" +
                    "</th>";
            for (int i = 0; i < eqpids.Count; i++)
            {
                html += "<th></th>";
            }
            html += "</tr>";

            // 置頂排序規則：MF 先 BUFFER_WET_CLEAN，其它模式先 WET_CLEAN，剩餘照字母排序
            bool isMfMode = k.EndsWith("_MF");
            var orderedMeterTypes = pivot.Keys
                .OrderBy(x =>
                {
                    if (isMfMode && string.Equals(x, "BUFFER_WET_CLEAN", StringComparison.OrdinalIgnoreCase)) return 0;
                    if (!isMfMode && string.Equals(x, "WET_CLEAN", StringComparison.OrdinalIgnoreCase)) return 0;
                    return 1;
                })
                .ThenBy(x => x);

            foreach (var mt in orderedMeterTypes)
            {
                html += "<tr class='pivotRow'>";
                html += "<td class='mtCell'>" + Server.HtmlEncode(mt) + "</td>";
                html += "<td class='targetCell' data-mt='" + Server.HtmlEncode(mt) + "'></td>";

                Dictionary<string, string> row = pivot[mt];
                foreach (string eqpid in eqpids)
                {
                    string cell;
                    row.TryGetValue(eqpid, out cell);
                    html += "<td class='valCell'>" + Server.HtmlEncode(cell ?? string.Empty) + "</td>";
                }
                html += "</tr>";
            }

            html += "</table>";

            // 前端過濾：只過濾 METERTYPE 欄 (第一欄)
            // TARGET：從 API 讀取 / 編輯 / 儲存
            html += @"<script type='text/javascript'>
(function(){
  function getToolMode(){
    var k = '" + Server.HtmlEncode(k) + @"';
    var parts = k.split('_');
    // e.g. ULKCVD_ALL_DEP => [ULKCVD, ALL, DEP]
    //      TEOSPE_ALL_DEP_AL => [TEOSPE, ALL, DEP, AL]
    var tool = (parts[0] || '');
    var mode = (parts[2] || '');
    if(parts.length >= 4){
      mode = mode + '_' + parts[3];
    }
    return { tool: tool, mode: mode };
  }


  window.filterPivot = function(){
    var input = document.getElementById('mtFilter');
    if(!input) return;
    var filter = (input.value || '').toUpperCase();
    var rows = document.querySelectorAll('#pivotTable tr.pivotRow');
    for(var i=0;i<rows.length;i++){
      var cell = rows[i].querySelector('td.mtCell');
      var txt = cell ? (cell.textContent || cell.innerText || '') : '';
      rows[i].style.display = (filter === '' || txt.toUpperCase().indexOf(filter) > -1) ? '' : 'none';
    }
  };

  window.setTargetEdit = function(enable){
    var cells = document.querySelectorAll('#pivotTable td.targetCell');
    for(var i=0;i<cells.length;i++){
      var cell = cells[i];
      var mt = cell.getAttribute('data-mt') || '';
      var current = cell.getAttribute('data-target') || '';

      if(enable){
        cell.textContent = '';
        var inpEl = document.createElement('input');
        inpEl.type = 'text';
        inpEl.className = 'targetInput';
        inpEl.style.width = '90px';
        inpEl.style.height = '22px';
        inpEl.value = current;
        inpEl._mt = mt;
        cell.appendChild(inpEl);
      }else{
        // if leaving edit mode, capture current input value back to data-target
        var existing = cell.querySelector('input.targetInput');
        if(existing){
          current = (existing.value || '').trim();
          cell.setAttribute('data-target', current);
        }
        cell.textContent = current;
      }
    }
  };

    function getSharedKey(){
    var tm = getToolMode();
    return { tool: tm.tool, mode: tm.mode };
  }

  window.saveTargets = async function(){
    var inputs = document.querySelectorAll('#pivotTable input.targetInput');
    if(!inputs || inputs.length === 0){
      // not in edit mode -> enter edit mode
      window.setTargetEdit(true);
      return;
    }

    var data = {};
    for(var i=0;i<inputs.length;i++){
      var inp = inputs[i];
      var mt = inp._mt || '';
      var val = (inp.value || '').trim();
      data[mt] = val;
    }

    var k = getSharedKey();
    var form = new FormData();
    form.append('tool', k.tool);
    form.append('mode', k.mode);
    form.append('json', JSON.stringify(data));

    var resp = await fetch('./TF2api/SaveTargetJson.ashx?ts=' + Date.now(), { method: 'POST', body: form });
    var txt = await resp.text();
    if(!resp.ok){
      alert('Save failed: HTTP ' + resp.status + String.fromCharCode(10) + txt);
      return;
    }

    var js;
    try{ js = JSON.parse(txt); }catch(e){
      alert('Save failed: invalid JSON response.' + String.fromCharCode(10) + txt);
      return;
    }
    if(!js || !js.ok){
      alert('Save failed: ' + (js && js.error ? js.error : 'unknown'));
      return;
    }

    await window.loadTargets();
    window.setTargetEdit(false);
    // loadTargets() will re-apply compare styling
    alert('Saved');
  };

  function applyTargetCompare(){
    var targetMap = {};
    var tCells = document.querySelectorAll('#pivotTable td.targetCell');
    for(var i=0;i<tCells.length;i++){
      var tc = tCells[i];
      var mt = tc.getAttribute('data-mt') || '';
      var t = (tc.getAttribute('data-target') || '').trim();
      targetMap[mt] = t;
    }

    // 1) compare styling (v > target => red)
    var rows = document.querySelectorAll('#pivotTable tr.pivotRow');
    for(var r=0;r<rows.length;r++){
      var row = rows[r];
      var mtCell = row.querySelector('td.mtCell');
      var mt = mtCell ? (mtCell.textContent || mtCell.innerText || '').trim() : '';
      var tStr = (targetMap[mt] != null) ? String(targetMap[mt]).trim() : '';
      var tVal = parseFloat(tStr);
      var hasTarget = tStr !== '' && !isNaN(tVal);

      var vals = row.querySelectorAll('td.valCell');
      for(var j=0;j<vals.length;j++){
        var cell = vals[j];
        cell.classList.remove('overTarget');
        if(!hasTarget) continue;
        var v = parseFloat((cell.textContent || cell.innerText || '').trim());
        if(!isNaN(v) && v > tVal){
          cell.classList.add('overTarget');
        }
      }
    }

    // 2) move WET_CLEAN / BUFFER_WET_CLEAN rows to top if any value >= 90% of target
    try{
      var table = document.getElementById('pivotTable');
      if(!table) return;

      function shouldPinRow(row){
        var mtCell = row.querySelector('td.mtCell');
        if(!mtCell) return false;
        var mt = (mtCell.textContent || mtCell.innerText || '').trim().toUpperCase();
        if(mt !== 'WET_CLEAN' && mt !== 'BUFFER_WET_CLEAN') return false;

        var tCell = row.querySelector('td.targetCell');
        var tStr = tCell ? String((tCell.getAttribute('data-target') || tCell.textContent || '')).trim() : '';
        var tVal = parseFloat(tStr);
        if(tStr === '' || isNaN(tVal) || tVal === 0) return false;

        var threshold = tVal * 0.9;
        var vals = row.querySelectorAll('td.valCell');
        for(var i=0;i<vals.length;i++){
          var v = parseFloat((vals[i].textContent || vals[i].innerText || '').trim());
          if(!isNaN(v) && v >= threshold) return true;
        }
        return false;
      }

      var pivotRows = Array.prototype.slice.call(document.querySelectorAll('#pivotTable tr.pivotRow'));
      var wetRow = null;
      var bufRow = null;
      for(var i=0;i<pivotRows.length;i++){
        var mtCell = pivotRows[i].querySelector('td.mtCell');
        var mt = mtCell ? (mtCell.textContent || mtCell.innerText || '').trim().toUpperCase() : '';
        if(mt === 'WET_CLEAN') wetRow = pivotRows[i];
        if(mt === 'BUFFER_WET_CLEAN') bufRow = pivotRows[i];
      }

      // insert after header rows (1st: header, 2nd: filter row)
      var anchor = document.querySelectorAll('#pivotTable tr')[1];
      if(!anchor) return;

      // order: WET_CLEAN then BUFFER_WET_CLEAN (only when condition met)
      if(wetRow && shouldPinRow(wetRow)){
        table.insertBefore(wetRow, anchor.nextSibling);
      }
      if(bufRow && shouldPinRow(bufRow)){
        anchor = document.querySelectorAll('#pivotTable tr')[1];
        table.insertBefore(bufRow, anchor.nextSibling);
      }
    }catch(e){
      // ignore
    }
  }

  window.loadTargets = async function(){
    var k = getSharedKey();
    var url = './TF2api/GetTargetJson.ashx?tool=' + encodeURIComponent(k.tool) + '&mode=' + encodeURIComponent(k.mode) + '&ts=' + Date.now();
    var resp = await fetch(url, { method: 'GET', cache: 'no-store' });
    var txt = await resp.text();
    if(!resp.ok){
      // don't block UI
      return;
    }

    var js;
    try{ js = JSON.parse(txt); }catch(e){
      return;
    }
    if(!js || !js.ok) return;

    var data = js.data || {};
    var cells = document.querySelectorAll('#pivotTable td.targetCell');
    for(var i=0;i<cells.length;i++){
      var cell = cells[i];
      var mt = cell.getAttribute('data-mt') || '';
      var v = (data[mt] != null) ? String(data[mt]) : '';
      cell.setAttribute('data-target', v);
      cell.textContent = v;
    }

    applyTargetCompare();
  };


  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', function(){
      window.loadTargets();
    });
  }else{
    window.loadTargets();
  }
})();
</script>";

            phTable.Controls.Add(new Literal { Text = html });
        }
    }
}
