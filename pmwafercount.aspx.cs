using System;
using System.Data.SqlClient;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class GPTPoCDB_SampleSite_NotesTable : System.Web.UI.Page
{
    private const string ConnStr = "Server=UMCESIDB02;Database=GPTPoCDB;User Id=GPTPoCDBUser;Password=DB02.2026;";

    private const string ToolKey = "WaferCount_Tool";

    // 首次載入回 PM 排程；postback（按 SACVD/NISACVD）後停在 Wafer Count
    protected string InitialView;

    protected void Page_Load(object sender, EventArgs e)
    {
        InitialView = IsPostBack ? "wafer" : "pm";

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

    // Entity 分類查詢：限定單一機台，GROUP 依母機號對到 entity，依群組順序 → EQPID → METERTYPE 排序
    // 收兩種 EQPID：
    //   子機台(chamber)：TOOL-B + 兩碼數字 + 1碼字母(A/B/C)，例如 SACVD-B01A
    //   母機台(MF)      ：TOOL-B + 兩碼數字（無字母），例如 SACVD-B01，顯示時 EQPID 後加 -MF
    // METERTYPE 精準到每台（依使用者提供的清單），舊的不符 METERTYPE 不收：
    //   SACVD  chamber → WET_CLEAN              ；MF → BUFFER_WET_CLEAN
    //   NISACVD chamber：B01 → A-PM,B-PM         ；其餘 → A-PM,WET_CLEAN
    //   NISACVD MF     ：B06/B07/B08 → BUFFER_WET_CLEAN；其餘 → BUFFER-PM
    private static string BuildEntitySql(string tool)
    {
        bool isNis = string.Equals(tool, "NISACVD", StringComparison.OrdinalIgnoreCase);

        // tool 來自受控集合(SACVD/NISACVD)，直接內嵌 LIKE prefix
        string toolLike = isNis ? "NISACVD-%" : "SACVD-%";

        // 內層粗收候選的 METERTYPE（union），精準過濾留到外層用 MOM 判斷
        string chamberMeters = isNis ? "'A-PM','B-PM','WET_CLEAN'" : "'WET_CLEAN'";
        string mfMeters = isNis ? "'BUFFER-PM','BUFFER_WET_CLEAN'" : "'BUFFER_WET_CLEAN'";

        // 外層精準 METERTYPE 條件（每台只收指定的那幾種）
        string meterPredicate = isNis
            ? @"(
        (s.ISMF = 0 AND s.MOM = 'NISACVD-B01' AND s.METERTYPE IN ('A-PM','B-PM'))
        OR (s.ISMF = 0 AND s.MOM <> 'NISACVD-B01' AND s.METERTYPE IN ('A-PM','WET_CLEAN'))
        OR (s.ISMF = 1 AND s.MOM IN ('NISACVD-B06','NISACVD-B07','NISACVD-B08') AND s.METERTYPE = 'BUFFER_WET_CLEAN')
        OR (s.ISMF = 1 AND s.MOM NOT IN ('NISACVD-B06','NISACVD-B07','NISACVD-B08') AND s.METERTYPE = 'BUFFER-PM')
    )"
            : @"(
        (s.ISMF = 0 AND s.METERTYPE = 'WET_CLEAN')
        OR (s.ISMF = 1 AND s.METERTYPE = 'BUFFER_WET_CLEAN')
    )";

        return @"
SELECT
    g.[GROUP],
    s.DISP_EQPID AS EQPID,
    s.DISP_METERTYPE AS METERTYPE,
    s.DATA_VAL,
    s.AVG_MOVE,
    s.SPEC_VAL
FROM
(
    SELECT
        x.EQPID,
        x.METERTYPE,
        x.DATA_VAL,
        -- 母機台(結尾為數字)= 1；子機台 = 0
        CASE WHEN x.EQPID LIKE '%[0-9]' THEN 1 ELSE 0 END AS ISMF,
        -- 母機台(結尾為數字)：MOM 即自身；子機台：砍掉結尾字母
        CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID
             ELSE LEFT(x.EQPID, LEN(x.EQPID) - 1) END AS MOM,
        -- 母機台顯示加 -MF；子機台維持原樣
        CASE WHEN x.EQPID LIKE '%[0-9]' THEN x.EQPID + '-MF'
             ELSE x.EQPID END AS DISP_EQPID,
        -- 顯示用 METERTYPE：NISACVD 的 WET_CLEAN 顯示為 B-PM；其餘照原值
        " + (isNis
            ? "CASE WHEN x.METERTYPE = 'WET_CLEAN' THEN 'B-PM' ELSE x.METERTYPE END"
            : "x.METERTYPE") + @" AS DISP_METERTYPE,
        -- SPEC：從 _MeterTarget_DB09 以 EQCH+METERTYPE 對應，取 ALARM 當 spec 值
        sp.SPEC_VAL,
        -- AVG MOVE：_MeterUEDA_DB09 取前 30 天每天 move(MAXQ-MINQ) 的平均
        mv.AVG_MOVE
    FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
    OUTER APPLY
    (
        SELECT TOP 1 t.ALARM AS SPEC_VAL
        FROM GPTPoCDB.dbo._MeterTarget_DB09 t
        WHERE t.EQCH = x.EQPID AND t.METERTYPE = x.METERTYPE
        ORDER BY t.LASTREADINGTIME DESC
    ) sp
    OUTER APPLY
    (
        -- 取前 30 天(今天以前)每天 move = MAXQ - MINQ 的平均
        -- 只計入 (0, 3000]：排除 0、負值(重置/異常)及大於 3000 的異常值
        SELECT AVG(CAST(u.MAXQ - u.MINQ AS decimal(18,4))) AS AVG_MOVE
        FROM GPTPoCDB.dbo._MeterUEDA_DB09 u
        WHERE u.EQCH = x.EQPID AND u.METERTYPE = x.METERTYPE
          AND u.TXNDATE >= DATEADD(DAY, -30, CAST(GETDATE() AS date))
          AND u.TXNDATE < CAST(GETDATE() AS date)
          AND (u.MAXQ - u.MINQ) > 0
          AND (u.MAXQ - u.MINQ) <= 3000
    ) mv
    WHERE
        (
            -- 子機台(chamber)
            (
                (x.EQPID LIKE 'SACVD-B[0-9][0-9][ABC]' OR x.EQPID LIKE 'NISACVD-B[0-9][0-9][ABC]')
                AND x.METERTYPE IN (" + chamberMeters + @")
            )
            OR
            -- 母機台(MF)
            (
                (x.EQPID LIKE 'SACVD-B[0-9][0-9]' OR x.EQPID LIKE 'NISACVD-B[0-9][0-9]')
                AND x.METERTYPE IN (" + mfMeters + @")
            )
        )
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
  AND " + meterPredicate + @"
ORDER BY g.GRP_ORD, s.EQPID, s.METERTYPE";
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

                // 表頭：GROUP / EQPID / METERTYPE / DATA_VAL + SPEC(可編輯) + DIFF(SPEC-現值)
                // 每欄可點擊排序（前端，不 postback）；data-type 決定數值或文字排序
                sb.Append("<tr>");
                sb.Append("<th class='sortable' data-col='0' data-type='text' onclick='sortBy(this)'>GROUP<span class='arr'></span></th>");
                sb.Append("<th class='sortable' data-col='1' data-type='text' onclick='sortBy(this)'>EQPID<span class='arr'></span></th>");
                sb.Append("<th class='sortable' data-col='2' data-type='text' onclick='sortBy(this)'>METERTYPE<span class='arr'></span></th>");
                sb.Append("<th class='sortable' data-col='3' data-type='num' onclick='sortBy(this)'>DATA_VAL<span class='arr'></span></th>");
                sb.Append("<th class='sortable' data-col='4' data-type='num' onclick='sortBy(this)'>DIFF<span class='arr'></span></th>");
                sb.Append("<th class='sortable' data-col='5' data-type='num' onclick='sortBy(this)'>Avg. move(pair)<span class='arr'></span></th>");
                sb.Append("<th class='sortable' data-col='6' data-type='num' onclick='sortBy(this)'>預估剩餘天數<span class='arr'></span></th>");
                sb.Append("<th class='sortable' data-col='7' data-type='num' onclick='sortBy(this)'>SPEC<span class='arr'></span></th>");
                sb.Append("</tr>");

                // 資料列：在 <tr> 加 data-entity（= GROUP 欄值），供前端依 checkbox 過濾
                int rowCount = 0;
                while (reader.Read())
                {
                    rowCount++;
                    string groupVal = reader["GROUP"].ToString();
                    string eqpid = reader["EQPID"].ToString();
                    string meter = reader["METERTYPE"].ToString();
                    string dataVal = reader["DATA_VAL"].ToString();
                    // SPEC 完全來自 DB(_MeterTarget_DB09.ALARM)，讀不到則留空
                    string specDef = reader["SPEC_VAL"] == DBNull.Value ? "" : reader["SPEC_VAL"].ToString().Trim();
                    // Avg. move：前一個月每天 (MAXQ-MINQ) 的平均（_MeterUEDA_DB09），四捨五入到整數
                    string avgMove = "";
                    if (reader["AVG_MOVE"] != DBNull.Value)
                    {
                        decimal am = Convert.ToDecimal(reader["AVG_MOVE"]);
                        avgMove = Math.Round(am, MidpointRounding.AwayFromZero).ToString("0");
                    }

                    sb.Append("<tr data-entity='");
                    sb.Append(Server.HtmlEncode(groupVal));
                    sb.Append("'>");
                    sb.Append("<td>").Append(Server.HtmlEncode(groupVal)).Append("</td>");
                    sb.Append("<td>").Append(Server.HtmlEncode(eqpid)).Append("</td>");
                    sb.Append("<td>").Append(Server.HtmlEncode(meter)).Append("</td>");
                    sb.Append("<td class='valCell'>").Append(Server.HtmlEncode(dataVal)).Append("</td>");
                    // DIFF：前端即時計算
                    sb.Append("<td class='diffCell'></td>");
                    // Avg. move：唯讀顯示，取自 DB
                    sb.Append("<td class='moveCell'>").Append(Server.HtmlEncode(avgMove)).Append("</td>");
                    // 預估剩餘天數：前端依 (SPEC-現值)/Avg.move 即時計算
                    sb.Append("<td class='daysCell'></td>");
                    // SPEC：唯讀顯示，直接取自 DB
                    sb.Append("<td class='specCell'>").Append(Server.HtmlEncode(specDef)).Append("</td>");
                    sb.Append("</tr>");
                }

                sb.Append("</table>");

                // 前端：依 Entity checkbox 顯示/隱藏資料列（不 postback）
                // 勾選狀態以 sessionStorage 依機台記住，切換機台後會還原
                sb.Append(@"<script type='text/javascript'>
(function(){
  var TOOL = '" + Server.HtmlEncode(tool) + @"';
  var KEY = 'wc_ent_' + TOOL;

  function saveEntities(){
    try{
      var checks = document.querySelectorAll('.entChk');
      var map = {};
      for(var i=0;i<checks.length;i++){ map[checks[i].value] = checks[i].checked; }
      sessionStorage.setItem(KEY, JSON.stringify(map));
    }catch(e){}
  }

  function restoreEntities(){
    try{
      var saved = JSON.parse(sessionStorage.getItem(KEY) || '{}');
      var checks = document.querySelectorAll('.entChk');
      for(var i=0;i<checks.length;i++){
        if(Object.prototype.hasOwnProperty.call(saved, checks[i].value)){
          checks[i].checked = !!saved[checks[i].value];
        }
      }
    }catch(e){}
  }

  window.filterEntities = function(){
    saveEntities();
    var checks = document.querySelectorAll('.entChk');
    var on = {};
    for(var i=0;i<checks.length;i++){ on[checks[i].value] = checks[i].checked; }
    var rows = document.querySelectorAll('#dataTable tr[data-entity]');
    for(var j=0;j<rows.length;j++){
      var e = rows[j].getAttribute('data-entity');
      rows[j].style.display = on[e] ? '' : 'none';
    }
  };

  window.setAllEntities = function(state){
    var checks = document.querySelectorAll('.entChk');
    for(var i=0;i<checks.length;i++){ checks[i].checked = !!state; }
    window.filterEntities();
  };

  // ---------- DIFF (SPEC - 現值)，SPEC 唯讀，完全來自 DB ----------
  function parseNum(s){
    s = (s == null) ? '' : String(s).trim().replace(/,/g,'');
    if(s === '') return NaN;
    var v = parseFloat(s);
    return isNaN(v) ? NaN : v;
  }

  function recalcRow(row){
    var valCell = row.querySelector('.valCell');
    var specCell = row.querySelector('.specCell');
    var diffCell = row.querySelector('.diffCell');
    var moveCell = row.querySelector('.moveCell');
    var daysCell = row.querySelector('.daysCell');
    if(!diffCell) return;
    var v = parseNum(valCell ? valCell.textContent : '');
    var sp = parseNum(specCell ? specCell.textContent : '');
    if(isNaN(v) || isNaN(sp)){
      diffCell.textContent = ''; diffCell.className = 'diffCell';
      if(daysCell){ daysCell.textContent = ''; daysCell.className = 'daysCell'; }
      return;
    }
    var diff = sp - v;
    // 不顯示正負號，僅顯示數值大小
    diffCell.textContent = Math.abs(diff);
    // 現值已達/超過 spec（差值 <= 0）標紅
    diffCell.className = 'diffCell' + (diff <= 0 ? ' over' : '');

    // 預估剩餘天數 = (SPEC - 現值) / Avg.move，顯示到小數點後一位；Avg.move 無效則留空
    if(daysCell){
      var mv = parseNum(moveCell ? moveCell.textContent : '');
      if(isNaN(mv) || mv <= 0){
        daysCell.textContent = '';
        daysCell.className = 'daysCell';
      }else{
        var days = diff / mv;
        if(days < 0) days = 0;
        daysCell.textContent = days.toFixed(1);
        // 已達 spec(剩 0 天)標紅
        daysCell.className = 'daysCell' + (days <= 0 ? ' over' : '');
      }
    }
  }

  function recalcAll(){
    var rows = document.querySelectorAll('#dataTable tr[data-entity]');
    for(var i=0;i<rows.length;i++){ recalcRow(rows[i]); }
  }

  // ---------- column sorting (client-side) ----------
  var sortState = { col: -1, dir: 1 };

  function cellSortValue(row, col, type){
    var cells = row.children;
    var cell = cells[col];
    if(!cell) return type === 'text' ? '' : NaN;
    if(type === 'num'){
      var t = (cell.textContent || '').replace(/[+,]/g,'').trim();
      return parseFloat(t);
    }
    return (cell.textContent || '').trim().toUpperCase();
  }

  window.sortBy = function(th){
    var table = document.getElementById('dataTable');
    if(!table) return;
    var col = parseInt(th.getAttribute('data-col'), 10);
    var type = th.getAttribute('data-type');

    if(sortState.col === col){ sortState.dir = -sortState.dir; }
    else { sortState.col = col; sortState.dir = 1; }
    var dir = sortState.dir;

    var rows = Array.prototype.slice.call(table.querySelectorAll('tr[data-entity]'));
    rows.sort(function(a, b){
      var av = cellSortValue(a, col, type);
      var bv = cellSortValue(b, col, type);
      if(type === 'text'){
        return av < bv ? -dir : (av > bv ? dir : 0);
      }
      // 數值：NaN 永遠排最後
      var an = isNaN(av), bn = isNaN(bv);
      if(an && bn) return 0;
      if(an) return 1;
      if(bn) return -1;
      return (av - bv) * dir;
    });

    for(var i=0;i<rows.length;i++){ table.appendChild(rows[i]); }

    // 更新表頭箭頭指示
    var ths = table.querySelectorAll('th.sortable .arr');
    for(var j=0;j<ths.length;j++){ ths[j].textContent = ''; }
    var arr = th.querySelector('.arr');
    if(arr) arr.textContent = dir > 0 ? ' ▲' : ' ▼';

    window.filterEntities();
  };

  // 預設：預估剩餘天數由小到大排序（小的在最上面；空值排最後）
  function defaultSortDaysAsc(){
    var th = document.querySelector('#dataTable th[data-col=\'6\']');
    if(!th) return;
    sortState.col = -1; sortState.dir = 1; // 確保 sortBy 視為升冪
    window.sortBy(th);
  }

  function init(){
    restoreEntities();
    window.filterEntities();
    recalcAll();
    defaultSortDaysAsc();
  }
  if(document.readyState === 'loading'){
    document.addEventListener('DOMContentLoaded', init);
  }else{
    init();
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
