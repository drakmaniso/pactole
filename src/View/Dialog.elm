module View.Income exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Model
import Msg
import View.Style as Style


view : Model.Model -> Element Msg.Msg
view model =
    column
        [ centerX
        , centerY
        , width (shrink |> minimum 600)
        , height shrink
        , Border.rounded 7
        , paddingXY 32 16
        , spacing 16
        , clip
        , Background.color (rgb 1 1 1)
        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 16, color = rgba 0 0 0 0.5 }
        , htmlAttribute <| HtmlAttr.style "z-index" "1000"
        ]
        [ row
            [ alignLeft
            , width shrink
            , paddingXY 0 8
            , spacing 12
            ]
            [ Input.text
                [ Style.bigFont
                , paddingXY 8 12

                --, Border.width 1
                , width (shrink |> minimum 300)
                , alignLeft
                , htmlAttribute <| HtmlAttr.id "dialog-amount"
                ]
                { label =
                    Input.labelLeft
                        [ Input.focusedOnLoad
                        , Style.bigFont
                        , width shrink
                        , alignLeft
                        , height fill
                        , Font.color Style.fgIncome
                        , paddingEach { top = 12, bottom = 12, left = 0, right = 24 }
                        , Border.width 1
                        , Border.color (rgba 0 0 0 0)
                        ]
                        (text "Entrée d'argent:")
                , text = model.dialogAmount
                , placeholder = Nothing
                , onChange = Msg.DialogAmount
                }
            , el
                [ Style.bigFont
                , paddingXY 0 12
                , width shrink
                , alignLeft
                , Border.width 1
                , Border.color (rgba 0 0 0 0)
                ]
                (text "€")
            , el
                [ width fill ]
                none
            ]
        , Input.multiline
            [ Style.bigFont
            , paddingXY 8 12
            , Border.width 1
            , width (fillPortion 2)
            ]
            { label =
                Input.labelLeft
                    [ width (fillPortion 1)
                    , height fill
                    , Font.color Style.fgIncome
                    , paddingEach { top = 12, bottom = 12, left = 0, right = 24 }
                    , Border.width 1
                    , Border.color (rgba 0 0 0 0)
                    ]
                    (text "Description:")
            , text = model.dialogDescription
            , placeholder = Just (Input.placeholder [] (text "Description"))
            , onChange = Msg.DialogDescription
            , spellcheck = True
            }
        , el [ height fill ] none
        , row
            [ alignRight
            , spacing 24
            , paddingEach { top = 24, bottom = 0, left = 0, right = 0 }
            ]
            [ Input.button
                (Style.button shrink Style.fgIncome Style.bgWhite False)
                { label = text "Annuler", onPress = Nothing }
            , Input.button
                (Style.button shrink Style.fgIncome Style.bgWhite True)
                { label = text "Confirmer", onPress = Nothing }
            ]
        ]
