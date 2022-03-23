module Page.Summary exposing (view)

import Dict
import Element as E
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Ledger
import Model
import Money
import Msg
import Ui
import Ui.Color as Color



-- SUMMARY VIEW


view : Model.Model -> E.Element Msg.Msg
view model =
    Keyed.el [ E.width E.fill, E.height E.fill ]
        ( "summary"
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.centerX
            , E.paddingXY 0 24
            ]
            [ E.el [ E.height E.fill ] E.none
            , E.row
                [ E.width E.fill
                , E.paddingEach { left = 0, top = 0, bottom = 12, right = 0 }
                ]
                [ E.el [ E.width E.fill ]
                    E.none
                , case Dict.values model.accounts of
                    [ singleAccount ] ->
                        E.el [ Ui.bigFont, Font.color Color.neutral30, Ui.notSelectable, Font.center ]
                            (E.text singleAccount)

                    _ ->
                        accountsRow model
                , E.el [ E.width E.fill ] E.none
                ]
            , E.el
                [ Ui.smallFont
                , E.width E.fill
                , Font.center
                , Font.color Color.neutral50
                , Ui.notSelectable
                ]
                (E.text "Solde actuel:")
            , balanceRow model
            , E.row [ E.height E.fill ] [ E.none ]
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
                    , color = Color.focusColor
                    }
                ]

          else
            E.focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , size = 0
                    , blur = 0
                    , color = Color.transparent
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
                Color.neutral30

            else
                Color.warning60
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
