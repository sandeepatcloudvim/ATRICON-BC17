tableextension 50000 ExtendItem extends Item
{
    fields
    {
        field(50000; "501k Num"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = '501k Num';
            TableRelation = "501k Number";
        }

    }

    var
        myInt: Integer;
        recItem: Record Item;

    procedure LookupVendorItem(var Itemrec: Record Item; VendorValue: text[250]): Boolean
    var
        ItemLookup: Page "CBR Item Lookup";
        Result: Boolean;
    begin
        Itemrec.reset;
        Itemrec.SetFilter("Vendor Item No.", '%1', '@' + '*' + VendorValue + '*');
        ItemLookup.SETTABLEVIEW(Itemrec);
        ItemLookup.SETRECORD(Itemrec);
        ItemLookup.LOOKUPMODE := TRUE;
        Result := ItemLookup.RUNMODAL = ACTION::LookupOK;
        IF Result THEN
            ItemLookup.GETRECORD(Itemrec)
        ELSE
            CLEAR(Itemrec);

        EXIT(Result);
    end;
}