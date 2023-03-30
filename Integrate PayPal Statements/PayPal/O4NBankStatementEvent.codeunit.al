codeunit 65204 "O4N Bank Statement Event"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Process Data Exch.", 'OnBeforeFormatFieldValue', '', false, false)]
    local procedure OnBeforeFormatFieldValue(var TransformedValue: Text; FieldRef: FieldRef; var IsHandled: Boolean)
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if FieldRef.Name <> BankAccReconciliationLine.FieldName("O4N Currency Code") then exit;
        GeneralLedgerSetup.Get();
        if TransformedValue = GeneralLedgerSetup."LCY Code" then
            TransformedValue := '';
    end;
}