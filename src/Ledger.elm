module Ledger exposing
    ( Category
    , Description
    , Ledger
    , Money
    , Reconciliation
    , Transaction
    , decoder
    , formatAmount
    , isExpense
    , myLedger
    , transactions
    )

import Array
import Calendar
import Json.Decode as Decode
import Json.Encode as Encode
import Time


type Ledger
    = Ledger { transactions : List Transaction }


type alias Transaction =
    { date : Calendar.Date
    , amount : Money
    , description : Description
    , category : Category
    , reconciliation : Reconciliation
    }



{-
   decoder =
       let
           toLedger transacs =
               Ledger { transactions = transacs }
       in
       Decode.map toLedger (Decode.list transactionDecoder)
-}


decoder =
    let
        toLedger t =
            Ledger { transactions = t }
    in
    Decode.map toLedger (Decode.field "transactions" (Decode.list transactionDecoder))


transactions : Ledger -> List Transaction
transactions (Ledger ledger) =
    ledger.transactions


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
        (( "date", Encode.int (dateToInt date) )
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


dateDecoder : Decode.Decoder Calendar.Date
dateDecoder =
    let
        toDate a =
            case a of
                Ok aa ->
                    intToDate aa

                Err e ->
                    Debug.log (Decode.errorToString e) (intToDate 0)
    in
    Decode.map intToDate (Decode.field "date" Decode.int)


dateToInt : Calendar.Date -> Int
dateToInt date =
    let
        y =
            Calendar.getYear date

        m =
            (Calendar.getMonth date |> Calendar.monthToInt) + 1

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
            Array.get (m - 1) Calendar.months

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



---------------------------------- DUMMY LEDGER


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
        { transactions =
            [ { date = date2
              , amount = Money -5000
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date2
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money -500
              , description = Description "Foo"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            , { date = date1
              , amount = Money 2500
              , description = Description "Bar"
              , category = NoCategory
              , reconciliation = NotReconciled
              }
            ]
        }
