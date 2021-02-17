tableextension 50003 ExtendItemVendor extends "Item Vendor"
{
    fields
    {
        // Add changes to table fields here
    }
    fieldgroups
    {
        addlast(DropDown; "Item No.", "Vendor Item No.")
        {

        }

    }

    var
        myInt: Integer;
}