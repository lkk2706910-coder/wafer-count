<%@ Page Language="C#" AutoEventWireup="true" CodeFile="pmwafercount.aspx.cs" Inherits="GPTPoCDB_SampleSite_NotesTable" %>

<!DOCTYPE html>
<html>
<head>
    <title>PM Wafer Count / PM Schedule</title>
    <style>
        :root {
            --blue-1: #4aa3d8;
            --blue-2: #2f7fb4;
            --line: #c9d7e3;
            --text: #1f2a33;
        }

        body {
            font-family: "Segoe UI", Arial, Helvetica, sans-serif;
            color: var(--text);
            margin: 18px;
        }

        /* top bar: tabs left, update time right */
        .topBar {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 14px;
        }

        .tabs {
            display: inline-flex;
            border: 1px solid #1f6fa0;
            border-radius: 8px;
            overflow: hidden;
        }

        .tab {
            height: 34px;
            padding: 0 20px;
            border: none;
            border-right: 1px solid #1f6fa0;
            background: #f5f7fa;
            color: #27414f;
            font-weight: 700;
            cursor: pointer;
        }

        .tab:last-child { border-right: none; }
        .tab:hover { background: #e9f1f8; }

        .tab.active {
            background: linear-gradient(#3b8ec3, #2f7fb4);
            color: #fff;
            cursor: default;
        }

        .tab.active:hover { background: linear-gradient(#3b8ec3, #2f7fb4); }

        .updateInfo {
            font-size: 12px;
            color: #355160;
            white-space: nowrap;
        }

        .updateInfo .label {
            font-weight: 700;
            margin-right: 4px;
        }

        .view h2 {
            margin: 0 0 12px 0;
            font-weight: 600;
        }

        /* ----- wafer count view ----- */
        .toolbar {
            display: inline-flex;
            gap: 0;
            margin-bottom: 12px;
            border: 1px solid #1f6fa0;
            border-radius: 8px;
            overflow: hidden;
        }

        .btn {
            height: 32px;
            padding: 0 18px;
            border: none;
            border-right: 1px solid #1f6fa0;
            background: #f5f7fa;
            color: #27414f;
            font-weight: 600;
            cursor: pointer;
        }

        .toolbar .btn:last-child { border-right: none; }
        .btn:hover { background: #e9f1f8; }

        .btn.active {
            background: linear-gradient(#3b8ec3, #2f7fb4);
            color: #fff;
            box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.25);
            cursor: default;
        }

        .btn.active:hover { background: linear-gradient(#3b8ec3, #2f7fb4); }

        .entityBar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 8px 14px;
            padding: 8px 12px;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: #fff;
            margin-bottom: 12px;
        }

        .entityBar .entityLabel { font-weight: 700; color: #244657; }

        .entityBar .chk {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            font-size: 13px;
            color: #27414f;
            cursor: pointer;
            user-select: none;
        }

        .entityBar .chk input { cursor: pointer; }

        .entityBar .entitySep {
            width: 1px;
            align-self: stretch;
            background: var(--line);
            margin: 0 2px;
        }

        .miniBtn {
            height: 26px;
            padding: 0 10px;
            border-radius: 6px;
            border: 1px solid var(--line);
            background: #f5f7fa;
            color: #27414f;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
        }

        .miniBtn:hover { background: #e9f1f8; }

        .tableWrap {
            border: 1px solid var(--line);
            border-radius: 8px;
            overflow: auto;
            background: #fff;
        }

        table { border-collapse: collapse; width: 100%; min-width: 480px; }

        th, td {
            border: 1px solid var(--line);
            padding: 6px 10px;
            text-align: left;
            font-size: 13px;
            white-space: nowrap;
        }

        th {
            background: linear-gradient(#6bc0ef, #3b8ec3);
            color: #fff;
            position: sticky;
            top: 0;
            z-index: 2;
        }

        tr:nth-child(even) td { background: #fafcff; }
        .noData { padding: 14px; color: #888; }

        #dataTable .moveCell { text-align: right; font-variant-numeric: tabular-nums; color: #355160; }
        #dataTable .daysCell { text-align: right; font-variant-numeric: tabular-nums; }
        #dataTable .daysCell.over { color: #d93025; font-weight: 700; }
        #dataTable .specCell { text-align: right; font-variant-numeric: tabular-nums; color: #355160; }
        #dataTable .diffCell { text-align: right; font-variant-numeric: tabular-nums; }
        #dataTable .diffCell.over { color: #d93025; font-weight: 700; }

        #dataTable th.sortable { cursor: pointer; user-select: none; }
        #dataTable th.sortable:hover { background: linear-gradient(#7cc8f2, #4a9ccb); }
        #dataTable th .arr { font-size: 11px; }

        /* ----- PM schedule view ----- */
        .pmLayout {
            display: flex;
            gap: 14px;
            align-items: flex-start;
        }

        .pmCalWrap { flex: 1 1 auto; min-width: 0; }

        .pmCalHead {
            display: flex;
            align-items: center;
            gap: 12px;
            margin-bottom: 10px;
        }

        .pmAutoList { margin-top: 12px; }
        .pmAutoList .autoErr { color: #c0392b; background: #fdecea; border: 1px solid #f5c6c0; border-radius: 6px; padding: 8px 10px; margin-bottom: 8px; font-size: 12px; white-space: pre-wrap; }
        .pmAutoList .autoHd { font-weight: 700; color: #244657; margin-bottom: 6px; display: flex; align-items: center; justify-content: space-between; gap: 10px; }
        .pmAutoList .autoTbl { border-collapse: collapse; width: 100%; }
        .pmAutoList .autoTbl th { background: #eef4f9; color: #27414f; text-align: left; padding: 5px 8px; font-size: 12px; border: 1px solid var(--line); position: static; }
        .pmAutoList .autoTbl td { padding: 4px 8px; font-size: 12px; border: 1px solid var(--line); }
        .pmAutoList .ovr { color: #b5731d; }

        .pmDirtyTag { color: #c0392b; font-size: 12px; font-weight: 700; }
        .pmSaveBtn:not([disabled]) { background: linear-gradient(#5bb6ea, #2f7fb4); color: #fff; border-color: #1f6fa0; }
        .pmLegend { margin-left: auto; display: inline-flex; gap: 12px; font-size: 12px; }
        .pmLegend .lgAuto { color: #b5731d; }
        .pmLegend .lgMoved { color: #2f7fb4; }
        .pmLegend .lgManual { color: #36a35b; }

        .pmCalHead .monthLabel {
            font-size: 18px;
            font-weight: 700;
            color: #244657;
            min-width: 150px;
            text-align: center;
        }

        .navBtn {
            height: 30px;
            width: 36px;
            border-radius: 6px;
            border: 1px solid #1f6fa0;
            background: #f5f7fa;
            color: #1f6fa0;
            font-weight: 700;
            cursor: pointer;
        }

        .navBtn:hover { background: #e9f1f8; }

        table.calendar {
            table-layout: fixed;
            width: 100%;
            min-width: 700px;
            border-collapse: collapse;
        }

        table.calendar th {
            background: linear-gradient(#6bc0ef, #3b8ec3);
            color: #fff;
            text-align: center;
            padding: 6px;
            position: static;
        }

        table.calendar td {
            vertical-align: top;
            height: 96px;
            width: 14.28%;
            padding: 4px;
            white-space: normal;
        }

        td.dayCell.other { background: #f4f6f8; }
        td.dayCell.today { outline: 2px solid var(--blue-1); outline-offset: -2px; }

        .dayHead {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 3px;
        }

        .dayNum { font-weight: 700; font-size: 12px; color: #355160; }
        .dayNum.sun { color: #d93025; }
        .dayNum.sat { color: #d93025; }

        .addPm {
            border: none;
            background: transparent;
            color: #2f7fb4;
            font-size: 16px;
            line-height: 1;
            cursor: pointer;
            padding: 0 2px;
            visibility: hidden;
        }

        td.dayCell:hover .addPm { visibility: visible; }

        /* manual PM item -> green */
        .pmItem {
            display: flex;
            align-items: center;
            gap: 4px;
            font-size: 11px;
            background: #e8f7ec;
            border: 1px solid #a9dcb7;
            border-radius: 4px;
            padding: 2px 4px;
            margin-bottom: 3px;
            color: #1f7a3d;
            cursor: grab;
        }

        .pmItem:active { cursor: grabbing; }
        .pmItem:hover { background: #d6f0dd; }
        .pmItem.selected { background: #2e9e54; color: #fff; border-color: #1f7a3d; }
        .pmItem.dragging { opacity: 0.4; }
        .pmItem .dot { color: #36a35b; font-weight: 700; flex: 0 0 auto; }
        .pmItem .dot.empty { color: #d99a00; }

        /* auto-scheduled PM item */
        .pmItem.auto {
            background: #fff4e6;
            border: 1px dashed #e0a45c;
            color: #9a5b14;
        }
        .pmItem.auto:hover { background: #ffe9cf; }
        .pmItem.auto.selected { background: #d98e2b; color: #fff; border-color: #b5731d; }
        .pmItem.auto .dot.auto { color: #d98e2b; }
        .pmItem.auto.selected .dot.auto { color: #fff; }

        /* auto item that was manually moved -> light blue */
        .pmItem.auto.moved {
            background: #e6f3fc;
            border: 1px solid #8ec5e8;
            color: #1f6fa0;
        }
        .pmItem.auto.moved:hover { background: #d4eafa; }
        .pmItem.auto.moved.selected { background: #2f7fb4; color: #fff; border-color: #1f6fa0; }
        .pmItem.auto.moved .dot.auto { color: #2f7fb4; }
        .pmItem.auto.moved.selected .dot.auto { color: #fff; }

        .pmItem .pmLabel {
            flex: 1 1 auto;
            min-width: 0;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .pmItem .pmActions {
            flex: 0 0 auto;
            display: none;
            gap: 1px;
        }

        .pmItem:hover .pmActions { display: inline-flex; }

        .pmItem .iconBtn {
            border: none;
            background: transparent;
            color: inherit;
            font-size: 11px;
            line-height: 1;
            padding: 1px 3px;
            border-radius: 3px;
            cursor: pointer;
        }

        .pmItem .iconBtn:hover { background: rgba(0, 0, 0, 0.12); }
        .pmItem.selected .iconBtn:hover { background: rgba(255, 255, 255, 0.25); }

        td.dayCell.dragOver { background: #fff6da; outline: 2px dashed var(--blue-2); outline-offset: -2px; }

        /* editor panel (right) */
        .pmEditor {
            flex: 0 0 320px;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: #fff;
            padding: 14px;
            position: sticky;
            top: 10px;
        }

        .pmEditor h3 { margin: 0 0 10px 0; font-size: 15px; color: #244657; }
        .pmEditor .muted { color: #8aa0ad; font-size: 13px; }
        .pmEditor label {
            display: block;
            font-size: 12px;
            font-weight: 700;
            color: #355160;
            margin: 10px 0 4px;
        }

        .pmEditor input[type="text"], .pmEditor textarea {
            width: 100%;
            box-sizing: border-box;
            border: 1px solid var(--line);
            border-radius: 6px;
            padding: 6px 8px;
            font-family: inherit;
            font-size: 13px;
        }

        .pmEditor textarea { min-height: 70px; resize: vertical; }
        .pmEditor .row { display: flex; gap: 8px; margin-top: 12px; }
        .pmEditor .row .btn { border-radius: 6px; border: 1px solid #1f6fa0; }
        .pmEditor .primary { background: linear-gradient(#5bb6ea, #2f7fb4); color: #fff; }
        .pmEditor .danger { background: #fff; border-color: #d99; color: #c0392b; }

        /* ----- work assignment view ----- */
        .waHead { display: flex; align-items: center; gap: 12px; margin-bottom: 10px; }
        .waHead .monthLabel { font-size: 18px; font-weight: 700; color: #244657; min-width: 150px; text-align: center; }

        table.waTable { border-collapse: collapse; width: 100%; min-width: 560px; }
        table.waTable th {
            background: linear-gradient(#6bc0ef, #3b8ec3);
            color: #fff; text-align: left; padding: 8px 10px; font-size: 13px; position: static;
        }
        table.waTable td { border: 1px solid var(--line); padding: 6px 10px; font-size: 13px; vertical-align: top; }
        table.waTable tr:nth-child(even) td { background: #fafcff; }
        table.waTable .waContent { white-space: pre-wrap; max-width: 420px; }
        table.waTable .waDate { white-space: nowrap; font-weight: 600; color: #244657; }
        table.waTable .waPerson {
            width: 100%; box-sizing: border-box; border: 1px solid var(--line);
            border-radius: 6px; padding: 5px 8px; font-size: 13px; font-family: inherit;
        }

        .hidden { display: none !important; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="topBar">
            <div class="tabs">
                <button type="button" class="tab active" data-view="pm" onclick="showView('pm')">PM 排程</button>
                <button type="button" class="tab" data-view="work" onclick="showView('work')">工作分配</button>
                <button type="button" class="tab" data-view="wafer" onclick="showView('wafer')">Wafer Count</button>
            </div>
            <div class="updateInfo">
                <span class="label">Update:</span>
                <asp:Label ID="lblUpdate" runat="server" />
            </div>
        </div>

        <!-- ===== Wafer Count view ===== -->
        <div id="waferView" class="view hidden">
            <h2>PM wafer count &mdash; WET_CLEAN (SACVD / NISACVD)</h2>

            <div class="toolbar">
                <asp:Button ID="btnSACVD" runat="server" Text="SACVD" OnClick="btnSACVD_Click" CssClass="btn active" />
                <asp:Button ID="btnNISACVD" runat="server" Text="NISACVD" OnClick="btnNISACVD_Click" CssClass="btn" />
            </div>

            <div class="entityBar">
                <span class="entityLabel">Entity分類：</span>
                <asp:PlaceHolder ID="phEntities" runat="server"></asp:PlaceHolder>
                <span class="entitySep"></span>
                <button type="button" class="miniBtn" onclick="setAllEntities(true)">全選</button>
                <button type="button" class="miniBtn" onclick="setAllEntities(false)">全不選</button>
            </div>

            <div class="tableWrap">
                <asp:PlaceHolder ID="phTable" runat="server"></asp:PlaceHolder>
            </div>
        </div>

        <!-- ===== PM Schedule view ===== -->
        <div id="pmView" class="view">
            <h2>PM 排程月曆</h2>
            <div class="pmLayout">
                <div class="pmCalWrap">
                    <div class="pmCalHead">
                        <button type="button" class="navBtn" onclick="pmPrevMonth()">&#9664;</button>
                        <div class="monthLabel" id="pmMonthLabel"></div>
                        <button type="button" class="navBtn" onclick="pmNextMonth()">&#9654;</button>
                        <button type="button" class="miniBtn" onclick="pmGoToday()">今天</button>
                        <button type="button" class="miniBtn pmSaveBtn" onclick="pmSaveAll()" disabled>儲存變更</button>
                        <button type="button" class="miniBtn pmRestoreBtn" onclick="pmRestore()" disabled>回復</button>
                        <span class="pmDirtyTag hidden">● 未儲存</span>
                        <span class="pmLegend">
                            <span class="lg lgAuto">&#9650; 自動預估</span>
                            <span class="lg lgMoved">&#9650; 已移動</span>
                            <span class="lg lgManual">&#9679; 手動</span>
                        </span>
                    </div>
                    <div id="pmCalendar"></div>
                    <div id="pmAutoList" class="pmAutoList"></div>
                </div>

                <div class="pmEditor">
                    <h3>PM 內容</h3>
                    <div id="pmEditorEmpty" class="muted">點選日期格右上的 <b>+</b> 新增機台 PM，或點月曆中的機台名稱編輯。</div>
                    <div id="pmEditorForm" class="hidden">
                        <div><b>日期：</b><span id="pmEdDate"></span></div>
                        <div id="pmEdMeterRow" class="hidden"><b>量測項：</b><span id="pmEdMeter"></span></div>
                        <label>機台 EQPID</label>
                        <input type="text" id="pmEdEqp" placeholder="例如 SACVD-B01A" />
                        <label>PM Action</label>
                        <textarea id="pmEdAction" placeholder="輸入本次 PM 要執行的動作"></textarea>
                        <label>回線測機項目</label>
                        <textarea id="pmEdRetest" placeholder="輸入回線後要測試/驗證的項目"></textarea>
                        <div class="row">
                            <button type="button" class="btn primary" onclick="pmSaveEntry()">套用</button>
                            <button type="button" class="btn danger" id="pmDelBtn" onclick="pmDeleteEntry()">刪除</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- ===== Work Assignment view ===== -->
        <div id="workView" class="view hidden">
            <h2>工作分配</h2>
            <div class="waHead">
                <button type="button" class="navBtn" onclick="pmPrevMonth()">&#9664;</button>
                <div class="monthLabel" id="waMonthLabel"></div>
                <button type="button" class="navBtn" onclick="pmNextMonth()">&#9654;</button>
                <button type="button" class="miniBtn" onclick="pmGoToday()">今天</button>
                <button type="button" class="miniBtn pmSaveBtn" onclick="pmSaveAll()" disabled>儲存變更</button>
                <button type="button" class="miniBtn pmRestoreBtn" onclick="pmRestore()" disabled>回復</button>
                <span class="pmDirtyTag hidden">● 未儲存</span>
            </div>
            <div class="tableWrap">
                <div id="waTable"></div>
            </div>
        </div>
    </form>

    <script type="text/javascript">
    (function () {
        // ---------- tab switching (client-side, remembered) ----------
        var activeView = '';
        window.showView = function (name) {
            // 離開 PM/工作分配(兩者共用同一份工作副本)時，若有未儲存變更先提醒
            var inPmGroup = (activeView === 'pm' || activeView === 'work');
            var toPmGroup = (name === 'pm' || name === 'work');
            if (inPmGroup && !toPmGroup && PM.dirty) {
                if (!confirm('有未儲存的變更，切換分頁將捨棄這些變更，確定？')) return;
                PM.loadMonth();   // 捨棄：重新載入回復到上次儲存狀態
            }
            activeView = name;
            var views = { wafer: 'waferView', pm: 'pmView', work: 'workView' };
            for (var k in views) {
                var el = document.getElementById(views[k]);
                if (el) el.classList.toggle('hidden', k !== name);
            }
            var tabs = document.querySelectorAll('.tab');
            for (var i = 0; i < tabs.length; i++) {
                tabs[i].classList.toggle('active', tabs[i].getAttribute('data-view') === name);
            }
            if (name === 'pm' || name === 'work') {
                if (!PM.loaded) { PM.init(); }
                else if (name === 'work') { PM.renderWA(); }
            }
        };

        // ---------- PM schedule calendar ----------
        var PM = {
            year: 0, month: 0, data: {}, loaded: false, dirty: false,
            editDate: null, editId: null
        };
        window.PM = PM;

        function pad(n) { return (n < 10 ? '0' : '') + n; }
        function ymStr(y, m) { return y + '-' + pad(m + 1); }
        function dStr(y, m, d) { return y + '-' + pad(m + 1) + '-' + pad(d); }
        function genId() { return 'pm' + Date.now() + Math.floor(Math.random() * 1000); }
        // 自動排程覆寫鍵：同一台不同量測項(A-PM/B-PM…)各自獨立
        function autoKey(eqpid, metertype) { return (eqpid || '') + '|' + (metertype || ''); }
        var WD = ['日', '一', '二', '三', '四', '五', '六'];
        var MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

        PM.autoOverrides = {};   // { eqpid: 'YYYY-MM-DD' } 使用者拖拉後的實際日期
        PM.autoLoaded = false;

        PM.init = function () {
            var now = new Date();
            PM.year = now.getFullYear();
            PM.month = now.getMonth();
            PM.loaded = true;
            PM.loadMonth();
        };

        PM.loadMonth = async function () {
            var ym = ymStr(PM.year, PM.month);
            try {
                var resp = await fetch('./TF2api/GetPmSchedule.ashx?ym=' + ym + '&ts=' + Date.now(), { cache: 'no-store' });
                var js = await resp.json();
                PM.data = (js && js.ok && js.data) ? js.data : {};
            } catch (e) {
                PM.data = {};
            }
            await PM.loadAuto();
            PM.closeEditor();
            PM.render();
            PM.renderWA();
            PM.setDirty(false);   // 載入即為已儲存狀態
        };

        // ---------- 變更暫存：所有編輯先進記憶體，按「儲存變更」才寫入 ----------
        PM.markDirty = function () { PM.setDirty(true); };
        PM.setDirty = function (v) {
            PM.dirty = !!v;
            var btns = document.querySelectorAll('.pmSaveBtn, .pmRestoreBtn');
            for (var i = 0; i < btns.length; i++) btns[i].disabled = !PM.dirty;
            var tags = document.querySelectorAll('.pmDirtyTag');
            for (var j = 0; j < tags.length; j++) tags[j].classList.toggle('hidden', !PM.dirty);
        };
        window.pmSaveAll = async function () {
            if (!PM.dirty) return;
            if (!(await PM.persist())) return;   // 手動排程(當月)；失敗會自行提示
            await PM.saveAutoOverrides();         // 自動覆寫日期(全域)
            PM.setDirty(false);
        };
        window.pmRestore = async function () {
            if (PM.dirty && !confirm('確定捨棄未儲存的變更，回復到上次儲存的狀態？')) return;
            await PM.loadMonth();                 // 重新載入，丟棄未儲存變更
        };

        // 讀自動排程清單 + 使用者覆寫日期，合併成 auto 項目放進 PM.data（不寫回手動排程檔）
        PM.loadAuto = async function () {
            // 先清掉舊的 auto 項目（每次重算）
            for (var k in PM.data) {
                if (!PM.data.hasOwnProperty(k)) continue;
                PM.data[k] = PM.data[k].filter(function (e) { return !e.auto; });
                if (PM.data[k].length === 0) delete PM.data[k];
            }

            // 覆寫日期（拖拉後記住的實際日期）
            try {
                var ro = await fetch('./TF2api/GetTargetJson.ashx?tool=AUTOPM&mode=OVERRIDE&ts=' + Date.now(), { cache: 'no-store' });
                var jo = await ro.json();
                PM.autoOverrides = (jo && jo.ok && jo.data) ? jo.data : {};
            } catch (e) { PM.autoOverrides = {}; }

            // 自動排程：每台預估到期日
            var list = [];
            PM.autoError = '';
            try {
                var ra = await fetch('./TF2api/GetAutoPm.ashx?ts=' + Date.now(), { cache: 'no-store' });
                var txt = await ra.text();
                var ja = null;
                try { ja = JSON.parse(txt); } catch (e) {}
                if (!ra.ok) {
                    PM.autoError = 'HTTP ' + ra.status + (txt ? (' - ' + txt.substring(0, 300)) : '');
                } else if (ja && ja.ok && ja.items) {
                    list = ja.items;
                } else if (ja && !ja.ok) {
                    PM.autoError = ja.error || 'unknown error';
                } else {
                    PM.autoError = '回應格式無法解析：' + txt.substring(0, 300);
                }
            } catch (e) { PM.autoError = String(e); }
            PM.autoLoaded = true;

            // ---- 自動分配每筆 PM 的日期 ----
            // 規則：1) 平日每天最多 3 台，且同 entity(群組) 一天最多 1 台
            //       2) 六日盡量不排，不得已才排且當天最多 1 台
            //       3) 只往前挪(不晚於到期日、不早於今天)；使用者拖過的(overridden)固定不動
            var today = new Date();
            var todayMid = new Date(today.getFullYear(), today.getMonth(), today.getDate());

            // 每日負載：{ 'YYYY-MM-DD': { n: 台數, ents: {entity:true} } }
            var dayLoad = {};
            function loadOf(ds) { return dayLoad[ds] || (dayLoad[ds] = { n: 0, ents: {} }); }
            function isWeekendDs(ds) {
                var p = ds.split('-');
                var wd = new Date(+p[0], +p[1] - 1, +p[2]).getDay();
                return wd === 0 || wd === 6;
            }
            function placeAt(ds, ent) {
                var ld = loadOf(ds); ld.n++; if (ent) ld.ents[ent] = true;
            }

            // 收集已存在的「手動 PM」鍵(eqpid|metertype)：
            // 已被編輯成手動的自動項目，不要再從 GetAutoPm 重複產生(否則重整會多一筆)
            var manualKeys = {};
            for (var dk in PM.data) {
                if (!PM.data.hasOwnProperty(dk)) continue;
                var arr = PM.data[dk];
                for (var mi = 0; mi < arr.length; mi++) {
                    var me = arr[mi];
                    if (!me.auto && me.metertype) manualKeys[autoKey(me.eqpid, me.metertype)] = true;
                }
            }

            // 拆成「固定(已覆寫)」與「待分配」兩類
            var fixedItems = [], freeItems = [];
            for (var i = 0; i < list.length; i++) {
                var it = list[i];
                it._mt = it.metertype || '';
                it._key = autoKey(it.eqpid, it._mt);   // eqpid|metertype，A-PM/B-PM 各自獨立
                if (manualKeys[it._key]) continue;     // 已轉成手動 → 略過，避免重複
                it._ent = it.group || '';
                if (PM.autoOverrides[it._key]) {
                    it._ds = PM.autoOverrides[it._key]; // 使用者拖過的實際日期
                    it._ovr = true;
                    fixedItems.push(it);
                } else {
                    var due = new Date(todayMid.getFullYear(), todayMid.getMonth(), todayMid.getDate() + (it.days || 0));
                    it._due = dStr(due.getFullYear(), due.getMonth(), due.getDate());
                    it._ovr = false;
                    freeItems.push(it);
                }
            }
            // 固定項目先占用日期
            for (var fi = 0; fi < fixedItems.length; fi++) placeAt(fixedItems[fi]._ds, fixedItems[fi]._ent);

            // 待分配：急者(到期日早)優先 → 剩餘天 → 機台，逐筆找位
            freeItems.sort(function (a, b) {
                if (a._due !== b._due) return a._due < b._due ? -1 : 1;
                if ((a.days || 0) !== (b.days || 0)) return (a.days || 0) - (b.days || 0);
                return a._key < b._key ? -1 : (a._key > b._key ? 1 : 0);
            });
            // 由到期日往前掃到今天的日期字串(含兩端)
            function backFromDue(dueDs) {
                var p = dueDs.split('-');
                var d = new Date(+p[0], +p[1] - 1, +p[2]);
                var arr = [];
                while (d >= todayMid) { arr.push(dStr(d.getFullYear(), d.getMonth(), d.getDate())); d.setDate(d.getDate() - 1); }
                return arr;
            }
            for (var k2 = 0; k2 < freeItems.length; k2++) {
                var fit = freeItems[k2];
                var cand = backFromDue(fit._due);   // [到期日, …, 今天]
                var picked = null;
                // 第一輪：平日，總數 < 3 且同 entity 當天未占用
                for (var ci = 0; ci < cand.length && !picked; ci++) {
                    var ds2 = cand[ci];
                    if (isWeekendDs(ds2)) continue;
                    var ld = loadOf(ds2);
                    if (ld.n < 3 && !(fit._ent && ld.ents[fit._ent])) picked = ds2;
                }
                // 第二輪：不得已才排六日，當天最多 1 台
                for (var cj = 0; cj < cand.length && !picked; cj++) {
                    var ds3 = cand[cj];
                    if (isWeekendDs(ds3) && loadOf(ds3).n < 1) picked = ds3;
                }
                // 仍無位：退回到期日(超量，盡力而為)
                if (!picked) picked = fit._due;
                fit._ds = picked;
                placeAt(picked, fit._ent);
            }

            // ---- 組 autoList 並放進當月月曆 ----
            PM.autoList = [];
            var allItems = fixedItems.concat(freeItems);
            allItems.sort(function (a, b) { return a._ds < b._ds ? -1 : (a._ds > b._ds ? 1 : (a._key < b._key ? -1 : 1)); });
            for (var ai = 0; ai < allItems.length; ai++) {
                var a = allItems[ai];
                PM.autoList.push({ eqpid: a.eqpid, metertype: a._mt, group: a._ent, days: a.days, diff: a.diff, due: a._ds, overridden: a._ovr });
                // 只把落在當月的放進月曆格子
                if (a._ds.substring(0, 7) !== ymStr(PM.year, PM.month)) continue;
                if (!PM.data[a._ds]) PM.data[a._ds] = [];
                PM.data[a._ds].push({
                    id: 'auto:' + a._key, auto: true, overridden: a._ovr,
                    eqpid: a.eqpid, metertype: a._mt, group: a._ent, days: a.days, diff: a.diff,
                    action: '', retest: ''
                });
            }
            PM.renderAutoList();
        };

        // 自動排程清單（不受月份限制，方便確認是否有資料、跳到對應月份）
        PM.renderAutoList = function () {
            var box = document.getElementById('pmAutoList');
            if (!box) return;
            var rows = PM.autoList || [];
            var html = '';
            if (PM.autoError) {
                html += '<div class="autoErr">自動排程讀取失敗：' + esc(PM.autoError) + '</div>';
            }
            html += '<div class="autoHd"><span>自動排程清單（' + rows.length + ' 台）</span>'
                  + '<button type="button" class="miniBtn" onclick="pmAutoReschedule()">自動重排</button></div>';
            if (rows.length === 0 && !PM.autoError) {
                html += '<div class="muted" style="padding:6px;">沒有可預估的機台（可能 SPEC 或 Avg.move 缺值）。</div>';
            } else {
                html += '<table class="autoTbl"><tr><th>機台</th><th>量測項</th><th>群組</th><th>剩餘片數</th><th>剩餘天</th><th>排定日</th></tr>';
                for (var i = 0; i < rows.length; i++) {
                    var rw = rows[i];
                    var ym = rw.due.substring(0, 7);
                    html += '<tr>'
                          + '<td>' + esc(rw.eqpid) + '</td>'
                          + '<td>' + esc(rw.metertype || '') + '</td>'
                          + '<td>' + esc(rw.group) + '</td>'
                          + '<td style="text-align:right;">' + (rw.diff != null ? rw.diff : '') + '</td>'
                          + '<td style="text-align:right;">' + (rw.days != null ? rw.days : '') + '</td>'
                          + '<td><a href="#" onclick="pmGotoMonth(\'' + ym + '\'); return false;">' + esc(rw.due) + '</a>'
                          + (rw.overridden ? ' <span class="ovr">(已調整)</span>' : '') + '</td>'
                          + '</tr>';
                }
                html += '</table>';
            }
            box.innerHTML = html;
        };

        window.pmGotoMonth = function (ym) {
            var parts = ym.split('-');
            PM.year = parseInt(parts[0], 10);
            PM.month = parseInt(parts[1], 10) - 1;
            PM.loadMonth();
        };

        // 自動重排：清掉所有拖拉覆寫，全部機台回到預估到期日並重新載入
        window.pmAutoReschedule = async function () {
            if (!confirm('自動重排會清除所有手動移動過的自動排程（回到自動分配的排定日），確定？')) return;
            PM.autoOverrides = {};
            await PM.saveAutoOverrides();
            await PM.loadMonth();
        };

        // 儲存 auto 的覆寫日期
        PM.saveAutoOverrides = async function () {
            var form = new FormData();
            form.append('tool', 'AUTOPM');
            form.append('mode', 'OVERRIDE');
            form.append('json', JSON.stringify(PM.autoOverrides));
            try { await fetch('./TF2api/SaveTargetJson.ashx?ts=' + Date.now(), { method: 'POST', body: form }); } catch (e) {}
        };

        PM.persist = async function () {
            var ym = ymStr(PM.year, PM.month);
            // 只存手動項目；auto 項目不寫進排程檔（由 GetAutoPm + 覆寫日期動態產生）
            var manual = {};
            for (var k in PM.data) {
                if (!PM.data.hasOwnProperty(k)) continue;
                var keep = PM.data[k].filter(function (e) { return !e.auto; });
                if (keep.length) manual[k] = keep;
            }
            var form = new FormData();
            form.append('ym', ym);
            form.append('json', JSON.stringify(manual));
            var resp = await fetch('./TF2api/SavePmSchedule.ashx?ts=' + Date.now(), { method: 'POST', body: form });
            var txt = await resp.text();
            if (!resp.ok) { alert('儲存失敗：HTTP ' + resp.status + '\n' + txt); return false; }
            var js;
            try { js = JSON.parse(txt); } catch (e) { alert('儲存失敗：回應格式錯誤\n' + txt); return false; }
            if (!js || !js.ok) { alert('儲存失敗：' + (js && js.error ? js.error : 'unknown')); return false; }
            return true;
        };

        PM.render = function () {
            document.getElementById('pmMonthLabel').textContent = PM.year + ' ' + MON[PM.month];

            var first = new Date(PM.year, PM.month, 1);
            var startWd = first.getDay();
            var daysInMonth = new Date(PM.year, PM.month + 1, 0).getDate();
            var today = new Date();
            var todayStr = dStr(today.getFullYear(), today.getMonth(), today.getDate());

            var html = '<table class="calendar"><tr>';
            for (var w = 0; w < 7; w++) { html += '<th>' + WD[w] + '</th>'; }
            html += '</tr>';

            var day = 1, cellIdx = 0;
            for (var r = 0; r < 6 && day <= daysInMonth; r++) {
                html += '<tr>';
                for (var c = 0; c < 7; c++, cellIdx++) {
                    if (cellIdx < startWd || day > daysInMonth) {
                        html += '<td class="dayCell other"></td>';
                        continue;
                    }
                    var ds = dStr(PM.year, PM.month, day);
                    var cls = 'dayCell' + (ds === todayStr ? ' today' : '');
                    var numCls = 'dayNum' + (c === 0 ? ' sun' : (c === 6 ? ' sat' : ''));
                    html += '<td class="' + cls + '" data-date="' + ds + '"'
                          + ' ondragover="pmDragOver(event)" ondragleave="pmDragLeave(event)" ondrop="pmDrop(event)">';
                    html += '<div class="dayHead"><span class="' + numCls + '">' + day + '</span>'
                          + '<button type="button" class="addPm" title="新增 PM" onclick="pmAdd(\'' + ds + '\')">+</button></div>';
                    html += '<div class="dayEvents">';
                    var items = PM.data[ds] || [];
                    for (var i = 0; i < items.length; i++) {
                        var it = items[i];
                        var sel = (PM.editDate === ds && PM.editId === it.id) ? ' selected' : '';
                        if (it.auto) {
                            // 自動排程項目：純預估=橘色，已手動移動過=淺藍色；可拖拉、可點擊編輯
                            var movedCls = it.overridden ? ' moved' : '';
                            var mtTxt = it.metertype ? (' · ' + it.metertype) : '';
                            html += '<span class="pmItem auto' + movedCls + sel + '" draggable="true"'
                                  + ' data-date="' + ds + '" data-id="' + esc(it.id) + '" title="' + esc(it.eqpid) + esc(mtTxt) + ' (預估 ' + (it.days || 0) + ' 天)"'
                                  + ' ondragstart="pmDragStart(event)" ondragend="pmDragEnd(event)">'
                                  + '<span class="dot auto">&#9650;</span>'
                                  + '<span class="pmLabel" onclick="pmEdit(\'' + ds + '\',\'' + it.id + '\')">' + esc(it.eqpid || '') + esc(mtTxt) + '</span>'
                                  + '</span>';
                        } else {
                            var hasAction = (it.action && it.action.trim()) || (it.retest && it.retest.trim());
                            var mMtTxt = it.metertype ? (' · ' + it.metertype) : '';
                            html += '<span class="pmItem' + sel + '" draggable="true"'
                                  + ' data-date="' + ds + '" data-id="' + esc(it.id) + '" title="' + esc(it.eqpid) + esc(mMtTxt) + '"'
                                  + ' ondragstart="pmDragStart(event)" ondragend="pmDragEnd(event)">'
                                  + '<span class="dot' + (hasAction ? '' : ' empty') + '">&#9679;</span>'
                                  + '<span class="pmLabel" onclick="pmEdit(\'' + ds + '\',\'' + it.id + '\')">' + esc(it.eqpid || '(未命名)') + esc(mMtTxt) + '</span>'
                                  + '<span class="pmActions">'
                                  + '<button type="button" class="iconBtn" title="編輯" onclick="event.stopPropagation(); pmEdit(\'' + ds + '\',\'' + it.id + '\')">&#9998;</button>'
                                  + '<button type="button" class="iconBtn" title="刪除" onclick="event.stopPropagation(); pmQuickDelete(\'' + ds + '\',\'' + it.id + '\')">&#10005;</button>'
                                  + '</span></span>';
                        }
                    }
                    html += '</div></td>';
                    day++;
                }
                html += '</tr>';
            }
            html += '</table>';
            document.getElementById('pmCalendar').innerHTML = html;
        };

        function esc(s) {
            s = (s == null) ? '' : String(s);
            return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
        }

        function findEntry(ds, id) {
            var arr = PM.data[ds] || [];
            for (var i = 0; i < arr.length; i++) { if (arr[i].id === id) return arr[i]; }
            return null;
        }

        PM.openEditor = function (ds, entry) {
            PM.editDate = ds;
            PM.editId = entry ? entry.id : null;
            document.getElementById('pmEditorEmpty').classList.add('hidden');
            document.getElementById('pmEditorForm').classList.remove('hidden');
            document.getElementById('pmEdDate').textContent = ds;
            var mt = entry ? (entry.metertype || '') : '';
            document.getElementById('pmEdMeter').textContent = mt;
            document.getElementById('pmEdMeterRow').classList.toggle('hidden', !mt);
            document.getElementById('pmEdEqp').value = entry ? (entry.eqpid || '') : '';
            document.getElementById('pmEdAction').value = entry ? (entry.action || '') : '';
            document.getElementById('pmEdRetest').value = entry ? (entry.retest || '') : '';
            document.getElementById('pmDelBtn').classList.toggle('hidden', !entry);
            PM.render();
            document.getElementById('pmEdEqp').focus();
        };

        PM.closeEditor = function () {
            PM.editDate = null;
            PM.editId = null;
            document.getElementById('pmEditorEmpty').classList.remove('hidden');
            document.getElementById('pmEditorForm').classList.add('hidden');
        };

        window.pmAdd = function (ds) { PM.openEditor(ds, null); };
        window.pmEdit = function (ds, id) { PM.openEditor(ds, findEntry(ds, id)); };

        // ---------- drag & drop (move PM to another day) ----------
        window.pmDragStart = function (ev) {
            var el = ev.currentTarget;
            el.classList.add('dragging');
            var payload = { d: el.getAttribute('data-date'), id: el.getAttribute('data-id') };
            ev.dataTransfer.setData('text/plain', JSON.stringify(payload));
            ev.dataTransfer.effectAllowed = 'move';
        };
        window.pmDragEnd = function (ev) { ev.currentTarget.classList.remove('dragging'); };
        window.pmDragOver = function (ev) {
            ev.preventDefault();
            ev.dataTransfer.dropEffect = 'move';
            ev.currentTarget.classList.add('dragOver');
        };
        window.pmDragLeave = function (ev) { ev.currentTarget.classList.remove('dragOver'); };
        window.pmDrop = async function (ev) {
            ev.preventDefault();
            var cell = ev.currentTarget;
            cell.classList.remove('dragOver');
            var toDate = cell.getAttribute('data-date');
            if (!toDate) return;

            var payload;
            try { payload = JSON.parse(ev.dataTransfer.getData('text/plain')); } catch (e) { return; }
            if (!payload || payload.d === toDate) return;

            var entry = findEntry(payload.d, payload.id);
            if (!entry) return;

            // move in-memory regardless of type
            PM.data[payload.d] = (PM.data[payload.d] || []).filter(function (x) { return x.id !== payload.id; });
            if (PM.data[payload.d].length === 0) delete PM.data[payload.d];
            if (!PM.data[toDate]) PM.data[toDate] = [];
            PM.data[toDate].push(entry);
            if (PM.editId === payload.id) { PM.editDate = toDate; }

            if (entry.auto) {
                // 自動排程：把實際日期記成覆寫（暫存記憶體，按「儲存變更」才寫入）
                PM.autoOverrides[autoKey(entry.eqpid, entry.metertype)] = toDate;
                entry.overridden = true;   // 改成「已移動」(淺藍)樣式
            }
            if (PM.editId === payload.id) {
                document.getElementById('pmEdDate').textContent = toDate;
            }
            PM.markDirty();
            PM.render();
        };

        window.pmQuickDelete = function (ds, id) {
            if (!confirm('確定刪除這筆 PM？')) return;
            PM.data[ds] = (PM.data[ds] || []).filter(function (x) { return x.id !== id; });
            if (PM.data[ds].length === 0) delete PM.data[ds];
            if (PM.editDate === ds && PM.editId === id) PM.closeEditor();
            PM.markDirty();
            PM.render();
        };

        window.pmSaveEntry = async function () {
            var ds = PM.editDate;
            if (!ds) return;
            var eqp = document.getElementById('pmEdEqp').value.trim();
            if (!eqp) { alert('請輸入機台 EQPID'); return; }
            var action = document.getElementById('pmEdAction').value;
            var retest = document.getElementById('pmEdRetest').value;

            if (!PM.data[ds]) PM.data[ds] = [];
            var entry = PM.editId ? findEntry(ds, PM.editId) : null;
            if (entry && entry.auto) {
                // 編輯自動項目 → 轉成手動 PM（填了 action/測機項目就「確定」這筆），
                // 並記住覆寫日期，避免重算時又冒出同一台 auto
                entry.auto = false;
                entry.id = genId();
                entry.eqpid = eqp; entry.action = action; entry.retest = retest;
                PM.autoOverrides[autoKey(eqp, entry.metertype)] = ds;
                PM.editId = entry.id;
            } else if (entry) {
                entry.eqpid = eqp; entry.action = action; entry.retest = retest;
            } else {
                entry = { id: genId(), eqpid: eqp, action: action, retest: retest };
                PM.data[ds].push(entry);
                PM.editId = entry.id;
            }

            PM.markDirty();
            PM.render();
            document.getElementById('pmDelBtn').classList.remove('hidden');
        };

        window.pmDeleteEntry = function () {
            var ds = PM.editDate, id = PM.editId;
            if (!ds || !id) return;
            if (!confirm('確定刪除這筆 PM？')) return;
            var arr = PM.data[ds] || [];
            PM.data[ds] = arr.filter(function (x) { return x.id !== id; });
            if (PM.data[ds].length === 0) delete PM.data[ds];
            PM.markDirty();
            PM.closeEditor();
            PM.render();
        };

        // 切換月份前若有未儲存變更先提醒(換月會重新載入而丟棄)
        function pmConfirmLeave() {
            return !PM.dirty || confirm('有未儲存的變更，切換月份將捨棄這些變更，確定？');
        }
        window.pmPrevMonth = function () {
            if (!pmConfirmLeave()) return;
            PM.month--; if (PM.month < 0) { PM.month = 11; PM.year--; }
            PM.loadMonth();
        };
        window.pmNextMonth = function () {
            if (!pmConfirmLeave()) return;
            PM.month++; if (PM.month > 11) { PM.month = 0; PM.year++; }
            PM.loadMonth();
        };
        window.pmGoToday = function () {
            if (!pmConfirmLeave()) return;
            var now = new Date();
            PM.year = now.getFullYear(); PM.month = now.getMonth();
            PM.loadMonth();
        };

        // ---------- work assignment table ----------
        PM.renderWA = function () {
            var label = document.getElementById('waMonthLabel');
            if (label) label.textContent = PM.year + ' ' + MON[PM.month];
            var box = document.getElementById('waTable');
            if (!box) return;

            var rows = [];
            for (var ds in PM.data) {
                if (!PM.data.hasOwnProperty(ds)) continue;
                var arr = PM.data[ds] || [];
                for (var i = 0; i < arr.length; i++) { rows.push({ ds: ds, e: arr[i] }); }
            }
            rows.sort(function (a, b) {
                if (a.ds !== b.ds) return a.ds < b.ds ? -1 : 1;
                var ax = a.e.eqpid || '', bx = b.e.eqpid || '';
                return ax < bx ? -1 : (ax > bx ? 1 : 0);
            });

            if (rows.length === 0) {
                box.innerHTML = '<div class="noData">本月尚無 PM 排程（請到「PM 排程」分頁新增）。</div>';
                return;
            }

            var html = '<table class="waTable"><tr><th>日期</th><th>機台</th><th>PM 內容</th><th>人員</th></tr>';
            for (var r = 0; r < rows.length; r++) {
                var ds2 = rows[r].ds, e = rows[r].e;
                var content = (e.action && e.action.trim()) ? esc(e.action) : '<span class="muted">(未填)</span>';
                var mtTxt = e.metertype ? (' · ' + esc(e.metertype)) : '';
                html += '<tr>';
                // 同一天的多台機台：日期只在該天第一列顯示，並用 rowspan 合併
                if (r === 0 || rows[r - 1].ds !== ds2) {
                    var span = 1;
                    while (r + span < rows.length && rows[r + span].ds === ds2) span++;
                    html += '<td class="waDate"' + (span > 1 ? ' rowspan="' + span + '"' : '') + '>' + esc(ds2) + '</td>';
                }
                html += '<td>' + esc(e.eqpid || '') + mtTxt + '</td>'
                      + '<td class="waContent">' + content + '</td>'
                      + '<td><input type="text" class="waPerson" value="' + esc(e.person || '') + '"'
                      + ' placeholder="輸入人員" onchange="pmSetPerson(&#39;' + ds2 + '&#39;,&#39;' + esc(e.id) + '&#39;, this.value)" /></td>'
                      + '</tr>';
            }
            html += '</table>';
            box.innerHTML = html;
        };

        window.pmSetPerson = function (ds, id, value) {
            var e = findEntry(ds, id);
            if (!e) return;
            e.person = value;
            PM.markDirty();
        };

        // 有未儲存變更時，關閉/重整頁面前提醒
        window.addEventListener('beforeunload', function (e) {
            if (PM.dirty) { e.preventDefault(); e.returnValue = ''; }
        });

        // ---------- land on PM schedule (first load) or stay on Wafer Count (postback) ----------
        function boot() {
            showView('<%= InitialView %>');
        }
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', boot);
        } else {
            boot();
        }
    })();
    </script>
</body>
</html>
