module Ui exposing
    ( backIcon
    , column
    , configCustom
    , configRadio
    , deleteIcon
    , editIcon
    , iconButton
    , onEnter
    , pageTitle
    , pageWithSidePanel
    , row
    , simpleButton
    )

import Element as El
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Html.Events as Events
import Json.Decode as Decode
import Style



-- CONTAINERS


pageWithSidePanel :
    List (El.Attribute msg)
    ->
        { panel : List (El.Element msg)
        , page : List (El.Element msg)
        }
    -> El.Element msg
pageWithSidePanel attributes { panel, page } =
    El.row
        ([ El.width El.fill
         , El.height El.fill
         , El.clipX
         , El.clipY
         , Background.color Style.bgPage
         , Style.fontFamily
         , Style.normalFont
         ]
            ++ attributes
        )
        [ El.column
            [ El.width (El.fillPortion 1)
            , El.height El.fill
            , El.padding 16
            , El.alignTop
            ]
            panel
        , El.column
            [ El.width (El.fillPortion 3)
            , El.height El.fill
            , Border.widthEach { top = 0, left = borderWidth, bottom = 0, right = 0 }
            , Border.color Style.bgDark
            ]
            page
        ]


column : List (El.Attribute msg) -> List (El.Element msg) -> El.Element msg
column =
    El.column


row : List (El.Attribute msg) -> List (El.Element msg) -> El.Element msg
row =
    El.row


configRadio :
    List (El.Attribute msg)
    ->
        { label : String
        , options : List (Input.Option option msg)
        , selected : Maybe option
        , onChange : option -> msg
        }
    -> El.Element msg
configRadio attributes { label, options, selected, onChange } =
    Input.radio
        [ El.paddingEach { top = 12, bottom = 24, left = 12 + 64, right = 12 }
        , El.width El.fill
        ]
        { label =
            Input.labelAbove
                [ El.paddingEach { bottom = 0, top = 0, left = 12, right = 12 } ]
                (El.text label)
        , options = options
        , selected = selected
        , onChange = onChange
        }


configCustom :
    List (El.Attribute msg)
    ->
        { label : String
        , content : El.Element msg
        }
    -> El.Element msg
configCustom attributes { label, content } =
    El.column [ El.padding 12, El.width El.fill ]
        [ El.el
            [ El.width El.fill
            , El.paddingEach { top = 0, bottom = 24, right = 0, left = 0 }
            ]
            (El.text label)
        , El.el [ El.paddingEach { left = 64, bottom = 24, right = 0, top = 0 } ] content
        ]



-- ICONS


backIcon attributes =
    El.el ([ Style.fontIcons, Style.normalFont ] ++ attributes)
        (El.text "\u{F060}")


editIcon attributes =
    El.el ([ Style.fontIcons, Style.normalFont, El.centerX ] ++ attributes)
        (El.text "\u{F044}")


deleteIcon attributes =
    El.el ([ Style.fontIcons, Style.normalFont, El.centerX ] ++ attributes)
        (El.text "\u{F2ED}")



-- ELEMENTS


pageTitle : List (El.Attribute msg) -> El.Element msg -> El.Element msg
pageTitle attributes element =
    El.el
        ([ Style.bigFont
         , Font.center
         , Font.bold
         , El.paddingEach { top = 12, bottom = 48, left = 12, right = 12 }
         , El.width El.fill
         ]
            ++ attributes
        )
        element



-- INTERACTIVE ELEMENTS


simpleButton :
    List (El.Attribute msg)
    -> { onPress : Maybe msg, label : El.Element msg }
    -> El.Element msg
simpleButton attributes { onPress, label } =
    Input.button
        ([ Background.color Style.bgPage
         , Style.normalFont
         , Font.color Style.fgTitle
         , Font.center
         , roundCorners
         , Border.width borderWidth
         , Border.color Style.fgDark
         , El.paddingXY 24 8
         ]
            ++ attributes
        )
        { onPress = onPress
        , label = label
        }


iconButton :
    List (El.Attribute msg)
    -> { onPress : Maybe msg, icon : El.Element msg }
    -> El.Element msg
iconButton attributes { onPress, icon } =
    Input.button
        ([ Background.color Style.bgPage
         , Style.normalFont
         , Font.color Style.fgTitle
         , Font.center
         , roundCorners
         , El.padding 8
         , El.width (El.px 48)
         , El.height (El.px 48)
         ]
            ++ attributes
        )
        { onPress = onPress
        , label = icon
        }



-- ATTRIBUTES


onEnter : msg -> El.Attribute msg
onEnter msg =
    El.htmlAttribute
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
