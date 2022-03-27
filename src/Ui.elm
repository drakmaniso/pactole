module Ui exposing
    ( Device
    , backIcon
    , bigFont
    , bigInnerShadow
    , bigWarningIcon
    , biggerFont
    , biggestFont
    , borderWidth
    , checkBox
    , checkIcon
    , closeIcon
    , configCustom
    , configRadio
    , dangerButton
    , dateNavigationBar
    , defaultShadow
    , deleteIcon
    , device
    , dialogSection
    , dialogSectionRow
    , editIcon
    , errorIcon
    , expenseButton
    , expenseIcon
    , fontFamily
    , helpImage
    , helpList
    , helpListItem
    , helpMiniButton
    , helpNumberedList
    , helpParagraph
    , helpSectionTitle
    , helpText
    , helpTextColumn
    , iconButton
    , iconFont
    , incomeButton
    , incomeIcon
    , innerShadow
    , loadIcon
    , logo
    , mainButton
    , minusIcon
    , mouseDown
    , mouseOver
    , normalFont
    , notSelectable
    , onEnter
    , pageTitle
    , plusIcon
    , radioButton
    , radioRowOption
    , roundCorners
    , ruler
    , saveIcon
    , simpleButton
    , smallFont
    , smallShadow
    , smallerFont
    , smallerShadow
    , transition
    , verySmallFont
    , viewDate
    , viewMoney
    , viewSum
    , warningIcon
    , warningParagraph
    , warningPopup
    )

import Date exposing (Date)
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
import Ui.Color as Color



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


smallerShadow : E.Attr decorative msg
smallerShadow =
    Border.shadow { offset = ( 0, 3 ), size = 0, blur = 3, color = E.rgba 0 0 0 0.3 }


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
    E.el [ iconFont, bigFont, E.centerX, E.paddingXY 24 0, Font.color Color.warning60 ]
        (E.text "\u{F071}")


errorIcon : E.Element msg
errorIcon =
    E.el [ iconFont, normalFont, E.centerX, E.paddingXY 24 0, Font.color Color.white ]
        (E.text "\u{F071}")


bigWarningIcon : E.Element msg
bigWarningIcon =
    E.el
        [ iconFont, Font.size 48, E.alignLeft, E.alignTop, E.padding 0, Font.color Color.warning60 ]
        (E.text "\u{F071}")


incomeIcon : E.Element msg
incomeIcon =
    E.el [ iconFont, normalFont, E.centerX, Font.color Color.income40 ]
        (E.text "\u{F067}")


expenseIcon : E.Element msg
expenseIcon =
    E.el [ iconFont, normalFont, E.centerX, Font.color Color.expense40 ]
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
                                [ Font.color Color.neutral30
                                , E.mouseDown [ Background.color Color.neutral90 ]
                                , E.mouseOver [ Background.color Color.neutral95 ]
                                ]

                            Input.Focused ->
                                [ E.mouseDown [ Background.color Color.neutral90 ]
                                , E.mouseOver [ Background.color Color.neutral95 ]
                                ]

                            Input.Selected ->
                                [ Font.color (E.rgb 1 1 1)
                                , Background.color Color.primary40
                                , smallShadow
                                , mouseDown [ Background.color Color.primary30 ]
                                , mouseOver [ Background.color Color.primary40 ]
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
    E.row
        [ E.width E.fill
        , E.paddingEach { top = 0, bottom = 8, left = 8, right = 8 }
        ]
        [ E.el [ E.width (E.fill |> E.maximum 64) ] E.none
        , E.el
            [ bigFont
            , Font.center
            , Font.bold
            , E.paddingEach { top = 4, bottom = 8, left = 12, right = 12 }
            , E.width E.fill
            , E.centerY
            , Background.color Color.neutral95
            , Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 32, bottomRight = 32 }
            , smallerShadow
            , Font.color Color.neutral40
            , Font.center
            ]
            element
        , E.el [ E.width (E.fill |> E.maximum 64) ] E.none
        ]


dialogSectionRow : E.Color -> String -> E.Element msg -> E.Element msg
dialogSectionRow titleColor titleText content =
    E.row [ E.width E.fill, E.spacing 24 ]
        [ E.el
            [ Font.color titleColor
            , normalFont
            , Font.bold
            , E.padding 0
            , notSelectable
            ]
            (E.text titleText)
        , content
        ]


dialogSection : E.Color -> String -> E.Element msg -> E.Element msg
dialogSection titleColor titleText content =
    E.column [ E.width E.fill, E.spacing 12 ]
        [ E.el
            [ E.width E.fill
            , Font.color titleColor
            , normalFont
            , Font.bold
            , E.padding 0
            , notSelectable
            ]
            (E.text titleText)
        , E.el [ E.width E.fill, E.paddingXY 0 0 ] content
        ]


ruler : E.Element msg
ruler =
    E.el
        [ E.width E.fill
        , E.height (E.px borderWidth)
        , E.paddingXY 48 0
        ]
        (E.el [ E.width E.fill, E.height E.fill, Background.color Color.neutral90 ] E.none)


logo : String -> E.Element msg
logo version =
    E.column [ E.width E.fill, E.height E.fill ]
        [ E.el [ E.width E.fill, E.height E.fill ] E.none
        , E.row [ E.width E.fill, E.height E.shrink ]
            [ E.el [ E.width E.fill, E.height E.fill ] E.none
            , E.image [ E.width (E.fillPortion 2) ]
                { src = "images/icon-512x512.png"
                , description = "Pactole Logo"
                }
            , E.el [ E.width E.fill, E.height E.fill ] E.none
            ]
        , E.el
            [ smallFont
            , E.centerX
            , Font.color Color.neutral50
            , E.paddingEach { left = 0, top = 12, bottom = 0, right = 0 }
            ]
            (E.text ("version " ++ version))
        , E.el [ E.width E.fill, E.height E.fill ] E.none
        ]


warningParagraph : List (E.Element msg) -> E.Element msg
warningParagraph elements =
    E.row
        [ normalFont
        , Font.color Color.neutral20
        , E.centerY
        , E.spacing 12
        , E.width E.fill
        , E.height (E.shrink |> E.minimum 48)
        ]
        [ bigWarningIcon
        , E.paragraph [] elements
        ]


warningPopup : List (E.Element msg) -> E.Element msg
warningPopup elements =
    E.el
        [ E.padding 18
        , E.centerX
        , notSelectable
        , E.htmlAttribute <| Html.Attributes.style "cursor" "default"
        ]
    <|
        E.paragraph
            [ Font.color Color.neutral10
            , Background.color Color.focus85
            , E.centerY
            , E.spacing 12
            , E.height (E.shrink |> E.minimum 48)
            , E.centerX
            , E.paddingEach { left = 24, right = 24, top = 12, bottom = 12 }
            , E.spacing 6
            , Border.rounded 6
            , smallerShadow
            , E.spacing 12
            , E.above <|
                E.el
                    [ E.centerX
                    , E.alignBottom
                    , iconFont
                    , biggestFont
                    , Font.color Color.focus85
                    , notSelectable
                    , E.htmlAttribute <| Html.Attributes.style "transform" "translate(0, 18px)"
                    ]
                <|
                    E.text "\u{F0D8}"
            , E.width <| E.px 380
            , Font.center
            , normalFont
            , Font.regular
            , notSelectable
            ]
            elements


dateNavigationBar : { a | showFocus : Bool, date : Date, today : Date } -> (Date -> msg) -> E.Element msg
dateNavigationBar model changeMsg =
    E.row
        [ E.width E.fill
        , E.paddingEach { top = 0, bottom = 8, left = 8, right = 8 }
        ]
        [ E.el [ E.width (E.fill |> E.maximum 64) ] E.none
        , Keyed.row
            [ E.width E.fill
            , E.alignTop
            , Background.color Color.neutral95
            , Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 32, bottomRight = 32 }
            , smallerShadow
            ]
            [ ( "previous month button"
              , E.el
                    [ E.width (E.fillPortion 2)
                    , E.height E.fill
                    ]
                    (Input.button
                        [ E.width E.fill
                        , E.height E.fill
                        , Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 0, bottomRight = 0 }
                        , Font.color Color.neutral30
                        , Border.widthEach { top = 0, bottom = 0, left = 0, right = 0 }
                        , Background.color Color.neutral95
                        , Border.color Color.neutral90
                        , Border.widthEach { left = 0, top = 0, bottom = 0, right = 0 }
                        , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }

                        -- , smallShadow
                        , transition
                        , mouseDown [ Background.color Color.neutral90 ]
                        , mouseOver [ Background.color Color.neutral98 ]
                        ]
                        { label =
                            E.row
                                [ E.width E.fill ]
                                [ E.el [ normalFont, E.centerX ]
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
                        , Font.color Color.neutral30
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
                        , Border.roundEach { topLeft = 0, bottomLeft = 0, topRight = 32, bottomRight = 32 }
                        , Font.color Color.neutral30
                        , Border.widthEach { top = 0, bottom = 0, left = 0, right = 0 }
                        , Background.color Color.neutral95
                        , Border.color Color.neutral90
                        , Border.widthEach { left = 0, top = 0, bottom = 0, right = 0 }
                        , E.paddingEach { top = 4, bottom = 8, left = 0, right = 0 }

                        -- , smallShadow
                        , transition
                        , mouseDown [ Background.color Color.neutral90 ]
                        , mouseOver [ Background.color Color.neutral98 ]
                        ]
                        { label =
                            E.row
                                [ E.width E.fill ]
                                [ E.el [ E.centerX, iconFont, normalFont ] (E.text "  \u{F061}  ")
                                , E.el [ normalFont, E.centerX ]
                                    (E.text (Date.getMonthName (Date.incrementMonth model.date)))
                                ]
                        , onPress = Just (changeMsg (Date.incrementMonthUI model.date model.today))
                        }
                    )
              )
            ]
        , E.el [ E.width (E.fill |> E.maximum 64) ] E.none
        ]


viewDate : Date -> E.Element msg
viewDate date =
    E.el
        [ E.width E.fill
        , Font.bold
        , bigFont
        , E.paddingEach { top = 0, bottom = 12, right = 0, left = 0 }
        , Font.color Color.neutral30
        , Font.center
        ]
        (E.text
            (Date.getWeekdayName date
                ++ " "
                ++ String.fromInt (Date.getDay date)
                ++ " "
                ++ Date.getMonthName date
            )
        )


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
                Font.color Color.neutral50

              else if isExpense then
                Font.color Color.expense40

              else if isZero then
                Font.color Color.neutral70

              else
                Font.color Color.income40
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
        [ Background.color Color.neutral95
        , normalFont
        , Font.color Color.neutral30
        , Font.center
        , roundCorners
        , Border.width 0
        , Border.color Color.neutral70
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color Color.neutral90 ]
        , mouseOver [ Background.color Color.white ]
        ]
        { onPress = onPress
        , label = label
        }


mainButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
mainButton { onPress, label } =
    Input.button
        [ Background.color Color.primary40
        , normalFont
        , Font.color Color.white
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color Color.primary40
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color Color.primary30, Border.color Color.primary30 ]
        , mouseOver [ Background.color Color.primary50, Border.color Color.primary50 ]
        ]
        { onPress = onPress
        , label = label
        }


dangerButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
dangerButton { onPress, label } =
    Input.button
        [ Background.color Color.warning60
        , normalFont
        , Font.color Color.white
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color Color.warning60
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color Color.warning50, Border.color Color.warning50 ]
        , mouseOver [ Background.color Color.warning70, Border.color Color.warning70 ]
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
        , Background.color Color.income90
        , normalFont
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color Color.income90
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color Color.income80, Border.color Color.income80 ]
        , mouseOver [ Background.color Color.income95, Border.color Color.income95 ]
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
        , Background.color Color.expense90
        , normalFont
        , Font.center
        , roundCorners
        , Border.width borderWidth
        , Border.color Color.expense90
        , defaultShadow
        , transition
        , E.paddingXY 24 8
        , mouseDown [ Background.color Color.expense80, Border.color Color.expense80 ]
        , mouseOver [ Background.color Color.expense95, Border.color Color.expense95 ]
        ]
        { onPress = onPress
        , label = label
        }


iconButton :
    { onPress : Maybe msg, icon : E.Element msg }
    -> E.Element msg
iconButton { onPress, icon } =
    Input.button
        [ Background.color Color.white
        , normalFont
        , Font.color Color.primary40
        , Font.center
        , roundCorners
        , E.padding 8
        , E.width (E.shrink |> E.minimum 64)
        , E.height (E.px 48)
        , E.mouseDown [ Background.color Color.neutral90 ]
        , E.mouseOver [ Background.color Color.neutral95 ]
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
        , Font.color Color.primary40
        , Font.center
        , E.width (E.px 48)
        , E.height (E.px 48)
        , E.alignRight
        , Background.color (E.rgba 1 1 1 1)
        , Border.rounded 0
        , Border.width borderWidth
        , Border.color Color.neutral70
        , E.padding 2
        , innerShadow
        , transition
        , E.mouseDown [ Background.color Color.neutral90 ]
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
                    [ Font.color Color.white
                    , Background.color Color.primary40
                    , smallShadow
                    , mouseDown [ Background.color Color.primary30 ]
                    , mouseOver [ Background.color Color.primary40 ]
                    ]

                else
                    [ Font.color Color.neutral30
                    , Background.color Color.white
                    , E.mouseDown [ Background.color Color.neutral90 ]
                    , E.mouseOver [ Background.color Color.neutral95 ]
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



-- HELP ELEMENTS


helpTextColumn : List (E.Element msg) -> E.Element msg
helpTextColumn paragraphs =
    E.row [ E.alignLeft, E.width (E.fill |> E.maximum 1200) ]
        [ E.el [ E.alignLeft, E.width (E.fillPortion 1) ] E.none
        , E.textColumn [ E.alignLeft, E.width (E.fillPortion 10) ] paragraphs
        , E.el [ E.alignLeft, E.width (E.fillPortion 1) ] E.none
        ]


helpSectionTitle : String -> E.Element msg
helpSectionTitle txt =
    E.paragraph
        [ bigFont
        , Font.bold
        , E.paddingEach { left = 12, top = 48, bottom = 12, right = 12 }
        ]
        [ E.text txt ]


helpParagraph : List (E.Element msg) -> E.Element msg
helpParagraph texts =
    E.paragraph
        [ normalFont
        , Font.color Color.neutral30
        , E.paddingEach { left = 12, top = 12, bottom = 12, right = 12 }
        ]
        texts


helpList : List (E.Element msg) -> E.Element msg
helpList listItems =
    let
        withBullet para =
            E.row
                [ E.paddingEach { left = 0, top = 6, bottom = 6, right = 0 }
                ]
                [ E.column [ E.height E.fill ]
                    [ E.el [ E.paddingXY 6 0 ] (E.text "•")
                    , E.el [ E.height E.fill ] E.none
                    ]
                , para
                ]
    in
    E.column
        [ E.paddingEach { left = 12, top = 6, bottom = 6, right = 12 }
        ]
        (List.map withBullet listItems)


helpNumberedList : List (E.Element msg) -> E.Element msg
helpNumberedList listItems =
    let
        withBullet index para =
            E.row
                [ E.paddingEach { left = 0, top = 6, bottom = 6, right = 0 }
                ]
                [ E.column [ E.height E.fill, E.spacing 0 ]
                    [ E.el [ E.width (E.px 48), Font.center ] (E.text (String.fromInt (index + 1) ++ "."))
                    , E.el [ E.height E.fill ] E.none
                    ]
                , para
                ]
    in
    E.column
        [ E.paddingEach { left = 12, top = 6, bottom = 6, right = 12 }
        ]
        (List.indexedMap withBullet listItems)


helpListItem : List (E.Element msg) -> E.Element msg
helpListItem texts =
    E.paragraph
        [ normalFont
        , Font.color Color.neutral30
        , E.padding 0
        ]
        texts


helpText : String -> E.Element msg
helpText txt =
    E.text txt


helpImage : String -> String -> E.Element msg
helpImage src description =
    E.image
        [ E.centerX
        ]
        { src = src, description = description }


helpMiniButton : { label : E.Element msg, onPress : msg } -> E.Element msg
helpMiniButton { label, onPress } =
    Input.button
        [ Font.color Color.primary40
        , Font.underline
        , E.mouseDown [ Font.color Color.primary30 ]
        , E.mouseOver [ Font.color Color.primary50 ]
        ]
        { label = label
        , onPress = Just onPress
        }
