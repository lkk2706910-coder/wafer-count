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

        #dataTable .specInput {
            border: 1px solid var(--line);
            border-radius: 5px;
            padding: 3px 6px;
            font: inherit;
            font-size: 13px;
        }

        #dataTable .diffCell { text-align: right; font-variant-numeric: tabular-nums; }
        #dataTable .diffCell.over { color: #d93025; font-weight: 700; }

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
        .dayNum.sat { color: #2f7fb4; }

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

        .pmItem {
            display: flex;
            align-items: center;
            gap: 4px;
            font-size: 11px;
            background: #e9f6ff;
            border: 1px solid #b9def5;
            border-radius: 4px;
            padding: 2px 4px;
            margin-bottom: 3px;
            color: #1f6fa0;
            cursor: grab;
        }

        .pmItem:active { cursor: grabbing; }
        .pmItem:hover { background: #d4eefc; }
        .pmItem.selected { background: #2f7fb4; color: #fff; border-color: #1f6fa0; }
        .pmItem.dragging { opacity: 0.4; }
        .pmItem .dot { color: #36a35b; font-weight: 700; flex: 0 0 auto; }
        .pmItem .dot.empty { color: #d99a00; }

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
                    </div>
                    <div id="pmCalendar"></div>
                </div>

                <div class="pmEditor">
                    <h3>PM 內容</h3>
                    <div id="pmEditorEmpty" class="muted">點選日期格右上的 <b>+</b> 新增機台 PM，或點月曆中的機台名稱編輯。</div>
                    <div id="pmEditorForm" class="hidden">
                        <div><b>日期：</b><span id="pmEdDate"></span></div>
                        <label>機台 EQPID</label>
                        <input type="text" id="pmEdEqp" placeholder="例如 SACVD-B01A" />
                        <label>PM Action</label>
                        <textarea id="pmEdAction" placeholder="輸入本次 PM 要執行的動作"></textarea>
                        <label>回線測機項目</label>
                        <textarea id="pmEdRetest" placeholder="輸入回線後要測試/驗證的項目"></textarea>
                        <div class="row">
                            <button type="button" class="btn primary" onclick="pmSaveEntry()">儲存</button>
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
            </div>
            <div class="tableWrap">
                <div id="waTable"></div>
            </div>
        </div>
    </form>

    <script type="text/javascript">
    (function () {
        // ---------- tab switching (client-side, remembered) ----------
        window.showView = function (name) {
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
            year: 0, month: 0, data: {}, loaded: false,
            editDate: null, editId: null
        };
        window.PM = PM;

        function pad(n) { return (n < 10 ? '0' : '') + n; }
        function ymStr(y, m) { return y + '-' + pad(m + 1); }
        function dStr(y, m, d) { return y + '-' + pad(m + 1) + '-' + pad(d); }
        function genId() { return 'pm' + Date.now() + Math.floor(Math.random() * 1000); }
        var WD = ['日', '一', '二', '三', '四', '五', '六'];
        var MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

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
            PM.closeEditor();
            PM.render();
            PM.renderWA();
        };

        PM.persist = async function () {
            var ym = ymStr(PM.year, PM.month);
            var form = new FormData();
            form.append('ym', ym);
            form.append('json', JSON.stringify(PM.data));
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
                        var hasAction = (it.action && it.action.trim()) || (it.retest && it.retest.trim());
                        var sel = (PM.editDate === ds && PM.editId === it.id) ? ' selected' : '';
                        html += '<span class="pmItem' + sel + '" draggable="true"'
                              + ' data-date="' + ds + '" data-id="' + esc(it.id) + '" title="' + esc(it.eqpid) + '"'
                              + ' ondragstart="pmDragStart(event)" ondragend="pmDragEnd(event)">'
                              + '<span class="dot' + (hasAction ? '' : ' empty') + '">&#9679;</span>'
                              + '<span class="pmLabel" onclick="pmEdit(\'' + ds + '\',\'' + it.id + '\')">' + esc(it.eqpid || '(未命名)') + '</span>'
                              + '<span class="pmActions">'
                              + '<button type="button" class="iconBtn" title="編輯" onclick="event.stopPropagation(); pmEdit(\'' + ds + '\',\'' + it.id + '\')">&#9998;</button>'
                              + '<button type="button" class="iconBtn" title="刪除" onclick="event.stopPropagation(); pmQuickDelete(\'' + ds + '\',\'' + it.id + '\')">&#10005;</button>'
                              + '</span></span>';
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

            // remove from source day, append to target day
            PM.data[payload.d] = (PM.data[payload.d] || []).filter(function (x) { return x.id !== payload.id; });
            if (PM.data[payload.d].length === 0) delete PM.data[payload.d];
            if (!PM.data[toDate]) PM.data[toDate] = [];
            PM.data[toDate].push(entry);

            // follow the moved item if it was being edited
            if (PM.editId === payload.id) { PM.editDate = toDate; }

            if (await PM.persist()) {
                PM.render();
                if (PM.editId === payload.id) {
                    document.getElementById('pmEdDate').textContent = toDate;
                }
            }
        };

        window.pmQuickDelete = async function (ds, id) {
            if (!confirm('確定刪除這筆 PM？')) return;
            PM.data[ds] = (PM.data[ds] || []).filter(function (x) { return x.id !== id; });
            if (PM.data[ds].length === 0) delete PM.data[ds];
            if (PM.editDate === ds && PM.editId === id) PM.closeEditor();
            if (await PM.persist()) PM.render();
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
            if (entry) {
                entry.eqpid = eqp; entry.action = action; entry.retest = retest;
            } else {
                entry = { id: genId(), eqpid: eqp, action: action, retest: retest };
                PM.data[ds].push(entry);
                PM.editId = entry.id;
            }

            if (await PM.persist()) {
                PM.render();
                document.getElementById('pmDelBtn').classList.remove('hidden');
            }
        };

        window.pmDeleteEntry = async function () {
            var ds = PM.editDate, id = PM.editId;
            if (!ds || !id) return;
            if (!confirm('確定刪除這筆 PM？')) return;
            var arr = PM.data[ds] || [];
            PM.data[ds] = arr.filter(function (x) { return x.id !== id; });
            if (PM.data[ds].length === 0) delete PM.data[ds];
            if (await PM.persist()) { PM.closeEditor(); PM.render(); }
        };

        window.pmPrevMonth = function () {
            PM.month--; if (PM.month < 0) { PM.month = 11; PM.year--; }
            PM.loadMonth();
        };
        window.pmNextMonth = function () {
            PM.month++; if (PM.month > 11) { PM.month = 0; PM.year++; }
            PM.loadMonth();
        };
        window.pmGoToday = function () {
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
                html += '<tr>'
                      + '<td>' + esc(ds2) + '</td>'
                      + '<td>' + esc(e.eqpid || '') + '</td>'
                      + '<td class="waContent">' + content + '</td>'
                      + '<td><input type="text" class="waPerson" value="' + esc(e.person || '') + '"'
                      + ' placeholder="輸入人員" onchange="pmSetPerson(&#39;' + ds2 + '&#39;,&#39;' + esc(e.id) + '&#39;, this.value)" /></td>'
                      + '</tr>';
            }
            html += '</table>';
            box.innerHTML = html;
        };

        window.pmSetPerson = async function (ds, id, value) {
            var e = findEntry(ds, id);
            if (!e) return;
            e.person = value;
            await PM.persist();
        };

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
