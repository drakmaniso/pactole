module Ledger exposing
    ( Category(..)
    , Description(..)
    , Ledger(..)
    , Money(..)
    , Reconciliation(..)
    , Transaction(..)
    , myLedger
    )

import Array
import Calendar
import Json.Decode as D
import Json.Encode as E
import Time


type Ledger
    = Ledger (List Transaction)


type Transaction
    = Transaction Calendar.Date Money Description Category Reconciliation


myLedger =
    let
        defaultDate =
            Calendar.fromPosix (Time.millisToPosix 0)

        date1 =
            case Calendar.fromRawParts { year = 2019, month = Time.Nov, day = 26 } of
                Nothing ->
                    Debug.log "what?" defaultDate

                Just date ->
                    date

        date2 =
            case Calendar.fromRawParts { year = 2019, month = Time.Nov, day = 10 } of
                Nothing ->
                    Debug.log "what?" defaultDate

                Just date ->
                    date
    in
    Ledger
        [ Transaction date1 (Money -5000) (Description "Foo") NoCategory NotReconciled
        , Transaction date1 (Money 20000) (Description "Bar") NoCategory NotReconciled
        , Transaction date2 (Money -2350) (Description "Baz") NoCategory NotReconciled
        ]


encodeTransaction : Transaction -> E.Value
encodeTransaction (Transaction dat (Money amo) des cat rec) =
    E.object
        ([ ( "date", E.int (dateToInt dat) )
         , ( "amount", E.int amo )
         ]
            ++ (case des of
                    NoDescription ->
                        []

                    Description d ->
                        [ ( "description", E.string d ) ]
               )
            ++ (case cat of
                    NoCategory ->
                        []

                    Category c ->
                        [ ( "category", E.string c ) ]
               )
            ++ (case rec of
                    NotReconciled ->
                        []

                    Reconciled ->
                        [ ( "reconciled", E.bool True ) ]
               )
        )


transactionDecoder =
    D.map5 JsonTransaction
        (D.field "date" D.int)
        (D.field "amount" D.int)
        (D.maybe (D.field "description" D.string))
        (D.maybe (D.field "category" D.string))
        (D.maybe (D.field "reconciled" D.bool))


decodeTransaction js =
    case D.decodeValue transactionDecoder js of
        Err e ->
            Err e

        Ok v ->
            Ok
                (Transaction
                    (intToDate v.date)
                    (Money v.amount)
                    (case v.description of
                        Nothing ->
                            NoDescription

                        Just d ->
                            Description d
                    )
                    (case v.category of
                        Nothing ->
                            NoCategory

                        Just c ->
                            Category c
                    )
                    (case v.reconciled of
                        Nothing ->
                            NotReconciled

                        Just False ->
                            NotReconciled

                        Just True ->
                            Reconciled
                    )
                )


type alias JsonTransaction =
    { date : Int
    , amount : Int
    , description : Maybe String
    , category : Maybe String
    , reconciled : Maybe Bool
    }



-- DATE


dateToInt : Calendar.Date -> Int
dateToInt date =
    let
        y =
            Calendar.getYear date

        m =
            Calendar.getMonth date |> Calendar.monthToInt

        d =
            Calendar.getDay date
    in
    d + 100 * m + 10000 + y


intToDate n =
    let
        y =
            n // 10000

        m =
            (n - y * 10000) // 100

        d =
            n - y * 10000 - m * 100

        mm =
            Array.get m Calendar.months

        raw =
            Calendar.fromRawParts
                { year = y
                , month =
                    case mm of
                        Nothing ->
                            Debug.log "Ledger.intToDate failed" Time.Jan

                        Just mmm ->
                            mmm
                , day = d
                }
    in
    case raw of
        Nothing ->
            Debug.log "Ledger.intToDate failed" (Calendar.fromPosix (Time.millisToPosix 0))

        Just date ->
            date



-- MONEY


type Money
    = Money Int



-- DESCRIPTION


type Description
    = Description String
    | NoDescription



-- CATEGORY


type Category
    = Category String
    | NoCategory



-- RECONCILIATION


type Reconciliation
    = Reconciled
    | NotReconciled
