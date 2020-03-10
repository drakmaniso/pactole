module View.Summary exposing (view)

import Element
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Model
import Msg
import View.Style as Style



-- SUMMARY VIEW


view model =
    Element.column
        [ Element.width Element.fill
        , Element.height Element.fill
        ]
        [ Element.row
            [ Element.width Element.fill ]
            [ if model.showAdvanced then
                Input.button
                    [ Style.fontIcons
                    , Style.normalFont
                    , Element.centerX
                    , Element.paddingXY 16 0
                    , Font.color Style.fgTitle
                    ]
                    { label = Element.text "\u{F013}", onPress = Just Msg.ToSettings }

              else
                Element.el [] Element.none

            --{ label = Element.text "\u{F0C9}", onPress = Just Msg.ToSettings }
            , Input.radioRow
                [ Element.width Element.fill ]
                { onChange = Msg.ChooseAccount
                , selected = model.account
                , label = Input.labelHidden "Compte"
                , options =
                    List.map
                        (\acc -> Input.optionWith acc (accountOption acc))
                        model.accounts
                }
            , Element.el [ Element.width Element.fill ] Element.none
            ]
        , Element.row [ Element.width Element.fill, Element.height Element.fill ] [ Element.none ]
        ]


accountOption : String -> Input.OptionState -> Element.Element msg
accountOption value state =
    Element.el
        ([ Element.centerX
         , Element.paddingXY 16 8
         , Border.rounded 3
         , Style.bigFont
         ]
            ++ (case state of
                    Input.Idle ->
                        [ Font.color Style.fgTitle ]

                    Input.Focused ->
                        []

                    Input.Selected ->
                        [ Font.color (Element.rgb 1 1 1), Background.color Style.bgTitle ]
               )
        )
        (Element.text value)
