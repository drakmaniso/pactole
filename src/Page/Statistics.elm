module Page.Statistics exposing (view)

import Dict
import Element as E
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
                        (Ledger.getMonthlyIncome shared.ledger shared.date)
                    , if shared.settings.categoriesEnabled then
                        viewCategories shared

                      else
                        E.none
                    , if shared.settings.categoriesEnabled then
                        viewItem
                            ""
                            "Sans catégorie: "
                            (Ledger.getMonthlyCategory shared.ledger shared.date 0)

                      else
                        viewItem
                            ""
                            "Dépenses: "
                            (Ledger.getMonthlyExpense shared.ledger shared.date)
                    , E.text " "
                    , E.el [ E.height E.fill ] E.none
                    ]
                ]
        }


viewMonthBalance shared =
    let
        monthBal =
            Ledger.getMonthlyTotal shared.ledger shared.date
    in
    E.row
        [ E.width E.fill
        , E.paddingXY 48 24
        ]
        [ E.el [ E.width (E.fillPortion 2) ] E.none
        , E.el
            [ Ui.biggerFont, Font.alignRight ]
            (E.text "Bilan du mois: ")
        , Ui.viewSum monthBal
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]


viewCategories : Shared.Model -> E.Element Shared.Msg
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
                        (Ledger.getMonthlyCategory shared.ledger shared.date catID)
                )
        )


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
        , Ui.viewMoney money
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]
