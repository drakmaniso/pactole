module Ui exposing
    ( backIcon
    , bigWarningIcon
    , configCustom
    , configRadio
    , dateNavigationBar
    , deleteIcon
    , editIcon
    , iconButton
    , mainButton
    , onEnter
    , pageTitle
    , pageWithSidePanel
    , plusIcon
    , radioRowOption
    , settingsButton
    , simpleButton
    , viewMoney
    , warningIcon
    , warningParagraph
    )

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
import Shared
import Style



-- COLORS


warningColor =
    E.rgb 0.82 0.47 0.0



-- CONTAINERS


pageWithSidePanel :
    List (E.Attribute msg)
    ->
        { panel : List (E.Element msg)
        , page : List (E.Element msg)
        }
    -> E.Element msg
pageWithSidePanel attributes { panel, page } =
    E.row
        ([ E.width E.fill
         , E.height E.fill
         , E.clipX
         , E.clipY
         , Background.color Style.bgPage
         , Style.fontFamily
         , Style.normalFont
         ]
            ++ attributes
        )
        [ E.column
            [ E.width (E.fillPortion 1)
            , E.height E.fill
            , E.padding 16
            , E.alignTop
            ]
            panel
        , E.column
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            , Border.widthEach { top = 0, left = borderWidth, bottom = 0, right = 0 }
            , Border.color Style.bgDark
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
                 , Style.bigFont
                 ]
                    ++ (case state of
                            Input.Idle ->
                                [ Font.color Style.fgTitle ]

                            Input.Focused ->
                                []

                            Input.Selected ->
                                [ Font.color (E.rgb 1 1 1), Background.color Style.bgTitle ]
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



-- ICONS


backIcon attributes =
    E.el ([ Style.fontIcons, Style.normalFont ] ++ attributes)
        (E.text "\u{F30A}")


editIcon attributes =
    E.el ([ Style.fontIcons, Style.normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F044}")


deleteIcon attributes =
    E.el ([ Style.fontIcons, Style.normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F2ED}")


plusIcon attributes =
    E.el ([ Style.fontIcons, Style.normalFont, E.centerX ] ++ attributes)
        (E.text "\u{F067}")


warningIcon attributes =
    E.el ([ Style.fontIcons, Style.bigFont, E.centerX, E.paddingXY 24 0, Font.color warningColor ] ++ attributes)
        (E.text "\u{F071}")


bigWarningIcon attributes =
    E.el
        ([ Style.fontIcons, Font.size 48, E.alignLeft, E.padding 12, Font.color warningColor ]
            ++ attributes
        )
        (E.text "\u{F071}")



-- ELEMENTS


pageTitle : List (E.Attribute msg) -> E.Element msg -> E.Element msg
pageTitle attributes element =
    E.el
        ([ Style.bigFont
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
        ([ Font.color warningColor
         , Style.smallFont
         , Font.color Style.fgBlack
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



-- INTERACTIVE ELEMENTS


simpleButton :
    List (E.Attribute msg)
    -> { onPress : Maybe msg, label : E.Element msg }
    -> E.Element msg
simpleButton attributes { onPress, label } =
    Input.button
        ([ Background.color Style.bgPage
         , Style.normalFont
         , Font.color Style.fgTitle
         , Font.center
         , roundCorners
         , Border.width borderWidth
         , Border.color Style.fgDark
         , E.paddingXY 24 8
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
        ([ Background.color Style.bgTitle
         , Style.normalFont
         , Font.color Style.fgWhite
         , Font.center
         , roundCorners
         , Border.width borderWidth
         , Border.color Style.bgTitle
         , E.paddingXY 24 8
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
        ([ Background.color Style.bgPage
         , Style.normalFont
         , Font.color Style.fgTitle
         , Font.center
         , roundCorners
         , E.padding 8
         , E.width (E.px 48)
         , E.height (E.px 48)
         ]
            ++ attributes
        )
        { onPress = onPress
        , label = icon
        }


settingsButton :
    List (E.Attribute msg)
    -> { onPress : Maybe msg, enabled : Bool }
    -> E.Element msg
settingsButton attributes { onPress, enabled } =
    if enabled then
        Input.button
            ([ Background.color Style.bgPage
             , Style.normalFont
             , Font.color Style.fgTitle
             , Font.center
             , roundCorners
             , E.padding 2
             , E.width (E.px 36)
             , E.height (E.px 36)
             ]
                ++ attributes
            )
            { onPress = onPress
            , label = E.el [ Style.fontIcons, Style.normalFont, E.centerX ] (E.text "\u{F013}")
            }

    else
        Input.button
            ([ Background.color Style.bgPage
             , Style.normalFont
             , Font.color Style.fgTitle
             , Font.center
             , roundCorners
             , E.padding 2
             , E.width (E.px 36)
             , E.height (E.px 36)
             ]
                ++ attributes
            )
            { onPress = Nothing
            , label =
                E.el [ Style.fontIcons, Style.normalFont, E.centerX, Font.color Style.bgLight ]
                    (E.text "\u{F013}")
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



-- CONSTANTS


borderWidth =
    2


roundCorners =
    Border.rounded 24
