module Page.Calendar exposing (dayView, viewMonth, viewWeek)

import Date exposing (Date)
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ui
import Ui.Color as Color



-- THE CALENDAR


viewMonth : Model -> E.Element Msg
viewMonth model =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.padding <|
            if model.context.device.orientation == E.Landscape then
                3

            else
                0
        ]
        (Ui.monthNavigationBar model.context model Msg.SelectDate
            :: weekDayNames model
            :: (Date.weeksOfMonth model.date
                    |> List.map
                        (\week ->
                            E.row
                                [ E.width E.fill
                                , E.height E.fill
                                , E.clipY
                                ]
                            <|
                                List.map
                                    (\day ->
                                        if Date.getMonth day == Date.getMonth model.date then
                                            calendarCell model day

                                        else
                                            E.el [ E.width E.fill, E.height E.fill ] E.none
                                    )
                                    week
                        )
               )
        )


viewWeek : Model -> E.Element Msg
viewWeek model =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.spacing <| model.context.em // 4
        ]
        [ Ui.weekNavigationBar model.context model Msg.SelectDate
        , weekDayNames model
        , E.row [ E.width E.fill, E.height E.fill ]
            (Date.daysOfWeek model.date
                |> List.map (\day -> calendarCell model day)
            )
        ]


weekDayNames : Model -> E.Element Msg
weekDayNames model =
    let
        em =
            model.context.em
    in
    if Ui.contentWidth model.context > 28 * em then
        E.row
            [ E.width E.fill
            , E.alignBottom
            , Ui.smallFont model.context
            , Ui.notSelectable
            , Font.color Color.neutral40
            ]
            [ E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Lundi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Mardi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Mercredi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Jeudi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Vendredi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Samedi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Dimanche"))
            ]

    else
        E.none


calendarCell : Model -> Date -> E.Element Msg
calendarCell model day =
    let
        em =
            model.context.em

        smallEm =
            model.context.smallEm

        compact =
            Ui.contentWidth model.context < 26 * model.context.em

        extraCompact =
            compact && model.context.height < 40 * model.context.em

        sel =
            day == model.date
    in
    E.el
        -- Need to wrap the button in E.el because of elm-ui E.focused bug
        [ E.width E.fill
        , E.height E.fill
        , E.clipY
        ]
        (Input.button
            [ E.width E.fill
            , E.height E.fill
            , E.clipY
            , Border.width 3
            , Ui.transition
            , Border.rounded
                (if sel then
                    em // 2

                 else
                    em // 4
                )
            , Border.color
                (if sel then
                    Color.primary40

                 else
                    Color.white
                )
            , Background.color
                (if sel then
                    Color.primary40

                 else
                    Color.neutral95
                )
            , E.mouseDown
                [ Background.color
                    (if sel then
                        Color.primary30

                     else
                        Color.neutral90
                    )
                ]
            , E.mouseOver
                [ Background.color
                    (if sel then
                        Color.primary40

                     else
                        Color.neutral98
                    )
                ]
            , Ui.focusVisibleOnly
            ]
            { label =
                E.column
                    [ E.width E.fill
                    , E.height E.fill
                    , E.clipY
                    ]
                    [ E.el
                        [ E.width E.fill
                        , E.paddingEach { top = 0, bottom = 0, left = 0, right = 0 }
                        , if extraCompact then
                            Ui.smallerFont model.context

                          else
                            Ui.smallFont model.context
                        , Font.center

                        -- , Font.color
                        --     (if sel then
                        --         Color.white
                        --      else
                        --         Color.neutral30
                        --     )
                        , Background.color
                            (if sel then
                                Color.primary95

                             else
                                Color.transparent
                            )
                        , Font.center
                        , if day == model.today then
                            Font.bold

                          else
                            Font.regular
                        ]
                        (E.text <|
                            if day == model.today then
                                "· " ++ (String.fromInt <| Date.getDay day) ++ " ·"

                            else
                                String.fromInt <| Date.getDay day
                        )
                    , E.paragraph
                        [ E.width E.fill
                        , E.height E.fill
                        , E.clip
                        , E.paddingEach
                            { left = 0
                            , right = 0
                            , top =
                                if extraCompact then
                                    0

                                else if compact then
                                    smallEm // 4

                                else
                                    smallEm // 2
                            , bottom = 0
                            }
                        , E.spacing <|
                            if extraCompact then
                                0

                            else if compact then
                                smallEm // 8

                            else
                                smallEm // 2
                        , Ui.smallFont model.context
                        , Font.center
                        , E.centerY
                        , Background.color
                            (if sel then
                                Color.primary95

                             else
                                Color.transparent
                            )
                        ]
                        (cellContentFor model day)
                    ]
            , onPress = Just (Msg.SelectDate day)
            }
        )


cellContentFor : Model -> Date -> List (E.Element Msg)
cellContentFor model day =
    let
        em =
            model.context.em

        smallEm =
            model.context.smallEm

        compact =
            Ui.contentWidth model.context < 26 * model.context.em

        extraCompact =
            compact && model.context.height < 40 * model.context.em

        render transaction =
            let
                future =
                    Date.compare day model.today == GT

                color =
                    if future then
                        Color.neutral60

                    else
                        Color.transactionColor (Money.isExpense transaction.amount)

                parts =
                    Money.toStrings transaction.amount
            in
            if extraCompact then
                E.el
                    [ E.width <| E.px <| smallEm // 2
                    , E.height <| E.px <| smallEm // 2
                    , Background.color color
                    , Border.rounded 1000
                    , Border.width 0
                    , E.htmlAttribute <| Html.Attributes.style "display" "inline-flex"
                    ]
                    E.none

            else if compact then
                E.el
                    [ E.width <| E.px <| smallEm
                    , E.height <| E.px <| smallEm
                    , Background.color color
                    , Border.rounded 1000
                    , E.htmlAttribute <| Html.Attributes.style "display" "inline-flex"
                    ]
                    E.none

            else
                E.el
                    [ Font.color Color.white
                    , Background.color color
                    , Border.rounded 1000
                    , E.htmlAttribute <| Html.Attributes.style "display" "inline-flex"
                    , E.paddingEach { left = em // 4, right = em // 4, top = 0, bottom = 0 }
                    ]
                    (E.paragraph
                        []
                        [ E.el [ Ui.smallFont model.context ] (E.text (parts.sign ++ parts.units))
                        , E.el [ Ui.smallerFont model.context ] (E.text ("," ++ parts.cents))
                        ]
                    )
    in
    (List.map render (Ledger.getTransactionsForDate model.ledger model.account day)
        ++ List.map render (Ledger.getRecurringTransactionsForDate model.recurring model.account day)
    )
        |> List.intersperse
            (if extraCompact then
                E.el
                    [ Ui.smallerFont model.context
                    , E.width <| E.px <| smallEm // 4
                    , E.height <| E.px <| smallEm // 2
                    ]
                    (E.text " ")

             else
                E.el [ Ui.smallFont model.context ] (E.text " ")
            )



-- DAY VIEW


dayView : Model -> E.Element Msg
dayView model =
    let
        em =
            model.context.em
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clip
        ]
        [ E.column
            [ E.width E.fill
            , E.height E.fill
            , E.paddingXY 0 (em // 2)
            , E.spacing (em // 4)
            , Font.color Color.neutral30
            , Font.center
            , Ui.notSelectable
            , E.height <| E.minimum (em * 5) <| E.fill
            , E.scrollbarY
            ]
            [ if model.context.device.orientation == E.Landscape && model.context.height > 28 * em then
                E.el [ E.width E.fill, Font.color Color.neutral40, Ui.smallFont model.context ]
                    (E.text <| Date.fancyDayDescription model.today model.date)

              else
                E.none
            , Ui.viewDate model.context model.date
            , E.column
                [ E.width E.fill
                ]
                (dayContentFor model model.date)
            ]
        , E.row
            [ E.width E.fill
            , E.height E.shrink
            , E.spacing em
            , E.paddingXY em (em // 2)
            ]
            [ Ui.incomeButton
                { label = Ui.incomeIcon
                , onPress = Just (Msg.ForTransaction <| Msg.NewTransaction False model.date)
                }
            , Ui.expenseButton
                { label = Ui.expenseIcon
                , onPress = Just (Msg.ForTransaction <| Msg.NewTransaction True model.date)
                }
            ]
        ]


dayContentFor : Model -> Date -> List (E.Element Msg)
dayContentFor model day =
    let
        em =
            model.context.em

        future =
            Date.compare day model.today == GT

        transactions =
            (Ledger.getTransactionsForDate model.ledger model.account day
                |> List.map
                    (\t ->
                        { id = t.id
                        , isRecurring = False
                        , date = t.date
                        , amount = t.amount
                        , description = t.description
                        , category = t.category
                        }
                    )
            )
                ++ (Ledger.getRecurringTransactionsForDate model.recurring model.account day
                        |> List.map
                            (\t ->
                                { id = t.id
                                , isRecurring = True
                                , date = t.date
                                , amount = t.amount
                                , description = t.description
                                , category = t.category
                                }
                            )
                   )

        render _ transaction =
            let
                category =
                    Model.category transaction.category model
            in
            E.el
                [ E.width E.fill
                , E.padding 0
                ]
                (Input.button
                    [ E.width E.fill
                    , E.paddingEach { top = em // 4, bottom = em // 4, left = em // 2, right = em // 2 }
                    , Border.width 4
                    , Border.color Color.transparent
                    , Ui.focusVisibleOnly
                    , E.mouseDown [ Background.color Color.neutral90 ]
                    , E.mouseOver [ Background.color Color.neutral95 ]
                    , Ui.transition
                    ]
                    { onPress =
                        Just
                            (if transaction.isRecurring then
                                (Msg.ForTransaction << Msg.ShowRecurring) transaction.id

                             else
                                (Msg.ForTransaction << Msg.EditTransaction) transaction.id
                            )
                    , label =
                        E.row
                            [ E.width E.fill
                            ]
                            [ E.el
                                [ E.width (E.fillPortion 3)
                                , E.height E.fill
                                ]
                                (E.column
                                    [ E.width E.fill ]
                                    [ Ui.viewMoney model.context transaction.amount future
                                    , E.el [ E.height E.fill ] E.none
                                    ]
                                )
                            , E.el
                                [ E.width (E.fillPortion 6)
                                , E.alignTop
                                , Font.color Color.neutral30
                                , Font.alignLeft
                                ]
                                (E.paragraph [] [ E.text (Ledger.getTransactionDescription transaction) ])
                            , E.el
                                [ E.width (E.fillPortion 1)
                                , E.alignTop
                                , Font.color Color.neutral30
                                , Ui.iconFont
                                , Font.center
                                ]
                                (if model.settings.categoriesEnabled then
                                    E.text category.icon

                                 else
                                    E.none
                                )
                            ]
                    }
                )
    in
    case transactions of
        [] ->
            [ E.el
                [ E.width E.fill
                , E.padding 0
                ]
              <|
                E.paragraph
                    [ E.width E.fill
                    , Font.center
                    , Font.color Color.neutral40
                    , E.paddingXY 8 32
                    , Border.color Color.transparent
                    , Border.width 4
                    ]
                    [ E.text "(Aucune opération)" ]
            ]

        t ->
            List.indexedMap render t
