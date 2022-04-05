module Log exposing (error)

import Model exposing (Model)
import Platform.Cmd exposing (Cmd)
import Ports


error : String -> ( Model, Cmd msg ) -> ( Model, Cmd msg )
error msg ( model, cmd ) =
    ( { model | errors = model.errors ++ [ msg ] }
    , Platform.Cmd.batch
        [ Ports.error msg
        , cmd
        ]
    )
