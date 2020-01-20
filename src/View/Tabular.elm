module View.Tabular exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Model
import Msg


view : Model.Model -> Element Msg.Msg
view model =
    row
        [ width fill
        , height fill
        , Background.color (rgb 0.8 0.9 0.8)
        , inFront (el [ alignTop, alignRight ] (Input.button [] { label = text "[Config]", onPress = Just Msg.ToSettings }))
        ]
        [ column
            [ width (fillPortion 3), height fill ]
            [ el [ centerX, alignTop ] (text "Opérations")
            , row
                [ width fill, height fill ]
                []
            ]
        , column
            [ width (fillPortion 6), height fill ]
            []
        ]
