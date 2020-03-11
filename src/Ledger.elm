module Ledger exposing
    ( Category
    , Description
    , Ledger
    , Money
    , Reconciliation
    , Transaction
    , decoder
    , empty
    , getAllTransactions
    , getAmountInput
    , getAmountParts
    , getDateTransactions
    , getDescriptionDisplay
    , getDescriptionInput
    , getTransaction
    , isExpense
    )

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Time



-- LEDGER


type Ledger
    = Ledger
        { transactions : List Transaction
        , nextId : Int
        }


empty =
    Ledger { transactions = [], nextId = 0 }


getAllTransactions : Ledger -> List Transaction
getAllTransactions (Ledger ledger) =
    ledger.transactions


getDateTransactions : Date.Date -> Ledger -> List Transaction
getDateTransactions date (Ledger ledger) =
    List.filter
        (\t -> t.date == date)
        ledger.transactions


getTransaction : Int -> Ledger -> Maybe Transaction
getTransaction id (Ledger ledger) =
    let
        matches =
            List.filter
                (\t -> t.id == id)
                ledger.transactions
    in
    case matches of
        [] ->
            Nothing

        [ t ] ->
            Just t

        _ ->
            Debug.log "INCONSISTENT LEDGER: MULTIPLE TRANSACIONTS WITH SAME ID" Nothing


decoder =
    let
        toLedger t =
            Ledger
                { transactions =
                    List.sortWith (\a b -> Date.compare a.date b.date) t
                , nextId =
                    List.map .id t
                        |> List.maximum
                        |> (\v ->
                                case v of
                                    Nothing ->
                                        0

                                    Just vv ->
                                        vv + 1
                           )
                }
    in
    Decode.map toLedger (Decode.field "transactions" (Decode.list transactionDecoder))



-- TRANSACTION


type alias Transaction =
    { id : Int
    , date : Date.Date
    , amount : Money
    , description : Description
    , category : Category
    , reconciliation : Reconciliation
    }


isExpense transaction =
    let
        (Money amount) =
            transaction.amount
    in
    amount < 0


encodeTransaction : Transaction -> Encode.Value
encodeTransaction { date, amount, description, category, reconciliation } =
    let
        (Money money) =
            amount

        withRec =
            case reconciliation of
                NotReconciled ->
                    []

                Reconciled ->
                    [ ( "reconciled", Encode.bool True ) ]

        withCatRec =
            case category of
                NoCategory ->
                    withRec

                Category c ->
                    ( "category", Encode.string c ) :: withRec

        withDescCatRec =
            case description of
                NoDescription ->
                    withCatRec

                Description d ->
                    ( "description", Encode.string d ) :: withCatRec
    in
    Encode.object
        (( "date", Encode.int (Date.toInt date) )
            :: ( "amount", Encode.int money )
            :: withDescCatRec
        )


transactionDecoder =
    Decode.map6 Transaction
        idDecoder
        dateDecoder
        amountDecoder
        descriptionDecoder
        categoryDecoder
        reconciliationDecoder



-- ID


idDecoder : Decode.Decoder Int
idDecoder =
    Decode.field "id" Decode.int



-- DATE


dateDecoder : Decode.Decoder Date.Date
dateDecoder =
    let
        toDate a =
            case a of
                Ok aa ->
                    Date.fromInt aa

                Err e ->
                    Debug.log (Decode.errorToString e) (Date.fromInt 0)
    in
    Decode.map Date.fromInt (Decode.field "date" Decode.int)



-- MONEY


type Money
    = Money Int


amountDecoder : Decode.Decoder Money
amountDecoder =
    let
        toAmount a =
            case a of
                Ok aa ->
                    Money aa

                Err e ->
                    Debug.log (Decode.errorToString e) (Money 0)
    in
    Decode.map Money (Decode.field "amount" Decode.int)


getAmountParts transaction =
    let
        (Money amount) =
            transaction.amount

        units =
            String.fromInt (amount // 100)

        mainPart =
            if amount < 0 then
                units

            else
                "+" ++ units

        cents =
            abs (remainderBy 100 amount)
    in
    if cents /= 0 then
        { units = mainPart
        , cents = Just ("," ++ String.padLeft 2 '0' (String.fromInt cents))
        }

    else
        { units = mainPart, cents = Nothing }


getAmountInput transaction =
    let
        (Money amount) =
            transaction.amount

        units =
            String.fromInt (amount // 100)

        cents =
            abs (remainderBy 100 amount)
    in
    if cents == 0 then
        units

    else
        units ++ "," ++ String.padLeft 2 '0' (String.fromInt cents)



-- DESCRIPTION


type Description
    = Description String
    | NoDescription


descriptionDecoder : Decode.Decoder Description
descriptionDecoder =
    let
        toDescription c =
            case c of
                Just s ->
                    Description s

                Nothing ->
                    NoDescription
    in
    Decode.map toDescription (Decode.maybe (Decode.field "description" Decode.string))


getDescriptionInput transaction =
    case transaction.description of
        Description d ->
            d

        NoDescription ->
            ""


getDescriptionDisplay transaction =
    case transaction.description of
        Description d ->
            d

        NoDescription ->
            if isExpense transaction then
                "Dépense"

            else
                "Entrée d'argent"



-- CATEGORY


type Category
    = Category String
    | NoCategory


categoryDecoder : Decode.Decoder Category
categoryDecoder =
    let
        toCategory c =
            case c of
                Just s ->
                    Category s

                Nothing ->
                    NoCategory
    in
    Decode.map toCategory (Decode.maybe (Decode.field "category" Decode.string))



-- RECONCILIATION


type Reconciliation
    = Reconciled
    | NotReconciled


reconciliationDecoder : Decode.Decoder Reconciliation
reconciliationDecoder =
    let
        toReconciliation r =
            case r of
                Just b ->
                    if b then
                        Reconciled

                    else
                        NotReconciled

                Nothing ->
                    NotReconciled
    in
    Decode.map toReconciliation (Decode.maybe (Decode.field "reconciled" Decode.bool))
