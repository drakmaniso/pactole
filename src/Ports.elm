port module Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


port accounts : (Decode.Value -> msg) -> Sub msg


port setAccounts : Encode.Value -> Cmd msg


port selectAccount : String -> Cmd msg


port ledger : (Decode.Value -> msg) -> Sub msg


port setLedger : ( String, Encode.Value ) -> Cmd msg
