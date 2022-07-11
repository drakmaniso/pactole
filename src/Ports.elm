port module Ports exposing
    ( error
    , fromServiceWorker
    , historyGo
    , historyPushState
    , onApplicationStart
    , onLeftSwipe
    , onPopState
    , onRightSwipe
    , onUserError
    , requestStoragePersistence
    , toServiceWorker
    )

import Json.Decode as Decode
import Json.Encode as Encode



-- From Window Javascript


port onApplicationStart : (() -> msg) -> Sub msg


port onPopState : (() -> msg) -> Sub msg


port onLeftSwipe : (() -> msg) -> Sub msg


port onRightSwipe : (() -> msg) -> Sub msg


port onUserError : (String -> msg) -> Sub msg



-- To Window Javascript


port historyPushState : () -> Cmd msg


port historyGo : Int -> Cmd msg


port error : String -> Cmd msg


port requestStoragePersistence : () -> Cmd msg



-- To Service Worker


port toServiceWorker : ( String, Encode.Value ) -> Cmd msg



-- From Service Worker


port fromServiceWorker : (( String, Decode.Value ) -> msg) -> Sub msg
