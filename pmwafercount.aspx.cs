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
    s.DATA_VAL
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
            : "x.METERTYPE") + @" AS DISP_METERTYPE
    FROM GPTDB_EAS.dbo.XSITEUSAGEMETER_P56 x
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

    // 依「群組 + 類別」回傳 spec 預設值（字串；無對應回 ""）
    // 類別由顯示用 METERTYPE 與 EQPID 推導：
    //   BUFFER(MF)：dispMeter 以 BUFFER 開頭
    //   A-PM / B-PM：NISACVD chamber
    //   CH：SACVD chamber（單一值，不分 A/B-PM）
    // NISACVD_4DC 另分 CHA/B 與 CHC（看 chamber 字母）
    private static string SpecDefault(string group, string dispEqpid, string dispMeter)
    {
        if (string.IsNullOrWhiteSpace(group)) return "";
        string g = group.ToUpperInvariant();
        string m = (dispMeter ?? "").ToUpperInvariant();

        bool isBuffer = m.StartsWith("BUFFER");
        bool isApm = m == "A-PM";
        bool isBpm = m == "B-PM";

        // chamber 字母（子機台 dispEqpid 結尾為 A/B/C；MF 結尾為 -MF）
        char ch = '\0';
        if (!string.IsNullOrEmpty(dispEqpid) && !dispEqpid.ToUpperInvariant().EndsWith("-MF"))
        {
            ch = char.ToUpperInvariant(dispEqpid[dispEqpid.Length - 1]);
        }

        switch (g)
        {
            case "NISACVD_SIN":
                if (isBuffer) return "150000";
                if (isApm) return "33000";
                if (isBpm) return "16500";
                break;
            case "NISACVD_LTUSG":
                if (isBuffer) return "150000";
                if (isApm) return "35200";
                if (isBpm) return "15000";
                break;
            case "NISACVD_4DC":
                if (isBuffer) return "150000";
                if (ch == 'C')
                {
                    if (isApm) return "33000";
                    if (isBpm) return "16500";
                }
                else // CHA / CHB
                {
                    if (isApm) return "44000";
                    if (isBpm) return "11000";
                }
                break;
            case "SACVD_HARP":
                return isBuffer ? "96800" : "3300";
            case "SACVD_SA":
                return isBuffer ? "96800" : "8400";
            case "SACVD_SMT":
                return isBuffer ? "96800" : "22000";
        }
        return "";
    }

    // spec 的識別鍵：每一列獨立（EQPID + METERTYPE），編輯互不影響
    private static string SpecKey(string group, string dispEqpid, string dispMeter)
    {
        return (dispEqpid ?? "") + "|" + (dispMeter ?? "");
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
                sb.Append("<th class='sortable' data-col='5' data-type='spec' onclick='sortBy(this)'>SPEC<span class='arr'></span></th>");
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
                    string specDef = SpecDefault(groupVal, eqpid, meter);
                    // spec key：群組 + 類別 + chamber，讓相同 spec 的列共用同一值
                    string specKey = SpecKey(groupVal, eqpid, meter);

                    sb.Append("<tr data-entity='");
                    sb.Append(Server.HtmlEncode(groupVal));
                    sb.Append("'>");
                    sb.Append("<td>").Append(Server.HtmlEncode(groupVal)).Append("</td>");
                    sb.Append("<td>").Append(Server.HtmlEncode(eqpid)).Append("</td>");
                    sb.Append("<td>").Append(Server.HtmlEncode(meter)).Append("</td>");
                    sb.Append("<td class='valCell'>").Append(Server.HtmlEncode(dataVal)).Append("</td>");
                    // DIFF：前端即時計算
                    sb.Append("<td class='diffCell'></td>");
                    // SPEC：可編輯輸入框，data-default 供「重置」用，data-key 供存檔/共用
                    sb.Append("<td><input type='text' class='specInput' style='width:90px;' data-key='");
                    sb.Append(Server.HtmlEncode(specKey));
                    sb.Append("' data-default='");
                    sb.Append(Server.HtmlEncode(specDef));
                    sb.Append("' value='");
                    sb.Append(Server.HtmlEncode(specDef));
                    sb.Append("' oninput='onSpecInput(this)' /></td>");
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

  // ---------- SPEC (editable) + DIFF (現值 - SPEC) ----------
  var SPEC_KEY = 'wc_spec_' + TOOL;     // sessionStorage cache key
  var saveTimer = null;

  function parseNum(s){
    s = (s == null) ? '' : String(s).trim().replace(/,/g,'');
    if(s === '') return NaN;
    var v = parseFloat(s);
    return isNaN(v) ? NaN : v;
  }

  function recalcRow(input){
    var row = input.closest('tr');
    if(!row) return;
    var valCell = row.querySelector('.valCell');
    var diffCell = row.querySelector('.diffCell');
    if(!diffCell) return;
    var v = parseNum(valCell ? valCell.textContent : '');
    var sp = parseNum(input.value);
    if(isNaN(v) || isNaN(sp)){ diffCell.textContent = ''; diffCell.className = 'diffCell'; return; }
    var diff = sp - v;
    // 不顯示正負號，僅顯示數值大小
    diffCell.textContent = Math.abs(diff);
    // 現值已達/超過 spec（差值 <= 0）標紅
    diffCell.className = 'diffCell' + (diff <= 0 ? ' over' : '');
  }

  function recalcAll(){
    var inputs = document.querySelectorAll('.specInput');
    for(var i=0;i<inputs.length;i++){ recalcRow(inputs[i]); }
  }

  window.onSpecInput = function(input){
    recalcRow(input);
    // debounce 存檔
    if(saveTimer) clearTimeout(saveTimer);
    saveTimer = setTimeout(saveSpecs, 600);
  };

  function collectSpecs(){
    var map = {};
    var inputs = document.querySelectorAll('.specInput');
    for(var i=0;i<inputs.length;i++){
      map[inputs[i].getAttribute('data-key')] = inputs[i].value.trim();
    }
    return map;
  }

  function applySpecs(map){
    if(!map) return;
    var inputs = document.querySelectorAll('.specInput');
    for(var i=0;i<inputs.length;i++){
      var k = inputs[i].getAttribute('data-key');
      if(Object.prototype.hasOwnProperty.call(map, k) && map[k] !== ''){
        inputs[i].value = map[k];
      }
    }
  }

  async function saveSpecs(){
    var map = collectSpecs();
    try{ sessionStorage.setItem(SPEC_KEY, JSON.stringify(map)); }catch(e){}
    try{
      var form = new FormData();
      form.append('tool', TOOL);
      form.append('mode', 'SPEC');
      form.append('json', JSON.stringify(map));
      await fetch('./TF2api/SaveTargetJson.ashx?ts=' + Date.now(), { method:'POST', body:form });
    }catch(e){}
  }

  async function loadSpecs(){
    // 先用 sessionStorage 快取即時套用，再用伺服器值覆蓋
    try{
      var cached = JSON.parse(sessionStorage.getItem(SPEC_KEY) || 'null');
      if(cached) applySpecs(cached);
    }catch(e){}
    recalcAll();
    try{
      var url = './TF2api/GetTargetJson.ashx?tool=' + encodeURIComponent(TOOL) + '&mode=SPEC&ts=' + Date.now();
      var resp = await fetch(url, { cache:'no-store' });
      if(resp.ok){
        var js = await resp.json();
        if(js && js.ok && js.data) applySpecs(js.data);
      }
    }catch(e){}
    recalcAll();
  }

  // ---------- column sorting (client-side) ----------
  var sortState = { col: -1, dir: 1 };

  function cellSortValue(row, col, type){
    var cells = row.children;
    var cell = cells[col];
    if(!cell) return type === 'text' ? '' : NaN;
    if(type === 'spec'){
      var inp = cell.querySelector('input');
      var raw = inp ? inp.value : cell.textContent;
      return parseFloat(String(raw).replace(/,/g,''));
    }
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

  // 預設：DIFF 欄由小到大排序（等 spec 載入、DIFF 算好後才排）
  function defaultSortDiffAsc(){
    var th = document.querySelector('#dataTable th[data-col=\'4\']');
    if(!th) return;
    sortState.col = -1; sortState.dir = 1; // 確保 sortBy 視為升冪
    window.sortBy(th);
  }

  async function init(){
    restoreEntities();
    window.filterEntities();
    await loadSpecs();
    defaultSortDiffAsc();
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
