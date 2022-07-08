module Page.Reconcile exposing (viewContent)

import Date exposing (Date)
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


viewContent : Model -> E.Element Msg
viewContent model =
    let
        em =
            model.context.em
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clip
        ]
        [ viewReconciled model
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.scrollbarY
            , E.clipX
            , Ui.scrollboxShadows
            ]
            [ viewTransactions model
            , E.el [ E.centerX, E.paddingXY (em // 2) (em * 2) ] <|
                Ui.flatButton
                    { label =
                        E.paragraph []
                            [ E.el [ Ui.iconFont, E.paddingXY (em // 2) 0 ] <| E.text "\u{F063}"
                            , E.text "  afficher plus  "
                            , E.el [ Ui.iconFont, E.paddingXY (em // 2) 0 ] <| E.text "\u{F063}"
                            ]
                    , onPress = Just Msg.IncreaseNbMonthsDisplayed
                    }
            ]
        ]


viewReconciled : Model -> E.Element msg
viewReconciled model =
    E.column
        [ E.width E.fill
        , E.padding <| model.context.em // 2
        , Font.color Color.neutral20
        ]
        [ E.row
            [ E.width E.fill ]
            [ E.el [ E.width E.fill ] E.none
            , E.el
                [ Ui.bigFont model.context
                ]
                (E.text "Solde pointé:")
            , Ui.viewBalance model.context (Ledger.getReconciled model.ledger model.account)
            , E.el [ E.width E.fill ] E.none
            ]
        ]


viewTransactions : Model -> E.Element Msg
viewTransactions model =
    let
        transactions =
            Ledger.getLastXMonthsTransactions model.ledger model.account model.today model.nbMonthsDisplayed
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , Font.color Color.neutral20
        ]
        (transactions
            |> List.foldr
                (\t ( rows, d ) ->
                    let
                        newRow =
                            rowTransaction model t
                    in
                    if Date.compare d t.date /= EQ && List.length rows /= 0 then
                        ( newRow :: rowDate model d :: rows, t.date )

                    else
                        ( newRow :: rows, t.date )
                )
                ( [], Date.default )
            |> (\( rows, d ) ->
                    case rows of
                        _ :: _ ->
                            rowDate model d :: rows

                        _ ->
                            rows
               )
        )


rowDate : Model -> Date -> E.Element Msg
rowDate model date =
    let
        em =
            model.context.em
    in
    E.el
        [ E.width <| E.maximum (24 * model.context.em) <| E.fill
        , E.centerX
        , E.paddingEach
            { top = 2 * em
            , bottom = em // 4
            , left = em // 4
            , right = em // 4
            }
        , Font.color Color.neutral50
        ]
    <|
        E.text <|
            Date.toString date


rowTransaction : Model -> Ledger.Transaction -> E.Element Msg
rowTransaction model transaction =
    let
        em =
            model.context.em
    in
    E.row
        [ E.width <| E.maximum (24 * em) <| E.fill
        , E.centerX
        , E.paddingXY (em // 2) (em // 8)
        , E.spacing 0
        ]
        [ colReconciled model transaction
        , buttonTransaction model transaction
        ]


buttonTransaction : Model -> Ledger.Transaction -> E.Element Msg
buttonTransaction model transaction =
    let
        em =
            model.context.em
    in
    Input.button
        [ E.width <| E.maximum (20 * em) <| E.fill
        , E.padding <| em // 4 + em // 8
        , Border.width 4
        , Border.color Color.transparent
        , Ui.focusVisibleOnly
        , E.mouseDown [ Background.color Color.neutral80 ]
        , E.mouseOver [ Background.color Color.neutral95 ]
        ]
        { onPress =
            Just <|
                Msg.OpenDialog Msg.DontFocusInput <|
                    Model.TransactionDialog
                        { id = Just transaction.id
                        , isExpense = Money.isExpense transaction.amount
                        , isRecurring = False
                        , date = transaction.date
                        , amount = ( Money.absToString transaction.amount, Nothing )
                        , description = transaction.description
                        , category = transaction.category
                        }
        , label =
            E.row
                [ E.width E.fill, E.height E.fill ]
                [ colAmount model transaction model.today
                , colCategory model transaction
                , colDescription model transaction
                ]
        }


colReconciled : Model -> Ledger.Transaction -> E.Element Msg
colReconciled model transaction =
    let
        em =
            model.context.em
    in
    E.el
        [ E.centerX
        , E.alignTop
        , E.padding (em // 4)
        ]
    <|
        Ui.reconcileCheckBox model.context
            { state = transaction.checked
            , onPress = Just (Msg.ForDatabase <| Msg.CheckTransaction transaction (not transaction.checked))
            }


colAmount : Model -> Ledger.Transaction -> Date -> E.Element msg
colAmount model transaction today =
    let
        future =
            Date.compare transaction.date today == GT
    in
    E.el [ E.alignTop ] <| Ui.viewMoney model.context transaction.amount future


colCategory : Model -> Ledger.Transaction -> E.Element msg
colCategory model transaction =
    let
        em =
            model.context.em

        category =
            Model.category transaction.category model
    in
    if model.settings.categoriesEnabled then
        if transaction.category == 0 then
            E.el
                [ E.width <| E.minimum (2 * em + em // 2) <| E.shrink
                , E.centerX
                , E.alignTop
                , Font.center
                , Font.color Color.neutral80
                , Font.bold
                ]
                (E.text "•")

        else
            E.el
                [ E.width <| E.minimum (2 * em + em // 2) <| E.shrink
                , E.centerX
                , E.alignTop
                , Font.center
                , Font.color Color.neutral20
                , Ui.iconFont
                ]
                (E.text <| category.icon)

    else
        E.none


colDescription : Model -> Ledger.Transaction -> E.Element msg
colDescription _ transaction =
    E.paragraph
        [ E.alignTop
        ]
    <|
        [ E.text <|
            Ledger.getTransactionDescription transaction
        ]
