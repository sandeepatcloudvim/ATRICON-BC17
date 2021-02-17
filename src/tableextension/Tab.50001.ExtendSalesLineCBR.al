tableextension 50001 ExtendSalesLine extends "Sales Line"
{
    fields
    {
        field(50000; "Vendor Item No."; Text[20])
        {
            DataClassification = ToBeClassified;
            Caption = 'Vendor Item No.';


            trigger OnLookup()
            var
                recItem: Record Item;
            begin

                if recItem.LookupVendorItem(recItem, "Vendor Item No.") then begin
                    "Vendor Item No." := recItem."Vendor Item No.";
                    Validate("No.", recItem."No.");
                end;
            end;

            trigger OnValidate()
            var
                recItem: Record Item;
            begin

                if recItem.LookupVendorItem(recItem, "Vendor Item No.") then begin
                    "Vendor Item No." := recItem."Vendor Item No.";
                    Validate("No.", recItem."No.");
                end;
            end;

        }
        modify("No.")
        {
            trigger OnAfterValidate()
            var
                recItem1: Record Item;
            begin
                if recItem1.Get("No.") then
                    "Vendor Item No." := recItem1."Vendor Item No.";
            end;
        }

    }

    var
        myInt: Integer;


}