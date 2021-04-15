module Ledger exposing
    ( Ledger
    , NewTransaction
    , Transaction
    , decode
    , decodeNewTransaction
    , decodeTransaction
    , empty
    , encodeNewTransaction
    , encodeTransaction
    , getBalance
    , getCategoryTotalForMonth
    , getExpenseForMonth
    , getIncomeForMonth
    , getNotReconciledBeforeMonth
    , getReconciled
    , getTotalForMonth
    , getTransaction
    , getTransactionDescription
    , getTransactionsForDate
    , getTransactionsForMonth
    , hasFutureTransactionsForMonth
    )

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Money



-- LEDGER


type Ledger
    = Ledger (List Transaction)


type alias Transaction =
    { id : Int
    , date : Date.Date
    , amount : Money.Money
    , description : String
    , category : Int
    , checked : Bool
    }


empty : Ledger
empty =
    Ledger []


getBalance : Ledger -> Date.Date -> Money.Money
getBalance (Ledger transactions) today =
    transactions
        |> List.filter (\t -> Date.compare t.date today /= GT)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getReconciled : Ledger -> Money.Money
getReconciled (Ledger transactions) =
    transactions
        |> List.filter (\t -> t.checked == True)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getNotReconciledBeforeMonth : Ledger -> Date.Date -> Bool
getNotReconciledBeforeMonth (Ledger transactions) date =
    let
        d =
            Date.firstDayOf date
    in
    transactions
        |> List.filter
            (\t -> Date.compare t.date d == LT)
        |> List.any
            (\t -> not t.checked)


getTransactionsForDate : Date.Date -> Ledger -> List Transaction
getTransactionsForDate date (Ledger transactions) =
    List.filter
        (\t -> t.date == date)
        transactions


getTransactionsForMonth : Ledger -> Date.Date -> Date.Date -> List Transaction
getTransactionsForMonth (Ledger transactions) date today =
    transactions
        --TODO
        |> List.filter
            (\t ->
                (Date.compare t.date today /= GT)
                    && (Date.getYear t.date == Date.getYear date)
                    && (Date.getMonth t.date == Date.getMonth date)
            )


getTotalForMonth : Ledger -> Date.Date -> Date.Date -> Money.Money
getTotalForMonth ledger date today =
    getTransactionsForMonth ledger date today
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


hasFutureTransactionsForMonth : Ledger -> Date.Date -> Date.Date -> Bool
hasFutureTransactionsForMonth (Ledger transactions) date today =
    transactions
        |> List.any
            (\t ->
                (Date.compare t.date today == GT)
                    && (Date.getYear t.date == Date.getYear date)
                    && (Date.getMonth t.date == Date.getMonth date)
            )


getIncomeForMonth : Ledger -> Date.Date -> Date.Date -> Money.Money
getIncomeForMonth ledger date today =
    getTransactionsForMonth ledger date today
        |> List.filter
            (\t -> not (Money.isExpense t.amount))
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getExpenseForMonth : Ledger -> Date.Date -> Date.Date -> Money.Money
getExpenseForMonth ledger date today =
    getTransactionsForMonth ledger date today
        |> List.filter
            (\t -> Money.isExpense t.amount)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getCategoryTotalForMonth : Ledger -> Date.Date -> Date.Date -> Int -> Money.Money
getCategoryTotalForMonth ledger date today catID =
    getTransactionsForMonth ledger date today
        |> List.filter
            (\t -> Money.isExpense t.amount)
        |> List.filter
            (\t -> t.category == catID)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getTransaction : Int -> Ledger -> Maybe Transaction
getTransaction id (Ledger transactions) =
    let
        matches =
            List.filter
                (\t -> t.id == id)
                transactions
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


getTransactionDescription : { a | description : String, amount : Money.Money } -> String
getTransactionDescription transaction =
    if transaction.description == "" then
        if Money.isExpense transaction.amount then
            "Dépense"

        else
            "Entrée d'argent"

    else
        transaction.description



-- JSON ENCODERS AND DECODERS


decode : Decode.Decoder Ledger
decode =
    Decode.map Ledger (Decode.list decodeTransaction)


encodeTransaction : Int -> Transaction -> Encode.Value
encodeTransaction account transaction =
    Encode.object
        [ ( "account", Encode.int account )
        , ( "id", Encode.int transaction.id )
        , ( "date", Encode.int (Date.toInt transaction.date) )
        , ( "amount", Money.encoder transaction.amount )
        , ( "description", Encode.string transaction.description )
        , ( "category", Encode.int transaction.category )
        , ( "checked", Encode.bool transaction.checked )
        ]


decodeTransaction : Decode.Decoder Transaction
decodeTransaction =
    Decode.map6 Transaction
        (Decode.field "id" Decode.int)
        (Decode.map Date.fromInt (Decode.field "date" Decode.int))
        (Decode.field "amount" Money.decoder)
        (Decode.field "description" Decode.string)
        (Decode.field "category" Decode.int)
        (Decode.field "checked" Decode.bool)


type alias NewTransaction =
    { date : Date.Date
    , amount : Money.Money
    , description : String
    , category : Int
    , checked : Bool
    }


encodeNewTransaction : Int -> NewTransaction -> Encode.Value
encodeNewTransaction account transaction =
    Encode.object
        [ ( "account", Encode.int account )
        , ( "date", Encode.int (Date.toInt transaction.date) )
        , ( "amount", Money.encoder transaction.amount )
        , ( "description", Encode.string transaction.description )
        , ( "category", Encode.int transaction.category )
        , ( "checked", Encode.bool transaction.checked )
        ]


decodeNewTransaction : Decode.Decoder ( Int, NewTransaction )
decodeNewTransaction =
    Decode.map2 (\acc tr -> ( acc, tr ))
        (Decode.field "account" Decode.int)
        (Decode.map5 NewTransaction
            (Decode.map Date.fromInt (Decode.field "date" Decode.int))
            (Decode.field "amount" Money.decoder)
            (Decode.field "description" Decode.string)
            (Decode.field "category" Decode.int)
            (Decode.field "checked" Decode.bool)
        )
