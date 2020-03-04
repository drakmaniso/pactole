module View.Style exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes


bgPage =
    rgb 0.85 0.82 0.75


bgWhite =
    rgb 1.0 1.0 1.0


bgTitle =
    rgb 0.3 0.6 0.7


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
    , Font.size 28
    ]


weekDayName =
    [ centerX, Font.size 16 ]


dayCell =
    [ Background.color (rgb 0.94 0.92 0.87)
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
