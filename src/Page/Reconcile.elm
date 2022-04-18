module Page.Reconcile exposing (viewContent)

import Date exposing (Date)
import Element as E
import Element.Background as Background
import Element.Font as Font
import Ledger
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


viewContent : Model -> E.Element Msg
viewContent model =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.padding <|
            if model.context.device.orientation == E.Landscape then
                4

            else
                0
        ]
        [ Ui.monthNavigationBar model.context model Msg.SelectDate
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
            , E.el [ Ui.bigFont model.context ] (E.text "Solde bancaire: ")
            , Ui.viewSum model.context (Ledger.getReconciled model.ledger model.account)
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
    let
        em =
            model.context.em
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , Font.color Color.neutral30
        ]
        (List.indexedMap
            (\idx transaction ->
                let
                    bg =
                        if Basics.remainderBy 2 idx == 0 then
                            Color.neutral95

                        else
                            Color.neutral90
                in
                E.el
                    [ E.width E.fill
                    , Background.color bg
                    ]
                    (if model.context.width > 20 * em then
                        E.row
                            [ E.width <| E.maximum (32 * em) <| E.fill
                            , E.centerX
                            , E.paddingXY (em // 4) (em // 4)
                            , E.spacing (em // 2)
                            ]
                            [ colReconciled model transaction bg
                            , colDate model transaction
                            , colAmount model transaction model.today
                            , colCategory model transaction
                            , colDescription model transaction
                            ]

                     else
                        E.row
                            [ E.width <| E.maximum (32 * em) <| E.fill
                            , E.centerX
                            , E.paddingXY (em // 2) (em // 2)
                            , E.spacing (em // 4)
                            ]
                            [ colReconciled model transaction bg
                            , colDate model transaction
                            , E.column [ E.width E.fill, E.height E.fill, E.spacing (em // 4) ]
                                [ colAmount model transaction model.today
                                , E.paragraph [ Font.alignRight ]
                                    [ colDescription model transaction
                                    ]
                                ]
                            ]
                    )
            )
            (Ledger.getTransactionsForMonth model.ledger model.account model.date model.today)
        )


colReconciled : Model -> Ledger.Transaction -> E.Color -> E.Element Msg
colReconciled model transaction bg =
    let
        em =
            model.context.em
    in
    E.el
        [ E.centerX
        , E.centerY
        , E.padding (em // 4)
        ]
    <|
        Ui.reconcileCheckBox model.context
            { background = bg
            , state = transaction.checked
            , onPress = Just (Msg.ForDatabase <| Msg.CheckTransaction transaction (not transaction.checked))
            }


colDate : Model -> Ledger.Transaction -> E.Element msg
colDate model transaction =
    let
        em =
            model.context.em
    in
    E.el
        [ E.width <| E.minimum (3 * em) <| E.shrink, E.alignLeft, Font.alignLeft, E.centerY ]
        (E.text (Date.toShortString transaction.date))


colAmount : Model -> Ledger.Transaction -> Date -> E.Element msg
colAmount model transaction today =
    let
        future =
            Date.compare transaction.date today == GT
    in
    Ui.viewMoney model.context transaction.amount future


colCategory : Model -> Ledger.Transaction -> E.Element msg
colCategory model transaction =
    let
        em =
            model.context.em

        category =
            Model.category transaction.category model
    in
    if model.settings.categoriesEnabled then
        E.el
            [ E.width <| E.minimum (em + em // 2) <| E.shrink, E.centerX, Font.center, Ui.iconFont ]
            (E.text <| category.icon ++ " ")

    else
        E.none


colDescription : Model -> Ledger.Transaction -> E.Element msg
colDescription _ transaction =
    E.paragraph
        [ E.width E.fill
        , E.centerY
        ]
    <|
        [ E.text <|
            Ledger.getTransactionDescription transaction
        ]
