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
    , getAllTransactions
    , getBalance
    , getDateTransactions
    , getDescriptionDisplay
    , getMonthTransactions
    , getMonthlyCategory
    , getMonthlyExpense
    , getMonthlyIncome
    , getMonthlyTotal
    , getReconciled
    , getTransaction
    , hasFutureTransactionsForMonth
    , uncheckedBeforeMonth
    )

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Money



-- LEDGER


type Ledger
    = Ledger
        { transactions : List Transaction
        , valid : Bool --TODO
        }


empty : Ledger
empty =
    Ledger { transactions = [], valid = False }


getAllTransactions : Ledger -> List Transaction
getAllTransactions (Ledger ledger) =
    ledger.transactions


getBalance : Ledger -> Date.Date -> Money.Money
getBalance (Ledger ledger) today =
    ledger.transactions
        |> List.filter (\t -> Date.compare t.date today /= GT)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getReconciled : Ledger -> Money.Money
getReconciled (Ledger ledger) =
    ledger.transactions
        |> List.filter (\t -> t.checked == True)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


uncheckedBeforeMonth : Ledger -> Date.Date -> Bool
uncheckedBeforeMonth (Ledger ledger) date =
    let
        d =
            Date.firstDayOf date
    in
    ledger.transactions
        |> List.filter
            (\t -> Date.compare t.date d == LT)
        |> List.any
            (\t -> not t.checked)


getDateTransactions : Date.Date -> Ledger -> List Transaction
getDateTransactions date (Ledger ledger) =
    List.filter
        (\t -> t.date == date)
        ledger.transactions


getMonthTransactions : Ledger -> Date.Date -> Date.Date -> List Transaction
getMonthTransactions (Ledger ledger) date today =
    ledger.transactions
        --TODO
        |> List.filter
            (\t ->
                (Date.compare t.date today /= GT)
                    && (Date.getYear t.date == Date.getYear date)
                    && (Date.getMonth t.date == Date.getMonth date)
            )


getMonthlyTotal : Ledger -> Date.Date -> Date.Date -> Money.Money
getMonthlyTotal ledger date today =
    getMonthTransactions ledger date today
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


hasFutureTransactionsForMonth : Ledger -> Date.Date -> Date.Date -> Bool
hasFutureTransactionsForMonth (Ledger ledger) date today =
    ledger.transactions
        |> List.any
            (\t ->
                (Date.compare t.date today == GT)
                    && (Date.getYear t.date == Date.getYear date)
                    && (Date.getMonth t.date == Date.getMonth date)
            )


getMonthlyIncome : Ledger -> Date.Date -> Date.Date -> Money.Money
getMonthlyIncome ledger date today =
    getMonthTransactions ledger date today
        |> List.filter
            (\t -> not (Money.isExpense t.amount))
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getMonthlyExpense : Ledger -> Date.Date -> Date.Date -> Money.Money
getMonthlyExpense ledger date today =
    getMonthTransactions ledger date today
        |> List.filter
            (\t -> Money.isExpense t.amount)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getMonthlyCategory : Ledger -> Date.Date -> Date.Date -> Int -> Money.Money
getMonthlyCategory ledger date today catID =
    getMonthTransactions ledger date today
        |> List.filter
            (\t -> Money.isExpense t.amount)
        |> List.filter
            (\t -> t.category == catID)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


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


decode : Decode.Decoder Ledger
decode =
    let
        toLedger t =
            Ledger
                { transactions =
                    List.sortWith (\a b -> Date.compare a.date b.date) t
                , valid = True
                }
    in
    Decode.map toLedger (Decode.field "transactions" (Decode.list decodeTransaction))



-- TRANSACTION


type alias Transaction =
    { id : Int
    , date : Date.Date
    , amount : Money.Money
    , description : String
    , category : Int
    , checked : Bool
    }


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



-- DESCRIPTION


getDescriptionDisplay : { a | description : String, amount : Money.Money } -> String
getDescriptionDisplay transaction =
    if transaction.description == "" then
        if Money.isExpense transaction.amount then
            "Dépense"

        else
            "Entrée d'argent"

    else
        transaction.description
