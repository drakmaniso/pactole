module Page.Summary exposing (view)

import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Ledger
import Model
import Money
import Msg
import Ui



-- SUMMARY VIEW


view : Model.Model -> E.Element Msg.Msg
view model =
    Keyed.el [ E.width E.fill, E.height E.fill ]
        ( "summary"
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.centerX
            ]
            [ E.row
                [ E.width E.fill
                ]
                [ E.el [ E.paddingXY 6 0, E.width E.fill ]
                    (settingsButton model)
                , case Dict.values model.accounts of
                    [ singleAccount ] ->
                        E.el [ Ui.bigFont, Font.color Ui.gray30, Ui.notSelectable ]
                            (E.text singleAccount)

                    _ ->
                        accountsRow model
                , E.el [ E.width E.fill ]
                    E.none
                ]
            , E.row [ E.height (E.fillPortion 1) ] [ E.none ]
            , E.el
                [ Ui.smallFont
                , E.paddingEach { top = 0, bottom = 6, left = 0, right = 0 }
                , E.width E.fill
                , Font.center
                , Font.color Ui.gray50
                , Ui.notSelectable
                ]
                (E.text "Solde actuel:")
            , balanceRow model
            , E.row [ E.height (E.fillPortion 1) ] [ E.none ]
            , buttonRow model
            , E.row [ E.height (E.fillPortion 2) ] [ E.none ]
            , Ui.ruler
            ]
        )


accountsRow : Model.Model -> E.Element Msg.Msg
accountsRow model =
    Input.radioRow
        [ E.width E.shrink
        , if model.showFocus then
            E.focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , size = 4
                    , blur = 0
                    , color = Ui.focusColor
                    }
                ]

          else
            E.focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , size = 0
                    , blur = 0
                    , color = Ui.transparent
                    }
                ]
        ]
        { onChange = Msg.SelectAccount
        , selected = Just model.account
        , label = Input.labelHidden "Compte"
        , options =
            List.map
                (\account ->
                    Ui.radioRowOption account
                        (E.text (Model.account account model))
                )
                (Dict.keys model.accounts)
        }


balanceRow : Model.Model -> E.Element msg
balanceRow model =
    let
        balance =
            Ledger.getBalance model.ledger model.account model.today

        parts =
            Money.toStrings balance

        sign =
            if parts.sign == "+" then
                ""

            else
                "-"

        color =
            if Money.isGreaterThan balance 0 then
                Ui.gray30

            else
                Ui.warning60
    in
    E.row
        [ E.width E.fill, Font.color color, Ui.notSelectable ]
        [ E.el [ E.width E.fill ] E.none
        , if Money.isGreaterThan balance model.settings.balanceWarning then
            E.none

          else
            Ui.warningIcon
        , E.el
            [ Ui.biggestFont
            , Font.bold
            ]
            (E.text (sign ++ parts.units))
        , E.el
            [ Ui.biggerFont
            , Font.bold
            , E.alignBottom
            , E.paddingEach { top = 0, bottom = 2, left = 0, right = 0 }
            ]
            (E.text ("," ++ parts.cents))
        , E.el
            [ Ui.bigFont
            , E.alignTop
            , E.paddingEach { top = 2, bottom = 0, left = 4, right = 0 }
            ]
            (E.text "€")
        , if Money.isGreaterThan balance model.settings.balanceWarning then
            E.none

          else
            Ui.warningIcon
        , E.el [ E.width E.fill ] E.none
        ]


buttonRow : Model.Model -> E.Element Msg.Msg
buttonRow model =
    Keyed.row
        [ E.width E.fill
        , E.spacing 24
        , E.paddingEach { left = 24, right = 24, top = 0, bottom = 0 }
        ]
        [ ( "blank left", E.el [ E.width E.fill ] E.none )
        , ( "stats button"
          , if model.page == Model.MainPage && model.settings.summaryEnabled then
                Ui.simpleButton
                    { onPress = Just (Msg.ChangePage Model.StatsPage)
                    , label = E.text " Bilan "
                    }

            else
                E.none
          )
        , ( "reconcile button"
          , if model.page == Model.MainPage && model.settings.reconciliationEnabled then
                Ui.simpleButton
                    { onPress = Just (Msg.ChangePage Model.ReconcilePage)
                    , label = E.text "Pointer"
                    }

            else
                E.none
          )
        , ( "back button"
          , if model.page /= Model.MainPage then
                Ui.simpleButton
                    { onPress = Just (Msg.ChangePage Model.MainPage)
                    , label =
                        E.row [ Font.center, E.width E.fill ]
                            [ E.el [ E.width E.fill ] E.none
                            , Ui.backIcon
                            , E.text "  Retour"
                            , E.el [ E.width E.fill ] E.none
                            ]
                    }

            else
                E.none
          )
        , ( "blank right", E.el [ E.width E.fill ] E.none )
        ]


settingsButton : Model.Model -> E.Element Msg.Msg
settingsButton model =
    if not model.settings.settingsLocked || model.showAdvanced then
        Input.button
            [ Background.color Ui.white
            , Ui.normalFont
            , Font.color Ui.primary40
            , Font.center
            , Ui.roundCorners
            , E.padding 2
            , E.width (E.px 36)
            , E.height (E.px 36)
            , E.alignLeft
            ]
            { onPress = Just (Msg.ChangePage Model.SettingsPage)
            , label = E.el [ Ui.iconFont, Ui.normalFont, E.centerX, Font.color Ui.gray70 ] (E.text "\u{F013}")
            }

    else
        Input.button
            [ Background.color Ui.white
            , Ui.normalFont
            , Font.color Ui.primary40
            , Font.center
            , Ui.roundCorners
            , E.padding 2
            , E.width (E.px 36)
            , E.height (E.px 36)
            , E.alignLeft
            ]
            { onPress = Just Msg.AttemptSettings
            , label =
                E.el [ Ui.iconFont, Ui.normalFont, E.centerX, Font.color Ui.gray90 ]
                    (E.text "\u{F013}")
            }
