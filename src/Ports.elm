port module Ports exposing
    ( closeDialog
    , error
    , exportDatabase
    , historyBack
    , onPopState
    , openDialog
    , receive
    , requestStoragePersistence
    , selectImport
    , sendToSW
    )

import Json.Decode as Decode
import Json.Encode as Encode



-- From Window Javascript


port onPopState : (() -> msg) -> Sub msg



-- To Window Javascript


port historyBack : () -> Cmd msg


port error : String -> Cmd msg


port exportDatabase : Encode.Value -> Cmd msg


port selectImport : () -> Cmd msg


port requestStoragePersistence : () -> Cmd msg


port openDialog : () -> Cmd msg


port closeDialog : () -> Cmd msg



-- To Service Worker


port sendToSW : ( String, Encode.Value ) -> Cmd msg



-- From Service Worker


port receive : (( String, Decode.Value ) -> msg) -> Sub msg
