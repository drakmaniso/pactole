module View.Style exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes


bgPage =
    --rgb 0.85 0.82 0.75
    --rgb 0.76 0.73 0.65
    rgb 0.74 0.71 0.65


bgLight =
    rgb 0.94 0.92 0.87


bgWhite =
    rgb 1.0 1.0 1.0


bgExpense =
    rgb 0.8 0.25 0.2


fgExpense =
    bgExpense


fgOnExpense =
    rgb 1.0 1.0 1.0


bgIncome =
    rgb255 44 136 32


fgIncome =
    bgIncome


fgOnIncome =
    rgb 1.0 1.0 1.0


bgTitle =
    --rgb 0.3 0.6 0.7
    rgb 0.12 0.51 0.65


fgTitle =
    bgTitle


fontFamily =
    Font.family
        [ Font.typeface "Nunito Sans"
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


calendarMonthName =
    [ centerX
    , Font.bold
    , bigFont
    ]


weekDayName =
    [ centerX, Font.size 16 ]


dayCell =
    [ Background.color bgLight
    , Border.color (rgba 0 0 0 0)
    , Border.width 2
    , Border.rounded 2

    -- , focused [ Border.color bgTitle, Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = rgba 0 0 0 0 } ]
    ]


dayCellSelected =
    [ Background.color (rgb 1 1 1)
    , Border.color bgTitle
    , Border.rounded 8
    , Border.width 2
    , focused [ Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = rgba 0 0 0 0 } ]

    -- , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 8, color = rgba 0 0 0 0.2 }
    , htmlAttribute <| Html.Attributes.style "z-index" "1000"
    ]


dayCellNone =
    [ Border.color (rgba 0 0 0 0)
    , Border.width 2
    ]
