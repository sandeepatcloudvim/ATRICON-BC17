pageextension 50001 ExtendSalesOrder extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        addafter("Create &Warehouse Shipment")
        {
            action("CBR Create Tracking Line")
            {
                ApplicationArea = All;
                Caption = 'Create Tracking Line';
                Promoted = true;
                Image = Track;
                PromotedCategory = Category7;
                trigger OnAction()
                begin
                    CBRInsertTrackingLines();
                end;
            }
        }
    }

    var
        myInt: Integer;
        recReservationEntry: Record "Reservation Entry";

    local procedure CBRInsertTrackingLines()
    var
        RecSalesLine: Record "Sales Line";
        SalesDocStatus: Enum "Sales Document Status";
        ReservationEntry: Record "Reservation Entry";
        ErrorTable: Record "Error Message";
        ItemRec: Record Item;
        Text001: Label 'Item Tracking Lines for the Sales Order: %1  has been created successfully';
        Text002: Label 'Would you like to auto fill the tracking line for the sales Order No %1';
    begin

        Rec.TestField(Status, 0);
        IF NOT CONFIRM(Text002, FALSE, Rec."No.") THEN
            EXIT;
        CBRDeleteReservationEntry(Rec);  // Clean the old Resrevation for the Order
        RecSalesLine.RESET;
        RecSalesLine.SETRANGE("Document Type", RecSalesLine."Document Type"::Order);
        RecSalesLine.SETRANGE("Document No.", Rec."No.");
        RecSalesLine.SETRANGE(Type, RecSalesLine.Type::Item);
        RecSalesLine.SETFILTER("No.", '<>%1', '*@ZZ*');
        RecSalesLine.SETFILTER("Qty. to Ship", '>%1', 0);
        IF RecSalesLine.FINDSET THEN
            REPEAT
                IF ItemRec.GET(RecSalesLine."No.") THEN BEGIN
                    IF ItemRec.Type = ItemRec.Type::Inventory THEN BEGIN
                        CBRDeleteUnusedReservationEntry(ItemRec."No.");
                        CBRUpdateSalesLineWithFullCasePackQty(RecSalesLine);
                        CBRAutoFillTrackingLines(RecSalesLine, ErrorTable);
                    END;
                END;
            UNTIL RecSalesLine.NEXT = 0;

        MESSAGE('Tracking lines for Sales order : %1 have been created successfully', Rec."No.");

    end;

    local procedure CBRUpdateSalesLineWithFullCasePackQty(VAR SalesLine: Record "Sales Line"): Boolean
    var
        AvablLotQty: Decimal;
        ReservEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ILE1: Record "Item Ledger Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        LotQty: Decimal;
        QtyChek: Boolean;
        QtyChek1: Boolean;
        TotalILEQty: Decimal;
        ReserveQty: Decimal;
        SalesLineRec: Record "Sales Line";
        CasePackQty: Decimal;
        ItemRec: Record Item;
        IUoM: Record "Item Unit of Measure";
        CurrLotNo: Code[20];
        ILERemainingQty: Decimal;
        AvaliablecasePackQty: Decimal;
        TotAvaliable: Decimal;
    begin
        TotalILEQty := 0;
        ReserveQty := 0;
        CurrLotNo := '';
        TotalILEQty := 0;
        TotAvaliable := 0;
        ItemRec.GET(SalesLine."No.");

        ItemLedgerEntry.RESET;
        ItemLedgerEntry.SETRANGE("Item No.", SalesLine."No.");
        ItemLedgerEntry.SETFILTER("Remaining Quantity", '>%1', 0);
        IF ItemLedgerEntry.FINDSET THEN BEGIN
            ItemLedgerEntry.CALCSUMS("Remaining Quantity");
            TotalILEQty := ItemLedgerEntry."Remaining Quantity";
        END;

        ReservEntry.RESET;
        ReservEntry.SETRANGE("Item No.", SalesLine."No.");
        ReservEntry.SETRANGE("Location Code", SalesLine."Location Code");
        ReservEntry.SETFILTER("Lot No.", '<>%1', '');
        ReservEntry.SETRANGE("Source Type", DATABASE::"Sales Line");
        IF ReservEntry.FINDSET THEN
            REPEAT
                ReserveQty += ReservEntry."Quantity (Base)";
            UNTIL ReservEntry.NEXT = 0;

        TotAvaliable := TotalILEQty + ReserveQty;

        IF SalesLine."Qty. to Ship (Base)" > TotAvaliable THEN BEGIN
            ItemLedgerEntry.RESET;
            ItemLedgerEntry.SETCURRENTKEY("Expiration Date");
            ItemLedgerEntry.SETRANGE("Item No.", SalesLine."No.");
            ItemLedgerEntry.SETFILTER("Remaining Quantity", '>%1', 0);
            IF ItemLedgerEntry.FINDSET THEN
                REPEAT
                    AvablLotQty := 0;
                    LotQty := 0;
                    ILERemainingQty := 0;
                    IF CurrLotNo <> ItemLedgerEntry."Lot No." THEN BEGIN  // Only trigger once for each Lot from the ILE
                        ILE1.RESET;
                        ILE1.SETCURRENTKEY(ILE1."Expiration Date");
                        ILE1.SETRANGE("Item No.", SalesLine."No.");
                        ILE1.SETRANGE("Lot No.", ItemLedgerEntry."Lot No.");
                        ILE1.SETFILTER("Remaining Quantity", '>%1', 0);
                        IF ILE1.FINDFIRST THEN BEGIN
                            ILE1.CALCSUMS("Remaining Quantity");
                            LotQty := CBRGetReservationQty(SalesLine, ILE1);
                            AvablLotQty := ILE1."Remaining Quantity" + LotQty;  // Get the total avaliable quantity
                            IF SalesLine."Unit of Measure Code" <> ItemRec."Base Unit of Measure" THEN   // Check if the item is sold in different UOM
                                CasePackQty += (AvablLotQty DIV SalesLine."Qty. per Unit of Measure")
                            ELSE BEGIN
                                IF SalesLine.Quantity > AvablLotQty THEN
                                    CasePackQty += AvablLotQty;
                            end;
                        end;
                    end;
                    CurrLotNo := ItemLedgerEntry."Lot No.";
                UNTIL (ItemLedgerEntry.NEXT = 0);

            SalesLine.VALIDATE("Qty. to Ship", CasePackQty);
            SalesLine.MODIFY;
            EXIT(TRUE);
        end
    end;

    local procedure CBRAutoFillTrackingLines(SalesLine: Record "Sales Line"; VAR ErrorTable: Record "Error Message"): Boolean
    var
        AvablLotQty: Decimal;
        ReservEntry: Record "Reservation Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ILE1: Record "Item Ledger Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
        LotQty: Decimal;
        TotalILEQty: Decimal;
        RequiredSaleLineQty: Decimal;
        ReserveQty: Decimal;
        SalesLineRec: Record "Sales Line";
        QtytoAssign: Decimal;
        CasePackQty: Decimal;
        ItemRec: Record Item;
        CurrLotNo: Code[20];
        ILERemainingQty: Decimal;
    begin
        TotalILEQty := 0;
        ReserveQty := 0;

        ItemLedgerEntry.RESET;
        ItemLedgerEntry.SETRANGE("Item No.", SalesLine."No.");
        ItemLedgerEntry.SETFILTER("Remaining Quantity", '>%1', 0);
        IF ItemLedgerEntry.FINDSET THEN BEGIN
            ItemLedgerEntry.CALCSUMS("Remaining Quantity");
            TotalILEQty := ItemLedgerEntry."Remaining Quantity";
        END;

        ReservEntry.RESET;
        ReservEntry.SETRANGE("Item No.", SalesLine."No.");
        ReservEntry.SETRANGE("Location Code", SalesLine."Location Code");
        ReservEntry.SETRANGE("Source Type", DATABASE::"Sales Line");
        IF ReservEntry.FINDSET THEN
            REPEAT
                ReserveQty += ReservEntry."Quantity (Base)";
            UNTIL ReservEntry.NEXT = 0;

        CurrLotNo := '';
        RequiredSaleLineQty := SalesLine."Qty. to Ship (Base)";

        ItemLedgerEntry.RESET;
        ItemLedgerEntry.SETCURRENTKEY("Expiration Date");
        ItemLedgerEntry.SETRANGE("Item No.", SalesLine."No.");
        ItemLedgerEntry.SETFILTER("Remaining Quantity", '>%1', 0);
        IF ItemLedgerEntry.FINDSET THEN
            REPEAT

                AvablLotQty := 0;
                LotQty := 0;
                ILERemainingQty := 0;

                IF CurrLotNo <> ItemLedgerEntry."Lot No." THEN BEGIN  // Only trigger once for each Lot from the ILE
                    ILE1.RESET;
                    ILE1.SETCURRENTKEY(ILE1."Expiration Date");
                    ILE1.SETRANGE("Item No.", SalesLine."No.");
                    ILE1.SETRANGE("Lot No.", ItemLedgerEntry."Lot No.");
                    ILE1.SETFILTER("Remaining Quantity", '>%1', 0);
                    IF ILE1.FINDFIRST THEN BEGIN
                        ILE1.CALCSUMS("Remaining Quantity");
                        LotQty := CBRGetReservationQty(SalesLine, ILE1);
                        AvablLotQty := ILE1."Remaining Quantity" + LotQty;  // Get the total avaliable quantity

                        ItemRec.GET(ILE1."Item No.");
                        IF SalesLine."Unit of Measure Code" <> ItemRec."Base Unit of Measure" THEN BEGIN  // Check if the item is sold in different UOM
                            CasePackQty := (AvablLotQty DIV SalesLine."Qty. per Unit of Measure");
                            AvablLotQty := (CasePackQty * SalesLine."Qty. per Unit of Measure");
                        END;

                        IF RequiredSaleLineQty > AvablLotQty THEN BEGIN
                            QtytoAssign := AvablLotQty;
                            CreateReservEntry.CreateReservEntryFor(DATABASE::"Sales Line", "Document Type", SalesLine."Document No.", '', 0, SalesLine."Line No.", SalesLine."Qty. per Unit of Measure", QtytoAssign, QtytoAssign, '', ILE1."Lot No.");
                            CreateReservEntry.CreateEntry(SalesLine."No.", ILE1."Variant Code", SalesLine."Location Code", SalesLine.Description, SalesLine."Requested Delivery Date", SalesLine."Shipment Date", 0, ReservEntry."Reservation Status"::Surplus);
                        END;
                        IF RequiredSaleLineQty <= AvablLotQty THEN BEGIN
                            QtytoAssign := RequiredSaleLineQty;
                            CreateReservEntry.CreateReservEntryFor(DATABASE::"Sales Line", "Document Type", SalesLine."Document No.", '', 0, SalesLine."Line No.", SalesLine."Qty. per Unit of Measure", QtytoAssign, QtytoAssign, '', ILE1."Lot No.");
                            CreateReservEntry.CreateEntry(SalesLine."No.", ILE1."Variant Code", SalesLine."Location Code", SalesLine.Description, SalesLine."Requested Delivery Date", SalesLine."Shipment Date", 0, ReservEntry."Reservation Status"::Surplus);
                            EXIT;
                        END;

                        //Reduce the required qty after the previous allocation ++
                        IF RequiredSaleLineQty > AvablLotQty THEN
                            RequiredSaleLineQty := RequiredSaleLineQty - AvablLotQty
                        ELSE
                            RequiredSaleLineQty := AvablLotQty;
                    END;
                END;
                CurrLotNo := ItemLedgerEntry."Lot No.";
            UNTIL ItemLedgerEntry.NEXT = 0;

        IF RequiredSaleLineQty <> 0 THEN
            CBRInsertErrorLog(SalesLine, RequiredSaleLineQty, ErrorTable);
    end;

    local procedure CBRInsertErrorLog(LocSalesLine: Record "Sales Line"; TotalQuantity: Integer; VAR ErrorTable: Record "Error Message")
    begin
        ErrorTable.INIT;
        IF ErrorTable.FINDLAST THEN
            ErrorTable.ID := ErrorTable.ID + 1
        ELSE
            ErrorTable.ID += 1;
        ErrorTable."Record ID" := LocSalesLine.RECORDID;
        ErrorTable."Field Number" := LocSalesLine.FIELDNO(LocSalesLine."Qty. to Ship (Base)");
        ErrorTable."Message Type" := ErrorTable."Message Type"::Information;
        ErrorTable.Description := 'Enough Lot Quantity is not available to fully assign the Sales Line Quantity ' + FORMAT(LocSalesLine."Qty. to Ship (Base)") + ' for Item ' + LocSalesLine."No." + ' , Balance Lot Quantity is ' + FORMAT(ABS(TotalQuantity));
        ErrorTable."Table Number" := DATABASE::"Sales Line";
        ErrorTable."Field Name" := LocSalesLine.FIELDNAME("Qty. to Ship (Base)");
        ErrorTable."Table Name" := LocSalesLine.TABLENAME;
        ErrorTable.INSERT;
    end;

    procedure CBRDeleteReservationEntry(SalesHead: Record "Sales Header")
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.RESET;
        ReservEntry.SETRANGE("Source Type", DATABASE::"Sales Line");
        ReservEntry.SETRANGE("Source ID", SalesHead."No.");
        IF ReservEntry.FINDSET THEN
            ReservEntry.DELETEALL;
    end;

    procedure CBRDeleteUnusedReservationEntry(ItemNo: Code[20])
    var
        recSalesLine: Record "Sales Line";
    begin
        recReservationEntry.RESET;
        recReservationEntry.SETRANGE("Item No.", ItemNo);
        IF recReservationEntry.FINDSET THEN
            REPEAT
                recSalesLine.RESET;
                recSalesLine.SETRANGE("Document No.", recReservationEntry."Source ID");
                IF NOT recSalesLine.FINDSET THEN
                    recReservationEntry.DELETE;
            UNTIL recReservationEntry.NEXT = 0;
    end;

    local procedure CBRGetReservationQty(SalesLine: Record "Sales Line"; ILE: Record "Item Ledger Entry"): Decimal
    var
        ReservationQty: Decimal;
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.RESET;
        ReservEntry.SETRANGE("Item No.", SalesLine."No.");
        ReservEntry.SETRANGE("Location Code", SalesLine."Location Code");
        ReservEntry.SETRANGE("Source Type", DATABASE::"Sales Line");
        ReservEntry.SETRANGE("Lot No.", ILE."Lot No.");
        IF ReservEntry.FINDSET THEN
            REPEAT
                ReservationQty += ReservEntry."Quantity (Base)";
            UNTIL ReservEntry.NEXT = 0;
        EXIT(ReservationQty)
    end;

}