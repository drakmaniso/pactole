module Ledger exposing
    ( Category
    , Description
    , Ledger
    , Money
    , Reconciliation
    , Transaction
    , decoder
    , empty
    , formatAmount
    , isExpense
    , transactions
    )

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Time


type Ledger
    = Ledger { transactions : List Transaction }


type alias Transaction =
    { date : Date.Date
    , amount : Money
    , description : Description
    , category : Category
    , reconciliation : Reconciliation
    }


empty =
    Ledger { transactions = [] }


transactions : Ledger -> List Transaction
transactions (Ledger ledger) =
    ledger.transactions


decoder =
    let
        toLedger t =
            Ledger { transactions = t }
    in
    Decode.map toLedger (Decode.field "transactions" (Decode.list transactionDecoder))


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
    Decode.map5 Transaction
        dateDecoder
        amountDecoder
        descriptionDecoder
        categoryDecoder
        reconciliationDecoder



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


isExpense transaction =
    let
        (Money amount) =
            transaction.amount
    in
    amount < 0


formatAmount (Money amount) =
    String.fromInt (amount // 100)



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
