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
    = Transaction
        { date : Calendar.Date
        , amount : Money
        , description : Description
        , category : Category
        , reconciliation : Reconciliation
        }


myLedger =
    let
        defaultDate =
            Calendar.fromPosix (Time.millisToPosix 0)

        date1 =
            case Calendar.fromRawParts { year = 2020, month = Time.Feb, day = 26 } of
                Nothing ->
                    Debug.log "what?" defaultDate

                Just date ->
                    date

        date2 =
            case Calendar.fromRawParts { year = 2020, month = Time.Feb, day = 10 } of
                Nothing ->
                    Debug.log "what?" defaultDate

                Just date ->
                    date
    in
    Ledger
        [ Transaction
            { date = date2
            , amount = Money -5000
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date2
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money -500
            , description = Description "Foo"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        , Transaction
            { date = date1
            , amount = Money 2500
            , description = Description "Bar"
            , category = NoCategory
            , reconciliation = NotReconciled
            }
        ]


encodeTransaction : Transaction -> E.Value
encodeTransaction (Transaction { date, amount, description, category, reconciliation }) =
    let
        (Money money) =
            amount

        withRec =
            case reconciliation of
                NotReconciled ->
                    []

                Reconciled ->
                    [ ( "reconciled", E.bool True ) ]

        withCatRec =
            case category of
                NoCategory ->
                    withRec

                Category c ->
                    ( "category", E.string c ) :: withRec

        withDescCatRec =
            case description of
                NoDescription ->
                    withCatRec

                Description d ->
                    ( "description", E.string d ) :: withCatRec
    in
    E.object
        (( "date", E.int (dateToInt date) )
            :: ( "amount", E.int money )
            :: withDescCatRec
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
            let
                date =
                    intToDate v.date

                money =
                    Money v.amount

                description =
                    case v.description of
                        Nothing ->
                            NoDescription

                        Just d ->
                            Description d

                category =
                    case v.category of
                        Nothing ->
                            NoCategory

                        Just c ->
                            Category c

                reconciled =
                    case v.reconciled of
                        Nothing ->
                            NotReconciled

                        Just False ->
                            NotReconciled

                        Just True ->
                            Reconciled
            in
            Ok
                (Transaction
                    { date = date
                    , amount = money
                    , description = description
                    , category = category
                    , reconciliation = reconciled
                    }
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
