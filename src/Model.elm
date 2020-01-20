module Model exposing (Dialog(..), Mode(..), Model, init)

import Calendar
import Ledger
import Time


defaultDate =
    Calendar.fromPosix (Time.millisToPosix 0)


init : Model
init =
    { mode = Calendar
    , dialog = None
    , today = Calendar.fromPosix (Time.millisToPosix 0)
    , date = Calendar.fromPosix (Time.millisToPosix 0)
    , selected = False
    , ledger = Ledger.myLedger
    , accounts = []
    , account = ""
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
