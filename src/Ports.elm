port module Ports exposing (..)

import Json.Decode as Decode
import Json.Encode as Encode


port updateAccountList : (Decode.Value -> msg) -> Sub msg


port storeAccounts : Encode.Value -> Cmd msg


port requestLedger : String -> Cmd msg


port updateLedger : (Decode.Value -> msg) -> Sub msg


port storeLedger : ( String, Encode.Value ) -> Cmd msg
