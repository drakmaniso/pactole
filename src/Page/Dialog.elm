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
    let
        bg =
            case dialog of
                Common.NewExpense ->
                    Style.bgExpense

                Common.EditExpense _ ->
                    Style.bgExpense

                Common.NewIncome ->
                    Style.bgIncome

                Common.EditIncome _ ->
                    Style.bgIncome
    in
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
            case dialog of
                Common.NewExpense ->
                    ( Style.bgExpense, "Nouvelle dépense" )

                Common.EditExpense _ ->
                    ( Style.bgExpense, "Dépense" )

                Common.NewIncome ->
                    ( Style.bgIncome, "Nouvelle entrée d'argent" )

                Common.EditIncome _ ->
                    ( Style.bgIncome, "Entrée d'argent" )
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
            case dialog of
                Common.NewExpense ->
                    Style.fgExpense

                Common.EditExpense _ ->
                    Style.fgExpense

                Common.NewIncome ->
                    Style.fgIncome

                Common.EditIncome _ ->
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
                    (text model.dialogAmountInfo)
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
            , text = model.dialogAmount
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
            case dialog of
                Common.NewExpense ->
                    Style.fgExpense

                Common.EditExpense _ ->
                    Style.fgExpense

                Common.NewIncome ->
                    Style.fgIncome

                Common.EditIncome _ ->
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
            , text = model.dialogDescription
            , placeholder = Nothing
            , onChange = Msg.DialogDescription
            , spellcheck = True
            }
        ]


buttonsRow dialog model =
    let
        ( fg, msg, isEdit ) =
            case dialog of
                Common.NewExpense ->
                    ( Style.fgExpense, Msg.ConfirmNew (Money.fromInput True model.dialogAmount), False )

                Common.EditExpense id ->
                    ( Style.fgExpense, Msg.ConfirmEdit id (Money.fromInput True model.dialogAmount), True )

                Common.NewIncome ->
                    ( Style.fgIncome, Msg.ConfirmNew (Money.fromInput False model.dialogAmount), False )

                Common.EditIncome id ->
                    ( Style.fgIncome, Msg.ConfirmEdit id (Money.fromInput False model.dialogAmount), True )
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
        , if isEdit then
            Input.button
                (Style.button shrink fg (rgba 0 0 0 0) False)
                { label = text "Supprimer", onPress = Just Msg.Delete }

          else
            none
        , Input.button
            (Style.button shrink fg Style.bgWhite True)
            { label = text "Confirmer"
            , onPress = Just msg
            }
        ]
