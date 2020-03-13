module View.Summary exposing (view)

import Element as Elem
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Model
import Msg
import View.Style as Style



-- SUMMARY VIEW


view model =
    Elem.column
        [ Elem.width Elem.fill
        , Elem.height Elem.fill
        ]
        [ Elem.row
            [ Elem.width Elem.shrink
            , Elem.alignLeft
            ]
            [ if model.showAdvanced then
                Input.button
                    (Style.button Elem.shrink Style.fgTitle (Elem.rgba 0 0 0 0) False)
                    { label =
                        Elem.text "Configurer"
                    , onPress = Just Msg.ToSettings
                    }

              else
                Input.radioRow
                    [ Elem.width Elem.fill
                    , Elem.focused
                        [ Border.shadow
                            { offset = ( 0, 0 )
                            , size = 4
                            , blur = 0
                            , color = Style.fgFocus
                            }
                        ]
                    ]
                    { onChange = Msg.ChooseAccount
                    , selected = model.account
                    , label = Input.labelHidden "Compte"
                    , options =
                        List.map
                            (\acc -> Input.optionWith acc (accountOption acc))
                            model.accounts
                    }
            , Elem.el [ Elem.width Elem.fill ] Elem.none
            ]
        , Elem.row [ Elem.width Elem.fill, Elem.height Elem.fill ] [ Elem.none ]
        ]


accountOption : String -> Input.OptionState -> Elem.Element msg
accountOption value state =
    Elem.el
        ([ Elem.centerX
         , Elem.paddingXY 16 8
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
        (Elem.text value)