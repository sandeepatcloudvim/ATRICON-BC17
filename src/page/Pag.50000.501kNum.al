page 50000 "501k Number"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "501k Number";

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("501k Number"; rec."501k Num")
                {
                    ApplicationArea = All;
                    Caption = '501k Num';
                }
                field("501k Description"; rec."501k Description")
                {
                    ApplicationArea = All;
                    Caption = '501k Num';
                }
            }
        }
        area(Factboxes)
        {

        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {
                ApplicationArea = All;

                trigger OnAction();
                begin

                end;
            }
        }
    }
}