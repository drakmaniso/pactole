module Page.Dialog exposing (view)

import Common
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Ledger
import Money
import Msg
import Style


view : Common.Dialog -> Common.Model -> Element Msg.Msg
view dialog model =
    column
        [ centerX
        , centerY
        , width (px 800)
        , height shrink
        , Border.rounded 7
        , paddingXY 24 0
        , spacing 0
        , scrollbarY
        , Background.color Style.bgWhite
        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 16, color = rgba 0 0 0 0.5 }
        ]
        [ titleRow dialog model
        , amountRow dialog model
        , descriptionRow dialog model
        , el [ height fill, Background.color Style.bgWhite ] none
        , buttonsRow dialog model
        ]


titleRow dialog model =
    let
        ( bg, label ) =
            case ( dialog.id, dialog.isExpense ) of
                ( Nothing, False ) ->
                    ( Style.bgIncome, "Nouvelle entrée d'argent" )

                ( Nothing, True ) ->
                    ( Style.bgExpense, "Nouvelle dépense" )

                ( Just _, False ) ->
                    ( Style.bgIncome, "Entrée d'argent" )

                ( Just _, True ) ->
                    ( Style.bgExpense, "Dépense" )
    in
    row
        [ alignLeft
        , width fill
        , paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
        , spacing 12
        , Background.color Style.bgWhite
        , Border.widthEach { top = 0, bottom = 3, left = 0, right = 0 }
        , Border.color Style.bgDark
        ]
        [ el
            [ width fill, Font.center, Style.bigFont, Font.bold, Font.color bg ]
            (text label)
        ]


amountRow dialog model =
    let
        fg =
            if dialog.isExpense then
                Style.fgExpense

            else
                Style.fgIncome
    in
    row
        [ alignLeft
        , width fill
        , paddingEach { top = 64, bottom = 32, right = 48, left = 48 }
        , spacing 12
        , Background.color Style.bgWhite
        ]
        [ Input.text
            [ Style.bigFont
            , paddingXY 8 12
            , width (shrink |> minimum 220)
            , alignLeft
            , Border.width 1
            , Border.color Style.bgDark
            , htmlAttribute <| HtmlAttr.id "dialog-amount"
            , below
                (el
                    [ Style.smallFont
                    , width fill
                    , paddingEach { top = 8, bottom = 8, left = 0, right = 0 }
                    , Font.center
                    , Font.color (rgb 0 0 0)
                    ]
                    (text dialog.amountError)
                )
            ]
            { label =
                Input.labelLeft
                    [ Input.focusedOnLoad
                    , Style.bigFont
                    , width shrink
                    , alignLeft
                    , height fill
                    , Font.color fg
                    , Font.alignRight
                    , paddingEach { top = 12, bottom = 12, left = 0, right = 24 }
                    , Border.width 1
                    , Border.color (rgba 0 0 0 0)
                    , pointer
                    ]
                    (text "Somme:")
            , text = dialog.amount
            , placeholder = Nothing
            , onChange = Msg.DialogAmount
            }
        , el
            [ Style.bigFont
            , Font.color fg
            , paddingXY 0 12
            , width shrink
            , alignLeft
            , Border.width 1
            , Border.color (rgba 0 0 0 0)
            ]
            (text "€")
        , el
            [ width fill ]
            none
        ]


descriptionRow dialog model =
    let
        fg =
            if dialog.isExpense then
                Style.fgExpense

            else
                Style.fgIncome
    in
    row
        [ width fill
        , paddingEach { top = 12, bottom = 24, right = 48, left = 48 }
        , spacing 12
        , Background.color Style.bgWhite
        ]
        [ Input.multiline
            [ Style.bigFont
            , paddingXY 8 12
            , Border.width 1
            , Border.color Style.bgDark
            , width fill
            , scrollbarY
            ]
            { label =
                Input.labelLeft
                    [ width shrink
                    , height fill
                    , Font.color fg
                    , Font.alignRight
                    , paddingEach { top = 12, bottom = 12, left = 0, right = 24 }
                    , Border.width 1
                    , Border.color (rgba 0 0 0 0)
                    , pointer
                    ]
                    (text "Description:")
            , text = dialog.description
            , placeholder = Nothing
            , onChange = Msg.DialogDescription
            , spellcheck = True
            }
        ]


buttonsRow dialog model =
    let
        fg =
            if dialog.isExpense then
                Style.fgExpense

            else
                Style.fgIncome
    in
    row
        [ width fill
        , spacing 24
        , paddingEach { top = 64, bottom = 12, left = 24, right = 24 }
        , Background.color Style.bgWhite
        ]
        [ Input.button
            (alignRight :: Style.button shrink fg (rgba 0 0 0 0) False)
            { label = text "Annuler", onPress = Just Msg.Close }
        , case dialog.id of
            Just _ ->
                Input.button
                    (Style.button shrink fg (rgba 0 0 0 0) False)
                    { label = text "Supprimer", onPress = Just Msg.Delete }

            Nothing ->
                none
        , Input.button
            (Style.button shrink fg Style.bgWhite True)
            { label = text "Confirmer"
            , onPress = Just Msg.DialogConfirm
            }
        ]
