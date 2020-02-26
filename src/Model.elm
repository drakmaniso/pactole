module Model exposing
    ( Dialog(..)
    , Mode(..)
    , Model
    , init
    )

import Array as Array
import Calendar
import Json.Decode as Decode
import Ledger
import Time


defaultDate =
    Calendar.fromPosix (Time.millisToPosix 0)


init : String -> Model
init flags =
    let
        accountList =
            case
                Decode.decodeString
                    (Decode.field "accounts" (Decode.array Decode.string))
                    flags
            of
                Ok a ->
                    Array.toList a

                Err e ->
                    Debug.log (Decode.errorToString e) []

        ( accounts, account ) =
            case accountList of
                first :: _ ->
                    ( accountList, first )

                _ ->
                    ( [ "Mon Compte" ], "Mon Compte" )
    in
    { mode = Calendar
    , dialog = None
    , today = Calendar.fromPosix (Time.millisToPosix 0)
    , date = Calendar.fromPosix (Time.millisToPosix 0)
    , selected = False
    , ledger = Ledger.myLedger
    , accounts = accounts
    , account = account
    }


type alias Model =
    { mode : Mode
    , dialog : Dialog
    , today : Calendar.Date
    , date : Calendar.Date
    , selected : Bool
    , ledger : Ledger.Ledger
    , accounts : List String
    , account : String
    }


type Mode
    = Calendar
    | Tabular


type Dialog
    = None
    | Settings
