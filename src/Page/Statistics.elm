module Page.Statistics exposing (viewContent, viewPanel)

import Dict
import Element as E
import Element.Font as Font
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Page.Summary as Summary
import Ui
import Ui.Color as Color



-- VIEW


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
        , E.padding 3
        ]
        [ Ui.dateNavigationBar model.device model Msg.SelectDate
        , viewMonthBalance model
        , viewMonthFutureWarning model
        , Ui.ruler
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.scrollbarY
            ]
            [ E.el [ E.height E.fill ] E.none
            , viewItem model
                ""
                "Entrées d'argent: "
                (Ledger.getIncomeForMonth model.ledger model.account model.date model.today)
            , if model.settings.categoriesEnabled then
                viewCategories model

              else
                E.none
            , if model.settings.categoriesEnabled then
                viewItem model
                    ""
                    "Sans catégorie: "
                    (Ledger.getCategoryTotalForMonth model.ledger model.account model.date model.today 0)

              else
                viewItem model
                    ""
                    "Dépenses: "
                    (Ledger.getExpenseForMonth model.ledger model.account model.date model.today)
            , E.text " "
            , E.el [ E.height E.fill ] E.none
            ]
        ]


viewMonthBalance : Model -> E.Element msg
viewMonthBalance model =
    let
        monthBal =
            Ledger.getTotalForMonth model.ledger model.account model.date model.today
    in
    E.row
        [ E.width E.fill
        , E.paddingXY 48 24
        , Font.color Color.neutral30
        ]
        [ E.el [ E.width (E.fillPortion 2) ] E.none
        , E.el
            [ Ui.bigFont model.device, Font.alignRight ]
            (E.text "Bilan du mois: ")
        , Ui.viewSum model.device monthBal
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]


viewMonthFutureWarning : Model -> E.Element msg
viewMonthFutureWarning shared =
    if
        Ledger.hasFutureTransactionsForMonth shared.recurring shared.account shared.date shared.today
            || Ledger.hasFutureTransactionsForMonth shared.ledger shared.account shared.date shared.today
    then
        E.row
            [ E.width E.fill
            , E.paddingEach { top = 0, bottom = 24, left = 48, right = 48 }
            , Font.color Color.neutral50
            ]
            [ E.el [ E.width (E.fillPortion 2) ] E.none
            , E.el
                [ Font.alignRight ]
                (E.text "(sans compter les futures opérations)")
            , E.el [ E.width (E.fillPortion 2) ] E.none
            ]

    else
        E.none


viewCategories : Model -> E.Element Msg
viewCategories model =
    E.column
        [ E.width E.fill
        , E.paddingXY 0 0
        ]
        (Dict.toList model.categories
            |> List.map
                (\( catID, category ) ->
                    viewItem model
                        category.icon
                        (category.name ++ ": ")
                        (Ledger.getCategoryTotalForMonth model.ledger model.account model.date model.today catID)
                )
        )


viewItem : Model -> String -> String -> Money.Money -> E.Element msg
viewItem model icon description money =
    E.row
        [ E.width E.fill
        , E.paddingXY 48 12
        , Font.color Color.neutral30
        ]
        [ E.row [ E.width (E.fillPortion 3), E.spacing 12 ]
            [ E.el [ E.width E.fill ] E.none
            , E.el [ Ui.iconFont, Font.center ] (E.text icon)
            , E.el [ Font.alignRight ] (E.text description)
            ]
        , Ui.viewMoney model.device money False
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]
