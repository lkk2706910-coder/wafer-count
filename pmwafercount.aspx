<%@ Page Language="C#" AutoEventWireup="true" CodeFile="pmwafercount.aspx.cs" Inherits="GPTPoCDB_SampleSite_NotesTable" %>

<!DOCTYPE html>
<html>
<head>
    <title>Notes Scrap RawCat Table</title>
    <style>
        :root {
            --blue-1: #4aa3d8;
            --blue-2: #2f7fb4;
            --blue-3: #e9f6ff;
            --line: #c9d7e3;
            --text: #1f2a33;
        }

        body {
            font-family: "Segoe UI", Arial, Helvetica, sans-serif;
            color: var(--text);
            margin: 18px;
        }

        h2 {
            margin: 0 0 14px 0;
            font-weight: 600;
        }

        /* toolbar */
        .toolbar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            gap: 10px 14px;
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: #fff;
            margin-bottom: 10px;
        }

        .toolbar label {
            font-size: 12px;
            font-weight: 600;
            color: #355160;
            margin-right: 6px;
        }

        .toolbar input[type="text"],
        .toolbar input[type="search"],
        .toolbar .aspNetDisabled,
        .toolbar input {
            height: 28px;
            padding: 4px 8px;
            border: 1px solid var(--line);
            border-radius: 6px;
            outline: none;
            min-width: 160px;
        }

        .btn {
            height: 30px;
            padding: 0 12px;
            border-radius: 6px;
            border: 1px solid #1f6fa0;
            background: linear-gradient(#5bb6ea, #2f7fb4);
            color: #fff;
            font-weight: 600;
            cursor: pointer;
        }

        .btn.secondary {
            border: 1px solid var(--line);
            background: #f5f7fa;
            color: #27414f;
        }

        .btn:active { filter: brightness(0.95); }

        /* button groups */
        .groupRow {
            padding: 10px 12px;
            border: 1px solid var(--line);
            border-radius: 8px;
            background: #fff;
            margin-bottom: 10px;
        }

        .groupRow .group {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            margin-right: 14px;
            flex-wrap: wrap;
        }

        .groupRow .title {
            font-weight: 700;
            color: #244657;
            margin-right: 6px;
        }

        /* table */
        .tableWrap {
            border: 1px solid var(--line);
            border-radius: 8px;
            overflow: auto;
            background: #fff;
        }

        table {
            border-collapse: collapse;
            width: max-content;
            min-width: 720px;
        }

        th, td {
            border: 1px solid var(--line);
            padding: 6px 8px;
            text-align: left;
            font-size: 12px;
            white-space: nowrap;
        }

        /* value > target highlight */
        #pivotTable td.overTarget {
            color: #d93025;
            font-weight: 700;
        }

        th {
            background: linear-gradient(#6bc0ef, #3b8ec3);
            color: #fff;
            position: sticky;
            top: 0;
            z-index: 2;
        }

        tr:nth-child(even) td { background: #fafcff; }

        /* header filter row inside table */
        th input {
            width: 95%;
            height: 24px;
            border-radius: 6px;
            border: 1px solid #8fc3e3;
            padding: 2px 6px;
        }

        /* freeze first column (METERTYPE) */
        #normalTable th:first-child,
        #normalTable td:first-child,
        #pivotTable th:first-child,
        #pivotTable td:first-child {
            position: sticky;
            left: 0;
            z-index: 4;
            background: #fff;
            width: 200px;
            min-width: 200px;
            max-width: 200px;
            box-shadow: 2px 0 0 0 var(--line);
        }

        /* freeze second column (TARGET) in pivot table (place right next to METERTYPE)
           NOTE: left must match the actual rendered width of the first column. */
        #pivotTable th:nth-child(2),
        #pivotTable td:nth-child(2) {
            position: sticky;
            left: 200px;
            z-index: 3;
            background: #fff;
            width: 180px;
            min-width: 180px;
            max-width: 180px;
            box-shadow: 2px 0 0 0 var(--line);
        }

        /* keep header style on frozen header cells */
        #normalTable th:first-child,
        #pivotTable th:first-child,
        #pivotTable th:nth-child(2) {
            background: linear-gradient(#6bc0ef, #3b8ec3);
            color: #fff;
        }

        /* keep filter-row frozen cells white */
        #normalTable tr:nth-child(2) th:first-child,
        #pivotTable tr:nth-child(2) th:first-child,
        #pivotTable tr:nth-child(2) th:nth-child(2) {
            background: #fff;
            color: var(--text);
        }

        /* don't stretch the METERTYPE filter input to full width */
        #pivotTable tr:nth-child(2) th:first-child input#mtFilter {
            width: 180px;
            max-width: 180px;
        }

        /* optional: clip long metertype text */
        #pivotTable td:first-child,
        #pivotTable th:first-child {
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* ... moved into sticky section above ... */
    </style>
</head>
<body>
    <h2>PM wafer count</h2>

    <form id="form1" runat="server">
        <div class="toolbar">
            <div>
                <asp:Label runat="server" AssociatedControlID="txtEqp" Text="EQPID" />
                <asp:TextBox ID="txtEqp" runat="server" />
            </div>

            <div>
                <asp:Label runat="server" AssociatedControlID="txtMeterType" Text="METERTYPE" />
                <asp:TextBox ID="txtMeterType" runat="server" />
            </div>

            <div>
                <asp:Button ID="btnSearch" runat="server" Text="Search" OnClick="btnSearch_Click" CssClass="btn" />
                <asp:Button ID="btnRefresh" runat="server" Text="更新" OnClick="btnRefresh_Click" CssClass="btn secondary" />
                <asp:Button ID="btnClear" runat="server" Text="Clear" OnClick="btnClear_Click" CssClass="btn secondary" />
            </div>
        </div>

        <!-- ALL (Pivot 版面) -->
        <div class="groupRow">
            <span class="group">
                <span class="title">ULKCVD ALL:</span>
                <asp:Button ID="btnULKCVD_ALL_DEP" runat="server" Text="DEP" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="ULKCVD_ALL_DEP" />
                <asp:Button ID="btnULKCVD_ALL_CUR" runat="server" Text="CUR" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="ULKCVD_ALL_CUR" />
                <asp:Button ID="btnULKCVD_ALL_MF" runat="server" Text="MF" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="ULKCVD_ALL_MF" />
            </span>

            <span class="group">
                <span class="title">TEOSPE ALL:</span>
                <asp:Button ID="btnTEOSPE_ALL_DEP_AL" runat="server" Text="AL" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="TEOSPE_ALL_DEP_AL" />
                <asp:Button ID="btnTEOSPE_ALL_DEP_CU" runat="server" Text="CU" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="TEOSPE_ALL_DEP_CU" />
                <asp:Button ID="btnTEOSPE_ALL_MF" runat="server" Text="MF" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="TEOSPE_ALL_MF" />
            </span>

            <span class="group">
                <span class="title">BLOKCVD ALL:</span>
                <asp:Button ID="btnBLOKCVD_ALL_DEP" runat="server" Text="DEP" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="BLOKCVD_ALL_DEP" />
                <asp:Button ID="btnBLOKCVD_ALL_MF" runat="server" Text="MF" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="BLOKCVD_ALL_MF" />
            </span>

            <span class="group">
                <span class="title">APF ALL:</span>
                <asp:Button ID="btnAPF_ALL_DEP" runat="server" Text="DEP" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="APF_ALL_DEP" />
                <asp:Button ID="btnAPF_ALL_MF" runat="server" Text="MF" CssClass="btn secondary" OnClick="btnFilter_Click" CommandArgument="APF_ALL_MF" />
            </span>
        </div>

        <!-- hidden dummy buttons for sort postback -->
        <asp:Button ID="btnSortDummy" runat="server" Text="Sort" OnClick="btnSort_Click" CommandArgument="DATA_VAL" Style="display:none" />
        <asp:Button ID="btnSortEqpDummy" runat="server" Text="Sort" OnClick="btnSort_Click" CommandArgument="EQPID" Style="display:none" />

        <div class="tableWrap">
            <asp:PlaceHolder ID="phTable" runat="server"></asp:PlaceHolder>
        </div>
    </form>
</body>
</html>
