module Ui exposing
    ( Device
    , backIcon
    , bigFont
    , bigWarningIcon
    , biggestFont
    , boldText
    , borderWidth
    , checkIcon
    , classifyDevice
    , closeIcon
    , configCustom
    , dangerButton
    , dateNavigationBar
    , defaultFontSize
    , defaultShadow
    , deleteIcon
    , dialogSection
    , dialogSectionRow
    , editIcon
    , errorIcon
    , expenseButton
    , expenseIcon
    , flatButton
    , focusVisibleOnly
    , fontFamily
    , helpImage
    , helpList
    , helpListItem
    , helpMiniButton
    , helpNumberedList
    , iconButton
    , iconFont
    , incomeButton
    , incomeIcon
    , innerShadow
    , labelLeft
    , loadIcon
    , mainButton
    , minusIcon
    , moneyInput
    , notSelectable
    , onEnter
    , pageTitle
    , paragraph
    , paragraphParts
    , plusIcon
    , radioButton
    , radioRowOption
    , reconcileCheckBox
    , roundCorners
    , ruler
    , saveIcon
    , simpleButton
    , smallFont
    , smallerFont
    , text
    , textColumn
    , textInput
    , title
    , toggleSwitch
    , transition
    , verticalSpacer
    , viewDate
    , viewIcon
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
    , em : Int
    }


classifyDevice : { width : Int, height : Int, fontSize : Int } -> Device
classifyDevice { width, height, fontSize } =
    let
        eDevice =
            E.classifyDevice { width = width, height = height }

        contentWidth =
            case eDevice.orientation of
                E.Portrait ->
                    width

                E.Landscape ->
                    round <| 2 * toFloat width / 3
    in
    { width = width
    , height = height
    , class = eDevice
    , em =
        if fontSize >= 6 && fontSize <= 128 then
            fontSize

        else if contentWidth >= 960 then
            26

        else if contentWidth <= 360 then
            16

        else
            round <| 16 + (toFloat contentWidth - 360) / 60
    }



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


focusVisibleOnly : E.Attribute msg
focusVisibleOnly =
    E.htmlAttribute <| Html.Attributes.class "focus-visible-only"


transition : E.Attribute msg
transition =
    E.htmlAttribute <| Html.Attributes.class "button-transition"


defaultShadow : E.Attribute msg
defaultShadow =
    {- E.htmlAttribute <|
       Html.Attributes.style "box-shadow"
           """
           32px 64px 32px 0px rgba(0, 0, 0, 0.01),
           16px 32px 16px 0px rgba(0, 0, 0, 0.02),
           8px 16px 8px 0px rgba(0, 0, 0, 0.04),
           4px 8px 4px 0px rgba(0, 0, 0, 0.08),
           2px 4px 2px 0px rgba(0, 0, 0, 0.08),
           1px 2px 1px 0px rgba(0, 0, 0, 0.08),
           0px 1px 1px 0px rgba(0, 0, 0, 0.16)
           """
    -}
    E.htmlAttribute <| Html.Attributes.class "button-shadow"


smallShadow : E.Attribute msg
smallShadow =
    E.htmlAttribute <|
        Html.Attributes.style "box-shadow"
            """
            8px 16px 8px 0px rgba(0, 0, 0, 0.01),
            4px 8px 4px 0px rgba(0, 0, 0, 0.02),
            2px 4px 2px 0px rgba(0, 0, 0, 0.04),
            1px 2px 1px 0px rgba(0, 0, 0, 0.08),
            0px 1px 1px 0px rgba(0, 0, 0, 0.16)
            """


innerShadow : E.Attribute msg
innerShadow =
    Border.innerShadow { offset = ( 0, 1 ), size = 0, blur = 4, color = E.rgba 0 0 0 0.5 }



-- FONTS


fontFamily : String -> E.Attribute msg
fontFamily font =
    Font.family
        [ Font.typeface font

        -- , Font.sansSerif
        ]


fontScale : Device -> Int -> Int
fontScale device n =
    E.modular (device.em |> toFloat) 1.4 n |> round


biggestFont : Device -> E.Attr decorative msg
biggestFont device =
    Font.size <| fontScale device 3


bigFont : Device -> E.Attr decorative msg
bigFont device =
    Font.size <| fontScale device 2


defaultFontSize : Device -> E.Attr decorative msg
defaultFontSize device =
    Font.size <| fontScale device 1


smallFont : Device -> E.Attr decorative msg
smallFont device =
    Font.size <| fontScale device -1


smallerFont : Device -> E.Attr decorative msg
smallerFont device =
    Font.size <| fontScale device -2


iconFont : E.Attribute msg
iconFont =
    Font.family [ Font.typeface "Font Awesome 5 Free" ]



-- ICONS


closeIcon : E.Element msg
closeIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F00D}")


backIcon : E.Element msg
backIcon =
    E.el [ iconFont ]
        (E.text "\u{F30A}")


editIcon : E.Element msg
editIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F044}")


deleteIcon : E.Element msg
deleteIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F2ED}")


minusIcon : E.Element msg
minusIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F068}")


plusIcon : E.Element msg
plusIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F067}")


checkIcon : E.Element msg
checkIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F00C}")


warningIcon : E.Element msg
warningIcon =
    E.el [ iconFont, E.centerX, E.paddingXY 24 0, Font.color Color.warning60 ]
        (E.text "\u{F071}")


errorIcon : E.Element msg
errorIcon =
    E.el [ iconFont, E.centerX, E.paddingXY 24 0, Font.color Color.white ]
        (E.text "\u{F071}")


bigWarningIcon : E.Element msg
bigWarningIcon =
    E.el
        [ iconFont, Font.size 48, E.alignLeft, E.alignTop, E.padding 0, Font.color Color.warning60 ]
        (E.text "\u{F071}")


incomeIcon : E.Element msg
incomeIcon =
    E.el [ iconFont, E.centerX, Font.color Color.income40 ]
        (E.text "\u{F067}")


expenseIcon : E.Element msg
expenseIcon =
    E.el [ iconFont, E.centerX, Font.color Color.expense40 ]
        (E.text "\u{F068}")


saveIcon : E.Element msg
saveIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F0C7}")


loadIcon : E.Element msg
loadIcon =
    E.el [ iconFont, E.centerX ]
        (E.text "\u{F2EA}")



-- CONTAINERS


toggleSwitch :
    Device
    ->
        { label : String
        , checked : Bool
        , onChange : Bool -> msg
        }
    -> E.Element msg
toggleSwitch device { label, checked, onChange } =
    Input.checkbox
        [ E.width E.fill
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        ]
        { label =
            Input.labelLeft
                [ E.paddingEach { bottom = 0, top = 0, left = 0, right = device.em } ]
                (E.el [] (E.text label))
        , checked = checked
        , onChange = onChange
        , icon =
            \v ->
                if v then
                    E.el
                        [ E.width <| E.px <| 2 * device.em
                        , E.height <| E.px <| device.em
                        , E.htmlAttribute <| Html.Attributes.style "transform" "translate(0px,2px)"
                        , E.behindContent <|
                            E.el
                                [ E.centerY
                                , E.width <| E.px <| 2 * device.em
                                , E.height <| E.px <| device.em
                                , Border.rounded device.em
                                , Background.color Color.primary85
                                , innerShadow
                                , transition
                                ]
                                E.none
                        , E.inFront <|
                            E.el
                                [ E.alignRight
                                , E.centerY
                                , E.width <| E.px <| device.em + 4
                                , E.height <| E.px <| device.em + 4
                                , E.htmlAttribute <| Html.Attributes.style "transform" "translate(+2px,-2px)"
                                , Border.rounded device.em
                                , Background.color Color.primary40
                                , smallShadow
                                , transition
                                , E.mouseOver [ Background.color Color.primary50 ]
                                , E.mouseDown [ Background.color Color.primary30 ]
                                ]
                                E.none
                        ]
                        E.none

                else
                    E.el
                        [ E.width <| E.px <| 2 * device.em
                        , E.height <| E.px <| device.em
                        , E.htmlAttribute <| Html.Attributes.style "transform" "translate(0px,2px)"
                        , E.behindContent <|
                            E.el
                                [ E.centerY
                                , E.width <| E.px <| 2 * device.em
                                , E.height <| E.px <| device.em
                                , Border.rounded device.em
                                , Background.color Color.neutral95
                                , innerShadow
                                , transition
                                ]
                                E.none
                        , E.inFront <|
                            E.el
                                [ E.alignLeft
                                , E.centerY
                                , E.width <| E.px <| device.em + 4
                                , E.height <| E.px <| device.em + 4
                                , E.htmlAttribute <| Html.Attributes.style "transform" "translate(-2px,-2px)"
                                , Border.rounded device.em
                                , Background.color Color.neutral70
                                , smallShadow
                                , transition
                                , E.mouseOver [ Background.color Color.neutral80 ]
                                , E.mouseDown [ Background.color Color.neutral60 ]
                                ]
                                E.none
                        ]
                        E.none
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
                                , E.mouseDown [ Background.color Color.primary30 ]
                                , E.mouseOver [ Background.color Color.primary40 ]
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


pageTitle : Device -> E.Element msg -> E.Element msg
pageTitle device element =
    E.row
        [ E.centerX
        , E.width E.fill
        , E.paddingEach { top = 3, bottom = 8, left = 2 * device.em, right = 2 * device.em }
        ]
        [ E.el
            [ bigFont device
            , Font.center
            , Font.bold
            , E.paddingEach { top = 4, bottom = 8, left = 12, right = 12 }
            , E.width E.fill
            , E.centerY
            , Background.color Color.neutral95
            , Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 32, bottomRight = 32 }
            , Font.color Color.neutral40
            , Font.center
            , smallShadow
            ]
            element
        ]


dialogSectionRow : E.Color -> String -> E.Element msg -> E.Element msg
dialogSectionRow titleColor titleText content =
    E.row [ E.width E.fill, E.spacing 24 ]
        [ E.el
            [ Font.color titleColor
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


warningParagraph : List (E.Element msg) -> E.Element msg
warningParagraph elements =
    E.row
        [ Font.color Color.neutral20
        , E.centerY
        , E.spacing 12
        , E.width E.fill
        , E.height (E.shrink |> E.minimum 48)
        ]
        [ bigWarningIcon
        , E.paragraph [] elements
        ]


warningPopup : Device -> List (E.Element msg) -> E.Element msg
warningPopup device elements =
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
            , E.spacing 12
            , E.above <|
                E.el
                    [ E.centerX
                    , E.alignBottom
                    , iconFont
                    , biggestFont device
                    , Font.color Color.focus85
                    , notSelectable
                    , E.htmlAttribute <| Html.Attributes.style "transform" "translate(0, 18px)"
                    ]
                <|
                    E.text "\u{F0D8}"
            , E.width <| E.px 380
            , Font.center
            , Font.regular
            , notSelectable
            , smallShadow
            ]
            elements


dateNavigationBar : Device -> { a | date : Date, today : Date } -> (Date -> msg) -> E.Element msg
dateNavigationBar device model changeMsg =
    E.row
        [ E.width E.fill
        , E.paddingEach { top = 3, bottom = 8, left = 2 * device.em, right = 2 * device.em }
        ]
        [ Keyed.row
            [ E.width <| E.fill
            , E.centerX
            , E.alignTop
            , Background.color Color.neutral95
            , Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 32, bottomRight = 32 }
            , smallShadow
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
                        , Background.color Color.neutral95
                        , Border.width 4
                        , Border.color Color.transparent
                        , focusVisibleOnly
                        , transition
                        , E.mouseDown [ Background.color Color.neutral90 ]
                        , E.mouseOver [ Background.color Color.neutral98 ]
                        ]
                        { label =
                            E.row
                                [ E.width E.fill ]
                                [ E.el [ E.centerX ]
                                    (E.text (Date.getMonthName (Date.decrementMonth model.date)))
                                , E.el [ E.centerX, iconFont ] (E.text "  \u{F060}  ")
                                ]
                        , onPress = Just (changeMsg (Date.decrementMonthUI model.date model.today))
                        }
                    )
              )
            , ( "current month header"
              , E.el
                    [ E.width (E.fillPortion 3)
                    , E.height E.fill
                    , notSelectable
                    ]
                    (E.el
                        [ E.centerX
                        , Font.bold
                        , bigFont device
                        , Font.color Color.neutral30
                        , E.padding 6
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
                        , Background.color Color.neutral95
                        , Border.width 4
                        , Border.color Color.transparent
                        , focusVisibleOnly
                        , transition
                        , E.mouseDown [ Background.color Color.neutral90 ]
                        , E.mouseOver [ Background.color Color.neutral98 ]
                        ]
                        { label =
                            E.row
                                [ E.width E.fill ]
                                [ E.el [ E.centerX, iconFont ] (E.text "  \u{F061}  ")
                                , E.el [ E.centerX ]
                                    (E.text (Date.getMonthName (Date.incrementMonth model.date)))
                                ]
                        , onPress = Just (changeMsg (Date.incrementMonthUI model.date model.today))
                        }
                    )
              )
            ]
        ]


viewIcon : String -> E.Element msg
viewIcon txt =
    E.el [ E.width (E.shrink |> E.minimum 48), iconFont, Font.center ]
        (E.text txt)


viewDate : Device -> Date -> E.Element msg
viewDate device date =
    E.paragraph
        [ E.width E.fill
        , Font.bold
        , bigFont device
        , E.paddingEach { top = 0, bottom = 12, right = 0, left = 0 }
        , Font.color Color.neutral30
        , Font.center
        ]
        [ E.text
            (Date.getWeekdayName date
                ++ " "
                ++ String.fromInt (Date.getDay date)
                ++ " "
                ++ Date.getMonthName date
            )
        ]


viewMoney : Device -> Money.Money -> Bool -> E.Element msg
viewMoney device money future =
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
            , Font.variant Font.tabularNumbers
            , Font.alignRight
            ]
            (if isZero then
                [ E.el [ E.width (E.fillPortion 75), defaultFontSize device, Font.alignRight ] (E.text "—")
                , E.el [ E.width (E.fillPortion 25) ] E.none
                ]

             else
                [ E.el
                    [ E.width (E.fillPortion 75)
                    , defaultFontSize device
                    , Font.bold
                    , Font.alignRight
                    ]
                    (E.text (openpar ++ parts.sign ++ parts.units ++ ","))
                , E.row
                    [ E.width (E.fillPortion 25) ]
                    [ E.el
                        [ Font.bold
                        , smallFont device
                        , Font.alignLeft
                        ]
                        (E.text ("" ++ parts.cents))
                    , E.el
                        [ defaultFontSize device
                        , Font.bold
                        , Font.alignRight
                        ]
                        (E.text closepar)
                    ]
                ]
            )
        ]


viewSum : Device -> Money.Money -> E.Element msg
viewSum device money =
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
            , bigFont device
            , Font.alignRight
            , Font.bold
            ]
            (E.text (parts.sign ++ parts.units))
        , E.el
            [ E.width (E.fillPortion 25)
            , defaultFontSize device
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
        , Font.color Color.neutral30
        , Font.center
        , roundCorners
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , defaultShadow
        , transition
        , E.paddingXY 20 4
        , E.mouseDown [ Background.color Color.neutral90 ]
        , E.mouseOver [ Background.color Color.neutral98 ]
        , E.htmlAttribute <| Html.Attributes.class "focus-visible-only"
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
        , Font.color Color.white
        , Font.center
        , roundCorners
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , defaultShadow
        , transition
        , E.paddingXY 20 4
        , E.mouseDown [ Background.color Color.primary30, Border.color Color.primary30 ]
        , E.mouseOver [ Background.color Color.primary50, Border.color Color.primary50 ]
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
        , Font.color Color.white
        , Font.center
        , roundCorners
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , defaultShadow
        , transition
        , E.paddingXY 20 4
        , E.mouseDown [ Background.color Color.warning50, Border.color Color.warning50 ]
        , E.mouseOver [ Background.color Color.warning70, Border.color Color.warning70 ]
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
        , Font.center
        , roundCorners
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , defaultShadow
        , transition
        , E.paddingXY 20 4
        , E.mouseDown [ Background.color Color.income80, Border.color Color.income80 ]
        , E.mouseOver [ Background.color Color.income95, Border.color Color.income95 ]
        , E.htmlAttribute <| Html.Attributes.class "focus-visible-only"
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
        , Font.center
        , roundCorners
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , defaultShadow
        , transition
        , E.paddingXY 20 4
        , E.mouseDown [ Background.color Color.expense80, Border.color Color.expense80 ]
        , E.mouseOver [ Background.color Color.expense95, Border.color Color.expense95 ]
        , focusVisibleOnly
        ]
        { onPress = onPress
        , label = label
        }


flatButton :
    { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
flatButton { onPress, label } =
    Input.button
        [ Background.color Color.transparent
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , transition
        , E.paddingXY 20 4
        , Font.color Color.primary40
        , E.mouseDown [ Font.color Color.primary30 ]
        , E.mouseOver [ Font.color Color.primary50 ]
        , E.htmlAttribute <| Html.Attributes.class "focus-visible-only"
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
        , Font.color Color.primary40
        , Font.center
        , roundCorners
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , E.padding 4
        , E.width (E.shrink |> E.minimum 64)
        , E.height (E.px 48)
        , E.mouseDown [ Background.color Color.neutral90 ]
        , E.mouseOver [ Background.color Color.neutral95 ]
        ]
        { onPress = onPress
        , label = icon
        }


reconcileCheckBox :
    { state : Bool, onPress : Maybe msg, background : E.Color }
    -> E.Element msg
reconcileCheckBox { state, onPress, background } =
    Input.button
        [ Font.color Color.primary40
        , Font.center
        , E.width (E.px 48)
        , E.height (E.px 48)
        , E.alignRight
        , Background.color (E.rgba 1 1 1 1)
        , Border.width 4
        , Border.color background
        , focusVisibleOnly
        , E.padding 2
        , innerShadow
        , transition
        , E.mouseDown [ Background.color Color.neutral90 ]
        , E.mouseOver []
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
        ([ Border.rounded 4
         , E.paddingXY 20 4
         , Border.width 4
         , Border.color Color.transparent
         , focusVisibleOnly
         , transition
         ]
            ++ (if active then
                    [ Font.color Color.white
                    , Background.color Color.primary40
                    , smallShadow
                    , E.mouseDown [ Background.color Color.primary30 ]
                    , E.mouseOver [ Background.color Color.primary40 ]
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


labelLeft : String -> Input.Label msg
labelLeft txt =
    Input.labelLeft [ E.paddingEach { left = 0, right = 12, top = 0, bottom = 0 } ] (E.text txt)


textInput : { width : Int, label : Input.Label msg, text : String, onChange : String -> msg } -> E.Element msg
textInput args =
    Input.text
        [ E.width <| E.fill
        , Border.width 4
        , Border.color Color.white
        , Background.color Color.neutral98
        , innerShadow
        , E.focused
            [ Border.color Color.focus85
            ]
        , Font.color Color.neutral20
        , E.htmlAttribute <| Html.Attributes.autocomplete False
        ]
        { label = args.label
        , text = args.text
        , placeholder = Nothing
        , onChange = args.onChange
        }


moneyInput :
    Device
    ->
        { label : Input.Label msg
        , color : E.Color
        , state : ( String, Maybe String )
        , onChange : String -> msg
        }
    -> E.Element msg
moneyInput device args =
    let
        minWidth =
            6 * device.em
    in
    Input.text
        [ E.paddingXY 8 12
        , E.width (E.shrink |> E.minimum minWidth)
        , E.alignLeft
        , Border.width 4
        , Border.color Color.white
        , Background.color Color.neutral98
        , innerShadow
        , E.focused
            [ Border.color Color.focus85
            ]
        , E.htmlAttribute <| Html.Attributes.id "dialog-focus"
        , E.htmlAttribute <| Html.Attributes.autocomplete False
        , Font.color args.color
        , case Tuple.second args.state of
            Just error ->
                E.below <|
                    warningPopup device
                        [ E.text error ]

            _ ->
                E.below <| E.none
        ]
        { label = args.label
        , text = Tuple.first args.state
        , placeholder = Nothing
        , onChange = args.onChange
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


helpList : List (E.Element msg) -> E.Element msg
helpList listItems =
    let
        withBullet para =
            E.row []
                [ E.column [ E.height E.fill ]
                    [ E.el [ E.paddingXY 6 0 ] (E.text "•")
                    , E.el [ E.height E.fill ] E.none
                    ]
                , para
                ]
    in
    E.column [ E.spacing 24 ]
        (List.map withBullet listItems)


helpNumberedList : List (E.Element msg) -> E.Element msg
helpNumberedList listItems =
    let
        withBullet index para =
            E.row
                []
                [ E.column [ E.height E.fill, E.spacing 0 ]
                    [ E.el [ E.width (E.px 48), Font.center ] (E.text (String.fromInt (index + 1) ++ "."))
                    , E.el [ E.height E.fill ] E.none
                    ]
                , para
                ]
    in
    E.column
        [ E.spacing 24
        ]
        (List.indexedMap withBullet listItems)


helpListItem : List (E.Element msg) -> E.Element msg
helpListItem texts =
    E.paragraph
        [ Font.color Color.neutral30
        , E.padding 0
        ]
        texts


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
        , Border.width 4
        , Border.color Color.transparent
        , focusVisibleOnly
        , E.mouseDown [ Font.color Color.primary30 ]
        , E.mouseOver [ Font.color Color.primary50 ]
        , transition
        ]
        { label = label
        , onPress = Just onPress
        }



-- TEXT


textColumn : Device -> List (E.Element msg) -> E.Element msg
textColumn device elements =
    E.column
        [ E.width E.fill
        , E.spacing device.em
        ]
        (elements
            |> List.map
                (\el ->
                    E.el
                        [ E.centerX
                        , E.width <| E.maximum (paragraphWidth device) <| E.fill
                        , E.padding 6
                        ]
                        el
                )
        )


paragraphWidth : Device -> Int
paragraphWidth device =
    let
        w =
            32 * device.em
    in
    if w > 940 then
        940

    else
        w


title : Device -> String -> E.Element msg
title device txt =
    E.paragraph
        [ bigFont device
        , Font.bold
        , Font.color Color.neutral30
        ]
        [ E.text txt ]


verticalSpacer : E.Element msg
verticalSpacer =
    E.el [ E.height (E.px 0) ] E.none


paragraph : String -> E.Element msg
paragraph txt =
    E.paragraph
        [ Font.color Color.neutral30
        ]
        [ E.text txt ]


paragraphParts : List (E.Element msg) -> E.Element msg
paragraphParts parts =
    E.paragraph
        [ Font.color Color.neutral30
        ]
        parts


text : String -> E.Element msg
text txt =
    E.text txt


boldText : String -> E.Element msg
boldText txt =
    E.el [ Font.bold ] (E.text txt)
