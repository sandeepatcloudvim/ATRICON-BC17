pageextension 50002 ExtendSalesOrderSubform extends "Sales Order Subform"
{
    layout
    {
        addbefore("No.")
        {
            field("Vendor Item No."; Rec."Vendor Item No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor Item No.';
                ShowMandatory = true;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

    var
        myInt: Integer;

}