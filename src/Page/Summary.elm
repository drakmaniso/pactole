module Page.Summary exposing (view)

import Dict
import Element as E
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ui
import Ui.Color as Color



-- SUMMARY VIEW


view : Model -> E.Element Msg
view model =
    Keyed.el
        [ E.width E.fill
        , E.height E.fill
        ]
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
                        E.el [ Ui.notSelectable, Font.center ]
                            (E.text singleAccount)

                    _ ->
                        viewAccounts model
                , E.el [ E.width E.fill ] E.none
                ]
            , viewBalance model
            , E.row [ E.height E.fill ] [ E.none ]
            ]
        )


viewAccounts : Model -> E.Element Msg
viewAccounts model =
    Input.radioRow
        [ E.width E.shrink
        , Border.width 4
        , Border.color Color.transparent
        , Ui.focusVisibleOnly
        ]
        { onChange = Msg.SelectAccount
        , selected = Just model.account
        , label = Input.labelHidden "Compte"
        , options =
            List.map
                (\account ->
                    Ui.radioRowOption account
                        (E.text (Model.accountName account model))
                )
                (Dict.keys model.accounts)
        }


viewBalance : Model -> E.Element msg
viewBalance model =
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
            if Money.isGreaterOrEqualThan balance 0 then
                Color.neutral30

            else
                Color.warning60
    in
    E.column
        [ E.centerX
        , E.paddingXY 24 6
        , Border.rounded 6
        , if Money.isGreaterOrEqualThan balance model.settings.balanceWarning then
            Border.color Color.transparent

          else
            Border.color Color.warning60
        , Border.width 2
        ]
        [ E.el
            [ Ui.smallFont model.device
            , E.centerX
            , Font.color Color.neutral40
            , Ui.notSelectable
            ]
            (E.text "Solde actuel:")
        , E.row
            [ E.centerX, Font.color color, Ui.notSelectable ]
            [ E.el
                [ Ui.biggestFont model.device
                , Font.bold
                ]
                (E.text (sign ++ parts.units))
            , E.el
                [ Ui.bigFont model.device
                , Font.bold
                , E.alignBottom
                , E.paddingEach { top = 0, bottom = 2, left = 0, right = 0 }
                ]
                (E.text ("," ++ parts.cents))
            , E.el
                [ Ui.bigFont model.device
                , E.alignTop
                , E.paddingEach { top = 2, bottom = 0, left = 4, right = 0 }
                ]
                (E.text "€")
            ]
        ]
