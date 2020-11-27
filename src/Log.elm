module Log exposing (..)

import Json.Encode as Encode
import Ports


error : String -> Cmd msg
error msg =
    Ports.send ( "error", Encode.string msg )
