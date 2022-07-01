module Page.Statistics exposing (viewContent)

import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Font as Font
import Html.Attributes
import Ledger
import Model exposing (Model)
import Money
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
        , E.padding <|
            if model.context.device.orientation == E.Landscape then
                4

            else
                0
        ]
        [ Ui.monthNavigationBar model.context model.monthDisplayed Msg.DisplayMonth
        , E.el
            [ E.width E.fill
            , E.height E.fill
            , E.clip
            , E.behindContent <|
                if model.context.animationDisabled then
                    E.none

                else
                    viewAnimatedContent model model.monthPrevious animPrevious
            ]
            (viewAnimatedContent model model.monthDisplayed anim)
        ]


viewAnimatedContent : Model -> Date.MonthYear -> String -> E.Element Msg
viewAnimatedContent model monthYear anim =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.scrollbarY
        , E.htmlAttribute <| Html.Attributes.class anim
        , E.htmlAttribute <| Html.Attributes.class "scrollbox"
        , Background.color Color.white
        ]
        [ E.column
            [ E.width E.fill
            , E.height E.fill
            ]
            [ E.el [ E.height E.fill ] E.none
            , viewItem model
                ""
                (if model.context.device.class == E.Phone then
                    "Entrées: "

                 else
                    "Entrées d'argent: "
                )
                (Ledger.getIncomeForMonth model.ledger model.account monthYear model.today)
            , if model.settings.categoriesEnabled then
                viewCategories model monthYear

              else
                E.none
            , if model.settings.categoriesEnabled then
                viewItem model
                    ""
                    "Sans catégorie: "
                    (Ledger.getCategoryTotalForMonth model.ledger model.account monthYear model.today 0)

              else
                viewItem model
                    ""
                    "Dépenses: "
                    (Ledger.getExpenseForMonth model.ledger model.account monthYear model.today)
            , E.el [ E.height <| E.px model.context.smallEm ] E.none
            , E.row
                [ E.height <| E.px 2
                , E.width <| E.maximum (20 * model.context.em) <| E.fill
                , E.centerX
                ]
                [ E.el [ E.width <| E.px model.context.em ] E.none
                , E.el [ E.width E.fill, E.height E.fill, Background.color Color.neutral70 ] E.none
                , E.el [ E.width <| E.px model.context.em ] E.none
                ]
            , E.el [ E.height <| E.px model.context.smallEm ] E.none
            , viewItem model
                ""
                "Bilan du mois: "
                (Ledger.getTotalForMonth model.ledger model.account monthYear model.today)
            , E.el [ E.height E.fill ] E.none
            ]
        ]


viewMonthBalance : Model -> Date.MonthYear -> E.Element msg
viewMonthBalance model monthYear =
    let
        monthBal =
            Ledger.getTotalForMonth model.ledger model.account monthYear model.today
    in
    E.row
        [ E.width E.fill
        , E.padding model.context.em
        , Font.color Color.neutral20
        ]
        [ E.el [ E.width (E.fillPortion 2) ] E.none
        , E.el
            [ Ui.bigFont model.context, Font.alignRight ]
            (E.text "Bilan du mois: ")
        , Ui.viewBalance model.context monthBal
        , E.el [ E.width (E.fillPortion 2) ] E.none
        ]


viewMonthFutureWarning : Model -> Date.MonthYear -> E.Element Msg
viewMonthFutureWarning model monthYear =
    if
        Ledger.hasFutureTransactionsForMonth model.recurring model.account monthYear model.today
            || Ledger.hasFutureTransactionsForMonth model.ledger model.account monthYear model.today
    then
        E.paragraph
            [ E.width E.fill
            , Font.color Color.neutral50
            , Font.center
            ]
            [ E.text "(sans compter les futures opérations)"
            ]

    else
        E.none


viewCategories : Model -> Date.MonthYear -> E.Element Msg
viewCategories model monthYear =
    E.column
        [ E.width E.fill ]
        (model.categories
            |> Dict.toList
            |> List.sortBy (\( _, { name } ) -> name)
            |> List.map
                (\( catID, category ) ->
                    viewItem model
                        category.icon
                        (category.name ++ ": ")
                        (Ledger.getCategoryTotalForMonth model.ledger model.account monthYear model.today catID)
                )
        )


viewItem : Model -> String -> String -> Money.Money -> E.Element msg
viewItem model icon description money =
    let
        em =
            model.context.em
    in
    E.row
        [ E.centerX
        , E.padding <|
            if model.context.device.class == E.Phone then
                em // 4

            else
                em // 2
        , Font.color Color.neutral20
        , E.spacing <| em // 2
        , E.width E.fill
        ]
        [ E.row [ E.width E.fill, E.spacing <| em // 2 ]
            [ E.el [ Ui.iconFont, E.alignRight ] (E.text icon)
            , E.el [ E.alignRight ] <| E.text description
            ]
        , E.row [ E.width E.fill ]
            [ Ui.viewMoney model.context money False
            , E.el [ E.width E.fill ] E.none
            ]
        ]
