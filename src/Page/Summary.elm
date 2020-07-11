module Page.Summary exposing (view)

import Common
import Dict
import Element as Elem
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Ledger
import Money
import Msg
import Style
import Ui



-- SUMMARY VIEW


view model =
    case model.account of
        Nothing ->
            Elem.column
                [ Elem.width Elem.fill
                , Elem.height Elem.fill
                , Elem.centerX
                , Elem.centerY
                ]
                [ Elem.el [] (Elem.text "Pactole") ]

        _ ->
            Elem.column
                [ Elem.width Elem.fill
                , Elem.height Elem.fill
                , Elem.centerX
                ]
                [ Elem.el
                    [ Style.smallFont
                    , Elem.paddingEach { top = 0, bottom = 12, left = 0, right = 0 }
                    , Elem.width Elem.fill
                    , Font.center
                    , Font.color Style.fgDark
                    ]
                    (Elem.text "Gestion des Comptes")
                , if model.showAdvanced then
                    Elem.row
                        [ Elem.width Elem.fill
                        ]
                        [ Elem.el [ Elem.width Elem.fill ] Elem.none
                        , Ui.simpleButton
                            []
                            { label =
                                Elem.text "Configurer"
                            , onPress = Just Msg.ToSettings
                            }
                        , Elem.el [ Elem.width Elem.fill ] Elem.none
                        ]

                  else
                    Elem.row
                        [ Elem.width Elem.fill
                        ]
                        [ Elem.el [ Elem.width Elem.fill ] Elem.none
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
                            { onChange = Msg.SelectAccount
                            , selected = model.account
                            , label = Input.labelHidden "Compte"
                            , options =
                                List.map
                                    (\account -> Input.optionWith account (accountOption account model))
                                    (Dict.keys model.accounts)
                            }
                        , Elem.el [ Elem.width Elem.fill ] Elem.none
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
                , balanceRow model
                , Elem.row [ Elem.height (Elem.fillPortion 1) ] [ Elem.none ]
                , buttonRow model
                , Elem.row [ Elem.height (Elem.fillPortion 2) ] [ Elem.none ]
                ]


accountOption : Int -> Common.Model -> Input.OptionState -> Elem.Element msg
accountOption accountID common state =
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
        (Elem.text (Common.accountName accountID common))


balanceRow model =
    let
        parts =
            Ledger.getBalance model.ledger
                |> Money.toStrings

        sign =
            if parts.sign == "+" then
                ""

            else
                "-"
    in
    Elem.row
        [ Elem.width Elem.fill ]
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
        [ Elem.width Elem.fill ]
        [ Elem.el [ Elem.width Elem.fill ] Elem.none
        , Ui.simpleButton
            [ Elem.width (Elem.fillPortion 3) ]
            { onPress = Nothing
            , label = Elem.text "Bilan"
            }
        , Elem.el [ Elem.width Elem.fill ] Elem.none
        , Ui.simpleButton
            [ Elem.width (Elem.fillPortion 3) ]
            { onPress = Nothing
            , label = Elem.text "Pointer"
            }
        , Elem.el [ Elem.width Elem.fill ] Elem.none
        ]
