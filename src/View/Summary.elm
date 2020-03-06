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
        [ Element.width Element.fill ]
        [ Element.row
            [ Element.width Element.fill ]
            [ Input.radioRow
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
            , Input.button
                Style.iconsSettings
                { label = Element.text "\u{F013}", onPress = Just Msg.ToSettings }
            ]
        ]


accountOption : String -> Input.OptionState -> Element.Element msg
accountOption value state =
    Element.el
        ([ Element.centerX
         , Element.paddingXY 16 8
         , Border.rounded 3
         ]
            ++ (case state of
                    Input.Idle ->
                        [ Font.color (Element.rgb 0.3 0.6 0.7) ]

                    Input.Focused ->
                        []

                    Input.Selected ->
                        [ Font.color (Element.rgb 1 1 1), Background.color (Element.rgb 0.3 0.6 0.7) ]
               )
        )
        (Element.text value)
