module Ui exposing (..)

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


transparent : E.Color
transparent =
    E.rgba 0 0 0 0


warningColor : E.Color
warningColor =
    E.rgb 0.82 0.47 0.0


focusColor : E.Color
focusColor =
    E.rgb 1.0 0.7 0


bgPage : E.Color
bgPage =
    E.rgb 1 1 1


bgLight : E.Color
bgLight =
    E.rgb 0.9 0.9 0.89


bgDark : E.Color
bgDark =
    E.rgb 0.7 0.7 0.65


bgWhite : E.Color
bgWhite =
    E.rgb 1.0 1.0 1.0


fgWhite : E.Color
fgWhite =
    E.rgb 1.0 1.0 1.0


fgBlack : E.Color
fgBlack =
    E.rgb 0 0 0


fgRed : E.Color
fgRed =
    E.rgb 0.84 0.22 0.0


fgDark : E.Color
fgDark =
    E.rgb 0.7 0.7 0.65


fgDarker : E.Color
fgDarker =
    E.rgb 0.5 0.5 0.45


fgTransaction : Bool -> E.Color
fgTransaction isExpense =
    if isExpense then
        fgExpense

    else
        fgIncome


bgTransaction : Bool -> E.Color
bgTransaction isExpense =
    if isExpense then
        bgExpense

    else
        bgIncome


bgExpense : E.Color
bgExpense =
    E.rgb 0.64 0.12 0.0


fgExpense : E.Color
fgExpense =
    bgExpense


fgOnExpense : E.Color
fgOnExpense =
    E.rgb 1.0 1.0 1.0


bgIncome : E.Color
bgIncome =
    E.rgb 0.1 0.44 0


bgIncomeButton : E.Color
bgIncomeButton =
    E.rgb 0.92 0.94 0.86


bgIncomeButtonOver : E.Color
bgIncomeButtonOver =
    E.rgb 0.98 1 0.96


bgIncomeButtonDown : E.Color
bgIncomeButtonDown =
    E.rgb 0.7 0.8 0.6


bgExpenseButton : E.Color
bgExpenseButton =
    E.rgb 0.94 0.87 0.87


bgExpenseButtonOver : E.Color
bgExpenseButtonOver =
    E.rgb 1 0.96 0.96


bgExpenseButtonDown : E.Color
bgExpenseButtonDown =
    E.rgb 0.8 0.6 0.6


fgIncome : E.Color
fgIncome =
    bgIncome


fgOnIncome : E.Color
fgOnIncome =
    E.rgb 1.0 1.0 1.0


bgEvenRow : E.Color
bgEvenRow =
    E.rgb 0.96 0.96 0.95


bgOddRow : E.Color
bgOddRow =
    E.rgb 0.92 0.92 0.91


bgButton : E.Color
bgButton =
    E.rgb 0.94 0.94 0.93


bgButtonOver : E.Color
bgButtonOver =
    E.rgb 1 1 1


bgButtonDown : E.Color
bgButtonDown =
    E.rgb 0.9 0.9 0.89


bgMouseOver : E.Color
bgMouseOver =
    E.rgb 0.94 0.94 0.93


bgMouseDown : E.Color
bgMouseDown =
    E.rgb 0.9 0.9 0.89


bgMainButton : E.Color
bgMainButton =
    bgTitle


bgMainButtonOver : E.Color
bgMainButtonOver =
    E.rgb 0.18 0.52 0.66


bgMainButtonDown : E.Color
bgMainButtonDown =
    E.rgb 0.08 0.19 0.3


bgTitle : E.Color
bgTitle =
    E.rgb 0.08 0.26 0.42


fgTitle : E.Color
fgTitle =
    bgTitle


fgOnTitle : E.Color
fgOnTitle =
    E.rgb 1 1 1



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
    E.el [ iconFont, bigFont, E.centerX, E.paddingXY 24 0, Font.color warningColor ]
        (E.text "\u{F071}")


bigWarningIcon : E.Element msg
bigWarningIcon =
    E.el
        [ iconFont, Font.size 48, E.alignLeft, E.alignTop, E.padding 0, Font.color warningColor ]
        (E.text "\u{F071}")


incomeIcon : E.Element msg
incomeIcon =
    E.el [ iconFont, normalFont, E.centerX, Font.color fgIncome ]
        (E.text "\u{F067}")


expenseIcon : E.Element msg
expenseIcon =
    E.el [ iconFont, normalFont, E.centerX, Font.color fgExpense ]
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
document title activePage activeDialog closeMsg showFocus =
    { title = title
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
        , Background.color bgPage
        , fontFamily
        , normalFont
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
            , Border.color bgWhite -- bgDark
            ]
            page
        ]


titledRow : String -> List (E.Element msg) -> E.Element msg
titledRow title elems =
    E.column
        [ E.width E.fill
        , E.height E.shrink
        , E.paddingEach { top = 24, bottom = 24, right = 64, left = 64 }
        , E.spacing 6
        , Background.color bgWhite
        ]
        [ E.el
            [ E.width E.shrink
            , E.height E.fill
            , Font.color fgTitle
            , normalFont
            , Font.bold
            , E.paddingEach { top = 0, bottom = 12, left = 0, right = 0 }
            , notSelectable
            ]
            (E.text title)
        , E.row
            [ E.width E.fill
            , E.paddingEach { top = 0, bottom = 0, left = 24, right = 0 }
            ]
            elems
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
                                [ Font.color fgTitle
                                , E.mouseDown [ Background.color bgMouseDown ]
                                , E.mouseOver [ Background.color bgMouseOver ]
                                ]

                            Input.Focused ->
                                [ E.mouseDown [ Background.color bgMouseDown ]
                                , E.mouseOver [ Background.color bgMouseOver ]
                                ]

                            Input.Selected ->
                                [ Font.color (E.rgb 1 1 1)
                                , Background.color bgMainButton
                                , smallShadow
                                , mouseDown [ Background.color bgMainButtonDown ]
                                , mouseOver [ Background.color bgMainButton ]
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
        , Font.color fgTitle
        ]
        element


ruler : E.Element msg
ruler =
    E.el
        [ E.width E.fill
        , E.height (E.px borderWidth)
        , E.paddingXY 48 0
        ]
        (E.el [ E.width E.fill, E.height E.fill, Background.color fgDark ] E.none)


warningParagraph : List (E.Element msg) -> E.Element msg
warningParagraph elements =
    E.row
        [ normalFont
        , Font.color fgBlack
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
        , Background.color bgWhite
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
                    , Font.color fgTitle
                    , Border.widthEach { top = 0, bottom = 0, left = 0, right = 0 }
                    , Background.color bgButton
                    , Border.color bgDark
                    , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                    , smallShadow
                    , transition
                    , mouseDown [ Background.color bgButtonDown ]
                    , mouseOver [ Background.color bgButtonOver ]
                    ]
                    { label =
                        E.row
                            [ E.width E.fill ]
                            [ E.el [ bigFont, Font.color fgTitle, E.centerX ]
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
                    , Font.color fgTitle
                    , Border.widthEach { top = 0, bottom = 0, left = 0, right = 0 }
                    , Background.color bgButton
                    , Border.color bgDark
                    , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }
                    , smallShadow
                    , transition
                    , mouseDown [ Background.color bgButtonDown ]
                    , mouseOver [ Background.color bgButtonOver ]
                    ]
                    { label =
                        E.row
                            [ E.width E.fill ]
                            [ E.el [ E.centerX, iconFont, normalFont ] (E.text "  \u{F061}  ")
                            , E.el [ bigFont, Font.color fgTitle, E.centerX ]
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
                Font.color fgDarker

              else if isExpense then
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
        [ Background.color bgButton
        , normalFont
        , Font.color fgTitle
        , Font.center
        , roundCorners
        , Border.width 0
        , Border.color fgDark
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color bgButtonDown ]
        , mouseOver [ Background.color bgButtonOver ]
        ]
        { onPress = onPress
        , label = label
        }


mainButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
mainButton { onPress, label } =
    Input.button
        [ Background.color bgTitle
        , normalFont
        , Font.color fgWhite
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color bgTitle
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color bgMainButtonDown, Border.color bgMainButtonDown ]
        , mouseOver [ Background.color bgMainButtonOver, Border.color bgMainButtonOver ]
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
        , Background.color bgIncomeButton
        , normalFont
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color bgIncomeButton
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color bgIncomeButtonDown, Border.color bgIncomeButtonDown ]
        , mouseOver [ Background.color bgIncomeButtonOver, Border.color bgIncomeButtonOver ]
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
        , Background.color bgExpenseButton
        , normalFont
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color bgExpenseButton
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color bgExpenseButtonDown, Border.color bgExpenseButtonDown ]
        , mouseOver [ Background.color bgExpenseButtonOver, Border.color bgExpenseButtonOver ]
        ]
        { onPress = onPress
        , label = label
        }


iconButton :
    { onPress : Maybe msg, icon : E.Element msg }
    -> E.Element msg
iconButton { onPress, icon } =
    Input.button
        [ Background.color bgPage
        , normalFont
        , Font.color fgTitle
        , Font.center
        , roundCorners
        , E.padding 8
        , E.width (E.shrink |> E.minimum 64)
        , E.height (E.px 48)
        , E.mouseDown [ Background.color bgMouseDown ]
        , E.mouseOver [ Background.color bgMouseOver ]
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
        , Font.color fgTitle
        , Font.center
        , E.width (E.px 48)
        , E.height (E.px 48)
        , E.alignRight
        , Background.color (E.rgba 1 1 1 1)
        , Border.rounded 0
        , Border.width borderWidth
        , Border.color fgDark
        , E.padding 2
        , innerShadow
        , transition
        , E.mouseDown [ Background.color bgMouseDown ]
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
                    [ Font.color fgWhite
                    , Background.color bgMainButton
                    , smallShadow
                    , mouseDown [ Background.color bgMainButtonDown ]
                    , mouseOver [ Background.color bgMainButton ]
                    ]

                else
                    [ Font.color fgTitle
                    , Background.color bgWhite
                    , E.mouseDown [ Background.color bgMouseDown ]
                    , E.mouseOver [ Background.color bgMouseOver ]
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
