module Page.Help exposing (..)

import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Model
import Msg
import Ui
import Ui.Color as Color


view : Model.Model -> E.Element Msg.Msg
view model =
    Ui.pageWithSidePanel (Msg.navigationBarConfig model)
        { panel =
            E.column
                [ E.width E.fill
                , E.height E.fill
                , E.clipX
                , E.clipY
                ]
                []
        , page =
            E.column
                [ E.width E.fill
                , E.height E.fill

                -- , Border.widthEach { right = 0, top = 0, bottom = 0, left = 2 }
                -- , Border.color Color.neutral80
                ]
                [ Ui.pageTitle (E.text "Guide d'utilisation")
                , configLocked model
                ]
        }


configLocked : Model.Model -> E.Element Msg.Msg
configLocked model =
    E.column [ E.width E.fill ]
        [ Ui.configRadio
            { onChange =
                \o ->
                    let
                        settings =
                            model.settings
                    in
                    if o then
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | settingsLocked = True }

                    else
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | settingsLocked = False }
            , label = "Verrouiller les réglages:"
            , options =
                [ Ui.radioRowOption False (E.text "Non")
                , Ui.radioRowOption True (E.text "Oui")
                ]
            , selected = Just model.settings.settingsLocked
            }
        , E.paragraph
            [ E.width E.fill
            , E.paddingEach { top = 0, bottom = 24, left = 64 + 12, right = 0 }
            ]
            [ E.text "Lorsque les réglages sont verrouillés, il faut cliquer 5 fois de suite sur l'icône \""
            , E.el [ Ui.iconFont, Ui.normalFont, Font.color Color.neutral70 ] (E.text "\u{F013}")
            , E.text "\" pour accéder aux réglages."
            ]
        ]
