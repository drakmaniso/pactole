module View.Dialog exposing (view)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Model
import Msg
import View.Style as Style


view : Model.Dialog -> Model.Model -> Element Msg.Msg
view dialog model =
    column
        [ centerX
        , centerY
        , width (px 800)
        , height shrink
        , Border.rounded 7
        , paddingXY 32 16
        , spacing 24
        , clip
        , Background.color (rgb 1 1 1)
        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 16, color = rgba 0 0 0 0.5 }
        ]
        [ amountRow dialog model
        , descriptionRow dialog model
        , el [ height fill ] none
        , buttonsRow dialog model
        ]


amountRow dialog model =
    let
        ( fg, label ) =
            case dialog of
                Model.NewExpense ->
                    ( Style.fgExpense, "Nouvelle dépense:" )

                Model.EditExpense _ ->
                    ( Style.fgExpense, "Dépense:" )

                Model.NewIncome ->
                    ( Style.fgIncome, "Nouvelle entrée d'argent:" )

                Model.EditIncome _ ->
                    ( Style.fgIncome, "Entrée d'argent:" )
    in
    row
        [ alignLeft
        , width shrink
        , paddingXY 0 8
        , spacing 12
        ]
        [ Input.text
            [ Style.bigFont
            , paddingXY 8 12
            , width (shrink |> minimum 320)
            , alignLeft
            , htmlAttribute <| HtmlAttr.id "dialog-amount"
            , below
                (el
                    [ Style.smallFont
                    , width fill
                    , paddingEach { top = 8, bottom = 0, left = 0, right = 0 }
                    , Font.center
                    , Font.color (rgb 1 0 0)
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
                    ]
                    (text label)
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
                Model.NewExpense ->
                    Style.fgExpense

                Model.EditExpense _ ->
                    Style.fgExpense

                Model.NewIncome ->
                    Style.fgIncome

                Model.EditIncome _ ->
                    Style.fgIncome
    in
    row
        [ width fill
        , paddingXY 0 8
        , spacing 12
        ]
        [ Input.multiline
            [ Style.bigFont
            , paddingXY 8 12
            , Border.width 1
            , width fill
            ]
            { label =
                Input.labelAbove
                    [ width shrink
                    , height fill
                    , Font.color fg
                    , Font.alignRight
                    , paddingEach { top = 12, bottom = 12, left = 0, right = 24 }
                    , Border.width 1
                    , Border.color (rgba 0 0 0 0)
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
        ( fg, isEdit ) =
            case dialog of
                Model.NewExpense ->
                    ( Style.fgExpense, False )

                Model.EditExpense _ ->
                    ( Style.fgExpense, True )

                Model.NewIncome ->
                    ( Style.fgIncome, False )

                Model.EditIncome _ ->
                    ( Style.fgIncome, True )
    in
    row
        [ alignRight
        , spacing 24
        , paddingEach { top = 24, bottom = 0, left = 0, right = 0 }
        ]
        [ Input.button
            (Style.button shrink fg Style.bgWhite False)
            { label = text "Annuler", onPress = Just Msg.Close }
        , if isEdit then
            Input.button
                (Style.button shrink fg Style.bgWhite False)
                { label = text "Supprimer", onPress = Nothing }

          else
            none
        , Input.button
            (Style.button shrink fg Style.bgWhite True)
            { label = text "Confirmer", onPress = Nothing }
        ]
