codeunit 65203 "O4N PayPal Post Process"
{
    TableNo = "Bank Acc. Reconciliation Line";

    trigger OnRun()
    var
    begin
        RemoveIncorrectCurrencyEntries(Rec, Rec."Statement Type", Rec."Bank Account No.", Rec."Statement No.");
        SetEndValues(Rec);
    end;

    local procedure RemoveIncorrectCurrencyEntries(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; StatementType: Option; BankAccNo: Code[20]; StatementNo: Code[20]): Boolean
    var
        TempBankAccReconciliationLineToRemove: Record "Bank Acc. Reconciliation Line" temporary;
        BankAcc: Record "Bank Account";
    begin
        BankAcc.Get(BankAccNo);
        if BankAcc."Currency Code" = '' then exit;
        TempBankAccReconciliationLineToRemove.Copy(BankAccReconciliationLine, true);
        TempBankAccReconciliationLineToRemove.SetFilter("O4N Currency Code", '<>%1', BankAcc."Currency Code");
        TempBankAccReconciliationLineToRemove.DeleteAll();
    end;

    local procedure SetEndValues(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        TempLastBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;
    begin
        TempLastBankAccReconciliationLine.Copy(BankAccReconciliationLine, true);
        if TempLastBankAccReconciliationLine.FindLast() then begin
            BankAccReconciliation.Get(BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.", BankAccReconciliationLine."Statement No.");
            BankAccReconciliation."Statement Date" := TempLastBankAccReconciliationLine."Transaction Date";
            BankAccReconciliation."Statement Ending Balance" := TempLastBankAccReconciliationLine."O4N Balance";
            BankAccReconciliation.Modify();
        end;
    end;
}
