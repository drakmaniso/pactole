port module Ports exposing (..)

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Model
import Money


port send : ( String, Encode.Value ) -> Cmd msg


port receive : (( String, Decode.Value ) -> msg) -> Sub msg
