codeunit 65205 "O4N Payment Exp. CSV"
{
    TableNo = "Data Exch.";

    trigger OnRun()
    var
        DataExchDef: Record "Data Exch. Def";
        FileNameTok: Label '%1 - %2.csv', Locked = true;
        OutStr: OutStream;
    begin
        Rec.TestField("Data Exch. Def Code");
        Clear(Rec."File Content");
        DataExchDef.Get(Rec."Data Exch. Def Code");
        DataExchDef.TestField("File Type", DataExchDef."File Type"::"Variable Text");

        case DataExchDef."File Encoding" of
            DataExchDef."File Encoding"::"MS-DOS":
                Rec."File Content".CreateOutStream(OutStr, TextEncoding::MSDos);
            DataExchDef."File Encoding"::"UTF-16":
                Rec."File Content".CreateOutStream(OutStr, TextEncoding::UTF16);
            DataExchDef."File Encoding"::"UTF-8":
                Rec."File Content".CreateOutStream(OutStr, TextEncoding::UTF8);
            DataExchDef."File Encoding"::WINDOWS:
                Rec."File Content".CreateOutStream(OutStr, TextEncoding::Windows);
        end;
        ExportToCSV(Rec, DataExchDef, OutStr);
        Rec."File Name" := CopyStr(StrSubstNo(FileNameTok, Format(CurrentDateTime(), 0, '<Year4>-<Month,2>-<Day,2> <Hour,2>.<Minute,2>.000'), CompanyProperty.DisplayName()), 1, MaxStrLen(Rec."File Name"));
        Rec.Modify();
    end;

    local procedure AddLines(DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; DataExchLineDef: Record "Data Exch. Line Def"; OutStr: OutStream)
    var
        DataExchColumnDef: Record "Data Exch. Column Def";
        DataExchField: Record "Data Exch. Field";
        TypeHelper: Codeunit "Type Helper";
        LineContent: TextBuilder;
    begin
        DataExchColumnDef.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchColumnDef.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        DataExchField.SetRange("Data Exch. No.", DataExch."Entry No.");
        DataExchField.SetRange("Data Exch. Def Code", DataExchLineDef."Data Exch. Def Code");
        DataExchField.SetRange("Data Exch. Line Def Code", DataExchLineDef.Code);
        if DataExchField.FindSet() then
            repeat
                DataExchField.SetRange("Line No.", DataExchField."Line No.");
                DataExchColumnDef.FindSet();
                LineContent.Clear();
                repeat
                    DataExchField.SetRange("Column No.", DataExchColumnDef."Column No.");
                    if not DataExchField.FindFirst() then
                        DataExchField.Init();
                    if LineContent.Length > 0 then
                        LineContent.Append(DataExchDef.ColumnSeparatorChar());
                    LineContent.Append(ConvertStr(DataExchField.GetValue(), DataExchDef.ColumnSeparatorChar(), PadStr('', StrLen(DataExchDef.ColumnSeparatorChar()), '_')));
                until DataExchColumnDef.Next() = 0;
                OutStr.WriteText(LineContent.ToText() + TypeHelper.NewLine());
                DataExchField.FindLast();
                DataExchField.SetRange("Line No.");
            until DataExchField.Next() = 0;
    end;

    local procedure ExportToCSV(DataExch: Record "Data Exch."; DataExchDef: Record "Data Exch. Def"; var OutStr: OutStream)
    var
        DataExchLineDef: Record "Data Exch. Line Def";
    begin
        DataExchLineDef.SetRange("Data Exch. Def Code", DataExchDef.Code);
        DataExchLineDef.SetFilter("Parent Code", '');
        DataExchLineDef.FindFirst();
        AddLines(DataExch, DataExchDef, DataExchLineDef, OutStr)
    end;
}