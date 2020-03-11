module Model exposing
    ( Dialog(..)
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
    , dialog : Dialog
    , today : Date.Date
    , date : Date.Date
    , selected : Bool
    , ledger : Ledger.Ledger
    , accounts : List String
    , account : Maybe String
    , showAdvanced : Bool
    , dialogAmount : String
    , dialogDescription : String
    }


type Page
    = MainPage
    | Settings


type Mode
    = Calendar
    | Tabular


type Dialog
    = None
    | Dialog


defaultDate =
    Date.fromPosix (Time.millisToPosix 0)


init : Decode.Value -> Model
init flags =
    let
        ( accounts, account ) =
            case Decode.decodeValue (Decode.field "accounts" (Decode.list Decode.string)) flags of
                Ok a ->
                    ( a, List.head a )

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) ( [], Nothing )

        ledger =
            case Decode.decodeValue (Decode.field "ledger" Ledger.decoder) flags of
                Ok l ->
                    l

                Err e ->
                    Debug.log ("init flags ledger: " ++ Decode.errorToString e) Ledger.empty
    in
    { page = MainPage
    , mode = Calendar
    , dialog = None
    , today = Date.fromPosix (Time.millisToPosix 0)
    , date = Date.fromPosix (Time.millisToPosix 0)
    , selected = False
    , ledger = ledger
    , accounts = accounts
    , account = account
    , showAdvanced = False
    , dialogAmount = ""
    , dialogDescription = ""
    }
