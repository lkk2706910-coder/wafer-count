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
            display: block;
            font-size: 11px;
            background: #e9f6ff;
            border: 1px solid #b9def5;
            border-radius: 4px;
            padding: 2px 5px;
            margin-bottom: 3px;
            color: #1f6fa0;
            cursor: pointer;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .pmItem:hover { background: #d4eefc; }
        .pmItem.selected { background: #2f7fb4; color: #fff; border-color: #1f6fa0; }
        .pmItem .dot { color: #36a35b; font-weight: 700; }
        .pmItem .dot.empty { color: #d99a00; }

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

        .hidden { display: none !important; }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="topBar">
            <div class="tabs">
                <button type="button" class="tab active" data-view="wafer" onclick="showView('wafer')">Wafer Count</button>
                <button type="button" class="tab" data-view="pm" onclick="showView('pm')">PM 排程</button>
            </div>
            <div class="updateInfo">
                <span class="label">Update:</span>
                <asp:Label ID="lblUpdate" runat="server" />
            </div>
        </div>

        <!-- ===== Wafer Count view ===== -->
        <div id="waferView" class="view">
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
        <div id="pmView" class="view hidden">
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
    </form>

    <script type="text/javascript">
    (function () {
        // ---------- tab switching (client-side, remembered) ----------
        window.showView = function (name) {
            var wafer = document.getElementById('waferView');
            var pm = document.getElementById('pmView');
            var isPm = name === 'pm';
            wafer.classList.toggle('hidden', isPm);
            pm.classList.toggle('hidden', !isPm);
            var tabs = document.querySelectorAll('.tab');
            for (var i = 0; i < tabs.length; i++) {
                tabs[i].classList.toggle('active', tabs[i].getAttribute('data-view') === name);
            }
            try { sessionStorage.setItem('wc_active_view', name); } catch (e) {}
            if (isPm && !PM.loaded) { PM.init(); }
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
                    html += '<td class="' + cls + '">';
                    html += '<div class="dayHead"><span class="' + numCls + '">' + day + '</span>'
                          + '<button type="button" class="addPm" title="新增 PM" onclick="pmAdd(\'' + ds + '\')">+</button></div>';
                    html += '<div class="dayEvents">';
                    var items = PM.data[ds] || [];
                    for (var i = 0; i < items.length; i++) {
                        var it = items[i];
                        var hasAction = (it.action && it.action.trim()) || (it.retest && it.retest.trim());
                        var sel = (PM.editDate === ds && PM.editId === it.id) ? ' selected' : '';
                        html += '<span class="pmItem' + sel + '" title="' + esc(it.eqpid) + '" onclick="pmEdit(\'' + ds + '\',\'' + it.id + '\')">'
                              + '<span class="dot' + (hasAction ? '' : ' empty') + '">&#9679;</span> ' + esc(it.eqpid || '(未命名)') + '</span>';
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

        // ---------- restore active tab on load ----------
        function boot() {
            var v = 'wafer';
            try { v = sessionStorage.getItem('wc_active_view') || 'wafer'; } catch (e) {}
            showView(v);
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
