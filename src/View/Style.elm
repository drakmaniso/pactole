module View.Style exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes


fgFocus =
    --rgb 0.98 0.62 0.05
    --rgb 0.15 0.76 0.98
    --rgba 0 0 0 0.4
    rgb 1.0 0.7 0


bgPage =
    --rgb 0.85 0.82 0.75
    --rgb 0.76 0.73 0.65
    -- rgb 0.74 0.71 0.65
    rgb 1 1 1


bgLight =
    -- rgb 0.94 0.92 0.87
    rgb 0.9 0.9 0.9


bgDark =
    -- rgb 0.72 0.71 0.68
    rgb 0.7 0.7 0.7


bgWhite =
    rgb 1.0 1.0 1.0


fgWhite =
    rgb 1.0 1.0 1.0


fgBlack =
    rgb 0 0 0


fgDark =
    rgb 0.6 0.6 0.6


bgExpense =
    -- rgb 0.8 0.25 0.2
    rgb 0.64 0.12 0.0


fgExpense =
    -- rgb 0.6 0.125 0
    bgExpense


fgOnExpense =
    rgb 1.0 1.0 1.0


bgIncome =
    -- rgb255 44 136 32
    -- rgb255 22 102 0
    rgb 0.1 0.44 0


fgIncome =
    -- rgb255 22 68 0
    bgIncome


fgOnIncome =
    rgb 1.0 1.0 1.0


bgTitle =
    --rgb 0.3 0.6 0.7
    rgb 0.12 0.51 0.65


fgTitle =
    bgTitle


fgOnTitle =
    rgb 1 1 1


fontFamily =
    Font.family
        [ Font.typeface "Work Sans"
        , Font.sansSerif
        ]


bigFont =
    Font.size 32


normalFont =
    Font.size 26


smallFont =
    Font.size 20


smallerFont =
    Font.size 14


verySmallFont =
    Font.size 16


fontIcons =
    Font.family [ Font.typeface "Font Awesome 5 Free" ]


icons =
    [ centerX
    , Font.family [ Font.typeface "Font Awesome 5 Free" ]
    , Font.size 32
    ]


iconsSettings =
    [ centerX
    , Font.family [ Font.typeface "Font Awesome 5 Free" ]
    , Font.size 24
    , Font.color bgTitle
    ]


customButton w fg bg filled =
    [ Background.color
        (if filled then
            fg

         else
            bg
        )
    , Font.color
        (if filled then
            bg

         else
            fg
        )
    , Border.color fg
    , width w
    , Font.center
    , Border.width 3
    , Border.rounded 24

    --, Border.shadow { offset = ( 0, 0 ), size = 2, blur = 4, color = rgba 0 0 0 0.2 }
    ]


button w fg bg inverted =
    normalFont :: paddingXY 24 8 :: customButton w fg bg inverted


iconButton w fg bg inverted =
    fontIcons :: bigFont :: paddingXY 12 6 :: customButton w fg bg inverted


calendarMonthName =
    [ centerX
    , Font.bold
    , bigFont
    ]


weekDayName =
    [ centerX, smallFont, Font.color fgDark ]


dayCell =
    [ Background.color bgWhite
    , Border.color (rgba 0 0 0 0)
    , Border.width 4
    , Border.rounded 0
    , focused
        [ Border.color fgFocus, Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = rgba 0 0 0 0 } ]
    ]


dayCellSelected =
    [ Background.color bgTitle
    , Border.color bgTitle
    , Border.rounded 0
    , Border.width 4
    , focused [ Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = rgba 0 0 0 0 } ]
    ]


dayCellNone =
    [ Border.color (rgba 0 0 0 0)
    , Border.width 4
    , Background.color bgLight
    ]
