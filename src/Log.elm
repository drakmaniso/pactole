module Log exposing (error)

import Json.Encode as Encode
import Model
import Platform.Cmd
import Ports


error : String -> ( Model.Model, Cmd msg ) -> ( Model.Model, Cmd msg )
error msg ( model, cmd ) =
    ( { model | error = Just msg }
    , Platform.Cmd.batch
        [ Ports.send ( "error", Encode.string msg )
        , cmd
        ]
    )
