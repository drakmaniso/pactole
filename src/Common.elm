module Common exposing
    ( Dialog
    , Mode(..)
    , Model
    , Page(..)
    , init
    )

import Array as Array
import Date
import Json.Decode as Decode
import Ledger
import Time


type alias Model =
    { page : Page
    , mode : Mode
    , dialog : Maybe Dialog
    , today : Date.Date
    , date : Date.Date
    , ledger : Ledger.Ledger
    , accounts : List String
    , account : Maybe String
    , showAdvanced : Bool

    {-
       , dialogAmount : String
       , dialogAmountInfo : String
       , dialogDescription : String
    -}
    }


type Page
    = MainPage
    | Settings


type Mode
    = Calendar
    | Tabular



{-
   type Dialog
       = NewIncome
       | NewExpense
       | EditIncome Int
       | EditExpense Int
-}


type alias Dialog =
    { id : Maybe Int
    , isExpense : Bool
    , date : Date.Date
    , amount : String
    , amountError : String
    , description : String
    }


init : Decode.Value -> Model
init flags =
    let
        ( accounts, account ) =
            case Decode.decodeValue (Decode.field "accounts" (Decode.list Decode.string)) flags of
                Ok a ->
                    ( a, List.head a )

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) ( [], Nothing )

        day =
            case Decode.decodeValue (Decode.at [ "today", "day" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) 0

        month =
            case Decode.decodeValue (Decode.at [ "today", "month" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) 0

        year =
            case Decode.decodeValue (Decode.at [ "today", "year" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) 0

        today =
            case Date.fromParts { day = day, month = month, year = year } of
                Just d ->
                    d

                Nothing ->
                    Debug.log "init flags: invalid date for today" Date.default

        ledger =
            case Decode.decodeValue (Decode.field "ledger" Ledger.decoder) flags of
                Ok l ->
                    l

                Err e ->
                    Debug.log ("init flags ledger: " ++ Decode.errorToString e) Ledger.empty
    in
    { page = MainPage
    , mode = Calendar
    , dialog = Nothing
    , today = today -- Date.fromPosix (Time.millisToPosix 0)
    , date = today --Date.fromPosix (Time.millisToPosix 0)
    , ledger = ledger
    , accounts = accounts
    , account = account
    , showAdvanced = False

    {-
       , dialogAmount = ""
       , dialogAmountInfo = ""
       , dialogDescription = ""
    -}
    }
