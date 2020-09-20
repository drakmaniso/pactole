module Page.Statistics exposing (view)

import Dict
import Element as E
import Element.Font as Font
import Ledger
import Money
import Page.Summary as Summary
import Page.Widgets as Widgets
import Shared
import Style
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
            [ Widgets.dateNavigation shared
            , E.el [ E.height E.fill ] E.none
            , viewItem
                "Entrées d'argent: "
                (Ledger.getMonthlyIncome shared.ledger shared.date)
            , if shared.settings.categoriesEnabled then
                viewCategories shared

              else
                E.none
            , if shared.settings.categoriesEnabled then
                viewItem
                    "Sans catégorie: "
                    (Ledger.getMonthlyCategory shared.ledger shared.date 0)

              else
                viewItem
                    "Dépenses: "
                    (Ledger.getMonthlyExpense shared.ledger shared.date)
            , E.el [ E.height E.fill ] E.none
            ]
        }


viewCategories : Shared.Model -> E.Element Shared.Msg
viewCategories shared =
    E.column
        [ E.width E.fill
        , E.paddingXY 0 0
        ]
        (Dict.toList shared.categories
            |> List.map
                (\( catID, category ) ->
                    viewItem (category.name ++ ": ") (Ledger.getMonthlyCategory shared.ledger shared.date catID)
                )
        )


viewItem description money =
    E.row
        [ E.width E.fill
        , E.paddingXY 48 12
        ]
        [ E.el [ Style.normalFont, Font.alignRight, E.width (E.fillPortion 3) ] (E.text description)
        , Widgets.viewMoney money
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]
