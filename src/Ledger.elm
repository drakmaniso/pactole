module Ledger exposing
    ( Amount(..)
    , Category
    , Ledger
    , Reconciliation
    , Transaction
    , addTransaction
    , decoder
    , empty
    , getAllTransactions
    , getAmountInput
    , getAmountParts
    , getBalance
    , getBalanceParts
    , getDateTransactions
    , getDescriptionDisplay
    , getTransaction
    , inputToAmount
    , isExpense
    , updateTransaction
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


getBalance : Ledger -> Amount
getBalance (Ledger ledger) =
    let
        balance =
            List.foldl
                (\transaction accum ->
                    let
                        (Amount amount) =
                            transaction.amount
                    in
                    accum + amount
                )
                0
                ledger.transactions
    in
    Amount balance


getBalanceParts ledger =
    let
        (Amount balance) =
            getBalance ledger

        units =
            balance // 100

        cents =
            abs (remainderBy 100 balance)
    in
    if True || cents /= 0 then
        { units =
            String.fromInt units ++ ","
        , cents = String.padLeft 2 '0' (String.fromInt cents)
        }

    else
        { units = String.fromInt units, cents = "" }


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


addTransaction : { date : Date.Date, sign : Int, amount : Amount, description : String } -> Ledger -> Ledger
addTransaction { date, sign, amount, description } (Ledger ledger) =
    let
        (Amount a) =
            amount

        signedAmount =
            Amount (sign * a)
    in
    Ledger
        { transactions =
            ledger.transactions
                ++ [ { id = ledger.nextId
                     , date = date
                     , amount = signedAmount
                     , description = description
                     , category = NoCategory
                     , reconciliation = NotReconciled
                     }
                   ]
        , nextId = ledger.nextId + 1
        }


updateTransaction : { id : Int, date : Date.Date, sign : Int, amount : Amount, description : String } -> Ledger -> Ledger
updateTransaction { id, date, sign, amount, description } (Ledger ledger) =
    let
        (Amount a) =
            amount

        signedAmount =
            Amount (sign * a)
    in
    Ledger
        { transactions =
            List.map
                (\t ->
                    if t.id == id then
                        { id = id
                        , date = date
                        , amount = signedAmount
                        , description = description
                        , category = NoCategory
                        , reconciliation = NotReconciled
                        }

                    else
                        t
                )
                ledger.transactions
        , nextId = ledger.nextId + 1
        }


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
    , description : String
    , category : Category
    , reconciliation : Reconciliation
    }


isExpense transaction =
    let
        (Amount amount) =
            transaction.amount
    in
    amount < 0


encodeTransaction : Transaction -> Encode.Value
encodeTransaction { date, amount, description, category, reconciliation } =
    let
        (Amount amountVal) =
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
    in
    Encode.object
        (( "date", Encode.int (Date.toInt date) )
            :: ( "amount", Encode.int amountVal )
            :: ( "description", Encode.string description )
            :: withCatRec
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
    = Amount Int -- Amount (units*100 + cents)


amountDecoder : Decode.Decoder Amount
amountDecoder =
    Decode.map Amount (Decode.field "amount" Decode.int)


getAmountParts transaction =
    let
        (Amount amount) =
            transaction.amount

        units =
            amount // 100

        cents =
            abs (remainderBy 100 amount)
    in
    if True || cents /= 0 then
        { units =
            (if units >= 0 then
                "+"

             else
                ""
            )
                ++ String.fromInt units
                ++ ","
        , cents = Just (String.padLeft 2 '0' (String.fromInt cents))
        }

    else
        { units = String.fromInt units, cents = Nothing }


getAmountInput transaction =
    let
        (Amount amount) =
            transaction.amount

        units =
            amount // 100

        cents =
            abs (remainderBy 100 amount)
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


inputToAmount string =
    let
        str =
            String.filter (\c -> c /= ' ') string
    in
    case String.split "," str of
        [ s ] ->
            Maybe.map
                (\v -> Amount (v * 100))
                (String.toInt s)

        [ s1, s2 ] ->
            let
                units =
                    Maybe.map
                        (\v -> v * 100)
                        (String.toInt s1)

                cents =
                    String.toInt s2
            in
            Maybe.map2 (+) units cents
                |> Maybe.map Amount

        _ ->
            Nothing



-- DESCRIPTION


descriptionDecoder : Decode.Decoder String
descriptionDecoder =
    Decode.oneOf [ Decode.field "description" Decode.string, Decode.succeed "" ]


getDescriptionDisplay transaction =
    if transaction.description == "" then
        if isExpense transaction then
            "Dépense"

        else
            "Entrée d'argent"

    else
        transaction.description



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
