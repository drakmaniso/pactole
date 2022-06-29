module Ledger exposing
    ( Ledger
    , NewTransaction
    , Transaction
    , decode
    , decodeNewTransaction
    , empty
    , encode
    , encodeNewTransaction
    , encodeTransaction
    , getActivatedRecurringTransactions
    , getAllTransactions
    , getBalance
    , getCategoryTotalForMonth
    , getExpenseForMonth
    , getIncomeForMonth
    , getNotReconciledBeforeMonth
    , getReconciled
    , getRecurringTransactionsForDate
    , getTotalForMonth
    , getTransaction
    , getTransactionDescription
    , getTransactionsForDate
    , getTransactionsForMonth
    , hasFutureTransactionsForMonth
    , newTransactionFromRecurring
    )

import Date exposing (Date)
import Json.Decode as Decode
import Json.Encode as Encode
import Money



-- LEDGER


type Ledger
    = Ledger (List Transaction)


type alias Transaction =
    { id : Int
    , account : Int
    , date : Date
    , amount : Money.Money
    , description : String
    , category : Int
    , checked : Bool
    }


type alias NewTransaction =
    { account : Int
    , date : Date
    , amount : Money.Money
    , description : String
    , category : Int
    , checked : Bool
    }


empty : Ledger
empty =
    Ledger []


getBalance : Ledger -> Int -> Date -> Money.Money
getBalance (Ledger transactions) account today =
    transactions
        |> List.filter (\t -> t.account == account)
        |> List.filter (\t -> Date.compare t.date today /= GT)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getReconciled : Ledger -> Int -> Money.Money
getReconciled (Ledger transactions) account =
    transactions
        |> List.filter (\t -> t.account == account)
        |> List.filter (\t -> t.checked == True)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getNotReconciledBeforeMonth : Ledger -> Int -> Date -> Bool
getNotReconciledBeforeMonth (Ledger transactions) account date =
    let
        d =
            Date.firstDayOf date
    in
    transactions
        |> List.filter (\t -> t.account == account)
        |> List.filter
            (\t -> Date.compare t.date d == LT)
        |> List.any
            (\t -> not t.checked)


getTransactionsForDate : Ledger -> Int -> Date -> List Transaction
getTransactionsForDate (Ledger transactions) account date =
    transactions
        |> List.filter (\t -> t.account == account)
        |> List.filter (\t -> t.date == date)


getTransactionsForMonth : Ledger -> Int -> Date.MonthYear -> Date -> List Transaction
getTransactionsForMonth (Ledger transactions) account monthYear today =
    transactions
        --TODO
        |> List.filter (\t -> t.account == account)
        |> List.filter
            (\t ->
                (Date.compare t.date today /= GT)
                    && (Date.getYear t.date == monthYear.year)
                    && (Date.getMonth t.date == monthYear.month)
            )
        |> List.sortWith
            (\a b -> Date.compare a.date b.date)


getTotalForMonth : Ledger -> Int -> Date.MonthYear -> Date -> Money.Money
getTotalForMonth ledger account monthYear today =
    getTransactionsForMonth ledger account monthYear today
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


hasFutureTransactionsForMonth : Ledger -> Int -> Date.MonthYear -> Date -> Bool
hasFutureTransactionsForMonth (Ledger transactions) account monthYear today =
    transactions
        |> List.filter (\t -> t.account == account)
        |> List.any
            (\t ->
                (Date.compare t.date today == GT)
                    && (Date.getYear t.date == monthYear.year)
                    && (Date.getMonth t.date == monthYear.month)
            )


getIncomeForMonth : Ledger -> Int -> Date.MonthYear -> Date -> Money.Money
getIncomeForMonth ledger account monthYear today =
    getTransactionsForMonth ledger account monthYear today
        |> List.filter (\t -> not (Money.isExpense t.amount))
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getExpenseForMonth : Ledger -> Int -> Date.MonthYear -> Date -> Money.Money
getExpenseForMonth ledger account monthYear today =
    getTransactionsForMonth ledger account monthYear today
        |> List.filter (\t -> Money.isExpense t.amount)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getCategoryTotalForMonth : Ledger -> Int -> Date.MonthYear -> Date -> Int -> Money.Money
getCategoryTotalForMonth ledger account monthYear today catID =
    getTransactionsForMonth ledger account monthYear today
        |> List.filter (\t -> Money.isExpense t.amount)
        |> List.filter (\t -> t.category == catID)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getActivatedRecurringTransactions : Ledger -> Date -> List Transaction
getActivatedRecurringTransactions (Ledger transactions) today =
    transactions
        |> List.filter (\t -> Date.compare t.date today /= GT)


newTransactionFromRecurring : Transaction -> NewTransaction
newTransactionFromRecurring transaction =
    { account = transaction.account
    , date = transaction.date
    , amount = transaction.amount
    , description = transaction.description
    , category = transaction.category
    , checked = transaction.checked
    }


getRecurringTransactionsForDate : Ledger -> Int -> Date -> List Transaction
getRecurringTransactionsForDate (Ledger transactions) account date =
    transactions
        |> List.filter (\t -> t.account == account)
        |> List.filter (\t -> Date.getDay t.date == Date.getDay date && Date.compare t.date date /= GT)


getAllTransactions : Ledger -> List Transaction
getAllTransactions (Ledger transactions) =
    transactions


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
   addTransaction : { date : Date, amount : Money.Money, description : String } -> Ledger -> Ledger
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


   updateTransaction : { id : Int, date : Date, amount : Money.Money, description : String } -> Ledger -> Ledger
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


getTransactionDescription : { a | description : String } -> String
getTransactionDescription transaction =
    if transaction.description == "" then
        "..."

    else
        transaction.description



-- JSON ENCODERS AND DECODERS


decode : Decode.Decoder Ledger
decode =
    Decode.map Ledger (Decode.list decodeTransaction)


encode : Ledger -> Encode.Value
encode (Ledger transactions) =
    Encode.list encodeTransaction transactions


encodeTransaction : Transaction -> Encode.Value
encodeTransaction transaction =
    Encode.object
        [ ( "account", Encode.int transaction.account )
        , ( "id", Encode.int transaction.id )
        , ( "date", Date.encode transaction.date )
        , ( "amount", Money.encode transaction.amount )
        , ( "description", Encode.string transaction.description )
        , ( "category", Encode.int transaction.category )
        , ( "checked", Encode.bool transaction.checked )
        ]


decodeTransaction : Decode.Decoder Transaction
decodeTransaction =
    Decode.map7 Transaction
        (Decode.field "id" Decode.int)
        (Decode.field "account" Decode.int)
        (Decode.field "date" Date.decode)
        (Decode.field "amount" Money.decode)
        (Decode.field "description" Decode.string)
        (Decode.field "category" Decode.int)
        (Decode.field "checked" Decode.bool)


encodeNewTransaction : NewTransaction -> Encode.Value
encodeNewTransaction transaction =
    Encode.object
        [ ( "account", Encode.int transaction.account )
        , ( "date", Date.encode transaction.date )
        , ( "amount", Money.encode transaction.amount )
        , ( "description", Encode.string transaction.description )
        , ( "category", Encode.int transaction.category )
        , ( "checked", Encode.bool transaction.checked )
        ]


decodeNewTransaction : Decode.Decoder NewTransaction
decodeNewTransaction =
    Decode.map6 NewTransaction
        (Decode.field "account" Decode.int)
        (Decode.field "date" Date.decode)
        (Decode.field "amount" Money.decode)
        (Decode.field "description" Decode.string)
        (Decode.field "category" Decode.int)
        (Decode.field "checked" Decode.bool)
