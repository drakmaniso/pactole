module Model exposing
    ( Dialog(..)
    , Mode(..)
    , Model
    , init
    )

import Array as Array
import Date
import Json.Decode as Decode
import Ledger
import Time


defaultDate =
    Date.fromPosix (Time.millisToPosix 0)


init : () -> Model
init flags =
    { mode = Tabular
    , dialog = None
    , today = Date.fromPosix (Time.millisToPosix 0)
    , date = Date.fromPosix (Time.millisToPosix 0)
    , selected = False
    , ledger = Ledger.myLedger
    , accounts = []
    , account = Nothing
    }


type alias Model =
    { mode : Mode
    , dialog : Dialog
    , today : Date.Date
    , date : Date.Date
    , selected : Bool
    , ledger : Ledger.Ledger
    , accounts : List String
    , account : Maybe String
    }


type Mode
    = Calendar
    | Tabular


type Dialog
    = None
    | Settings
