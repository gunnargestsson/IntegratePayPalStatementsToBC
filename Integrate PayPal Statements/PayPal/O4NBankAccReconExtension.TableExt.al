tableextension 65200 "O4N Bank Acc.Recon Extension" extends "Bank Acc. Reconciliation Line"
{
    fields
    {
        field(65200; "O4N Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(65201; "O4N Balance"; Decimal)
        {
            AutoFormatExpression = "O4N Currency Code";
            AutoFormatType = 1;
            Caption = 'Balance';
            DataClassification = CustomerContent;
        }
    }
}
