module View.Settings exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Model
import Msg
import View.Style as Style


view : Model.Model -> Element Msg.Msg
view model =
    row
        [ width fill
        , height fill
        , clipX
        , clipY
        , htmlAttribute <| Html.Attributes.style "z-index" "-1"
        , Background.color Style.bgPage
        , Style.fontFamily
        ]
        [ column
            [ width (fillPortion 25), height fill, padding 16, alignTop ]
            [ Input.button
                (Style.button shrink Style.fgTitle Style.bgWhite True)
                { onPress = Just Msg.ToMainPage
                , label =
                    el
                        []
                        (text "Confirmer")
                }
            , el
                [ width fill, height fill ]
                none
            ]
        , column
            [ width (fillPortion 75)
            , height fill
            , padding 24
            , spacing 24
            , Background.color Style.bgLight
            , Style.normalFont
            ]
            [ el
                [ Style.bigFont
                , paddingEach { top = 0, bottom = 24, left = 0, right = 0 }
                ]
                (text "Configuration")
            , el [] (text "Comptes enregistrés sur cet ordinateur:")
            , table
                []
                { data = model.accounts
                , columns =
                    [ { header = text "Nom du compte"
                      , width = fill
                      , view = \account -> el [] (text account)
                      }
                    ]
                }
            , Input.radio
                [ padding 12, spacing 12 ]
                { onChange =
                    \o ->
                        case o of
                            Model.Calendar ->
                                Msg.ToCalendar

                            Model.Tabular ->
                                Msg.ToTabular
                , label = Input.labelAbove [] (text "Mode d'affichage des opérations:")
                , options =
                    [ Input.option Model.Calendar (text "Calendrier")
                    , Input.option Model.Tabular (text "Liste")
                    ]
                , selected = Just model.mode
                }
            ]
        ]
