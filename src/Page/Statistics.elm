module Page.Statistics exposing (view)

import Dict
import Element as E
import Element.Border as Border
import Element.Font as Font
import Ledger
import Model
import Money
import Msg
import Page.Summary as Summary
import Ui



-- VIEW


view : Model.Model -> E.Element Msg.Msg
view shared =
    Ui.pageWithSidePanel
        { panel =
            E.column
                [ E.width E.fill
                , E.height E.fill
                , E.clipX
                , E.clipY
                ]
                [ E.el
                    [ E.width E.fill, E.height (E.fillPortion 1) ]
                    (Summary.view shared)
                , E.el
                    [ E.width E.fill, E.height (E.fillPortion 2) ]
                    E.none
                ]
        , page =
            E.column
                [ E.width E.fill
                , E.height E.fill
                , E.clipX
                , E.clipY
                ]
                [ Ui.dateNavigationBar shared
                , viewMonthBalance shared
                , viewMonthFutureWarning shared
                , E.column
                    [ E.width E.fill
                    , E.height E.fill
                    , E.scrollbarY
                    , Border.widthEach { top = Ui.borderWidth, bottom = 0, right = 0, left = 0 }
                    , Border.color Ui.fgDark
                    ]
                    [ E.el [ E.height E.fill ] E.none
                    , viewItem
                        ""
                        "Entrées d'argent: "
                        (Ledger.getIncomeForMonth shared.ledger shared.account shared.date shared.today)
                    , if shared.settings.categoriesEnabled then
                        viewCategories shared

                      else
                        E.none
                    , if shared.settings.categoriesEnabled then
                        viewItem
                            ""
                            "Sans catégorie: "
                            (Ledger.getCategoryTotalForMonth shared.ledger shared.account shared.date shared.today 0)

                      else
                        viewItem
                            ""
                            "Dépenses: "
                            (Ledger.getExpenseForMonth shared.ledger shared.account shared.date shared.today)
                    , E.text " "
                    , E.el [ E.height E.fill ] E.none
                    ]
                ]
        }


viewMonthBalance : Model.Model -> E.Element msg
viewMonthBalance shared =
    let
        monthBal =
            Ledger.getTotalForMonth shared.ledger shared.account shared.date shared.today
    in
    E.row
        [ E.width E.fill
        , E.paddingXY 48 24
        , Font.color Ui.fgBlack
        ]
        [ E.el [ E.width (E.fillPortion 2) ] E.none
        , E.el
            [ Ui.biggerFont, Font.alignRight ]
            (E.text "Bilan du mois: ")
        , Ui.viewSum monthBal
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]


viewMonthFutureWarning : Model.Model -> E.Element msg
viewMonthFutureWarning shared =
    if
        Ledger.hasFutureTransactionsForMonth shared.recurring shared.account shared.date shared.today
            || Ledger.hasFutureTransactionsForMonth shared.ledger shared.account shared.date shared.today
    then
        E.row
            [ E.width E.fill
            , E.paddingEach { top = 0, bottom = 24, left = 48, right = 48 }
            , Ui.normalFont
            , Font.color Ui.fgDarker
            ]
            [ E.el [ E.width (E.fillPortion 2) ] E.none
            , E.el
                [ Font.alignRight ]
                (E.text "(sans compter les futures opérations)")
            , E.el [ E.width (E.fillPortion 2) ] E.none
            ]

    else
        E.none


viewCategories : Model.Model -> E.Element Msg.Msg
viewCategories shared =
    E.column
        [ E.width E.fill
        , E.paddingXY 0 0
        ]
        (Dict.toList shared.categories
            |> List.map
                (\( catID, category ) ->
                    viewItem
                        category.icon
                        (category.name ++ ": ")
                        (Ledger.getCategoryTotalForMonth shared.ledger shared.account shared.date shared.today catID)
                )
        )


viewItem : String -> String -> Money.Money -> E.Element msg
viewItem icon description money =
    E.row
        [ E.width E.fill
        , E.paddingXY 48 12
        ]
        [ E.row [ E.width (E.fillPortion 3), E.spacing 12 ]
            [ E.el [ E.width E.fill ] E.none
            , E.el [ Ui.iconFont, Font.center ] (E.text icon)
            , E.el [ Ui.normalFont, Font.alignRight ] (E.text description)
            ]
        , Ui.viewMoney money False
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]
