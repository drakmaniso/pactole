module Ui exposing (..)

--TODO: remove dependency to module Msg

import Date
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Html.Events as Events
import Json.Decode as Decode
import Money
import Msg



-- CONSTANTS


borderWidth =
    2


roundCorners =
    Border.rounded 24


notSelectable =
    E.htmlAttribute (Html.Attributes.style "user-select" "none")



-- COLORS


transparent =
    E.rgba 0 0 0 0


warningColor =
    E.rgb 0.82 0.47 0.0


fgFocus =
    --rgb 0.98 0.62 0.05
    --rgb 0.15 0.76 0.98
    --rgba 0 0 0 0.4
    E.rgb 1.0 0.7 0


bgPage =
    --rgb 0.85 0.82 0.75
    --rgb 0.76 0.73 0.65
    -- rgb 0.74 0.71 0.65
    E.rgb 1 1 1


bgLight =
    -- rgb 0.94 0.92 0.87
    --E.rgb 0.86 0.86 0.86
    E.rgb 0.9 0.9 0.89


bgDark =
    -- rgb 0.72 0.71 0.68
    E.rgb 0.7 0.7 0.65


bgWhite =
    E.rgb 1.0 1.0 1.0


fgWhite =
    E.rgb 1.0 1.0 1.0


fgBlack =
    E.rgb 0 0 0


fgRed =
    E.rgb 0.84 0.22 0.0


fgDark =
    E.rgb 0.7 0.7 0.65


fgTransaction isExpense =
    if isExpense then
        fgExpense

    else
        fgIncome


bgTransaction isExpense =
    if isExpense then
        bgExpense

    else
        bgIncome


bgExpense =
    -- rgb 0.8 0.25 0.2
    E.rgb 0.64 0.12 0.0


fgExpense =
    -- rgb 0.6 0.125 0
    bgExpense


fgOnExpense =
    E.rgb 1.0 1.0 1.0


bgIncome =
    -- rgb255 44 136 32
    -- rgb255 22 102 0
    E.rgb 0.1 0.44 0


fgIncome =
    -- rgb255 22 68 0
    bgIncome


fgOnIncome =
    E.rgb 1.0 1.0 1.0


bgTitle =
    --rgb 0.3 0.6 0.7
    --rgb 0.12 0.51 0.65
    --rgb 0.06 0.25 0.32
    E.rgb 0.08 0.26 0.42


bgEvenRow =
    --E.rgb 0.99 0.98 0.9
    E.rgb 0.96 0.96 0.95


bgOddRow =
    --E.rgb 0.96 0.95 0.74
    E.rgb 0.9 0.9 0.89


bgMouseOver =
    E.rgb 0.85 0.92 0.98


bgMouseDown =
    E.rgb 0.7 0.7 0.65


fgTitle =
    bgTitle


fgOnTitle =
    E.rgb 1 1 1



-- FONTS


fontFamily =
    Font.family
        [ Font.typeface "Work Sans"
        , Font.sansSerif
        ]


biggestFont =
    Font.size 48


biggerFont =
    Font.size 36


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


iconFont =
    Font.family [ Font.typeface "Font Awesome 5 Free" ]



-- ICONS


closeIcon attributes =
    E.el ([ iconFont, normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F00D}")


backIcon attributes =
    E.el ([ iconFont, normalFont ] ++ attributes)
        (E.text "\u{F30A}")


editIcon attributes =
    E.el ([ iconFont, normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F044}")


deleteIcon attributes =
    E.el ([ iconFont, normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F2ED}")


minusIcon attributes =
    E.el ([ iconFont, normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F068}")


plusIcon attributes =
    E.el ([ iconFont, normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F067}")


checkIcon attributes =
    E.el ([ iconFont, normalFont ] ++ attributes)
        (E.text "\u{F00C}")


warningIcon attributes =
    E.el ([ iconFont, bigFont, E.centerX, E.paddingXY 24 0, Font.color warningColor ] ++ attributes)
        (E.text "\u{F071}")


bigWarningIcon attributes =
    E.el
        ([ iconFont, Font.size 48, E.alignLeft, E.padding 12, Font.color warningColor ]
            ++ attributes
        )
        (E.text "\u{F071}")


incomeIcon attributes =
    E.el ([ iconFont, normalFont, E.centerX, Font.color fgIncome ] ++ attributes)
        (E.text "\u{F067}")


expenseIcon attributes =
    E.el ([ iconFont, normalFont, E.centerX, Font.color fgExpense ] ++ attributes)
        (E.text "\u{F068}")



-- CONTAINERS


pageWithSidePanel :
    List (E.Attribute msg)
    ->
        { panel : E.Element msg
        , page : E.Element msg
        }
    -> E.Element msg
pageWithSidePanel attributes { panel, page } =
    E.row
        ([ E.width E.fill
         , E.height E.fill
         , E.clipX
         , E.clipY
         , Background.color bgPage
         , fontFamily
         , normalFont
         ]
            ++ attributes
        )
        [ E.el
            [ E.width (E.fillPortion 1)
            , E.height E.fill
            , E.clipY
            , E.paddingXY 0 16
            , E.alignTop
            ]
            panel
        , E.el
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            , E.clipY
            , Border.widthEach { top = 0, left = borderWidth, bottom = 0, right = 0 }
            , Border.color bgDark
            ]
            page
        ]


configRadio :
    List (E.Attribute msg)
    ->
        { label : String
        , options : List (Input.Option option msg)
        , selected : Maybe option
        , onChange : option -> msg
        }
    -> E.Element msg
configRadio attributes { label, options, selected, onChange } =
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
                 , E.mouseDown [ Background.color bgMouseDown ]
                 ]
                    ++ (case state of
                            Input.Idle ->
                                [ Font.color fgTitle ]

                            Input.Focused ->
                                []

                            Input.Selected ->
                                [ Font.color (E.rgb 1 1 1), Background.color bgTitle ]
                       )
                )
                element
        )


configCustom :
    List (E.Attribute msg)
    ->
        { label : String
        , content : E.Element msg
        }
    -> E.Element msg
configCustom attributes { label, content } =
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


pageTitle : List (E.Attribute msg) -> E.Element msg -> E.Element msg
pageTitle attributes element =
    E.el
        ([ bigFont
         , Font.center
         , Font.bold
         , E.paddingEach { top = 12, bottom = 12, left = 12, right = 12 }
         , E.width E.fill
         ]
            ++ attributes
        )
        element


warningParagraph : List (E.Attribute msg) -> List (E.Element msg) -> E.Element msg
warningParagraph attributes elements =
    E.row
        ([ normalFont
         , Font.color fgBlack
         , E.centerY
         , E.spacing 12
         ]
            ++ attributes
        )
        [ bigWarningIcon []
        , E.paragraph [] elements
        ]


dateNavigationBar model =
    E.row
        [ E.width E.fill
        , E.alignTop
        , E.paddingEach { top = 0, bottom = 8, left = 0, right = 0 }
        , Background.color bgWhite
        ]
        [ E.el
            [ E.width (E.fillPortion 2)
            , E.height E.fill
            ]
            (Input.button
                [ E.width E.fill
                , E.height E.fill
                , Border.roundEach { topLeft = 0, bottomLeft = 0, topRight = 0, bottomRight = 32 }
                , Font.color fgTitle
                , Border.widthEach { top = 0, bottom = 2, left = 0, right = 2 }
                , Background.color bgWhite
                , Border.color bgDark
                , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                , if model.showFocus then
                    E.focused
                        [ Border.color fgFocus
                        , Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = E.rgba 0 0 0 0 }
                        ]

                  else
                    E.focused []
                , E.mouseDown [ Background.color bgMouseDown ]
                ]
                { label =
                    E.row
                        [ E.width E.fill ]
                        [ E.el [ bigFont, Font.color fgTitle, E.centerX ]
                            (E.text (Date.getMonthName (Date.decrementMonth model.date)))
                        , E.el [ E.centerX, iconFont, normalFont ] (E.text "  \u{F060}  ")
                        ]
                , onPress = Just (Msg.SelectDate (Date.decrementMonth model.date))
                }
            )
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
                ]
                (E.text (Date.getMonthFullName model.today model.date))
            )
        , E.el
            -- needed to circumvent focus bug in elm-ui
            [ E.width (E.fillPortion 2)
            , E.height E.fill
            ]
            (if
                (Date.getYear model.date /= Date.getYear model.today)
                    || (Date.getMonth model.date /= Date.getMonth model.today)
             then
                Input.button
                    [ E.width E.fill
                    , E.height E.fill
                    , Border.roundEach { topLeft = 0, bottomLeft = 32, topRight = 0, bottomRight = 0 }
                    , Font.color fgTitle
                    , Border.widthEach { top = 0, bottom = 2, left = 2, right = 0 }
                    , Background.color bgWhite
                    , Border.color bgDark
                    , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                    , if model.showFocus then
                        E.focused
                            [ Border.color fgFocus
                            , Border.shadow { offset = ( 0, 0 ), size = 0, blur = 0, color = E.rgba 0 0 0 0 }
                            ]

                      else
                        E.focused []
                    , E.mouseDown [ Background.color bgMouseDown ]
                    ]
                    { label =
                        E.row
                            [ E.width E.fill ]
                            [ E.el [ E.centerX, iconFont, normalFont ] (E.text "  \u{F061}  ")
                            , E.el [ bigFont, Font.color fgTitle, E.centerX ]
                                (E.text (Date.getMonthName (Date.incrementMonth model.date)))
                            ]
                    , onPress = Just (Msg.SelectDate (Date.incrementMonth model.date))
                    }

             else
                E.el
                    [ E.width E.fill
                    , E.height E.fill
                    , Border.roundEach { topLeft = 0, bottomLeft = 32, topRight = 0, bottomRight = 0 }
                    , Border.widthEach { top = 0, bottom = 2, left = 2, right = 0 }
                    , Background.color bgWhite
                    , Border.color bgDark
                    , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                    ]
                    E.none
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
            Font.color fgExpense

          else if isZero then
            Font.color fgDark

          else
            Font.color fgIncome
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
                (E.text (parts.sign ++ parts.units))
            , E.el
                [ E.width (E.fillPortion 25)
                , Font.bold
                , smallFont
                , Font.alignLeft
                , E.alignBottom
                , E.paddingXY 0 1
                ]
                (E.text ("," ++ parts.cents))
            ]
        )


viewSum money =
    let
        parts =
            Money.toStrings money
    in
    E.row
        [ E.width E.shrink
        , E.height E.shrink
        , E.paddingEach { top = 0, bottom = 0, left = 16, right = 16 }
        , Font.color fgBlack
        ]
        [ E.el
            [ E.width (E.fillPortion 75)
            , biggestFont
            , Font.alignRight
            ]
            (E.text (parts.sign ++ parts.units))
        , E.el
            [ E.width (E.fillPortion 25)
            , biggerFont
            , Font.alignLeft
            , E.alignBottom
            , E.paddingXY 0 1
            ]
            (E.text ("," ++ parts.cents))
        ]



-- INTERACTIVE ELEMENTS


simpleButton :
    List (E.Attribute msg)
    -> { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
simpleButton attributes { onPress, label } =
    Input.button
        ([ Background.color bgPage
         , normalFont
         , Font.color fgTitle
         , Font.center
         , roundCorners
         , Border.width borderWidth
         , Border.color fgDark
         , E.paddingXY 24 8

         --, E.mouseOver [ Background.color bgMouseOver ]
         , E.mouseDown [ Background.color bgMouseDown ]
         ]
            ++ attributes
        )
        { onPress = onPress
        , label = label
        }


mainButton :
    List (E.Attribute msg)
    -> { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
mainButton attributes { onPress, label } =
    Input.button
        ([ Background.color bgTitle
         , normalFont
         , Font.color fgWhite
         , Font.center
         , roundCorners
         , Border.width borderWidth
         , Border.color bgTitle
         , E.paddingXY 24 8
         , E.mouseDown [ Background.color bgMouseDown ]
         ]
            ++ attributes
        )
        { onPress = onPress
        , label = label
        }


coloredButton :
    List (E.Attribute msg)
    -> { onPress : Maybe msg, label : E.Element msg, color : E.Color }
    -> E.Element msg
coloredButton attributes { onPress, label, color } =
    Input.button
        ([ Background.color bgPage
         , normalFont
         , Font.color color
         , Font.center
         , roundCorners
         , Border.width borderWidth
         , Border.color color
         , E.paddingXY 24 8

         --, E.mouseOver [ Background.color bgMouseOver ]
         , E.mouseDown [ Background.color bgMouseDown ]
         ]
            ++ attributes
        )
        { onPress = onPress
        , label = label
        }


iconButton :
    List (E.Attribute msg)
    -> { onPress : Maybe msg, icon : E.Element msg }
    -> E.Element msg
iconButton attributes { onPress, icon } =
    Input.button
        ([ Background.color bgPage
         , normalFont
         , Font.color fgTitle
         , Font.center
         , roundCorners
         , E.padding 8
         , E.width (E.px 48)
         , E.height (E.px 48)

         --, E.mouseOver [ Background.color bgMouseOver ]
         , E.mouseDown [ Background.color bgMouseDown ]
         ]
            ++ attributes
        )
        { onPress = onPress
        , label = icon
        }


radioButton attributes { onPress, icon, label, active } =
    Input.button
        ([ normalFont
         , Border.rounded 4
         , E.paddingXY 24 8
         ]
            ++ (if active then
                    [ Font.color fgWhite
                    , Background.color bgTitle
                    ]

                else
                    [ Font.color fgTitle
                    , Background.color bgWhite
                    ]
               )
            ++ attributes
        )
        { onPress = onPress
        , label =
            E.row []
                [ E.el [ iconFont ] (E.text icon)
                , E.text " "
                , E.text label
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
