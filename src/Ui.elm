module Ui exposing (..)

import Bitwise
import Browser
import Date
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Html.Attributes
import Html.Events as Events
import Json.Decode as Decode
import Money



-- ENVIRONMENT FOR UI


type alias Device =
    { width : Int
    , height : Int
    , class : E.Device
    }


device : Int -> Int -> Device
device width height =
    { width = width, height = height, class = E.classifyDevice { width = width, height = height } }



-- CONSTANTS


borderWidth : number
borderWidth =
    2


roundCorners : E.Attribute msg
roundCorners =
    Border.rounded 24


notSelectable : E.Attribute msg
notSelectable =
    E.htmlAttribute (Html.Attributes.style "user-select" "none")



-- COLORS


hex color =
    E.rgb255
        (color |> Bitwise.and 0x00FF0000 |> Bitwise.shiftRightBy 16)
        (color |> Bitwise.and 0xFF00 |> Bitwise.shiftRightBy 8)
        (color |> Bitwise.and 0xFF)


transparent : E.Color
transparent =
    E.rgba 0 0 0 0


warning70 : E.Color
warning70 =
    hex 0x00FF8263


warning60 : E.Color
warning60 =
    hex 0x00FE4200


warning50 : E.Color
warning50 =
    hex 0x00D23500


focusColor : E.Color
focusColor =
    -- E.rgb 1.0 0.7 0
    hex 0x00FFD000


white : E.Color
white =
    E.rgb 1.0 1.0 1.0


gray95 : E.Color
gray95 =
    -- E.rgb 0.95 0.95 0.95
    hex 0x00F1F1F1


gray93 : E.Color
gray93 =
    -- E.rgb 0.9 0.9 0.9
    hex 0x00EBEBEB


gray90 : E.Color
gray90 =
    -- E.rgb 0.9 0.9 0.9
    hex 0x00E2E2E2


gray70 : E.Color
gray70 =
    -- E.rgb 0.7 0.7 0.7
    hex 0x00ABABAB


gray60 : E.Color
gray60 =
    hex 0x00919191


gray50 : E.Color
gray50 =
    -- E.rgb 0.5 0.5 0.5
    hex 0x00777777


gray40 : E.Color
gray40 =
    hex 0x005E5E5E


gray30 : E.Color
gray30 =
    hex 0x00464646


gray20 : E.Color
gray20 =
    hex 0x002E2E2E


gray10 : E.Color
gray10 =
    hex 0x00161616


black : E.Color
black =
    hex 0x00


transactionColor : Bool -> E.Color
transactionColor isExpense =
    if isExpense then
        expense40

    else
        income40


expense40 : E.Color
expense40 =
    -- E.rgb 0.64 0.12 0.00
    -- hex 0xA31F00
    hex 0x00B30009


expense50 : E.Color
expense50 =
    hex 0x00E0000F


expense30 : E.Color
expense30 =
    hex 0x00880005


expense90 : E.Color
expense90 =
    -- E.rgb 0.94 0.87 0.87
    -- hex 0xF0DEDE
    hex 0x00F4DCD8


expense95 : E.Color
expense95 =
    -- E.rgb 1 0.96 0.96
    hex 0x00FAEEEC


expense80 : E.Color
expense80 =
    -- E.rgb 0.8 0.6 0.6
    -- hex 0xCC9999
    hex 0x00E9BAB3


income40 : E.Color
income40 =
    -- E.rgb 0.1 0.44 0
    -- hex 0x1A7000
    -- hex 0x006F53
    hex 0x000D7200


income50 : E.Color
income50 =
    hex 0x00139000


income30 : E.Color
income30 =
    hex 0x00075600


income90 : E.Color
income90 =
    -- E.rgb 0.92 0.94 0.86
    hex 0x00DAE7D8


income95 : E.Color
income95 =
    -- E.rgb 0.98 1 0.96
    hex 0x00ECF3EB


income80 : E.Color
income80 =
    -- E.rgb 0.7 0.8 0.6
    hex 0x00B7CFB4


primary50 : E.Color
primary50 =
    -- E.rgb 0.18 0.52 0.66
    -- hex 0x007DC2
    -- hex 0x387BBB
    hex 0x00387BBB


primary40 : E.Color
primary40 =
    -- E.rgb 0.08 0.26 0.42
    -- hex 0x14426b
    -- hex 0x00639B
    -- hex 0x1B4873
    hex 0x00286197


primary30 : E.Color
primary30 =
    -- E.rgb 0.08 0.19 0.3
    -- hex 0x004A75
    hex 0x001B4873



-- STYLES FOR INTERACTIVE ELEMENTS


transition : E.Attribute msg
transition =
    E.htmlAttribute (Html.Attributes.style "transition" "background 0.1s, color 0.1s, box-shadow 0.1s, border-color 0.1s")


defaultShadow : E.Attr decorative msg
defaultShadow =
    Border.shadow { offset = ( 0, 5 ), size = 0, blur = 8, color = E.rgba 0 0 0 0.5 }


smallShadow : E.Attr decorative msg
smallShadow =
    Border.shadow { offset = ( 0, 2 ), size = 0, blur = 6, color = E.rgba 0 0 0 0.5 }


innerShadow : E.Attr decorative msg
innerShadow =
    Border.innerShadow { offset = ( 0, 1 ), size = 0, blur = 4, color = E.rgba 0 0 0 0.5 }


bigInnerShadow : E.Attr decorative msg
bigInnerShadow =
    Border.innerShadow { offset = ( 0, 1 ), size = 0, blur = 6, color = E.rgba 0 0 0 0.7 }


mouseDown : List (E.Attr Never Never) -> E.Attribute msg
mouseDown attr =
    E.mouseDown
        (Border.shadow { offset = ( 0, 1 ), size = 0, blur = 3, color = E.rgba 0 0 0 0.4 }
            :: attr
        )


mouseOver : List E.Decoration -> E.Attribute msg
mouseOver attr =
    E.mouseOver attr



-- FONTS


fontFamily : E.Attribute msg
fontFamily =
    Font.family
        [ Font.typeface "Work Sans"
        , Font.sansSerif
        ]


biggestFont : E.Attr decorative msg
biggestFont =
    Font.size 48


biggerFont : E.Attr decorative msg
biggerFont =
    Font.size 36


bigFont : E.Attr decorative msg
bigFont =
    Font.size 32


normalFont : E.Attr decorative msg
normalFont =
    Font.size 26


smallFont : E.Attr decorative msg
smallFont =
    Font.size 20


smallerFont : E.Attr decorative msg
smallerFont =
    Font.size 14


verySmallFont : E.Attr decorative msg
verySmallFont =
    Font.size 16


iconFont : E.Attribute msg
iconFont =
    Font.family [ Font.typeface "Font Awesome 5 Free" ]



-- ICONS


closeIcon : E.Element msg
closeIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F00D}")


backIcon : E.Element msg
backIcon =
    E.el [ iconFont, normalFont ]
        (E.text "\u{F30A}")


editIcon : E.Element msg
editIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F044}")


deleteIcon : E.Element msg
deleteIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F2ED}")


minusIcon : E.Element msg
minusIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F068}")


plusIcon : E.Element msg
plusIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F067}")


checkIcon : E.Element msg
checkIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F00C}")


warningIcon : E.Element msg
warningIcon =
    E.el [ iconFont, bigFont, E.centerX, E.paddingXY 24 0, Font.color warning60 ]
        (E.text "\u{F071}")


bigWarningIcon : E.Element msg
bigWarningIcon =
    E.el
        [ iconFont, Font.size 48, E.alignLeft, E.alignTop, E.padding 0, Font.color warning60 ]
        (E.text "\u{F071}")


incomeIcon : E.Element msg
incomeIcon =
    E.el [ iconFont, normalFont, E.centerX, Font.color income40 ]
        (E.text "\u{F067}")


expenseIcon : E.Element msg
expenseIcon =
    E.el [ iconFont, normalFont, E.centerX, Font.color expense40 ]
        (E.text "\u{F068}")


saveIcon : E.Element msg
saveIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F0C7}")


loadIcon : E.Element msg
loadIcon =
    E.el [ iconFont, normalFont, E.centerX ]
        (E.text "\u{F2EA}")



-- CONTAINERS


document : String -> E.Element msg -> Maybe (E.Element msg) -> msg -> Bool -> Browser.Document msg
document titleText activePage activeDialog closeMsg showFocus =
    { title = titleText
    , body =
        [ E.layoutWith
            { options =
                [ E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow =
                        if showFocus then
                            Just
                                { color = focusColor
                                , offset = ( 0, 0 )
                                , blur = 0
                                , size = 4
                                }

                        else
                            Nothing
                    }
                ]
            }
            (case activeDialog of
                Just d ->
                    [ E.inFront
                        (E.el
                            [ E.width E.fill
                            , E.height E.fill
                            , fontFamily
                            , Font.color gray30
                            , E.padding 16
                            , E.scrollbarY
                            , E.behindContent
                                (Input.button
                                    [ E.width E.fill
                                    , E.height E.fill
                                    , Background.color (E.rgba 0 0 0 0.6)
                                    ]
                                    { label = E.none
                                    , onPress = Just closeMsg
                                    }
                                )
                            ]
                            d
                        )
                    ]

                Nothing ->
                    [ E.inFront (E.column [] [])
                    ]
            )
            activePage
        ]
    }


pageWithSidePanel : { panel : E.Element msg, page : E.Element msg } -> E.Element msg
pageWithSidePanel { panel, page } =
    E.row
        [ E.width E.fill
        , E.height E.fill
        , E.clipX
        , E.clipY
        , Background.color white
        , fontFamily
        , normalFont
        , Font.color gray30
        ]
        [ E.el
            [ E.width (E.fillPortion 1)
            , E.height E.fill
            , E.clipY
            , E.paddingXY 6 12
            , E.alignTop
            ]
            panel
        , E.el
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            , E.clipY
            , E.paddingEach { top = 0, left = 6, bottom = 3, right = 6 }
            , Border.widthEach { top = 0, left = borderWidth, bottom = 0, right = 0 }
            , Border.color white -- bgDark
            ]
            page
        ]


configRadio :
    { label : String
    , options : List (Input.Option option msg)
    , selected : Maybe option
    , onChange : option -> msg
    }
    -> E.Element msg
configRadio { label, options, selected, onChange } =
    Input.radioRow
        [ E.paddingEach { top = 12, bottom = 24, left = 12 + 64, right = 12 }
        , E.width E.fill
        ]
        { label =
            Input.labelAbove
                [ E.paddingEach { bottom = 0, top = 48, left = 12, right = 12 } ]
                (E.el [ Font.bold ] (E.text label))
        , options = options
        , selected = selected
        , onChange = onChange
        }


radioRowOption : value -> E.Element msg -> Input.Option value msg
radioRowOption value element =
    Input.optionWith
        value
        (\state ->
            E.el
                ([ E.centerX
                 , E.paddingXY 16 7
                 , Border.rounded 3
                 , bigFont
                 , transition
                 ]
                    ++ (case state of
                            Input.Idle ->
                                [ Font.color gray30
                                , E.mouseDown [ Background.color gray90 ]
                                , E.mouseOver [ Background.color gray95 ]
                                ]

                            Input.Focused ->
                                [ E.mouseDown [ Background.color gray90 ]
                                , E.mouseOver [ Background.color gray95 ]
                                ]

                            Input.Selected ->
                                [ Font.color (E.rgb 1 1 1)
                                , Background.color primary40
                                , smallShadow
                                , mouseDown [ Background.color primary30 ]
                                , mouseOver [ Background.color primary40 ]
                                ]
                       )
                )
                element
        )


configCustom :
    { label : String
    , content : E.Element msg
    }
    -> E.Element msg
configCustom { label, content } =
    E.column
        [ E.paddingEach { top = 48, bottom = 24, left = 12, right = 12 }
        , E.width E.fill
        ]
        [ E.el
            [ E.width E.fill
            , E.paddingEach { top = 0, bottom = 24, right = 0, left = 0 }
            ]
            (E.el [ Font.bold ] (E.text label))
        , E.el [ E.paddingEach { left = 64, bottom = 24, right = 0, top = 0 } ] content
        ]



-- ELEMENTS


pageTitle : E.Element msg -> E.Element msg
pageTitle element =
    E.el
        [ bigFont
        , Font.center
        , Font.bold
        , E.paddingEach { top = 12, bottom = 12, left = 12, right = 12 }
        , E.width E.fill
        , E.centerY
        , Font.color gray40
        ]
        element


title : E.Color -> String -> E.Element msg
title color text =
    E.el
        [ E.width E.fill
        , Font.color color
        , normalFont
        , Font.bold
        , E.padding 0
        , notSelectable
        ]
        (E.text text)


ruler : E.Element msg
ruler =
    E.el
        [ E.width E.fill
        , E.height (E.px borderWidth)
        , E.paddingXY 48 0
        ]
        (E.el [ E.width E.fill, E.height E.fill, Background.color gray90 ] E.none)


warningParagraph : List (E.Element msg) -> E.Element msg
warningParagraph elements =
    E.row
        [ normalFont
        , Font.color gray20
        , E.centerY
        , E.spacing 12
        , E.width E.fill
        , E.height (E.shrink |> E.minimum 48)
        ]
        [ bigWarningIcon
        , E.paragraph [] elements
        ]


dateNavigationBar : { a | showFocus : Bool, date : Date.Date, today : Date.Date } -> (Date.Date -> msg) -> E.Element msg
dateNavigationBar model changeMsg =
    Keyed.row
        [ E.width E.fill
        , E.alignTop
        , E.paddingEach { top = 0, bottom = 8, left = 8, right = 8 }
        , Background.color white
        ]
        [ ( "previous month button"
          , E.el
                [ E.width (E.fillPortion 2)
                , E.height E.fill
                ]
                (Input.button
                    [ E.width E.fill
                    , E.height E.fill
                    , Border.roundEach { topLeft = 0, bottomLeft = 0, topRight = 0, bottomRight = 32 }
                    , Font.color gray30
                    , Border.widthEach { top = 0, bottom = 0, left = 0, right = 0 }
                    , Background.color gray95
                    , Border.color gray70
                    , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                    , smallShadow
                    , transition
                    , mouseDown [ Background.color gray90 ]
                    , mouseOver [ Background.color white ]
                    ]
                    { label =
                        E.row
                            [ E.width E.fill ]
                            [ E.el [ bigFont, E.centerX ]
                                (E.text (Date.getMonthName (Date.decrementMonth model.date)))
                            , E.el [ E.centerX, iconFont, normalFont ] (E.text "  \u{F060}  ")
                            ]
                    , onPress = Just (changeMsg (Date.decrementMonthUI model.date model.today))
                    }
                )
          )
        , ( "current month header"
          , E.el
                [ E.width (E.fillPortion 3)
                , E.height E.fill
                , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                , notSelectable
                ]
                (E.el
                    [ E.centerX
                    , Font.bold
                    , bigFont
                    , Font.color gray30
                    ]
                    (E.text (Date.getMonthFullName model.today model.date))
                )
          )
        , ( "next month button"
          , E.el
                -- needed to circumvent focus bug in elm-ui
                [ E.width (E.fillPortion 2)
                , E.height E.fill
                ]
                (Input.button
                    [ E.width E.fill
                    , E.height E.fill
                    , Border.roundEach { topLeft = 0, bottomLeft = 32, topRight = 0, bottomRight = 0 }
                    , Font.color gray30
                    , Border.widthEach { top = 0, bottom = 0, left = 0, right = 0 }
                    , Background.color gray95
                    , Border.color gray70
                    , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                    , smallShadow
                    , transition
                    , mouseDown [ Background.color gray90 ]
                    , mouseOver [ Background.color white ]
                    ]
                    { label =
                        E.row
                            [ E.width E.fill ]
                            [ E.el [ E.centerX, iconFont, normalFont ] (E.text "  \u{F061}  ")
                            , E.el [ bigFont, E.centerX ]
                                (E.text (Date.getMonthName (Date.incrementMonth model.date)))
                            ]
                    , onPress = Just (changeMsg (Date.incrementMonthUI model.date model.today))
                    }
                )
          )
        ]


viewMoney : Money.Money -> Bool -> E.Element msg
viewMoney money future =
    let
        openpar =
            if future then
                "("

            else
                ""

        closepar =
            if future then
                ")"

            else
                ""

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
        ]
        [ E.el [ E.width E.fill ] E.none
        , E.paragraph
            [ if future then
                Font.color gray50

              else if isExpense then
                Font.color expense40

              else if isZero then
                Font.color gray70

              else
                Font.color income40
            ]
            (if isZero then
                [ E.el [ E.width (E.fillPortion 75), normalFont, Font.alignRight ] (E.text "—")
                , E.el [ E.width (E.fillPortion 25) ] E.none
                ]

             else
                [ E.el
                    [ E.width (E.fillPortion 75)
                    , normalFont
                    , Font.bold
                    , Font.alignRight
                    ]
                    (E.text (openpar ++ parts.sign ++ parts.units ++ ","))
                , E.row
                    [ E.width (E.fillPortion 25) ]
                    [ E.el
                        [ Font.bold
                        , smallFont
                        , Font.alignLeft

                        -- , E.alignBottom
                        -- , E.paddingEach { top = 2, bottom = 0, left = 0, right = 0 }
                        ]
                        (E.text ("" ++ parts.cents))
                    , E.el
                        [ normalFont
                        , Font.bold
                        , Font.alignRight
                        ]
                        (E.text closepar)
                    ]
                ]
            )
        ]


viewSum : Money.Money -> E.Element msg
viewSum money =
    let
        parts =
            Money.toStrings money
    in
    E.row
        [ E.width E.shrink
        , E.height E.shrink
        , E.paddingEach { top = 0, bottom = 0, left = 16, right = 16 }
        ]
        [ E.el
            [ E.width (E.fillPortion 75)
            , biggerFont
            , Font.alignRight
            , Font.bold
            ]
            (E.text (parts.sign ++ parts.units))
        , E.el
            [ E.width (E.fillPortion 25)
            , normalFont
            , Font.alignLeft
            , E.alignBottom
            , E.paddingXY 0 1
            , Font.bold
            ]
            (E.text ("," ++ parts.cents))
        ]



-- INTERACTIVE ELEMENTS


simpleButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
simpleButton { onPress, label } =
    Input.button
        [ Background.color gray95
        , normalFont
        , Font.color gray30
        , Font.center
        , roundCorners
        , Border.width 0
        , Border.color gray70
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color gray90 ]
        , mouseOver [ Background.color white ]
        ]
        { onPress = onPress
        , label = label
        }


mainButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
mainButton { onPress, label } =
    Input.button
        [ Background.color primary40
        , normalFont
        , Font.color white
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color primary40
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color primary30, Border.color primary30 ]
        , mouseOver [ Background.color primary50, Border.color primary50 ]
        ]
        { onPress = onPress
        , label = label
        }


dangerButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
dangerButton { onPress, label } =
    Input.button
        [ Background.color warning60
        , normalFont
        , Font.color white
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color warning60
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color warning50, Border.color warning50 ]
        , mouseOver [ Background.color warning70, Border.color warning70 ]
        ]
        { onPress = onPress
        , label = label
        }


incomeButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
incomeButton { onPress, label } =
    Input.button
        [ E.width (E.fillPortion 2)
        , Background.color income90
        , normalFont
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color income90
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color income80, Border.color income80 ]
        , mouseOver [ Background.color income95, Border.color income95 ]
        ]
        { onPress = onPress
        , label = label
        }


expenseButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
expenseButton { onPress, label } =
    Input.button
        [ E.width (E.fillPortion 2)
        , Background.color expense90
        , normalFont
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color expense90
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color expense80, Border.color expense80 ]
        , mouseOver [ Background.color expense95, Border.color expense95 ]
        ]
        { onPress = onPress
        , label = label
        }


iconButton :
    { onPress : Maybe msg, icon : E.Element msg }
    -> E.Element msg
iconButton { onPress, icon } =
    Input.button
        [ Background.color white
        , normalFont
        , Font.color primary40
        , Font.center
        , roundCorners
        , E.padding 8
        , E.width (E.shrink |> E.minimum 64)
        , E.height (E.px 48)
        , E.mouseDown [ Background.color gray90 ]
        , E.mouseOver [ Background.color gray95 ]
        ]
        { onPress = onPress
        , label = icon
        }


checkBox :
    { state : Bool, onPress : Maybe msg }
    -> E.Element msg
checkBox { state, onPress } =
    Input.button
        [ normalFont
        , Font.color primary40
        , Font.center
        , E.width (E.px 48)
        , E.height (E.px 48)
        , E.alignRight
        , Background.color (E.rgba 1 1 1 1)
        , Border.rounded 0
        , Border.width borderWidth
        , Border.color gray70
        , E.padding 2
        , innerShadow
        , transition
        , E.mouseDown [ Background.color gray90 ]
        , E.mouseOver [ bigInnerShadow ]
        ]
        { onPress = onPress
        , label =
            if state then
                checkIcon

            else
                E.none
        }


radioButton : { a | onPress : Maybe msg, icon : String, label : String, active : Bool } -> E.Element msg
radioButton { onPress, icon, label, active } =
    Input.button
        ([ normalFont
         , Border.rounded 4
         , E.paddingXY 24 8
         , transition
         ]
            ++ (if active then
                    [ Font.color white
                    , Background.color primary40
                    , smallShadow
                    , mouseDown [ Background.color primary30 ]
                    , mouseOver [ Background.color primary40 ]
                    ]

                else
                    [ Font.color gray30
                    , Background.color white
                    , E.mouseDown [ Background.color gray90 ]
                    , E.mouseOver [ Background.color gray95 ]
                    ]
               )
        )
        { onPress = onPress
        , label =
            E.row []
                [ if icon /= "" then
                    E.el [ E.width (E.shrink |> E.minimum 48), iconFont, Font.center ]
                        (E.text icon)

                  else
                    E.none
                , if label /= "" then
                    E.text (" " ++ label)

                  else
                    E.none
                ]
        }



-- ATTRIBUTES


onEnter : msg -> E.Attribute msg
onEnter msg =
    E.htmlAttribute
        (Events.on "keyup"
            (Decode.field "key" Decode.string
                |> Decode.andThen
                    (\key ->
                        if key == "Enter" then
                            Decode.succeed msg

                        else
                            Decode.fail "Not the enter key"
                    )
            )
        )
