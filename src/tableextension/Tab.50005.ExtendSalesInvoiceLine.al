tableextension 50005 ExtendSalesInvoiceLine extends "Sales Invoice Line"
{
    fields
    {
        field(50000; "Vendor Item No."; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor Item No.';

        }

    }

    var
        myInt: Integer;


}