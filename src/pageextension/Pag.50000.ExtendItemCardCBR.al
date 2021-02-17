pageextension 50000 ExtendItemCard extends "Item Card"
{
    layout
    {
        addafter("Purchasing Code")
        {
            field("501k Num"; rec."501k Num")
            {
                ApplicationArea = All;
                Caption = '501k Num';
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