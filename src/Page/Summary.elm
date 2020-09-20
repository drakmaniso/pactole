module Page.Summary exposing (view)

import Dict
import Element as Elem
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Ledger
import Money
import Shared
import Style
import Ui



-- SUMMARY VIEW


view model =
    Elem.column
        [ Elem.width Elem.fill
        , Elem.height Elem.fill
        , Elem.centerX
        ]
        [ Elem.row
            [ Elem.width Elem.fill
            ]
            [ Elem.el [ Elem.width Elem.fill ]
                Elem.none
            , Input.radioRow
                [ Elem.width Elem.shrink
                , Elem.focused
                    [ Border.shadow
                        { offset = ( 0, 0 )
                        , size = 4
                        , blur = 0
                        , color = Style.fgFocus
                        }
                    ]
                ]
                { onChange = Shared.SelectAccount
                , selected = model.account
                , label = Input.labelHidden "Compte"
                , options =
                    List.map
                        (\account -> Input.optionWith account (accountOption account model))
                        (Dict.keys model.accounts)
                }
            , Elem.el [ Elem.width Elem.fill ]
                (Ui.settingsButton
                    [ Elem.alignRight ]
                    { onPress = Just (Shared.ChangePage Shared.SettingsPage)
                    , enabled = model.showAdvanced
                    }
                )
            ]
        , Elem.row [ Elem.height (Elem.fillPortion 1) ] [ Elem.none ]
        , Elem.el
            [ Style.smallFont
            , Elem.paddingEach { top = 0, bottom = 6, left = 0, right = 0 }
            , Elem.width Elem.fill
            , Font.center
            , Font.color Style.fgDark
            ]
            (Elem.text "Solde actuel:")
        , if model.account /= Nothing then
            balanceRow model

          else
            Elem.none
        , Elem.row [ Elem.height (Elem.fillPortion 1) ] [ Elem.none ]
        , buttonRow model
        , Elem.row [ Elem.height (Elem.fillPortion 2) ] [ Elem.none ]
        ]


accountOption : Int -> Shared.Model -> Input.OptionState -> Elem.Element msg
accountOption accountID shared state =
    Elem.el
        ([ Elem.centerX
         , Elem.paddingXY 16 7
         , Border.rounded 3
         , Style.bigFont
         ]
            ++ (case state of
                    Input.Idle ->
                        [ Font.color Style.fgTitle ]

                    Input.Focused ->
                        []

                    Input.Selected ->
                        [ Font.color (Elem.rgb 1 1 1), Background.color Style.bgTitle ]
               )
        )
        (Elem.text (Shared.accountName accountID shared))


balanceRow model =
    let
        balance =
            Ledger.getBalance model.ledger

        parts =
            Money.toStrings balance

        sign =
            if parts.sign == "+" then
                ""

            else
                "-"

        color =
            if Money.isGreaterThan balance 100 then
                Style.fgBlack

            else if Money.isGreaterThan balance 0 then
                Style.fgWarning

            else
                Style.fgRed
    in
    Elem.row
        [ Elem.width Elem.fill, Font.color color ]
        [ Elem.el [ Elem.width Elem.fill ] Elem.none
        , Elem.el
            [ Style.biggestFont
            , Font.bold
            ]
            (Elem.text (sign ++ parts.units))
        , Elem.el
            [ Style.biggerFont
            , Font.bold
            , Elem.alignBottom
            , Elem.paddingEach { top = 0, bottom = 2, left = 0, right = 0 }
            ]
            (Elem.text ("," ++ parts.cents))
        , Elem.el
            [ Style.bigFont
            , Elem.alignTop
            , Elem.paddingEach { top = 2, bottom = 0, left = 4, right = 0 }
            ]
            (Elem.text "€")
        , Elem.el [ Elem.width Elem.fill ] Elem.none
        ]


buttonRow model =
    Elem.row
        [ Elem.width Elem.fill, Elem.spacing 12 ]
        [ Elem.el [ Elem.width Elem.fill ] Elem.none
        , if model.page == Shared.MainPage && model.settings.summaryEnabled then
            Ui.simpleButton
                [ Elem.width (Elem.fillPortion 3)
                , Elem.htmlAttribute <| HtmlAttr.id "unfocus-on-page-change"
                ]
                { onPress = Just (Shared.ChangePage Shared.StatsPage)
                , label = Elem.text "Bilan"
                }

          else
            Elem.none
        , if model.page == Shared.MainPage && model.settings.reconciliationEnabled then
            Ui.simpleButton
                [ Elem.width (Elem.fillPortion 3)
                , Elem.htmlAttribute <| HtmlAttr.id "unfocus-on-page-change"
                ]
                { onPress = Nothing
                , label = Elem.text "Pointer"
                }

          else
            Elem.none
        , if model.page /= Shared.MainPage then
            Ui.simpleButton
                [ Elem.width (Elem.fillPortion 3)
                , Elem.htmlAttribute <| HtmlAttr.id "unfocus-on-page-change"
                ]
                { onPress = Just (Shared.ChangePage Shared.MainPage)
                , label =
                    Ui.row [ Font.center, Elem.width Elem.fill ]
                        [ Elem.el [ Elem.width Elem.fill ] Elem.none
                        , Ui.backIcon []
                        , Elem.text "  Retour"
                        , Elem.el [ Elem.width Elem.fill ] Elem.none
                        ]
                }

          else
            Elem.none
        , Elem.el [ Elem.width Elem.fill ] Elem.none
        ]
