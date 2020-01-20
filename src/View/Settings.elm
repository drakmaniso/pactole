module View.Settings exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Model
import Msg


view : Model.Model -> Element Msg.Msg
view model =
    column
        [ centerX
        , centerY
        , width (shrink |> minimum 400)
        , height (shrink |> minimum 200)
        , Border.rounded 16
        , clip
        , Background.color (rgb 1 1 1)
        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 16, color = rgba 0 0 0 0.5 }
        , htmlAttribute <| HtmlAttr.style "z-index" "1000"
        ]
        [ row
            [ width fill, paddingXY 16 8, alignTop, Background.color (rgb 0.9 0.8 0.8) ]
            [ el [ width fill, height fill ] (text "Configuration")
            , Input.button [] { label = el [ centerX ] (text " X "), onPress = Just Msg.Close }
            ]
        , row
            [ alignTop ]
            [ column
                []
                [ Input.button [] { label = text "Calendrier", onPress = Just Msg.ToCalendar }
                , Input.button [] { label = text "Opérations", onPress = Just Msg.ToTabular }
                ]
            ]
        ]
