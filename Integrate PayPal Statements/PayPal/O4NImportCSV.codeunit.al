codeunit 65202 "O4N Import CSV"
{
    Permissions = tabledata "Data Exch. Field" = rimd;
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        ReadStream: InStream;
        LineNo: Integer;
        ReadLen: Integer;
        SkippedLineNo: Integer;
        ParentNodeId: Text[250];
        ReadText: Text;
    begin
        Rec.CalcFields("File Content");
        DataExchDef.Get(Rec."Data Exch. Def Code");
        SetDelimiter();
        case DataExchDef."File Encoding" of
            DataExchDef."File Encoding"::"MS-DOS":
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::MSDos);
            DataExchDef."File Encoding"::WINDOWS:
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::Windows);
            DataExchDef."File Encoding"::"UTF-8":
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::UTF8);
            DataExchDef."File Encoding"::"UTF-16":
                Rec."File Content".CreateInStream(ReadStream, TextEncoding::UTF16);
        end;
        repeat
            ReadLen := ReadStream.ReadText(ReadText);
            if ReadLen > 0 then
                ParseLine(Rec, ReadText, ParentNodeId, LineNo, SkippedLineNo);
        until ReadLen = 0;
    end;

    var
        DataExchDef: Record "Data Exch. Def";
        TempDelimiters: Record "Integer" temporary;
        TempLineDefBuffer: Record "Name/Value Buffer" temporary;
        MissingColumnSeparatorTxt: Label '%1 is missing for %2 %3', Comment = 'Data Exchange Def., %1 = FieldCaption("Column Separator"), %2 = TableCaption(), %3 = Code';

    local procedure AddFields(DataExch: Record "Data Exch."; DataExchLineDef: Record "Data Exch. Line Def"; var Columns: Record "Name/Value Buffer"; var ParentNodeId: Text[250]; var LineNo: Integer)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        NodeId: Text[250];
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);

        if DataExchLineDef."Parent Code" = '' then begin
            TempLineDefBuffer.SetFilter(Name, '<>%1', DataExchLineDef.Code);
            TempLineDefBuffer.DeleteAll();
        end;

        TempLineDefBuffer.ID += 1;
        TempLineDefBuffer.Name := DataExchLineDef.Code;
        TempLineDefBuffer.Insert();
        TempLineDefBuffer.SetRange(Name, DataExchLineDef.Code);

        NodeId := CopyStr(DelChr(DelChr(Format(CreateGuid()), '=', '{'), '=', '}'), 1, MaxStrLen(NodeId));
        if Columns.Find('-') then
            repeat
                Columns.Value := DelChr(DelChr(Columns.Value, '<', '"'), '>', '"');
                DataExchColumnDef.SetRange("Column No.", Columns.ID);
                DataExchColumnDef.SetRange(Constant, '');
                if DataExchColumnDef.FindFirst() then
                    if DataExchLineDef."Parent Code" <> '' then
                        DataExchField.InsertRecXMLFieldWithParentNodeID(DataExch."Entry No.", TempLineDefBuffer.Count(), DataExchColumnDef."Column No.", NodeId, ParentNodeId, Columns.Value, DataExchLineDef.Code)
                    else
                        DataExchField.InsertRecXMLField(DataExch."Entry No.", TempLineDefBuffer.Count(), DataExchColumnDef."Column No.", NodeId, Columns.Value, DataExchLineDef.Code);
            until Columns.Next() = 0;

        DataExchColumnDef.SetRange("Column No.");
        DataExchColumnDef.SetFilter(Constant, '<>%1', '');
        if DataExchColumnDef.FindSet() then
            repeat
                if DataExchLineDef."Parent Code" <> '' then
                    DataExchField.InsertRecXMLFieldWithParentNodeID(DataExch."Entry No.", TempLineDefBuffer.Count(), DataExchColumnDef."Column No.", NodeId, ParentNodeId, DataExchColumnDef.Constant, DataExchLineDef.Code)
                else
                    DataExchField.InsertRecXMLField(DataExch."Entry No.", TempLineDefBuffer.Count(), DataExchColumnDef."Column No.", NodeId, DataExchColumnDef.Constant, DataExchLineDef.Code);
            until DataExchColumnDef.Next() = 0;

        if DataExchLineDef."Parent Code" = '' then
            ParentNodeId := NodeId;
    end;

    local procedure GetNextColumn(var Line: Text; var ColumnValue: Text[250]): Boolean
    var
        InDoubleQuotes: Boolean;
        Char: Char;
        Pos: Integer;
    begin
        ColumnValue := '';
        if Line = '' then exit(false);
        for Pos := 1 to StrLen(Line) do begin
            Char := Line[Pos];
            TempDelimiters.SetRange(Number, Char);
            if (Char = 34) then
                InDoubleQuotes := not InDoubleQuotes
            else
                case true of
                    InDoubleQuotes:
                        ColumnValue += Format(Char);
                    else
                        if TempDelimiters.FindFirst() then begin
                            Line := CopyStr(Line, Pos + 1);
                            exit(true);
                        end else
                            ColumnValue += Format(Char);
                end;
        end;
        Line := '';
        exit(true);
    end;

    local procedure ParseLine(DataExch: Record "Data Exch."; Line: Text; var ParentNodeId: Text[250]; var LineNo: Integer; var SkippedLineNo: Integer)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
        TempColumns: Record "Name/Value Buffer" temporary;
    begin
        if ((LineNo + SkippedLineNo) < DataExchDef."Header Lines") then begin
            SkippedLineNo += 1;
            exit;
        end;

        DataExchLineDef.SetRange("Data Exch. Def Code", DataExch."Data Exch. Def Code");
        if not DataExchLineDef.FindSet() then exit;

        if DataExchLineDef."Parent Code" = '' then
            LineNo += 1;

        while GetNextColumn(Line, TempColumns.Value) do begin
            TempColumns.ID += 1;
            TempColumns.Insert();
        end;

        repeat
            AddFields(DataExch, DataExchLineDef, TempColumns, ParentNodeId, LineNo)
        until DataExchLineDef.Next() = 0;
    end;

    local procedure SetDelimiter()
    var
        Char: Integer;
        Pos: Integer;
    begin
        case DataExchDef."Column Separator" of
            DataExchDef."Column Separator"::Comma:
                begin
                    TempDelimiters.Number := 44;
                    TempDelimiters.Insert();
                end;
            DataExchDef."Column Separator"::Semicolon:
                begin
                    TempDelimiters.Number := 59;
                    TempDelimiters.Insert();
                end;
            DataExchDef."Column Separator"::Space:
                begin
                    TempDelimiters.Number := 32;
                    TempDelimiters.Insert();
                end;
            DataExchDef."Column Separator"::Tab:
                begin
                    TempDelimiters.Number := 9;
                    TempDelimiters.Insert();
                end;
            DataExchDef."Column Separator"::Custom:
                for Pos := 1 to StrLen(DataExchDef."Custom Column Separator") do begin
                    Char := DataExchDef."Custom Column Separator"[Pos];
                    TempDelimiters.Number := Char;
                    TempDelimiters.Insert();
                end;
            else
                Error(MissingColumnSeparatorTxt, DataExchDef.FieldCaption("Column Separator"), DataExchDef.TableCaption(), DataExchDef.Code);
        end;
    end;
}
