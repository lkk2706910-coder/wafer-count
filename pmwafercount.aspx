<%@ Page Language="C#" AutoEventWireup="true" CodeFile="pmwafercount.aspx.cs" Inherits="GPTPoCDB_SampleSite_NotesTable" %>

<!DOCTYPE html>
<html>
<head>
    <title>PM Wafer Count - WET_CLEAN</title>
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

        /* header: title left, update time top-right */
        .pageHeader {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            margin-bottom: 14px;
        }

        .pageHeader h2 {
            margin: 0;
            font-weight: 600;
        }

        .updateInfo {
            font-size: 12px;
            color: #355160;
            white-space: nowrap;
        }

        .updateInfo .label {
            font-weight: 700;
            margin-right: 4px;
        }

        /* toolbar: segmented toggle */
        .toolbar {
            display: inline-flex;
            gap: 0;
            margin-bottom: 12px;
            border: 1px solid #1f6fa0;
            border-radius: 8px;
            overflow: hidden;
        }

        /* unselected button */
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

        /* selected (pressed) button */
        .btn.active {
            background: linear-gradient(#3b8ec3, #2f7fb4);
            color: #fff;
            box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.25);
            cursor: default;
        }

        .btn.active:hover { background: linear-gradient(#3b8ec3, #2f7fb4); }

        .tableWrap {
            border: 1px solid var(--line);
            border-radius: 8px;
            overflow: auto;
            background: #fff;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            min-width: 480px;
        }

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

        .noData {
            padding: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <form id="form1" runat="server">
        <div class="pageHeader">
            <h2>PM wafer count &mdash; WET_CLEAN (SACVD / NISACVD)</h2>
            <div class="updateInfo">
                <span class="label">Update:</span>
                <asp:Label ID="lblUpdate" runat="server" />
            </div>
        </div>

        <div class="toolbar">
            <asp:Button ID="btnByTool" runat="server" Text="SACVD/NISACVD" OnClick="btnByTool_Click" CssClass="btn" />
            <asp:Button ID="btnByEntity" runat="server" Text="Entity分類" OnClick="btnByEntity_Click" CssClass="btn active" />
        </div>

        <div class="tableWrap">
            <asp:PlaceHolder ID="phTable" runat="server"></asp:PlaceHolder>
        </div>
    </form>
</body>
</html>
