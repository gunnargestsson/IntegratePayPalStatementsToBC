permissionset 65200 "O4N PayPal Statement"
{
    Assignable = true;
    Caption = 'PayPal Statement', MaxLength = 30;
    Permissions =
        codeunit "O4N PayPal Post Process" = X,
        codeunit "O4N Payment Exp. CSV" = X,
        codeunit "O4N Import CSV" = X,
        codeunit "O4N Bank Statement Event" = X;
}
