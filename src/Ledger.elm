module Ledger exposing
    ( Category
    , Ledger
    , Reconciliation
    , Transaction
    , decoder
    , empty
    , encode
    , getAllTransactions
    , getBalance
    , getDateTransactions
    , getDescriptionDisplay
    , getTransaction
    )

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Money
import Time



-- LEDGER


type Ledger
    = Ledger
        { transactions : List Transaction
        }


empty =
    Ledger { transactions = [] }


getAllTransactions : Ledger -> List Transaction
getAllTransactions (Ledger ledger) =
    ledger.transactions


getBalance : Ledger -> Money.Money
getBalance (Ledger ledger) =
    List.foldl
        (\t accum -> Money.add accum t.amount)
        Money.zero
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
            --TODO: error: multiple transactions with the same ID
            Nothing



{-
   addTransaction : { date : Date.Date, amount : Money.Money, description : String } -> Ledger -> Ledger
   addTransaction { date, amount, description } (Ledger ledger) =
       Ledger
           { transactions =
               ledger.transactions
                   ++ [ { id = ledger.nextId
                        , date = date
                        , amount = amount
                        , description = description
                        , category = NoCategory
                        , reconciliation = NotReconciled
                        }
                      ]
           , nextId = ledger.nextId + 1
           }


   updateTransaction : { id : Int, date : Date.Date, amount : Money.Money, description : String } -> Ledger -> Ledger
   updateTransaction { id, date, amount, description } (Ledger ledger) =
       Ledger
           { transactions =
               List.map
                   (\t ->
                       if t.id == id then
                           { id = id
                           , date = date
                           , amount = amount
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


   deleteTransaction : Int -> Ledger -> Ledger
   deleteTransaction id (Ledger ledger) =
       Ledger
           { transactions =
               List.filter
                   (\t -> t.id /= id)
                   ledger.transactions
           , nextId = ledger.nextId
           }
-}


decoder =
    let
        toLedger t =
            Ledger
                { transactions =
                    List.sortWith (\a b -> Date.compare a.date b.date) t
                }
    in
    Decode.map toLedger (Decode.field "transactions" (Decode.list transactionDecoder))


encode : Ledger -> Encode.Value
encode (Ledger ledger) =
    Encode.object
        [ ( "transactions", Encode.list encodeTransaction ledger.transactions ) ]



-- TRANSACTION


type alias Transaction =
    { id : Int
    , date : Date.Date
    , amount : Money.Money
    , description : String
    , category : Category
    , reconciliation : Reconciliation
    }


encodeTransaction : Transaction -> Encode.Value
encodeTransaction { id, date, amount, description, category, reconciliation } =
    let
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
        (( "id", Encode.int id )
            :: ( "date", Encode.int (Date.toInt date) )
            :: ( "amount", Money.encoder amount )
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
    Decode.map Date.fromInt (Decode.field "date" Decode.int)



-- AMOUNT


amountDecoder : Decode.Decoder Money.Money
amountDecoder =
    Decode.field "amount" Money.decoder



-- DESCRIPTION


descriptionDecoder : Decode.Decoder String
descriptionDecoder =
    Decode.oneOf [ Decode.field "description" Decode.string, Decode.succeed "" ]


getDescriptionDisplay transaction =
    if transaction.description == "" then
        if Money.isExpense transaction.amount then
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
