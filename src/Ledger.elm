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


getMonthTransactions : Ledger -> Date.Date -> List Transaction
getMonthTransactions (Ledger ledger) date =
    let
        year =
            Date.getYear date

        month =
            Date.getMonth date
    in
    ledger.transactions
        --TODO
        |> List.filter
            (\t ->
                (Date.getYear t.date == year)
                    && (Date.getMonth t.date == month)
            )


getMonthlyTotal : Ledger -> Date.Date -> Money.Money
getMonthlyTotal ledger date =
    getMonthTransactions ledger date
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getMonthlyIncome : Ledger -> Date.Date -> Money.Money
getMonthlyIncome ledger date =
    getMonthTransactions ledger date
        |> List.filter
            (\t -> not (Money.isExpense t.amount))
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getMonthlyExpense : Ledger -> Date.Date -> Money.Money
getMonthlyExpense ledger date =
    getMonthTransactions ledger date
        |> List.filter
            (\t -> Money.isExpense t.amount)
        |> List.foldl
            (\t accum -> Money.add accum t.amount)
            Money.zero


getMonthlyCategory : Ledger -> Date.Date -> Int -> Money.Money
getMonthlyCategory ledger date catID =
    getMonthTransactions ledger date
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


decode =
    let
        toLedger t =
            Ledger
                { transactions =
                    List.sortWith (\a b -> Date.compare a.date b.date) t
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


getDescriptionDisplay transaction =
    if transaction.description == "" then
        if Money.isExpense transaction.amount then
            "Dépense"

        else
            "Entrée d'argent"

    else
        transaction.description
