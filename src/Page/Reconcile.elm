module Page.Reconcile exposing (viewContent)

import Date exposing (Date)
import Element as E
import Element.Background as Background
import Element.Font as Font
import Html.Attributes
import Ledger
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


viewContent : Model -> E.Element Msg
viewContent model =
    let
        ( anim, animPrevious ) =
            Ui.animationClasses model.context model.monthDisplayed model.monthPrevious
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clip
        ]
        [ viewReconciled model
        , E.el
            [ E.height <| E.px 2
            , E.width <| E.maximum (32 * model.context.em) <| E.fill
            , E.centerX
            , Background.color Color.neutral80
            ]
            E.none
        , E.el
            [ E.width E.fill
            , E.height E.fill
            , E.scrollbarY
            , E.clipX
            ]
          <|
            viewTransactions model
        ]



-- [ Ui.monthNavigationBar model.context model.monthDisplayed Msg.DisplayMonth
-- , E.el
--     [ E.width E.fill
--     , E.height E.fill
--     , E.clip
--     , E.behindContent <|
--         if model.context.animationDisabled then
--             E.none
--         else
--             viewAnimatedContent model model.monthPrevious animPrevious
--     ]
--     (viewAnimatedContent model model.monthDisplayed anim)
-- ]
-- viewAnimatedContent : Model -> Date.MonthYear -> String -> E.Element Msg
-- viewAnimatedContent model monthYear anim =
--     E.column
--         [ E.width E.fill
--         , E.height E.fill
--         , E.scrollbarY
--         , E.htmlAttribute <| Html.Attributes.class anim
--         , Background.color Color.white
--         ]
--         [ viewReconciled model monthYear
--         , viewTransactions model monthYear
--         ]


viewReconciled : Model -> E.Element msg
viewReconciled model =
    E.column
        [ E.width E.fill, E.padding <| model.context.em, E.spacing 24, Font.color Color.neutral20 ]
        [ E.row
            [ E.width E.fill ]
            [ E.el [ E.width E.fill ] E.none
            , E.el [ Ui.bigFont model.context ] (E.text "Solde pointé:")
            , Ui.viewSum model.context (Ledger.getReconciled model.ledger model.account)
            , E.el [ E.width E.fill ] E.none
            ]
        ]


viewTransactions : Model -> E.Element Msg
viewTransactions model =
    let
        em =
            model.context.em

        transactions =
            Ledger.getLastXMonthsTransactions model.ledger model.account model.today 6
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , Font.color Color.neutral20
        ]
        (transactions
            |> List.foldr
                (\t ( l, idx, d ) ->
                    let
                        newRow =
                            rowTransaction model idx t
                    in
                    if Date.compare d t.date /= EQ && List.length l /= 0 then
                        ( newRow :: rowDate model d :: l, idx + 1, t.date )

                    else
                        ( newRow :: l, idx + 1, t.date )
                )
                ( [], 0, Date.default )
            |> (\( l, _, d ) ->
                    case l of
                        _ :: _ ->
                            rowDate model d :: l

                        _ ->
                            l
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
            , bottom = em // 2
            , left = em // 4
            , right = em // 4
            }
        , Font.color Color.neutral50
        ]
    <|
        -- Ui.viewDate model.context date
        E.text
        <|
            Date.toString date


rowTransaction : Model -> Int -> Ledger.Transaction -> E.Element Msg
rowTransaction model idx transaction =
    let
        em =
            model.context.em

        bg =
            if Basics.remainderBy 2 idx == 0 then
                Color.neutral95

            else
                Color.neutral90
    in
    E.row
        [ E.width <| E.maximum (24 * em) <| E.fill
        , E.centerX
        , E.paddingXY (em // 2) (em // 4)
        , E.spacing (em // 2)
        , Background.color bg
        ]
        [ colReconciled model transaction bg
        , colCategory model transaction
        , colDescription model transaction
        , colAmount model transaction model.today
        ]


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
