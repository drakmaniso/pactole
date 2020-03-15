module Ledger exposing
    ( Amount(..)
    , Category
    , Description
    , Ledger
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
    , validateAmountInput
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
    , amount : Amount
    , description : Description
    , category : Category
    , reconciliation : Reconciliation
    }


isExpense transaction =
    let
        (Amount units _) =
            transaction.amount
    in
    units < 0


encodeTransaction : Transaction -> Encode.Value
encodeTransaction { date, amount, description, category, reconciliation } =
    let
        (Amount units cents) =
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
            :: ( "amount", Encode.int (100 * units + cents) )
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



-- AMOUNT


type Amount
    = Amount Int Int -- Amount units cents


amountDecoder : Decode.Decoder Amount
amountDecoder =
    let
        amount v =
            Amount (v // 100) (abs (remainderBy 100 v))
    in
    Decode.map amount (Decode.field "amount" Decode.int)


getAmountParts transaction =
    let
        (Amount units cents) =
            transaction.amount
    in
    if True || cents /= 0 then
        { units =
            (if units >= 0 then
                "+"

             else
                ""
            )
                ++ String.fromInt units
        , cents = Just ("," ++ String.padLeft 2 '0' (String.fromInt cents))
        }

    else
        { units = String.fromInt units, cents = Nothing }


getAmountInput transaction =
    let
        (Amount units cents) =
            transaction.amount
    in
    if cents == 0 then
        String.fromInt (abs units)

    else
        String.fromInt (abs units) ++ "," ++ String.padLeft 2 '0' (String.fromInt cents)


validateAmountInput string =
    let
        str =
            String.filter (\c -> c /= ' ') string

        commas =
            String.indices "," str
    in
    if str == "" then
        "entrer un nombre"

    else if String.any (\c -> not (Char.isDigit c || c == ',')) str then
        "utiliser uniquement des chiffres et une virgule"

    else
        case commas of
            [] ->
                ""

            [ i ] ->
                if i /= (String.length str - 3) then
                    "mettre deux chiffres après la virgule"

                else
                    ""

            _ ->
                "utiliser une seule virgule"



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
