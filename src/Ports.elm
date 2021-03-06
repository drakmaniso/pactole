port module Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


port send : ( String, Encode.Value ) -> Cmd msg


port receive : (( String, Decode.Value ) -> msg) -> Sub msg
