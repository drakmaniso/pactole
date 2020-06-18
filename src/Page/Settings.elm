module Page.Settings exposing (view)

import Common
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Msg
import Style


view : Common.Model -> Element Msg.Msg
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
                (Style.button shrink Style.fgTitle Style.bgLight Style.bgLight)
                { onPress = Just Msg.ToMainPage
                , label =
                    row
                        []
                        [ el
                            [ Style.fontIcons
                            , Style.normalFont
                            ]
                            (text "\u{F060}")
                        , el
                            []
                            (text "  Retour")
                        ]
                }
            , el
                [ width fill, height fill ]
                none
            ]
        , column
            [ width (fillPortion 75)
            , height fill
            , Border.widthEach { top = 0, bottom = 0, left = 3, right = 0 }
            , Border.color Style.bgDark
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
                            Common.Calendar ->
                                Msg.ToCalendar

                            Common.Tabular ->
                                Msg.ToTabular
                , label = Input.labelAbove [] (text "Mode d'affichage des opérations:")
                , options =
                    [ Input.option Common.Calendar (text "Calendrier")
                    , Input.option Common.Tabular (text "Liste")
                    ]
                , selected = Just model.mode
                }
            ]
        ]
