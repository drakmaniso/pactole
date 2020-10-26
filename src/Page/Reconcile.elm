module Page.Reconcile exposing (view)

import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Ledger
import Money
import Page.Summary as Summary
import Shared
import Ui



-- VIEW


view : Shared.Model -> E.Element Shared.Msg
view shared =
    Ui.pageWithSidePanel []
        { panel =
            [ E.el
                [ E.width E.fill, E.height (E.fillPortion 1) ]
                (Summary.view shared)
            , E.el
                [ E.width E.fill, E.height (E.fillPortion 2) ]
                E.none
            ]
        , page =
            [ Ui.dateNavigationBar shared
            , E.column
                [ E.width E.fill
                , E.height E.fill
                , E.scrollbarY
                ]
                [ viewReconciled shared
                , viewTransactions shared
                ]
            ]
        }


viewReconciled shared =
    let
        prevMonth =
            Date.getMonthName (Date.decrementMonth shared.date)
    in
    E.column
        [ E.width E.fill, E.paddingXY 48 24, E.spacing 24 ]
        [ E.row
            [ E.width E.fill ]
            [ E.el [ E.width E.fill ] E.none
            , E.el [ Ui.biggerFont ] (E.text "Total pointé: ")
            , Ui.viewSum (Ledger.getReconciled shared.ledger)
            , E.el [ E.width E.fill ] E.none
            ]
        , if Ledger.uncheckedBeforeMonth shared.ledger shared.date then
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


viewTransactions shared =
    {-
       E.table
           [ E.paddingXY 48 24, E.spacing 24 ]
           { data = Ledger.getMonthTransactions shared.ledger shared.date
           , columns =
               [ colAmount, colDate, colDescription ]
           }
    -}
    E.column
        [ E.padding 0
        , E.spacing 0
        , E.width E.fill
        , E.height E.fill
        , E.scrollbarY
        , Border.widthEach { top = Ui.borderWidth, bottom = 0, right = 0, left = 0 }
        , Border.color Ui.fgDark
        ]
        (List.indexedMap
            (\idx transaction ->
                E.row
                    [ E.width E.fill
                    , E.paddingXY 12 18

                    -- , E.mouseOver [ Background.color Ui.bgMouseOver ]
                    --, E.pointer
                    , if Basics.remainderBy 2 idx == 0 then
                        Background.color Ui.bgEvenRow

                      else
                        Background.color Ui.bgOddRow
                    ]
                    [ colReconciled transaction
                    , colAmount transaction
                    , colDate transaction
                    , colDescription transaction
                    ]
            )
            (Ledger.getMonthTransactions shared.ledger shared.date)
        )


colReconciled transaction =
    E.el
        [ E.width (E.fillPortion 1) ]
        (Ui.iconButton
            [ E.alignRight
            , Background.color (E.rgba 1 1 1 1)
            , Border.rounded 0
            , Border.width Ui.borderWidth
            , Border.color Ui.fgDark
            , E.padding 2
            ]
            { icon =
                if transaction.checked then
                    Ui.checkIcon [ E.centerX, E.centerY ]

                else
                    E.none
            , onPress = Just (Shared.CheckTransaction transaction (not transaction.checked))
            }
        )


colDate transaction =
    E.el
        [ E.width (E.fillPortion 1) ]
        (E.text (Date.toString transaction.date))


colAmount transaction =
    E.el
        [ E.width (E.fillPortion 1) ]
        (Ui.viewMoney transaction.amount)


colDescription transaction =
    E.el
        [ E.width (E.fillPortion 4) ]
        (if transaction.description == "" then
            E.el [ Font.color Ui.fgDark ] (E.text "—")

         else
            E.text transaction.description
        )
