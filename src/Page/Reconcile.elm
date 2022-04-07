module Page.Reconcile exposing (viewContent, viewPanel)

import Date exposing (Date)
import Element as E
import Element.Background as Background
import Element.Font as Font
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Page.Summary as Summary
import Ui
import Ui.Color as Color


viewPanel : Model -> E.Element Msg
viewPanel model =
    Ui.twoPartsSidePanel
        { top = Summary.view model
        , bottom = E.none
        }


viewContent : Model -> E.Element Msg
viewContent model =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clipY
        , E.padding 3
        ]
        [ Ui.dateNavigationBar model.device model Msg.SelectDate
        , viewReconciled model
        , viewTransactions model
        ]


viewReconciled : Model -> E.Element msg
viewReconciled model =
    let
        prevMonth =
            Date.getMonthName (Date.decrementMonth model.date)
    in
    E.column
        [ E.width E.fill, E.paddingXY 48 24, E.spacing 24, Font.color Color.neutral30 ]
        [ E.row
            [ E.width E.fill ]
            [ E.el [ E.width E.fill ] E.none
            , E.el [ Ui.bigFont model.device ] (E.text "Solde bancaire: ")
            , Ui.viewSum model.device (Ledger.getReconciled model.ledger model.account)
            , E.el [ E.width E.fill ] E.none
            ]
        , if Ledger.getNotReconciledBeforeMonth model.ledger model.account model.date then
            E.el
                [ E.width E.fill, Font.center ]
                (E.paragraph []
                    [ E.text "Attention: il reste des opérations à pointer en "
                    , E.el [ Font.bold ] (E.text prevMonth)
                    ]
                )

          else
            E.none
        ]


viewTransactions : Model -> E.Element Msg
viewTransactions model =
    E.column
        [ E.padding 0
        , E.spacing 0
        , E.width E.fill
        , E.height E.fill
        , E.scrollbarY
        , Font.color Color.neutral30
        ]
        (List.indexedMap
            (\idx transaction ->
                E.row
                    [ E.width E.fill
                    , E.paddingXY 12 18
                    , if Basics.remainderBy 2 idx == 0 then
                        Background.color Color.neutral95

                      else
                        Background.color Color.neutral90
                    ]
                    [ colDate transaction
                    , colReconciled transaction
                    , colAmount model transaction model.today
                    , colDescription transaction
                    ]
            )
            (Ledger.getTransactionsForMonth model.ledger model.account model.date model.today)
        )


colReconciled : Ledger.Transaction -> E.Element Msg
colReconciled transaction =
    E.el
        [ E.width (E.fillPortion 1) ]
        (Ui.checkBox
            { state = transaction.checked
            , onPress = Just (Msg.ForDatabase <| Msg.CheckTransaction transaction (not transaction.checked))
            }
        )


colDate : { a | date : Date } -> E.Element msg
colDate transaction =
    E.el
        [ E.width (E.fillPortion 2), E.alignRight, Font.alignRight ]
        (E.text (Date.toShortString transaction.date))


colAmount : Model -> { a | date : Date, amount : Money.Money } -> Date -> E.Element msg
colAmount model transaction today =
    let
        future =
            Date.compare transaction.date today == GT
    in
    E.el
        [ E.width (E.fillPortion 2) ]
        (Ui.viewMoney model.device transaction.amount future)


colDescription : { a | description : String } -> E.Element msg
colDescription transaction =
    E.el
        [ E.width (E.fillPortion 8), E.clip ]
        (if transaction.description == "" then
            E.el [ Font.color Color.neutral70 ] (E.text "—")

         else
            E.text transaction.description
        )
