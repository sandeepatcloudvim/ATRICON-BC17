table 50000 "501k Number"
{
    DataClassification = ToBeClassified;
    LookupPageID = "501k Number";
    DrillDownPageId = "501k Number";
    DataCaptionFields = "501k Num", "501k Description";

    fields
    {
        field(1; "501k Num"; Code[20])
        {
            DataClassification = ToBeClassified;
            Caption = '501k Num';
        }
        field(2; "501k Description"; Text[100])
        {
            DataClassification = ToBeClassified;
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "501k Num")
        {
            Clustered = true;
        }
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

}