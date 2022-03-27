module Page.Installation exposing (..)

import Element as E
import Model exposing (Model)
import Msg exposing (Msg)
import Ui


view : Model -> E.Element Msg
view _ =
    E.column []
        [ E.text "Installation"
        , Ui.simpleButton
            { label = E.text "create account"
            , onPress = Just Msg.Close
            }
        ]
