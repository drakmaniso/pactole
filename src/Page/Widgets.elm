module Page.Widgets exposing (..)

import Date
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Money
import Shared
import Style
import Ui


dateNavigation model =
    E.row
        [ E.width E.fill
        , E.alignTop
        , E.paddingEach { top = 0, bottom = 8, left = 0, right = 0 }
        , Background.color Style.bgWhite
        ]
        [ E.el
            [ E.width (E.fillPortion 2)
            , E.height E.fill
            ]
            (Input.button
                [ E.width E.fill
                , E.height E.fill
                , Border.roundEach { topLeft = 0, bottomLeft = 0, topRight = 0, bottomRight = 32 }
                , Font.color Style.fgTitle
                , Border.widthEach { top = 0, bottom = 2, left = 0, right = 2 }
                , Background.color Style.bgWhite
                , Border.color Style.bgDark
                , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                , E.focused
                    [ Border.color Style.fgFocus
                    , Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = E.rgba 0 0 0 0 }
                    ]
                ]
                { label =
                    E.row
                        [ E.width E.fill ]
                        [ E.el [ Style.bigFont, Font.color Style.fgTitle, E.centerX ]
                            (E.text (Date.getMonthName (Date.decrementMonth model.date)))
                        , E.el [ E.centerX, Style.fontIcons, Style.normalFont ] (E.text "  \u{F060}  ")
                        ]
                , onPress = Just (Shared.SelectDate (Date.decrementMonth model.date))
                }
            )
        , E.el
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
            ]
            (E.el Style.calendarMonthName (E.text (Date.getMonthFullName model.today model.date)))
        , E.el
            -- needed to circumvent focus bug in elm-ui
            [ E.width (E.fillPortion 2)
            , E.height E.fill
            ]
            (Input.button
                [ E.width E.fill
                , E.height E.fill
                , Border.roundEach { topLeft = 0, bottomLeft = 32, topRight = 0, bottomRight = 0 }
                , Font.color Style.fgTitle
                , Border.widthEach { top = 0, bottom = 2, left = 2, right = 0 }
                , Background.color Style.bgWhite
                , Border.color Style.bgDark
                , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                , E.focused
                    [ Border.color Style.fgFocus
                    , Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = E.rgba 0 0 0 0 }
                    ]
                ]
                { label =
                    E.row
                        [ E.width E.fill ]
                        [ E.el [ E.centerX, Style.fontIcons, Style.normalFont ] (E.text "  \u{F061}  ")
                        , E.el [ Style.bigFont, Font.color Style.fgTitle, E.centerX ]
                            (E.text (Date.getMonthName (Date.incrementMonth model.date)))
                        ]
                , onPress = Just (Shared.SelectDate (Date.incrementMonth model.date))
                }
            )
        ]


viewMoney money =
    let
        parts =
            Money.toStrings money

        isExpense =
            Money.isExpense money

        isZero =
            Money.isZero money
    in
    E.row
        [ E.width E.fill
        , E.height E.shrink
        , E.paddingEach { top = 0, bottom = 0, left = 0, right = 16 }
        , if isExpense then
            Font.color Style.fgExpense

          else if isZero then
            Font.color Style.fgDark

          else
            Font.color Style.fgIncome
        ]
        (if isZero then
            [ E.el [ E.width (E.fillPortion 75), Style.normalFont, Font.alignRight ] (E.text "—")
            , E.el [ E.width (E.fillPortion 25) ] E.none
            ]

         else
            [ E.el
                [ E.width (E.fillPortion 75)
                , Style.normalFont
                , Font.bold
                , Font.alignRight
                ]
                (E.text (parts.sign ++ parts.units))
            , E.el
                [ E.width (E.fillPortion 25)
                , Font.bold
                , Style.smallFont
                , Font.alignLeft
                , E.alignBottom
                , E.paddingXY 0 1
                ]
                (E.text ("," ++ parts.cents))
            ]
        )
