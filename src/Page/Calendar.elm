module Page.Calendar exposing (viewContent, viewPanel)

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
import Page.Summary as Summary
import Time
import Ui
import Ui.Color as Color



-- VIEW


viewPanel : Model -> E.Element Msg
viewPanel model =
    Ui.twoPartsSidePanel { top = Summary.view model, bottom = dayView model }



-- THE CALENDAR


viewContent : Model -> E.Element Msg
viewContent model =
    let
        findTheFirst date =
            if Date.getDay date == 1 then
                date

            else
                findTheFirst (Date.decrementDay date)

        findTheLast date =
            if Date.getDay date == Date.getDay (Date.lastDayOf date) then
                date

            else
                findTheLast (Date.incrementDay date)

        findMonday date =
            case Date.getWeekday date of
                Time.Mon ->
                    date

                _ ->
                    findMonday (Date.decrementDay date)

        loopThroughMonth date =
            let
                theLast =
                    findTheLast model.date
            in
            case ( Date.compare date theLast, Date.getWeekday date ) of
                ( GT, Time.Mon ) ->
                    []

                _ ->
                    E.row
                        [ E.width E.fill
                        , E.height E.fill
                        , E.clipY
                        ]
                        (loopThroughWeek date)
                        :: loopThroughMonth (Date.incrementWeek date)

        loopThroughWeek date =
            case Date.getWeekday date of
                Time.Sun ->
                    [ calendarCell model date ]

                _ ->
                    calendarCell model date :: loopThroughWeek (Date.incrementDay date)
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.padding 3
        ]
        (calendarHeader model
            :: loopThroughMonth (findMonday (findTheFirst model.date))
        )


calendarHeader : Model -> E.Element Msg
calendarHeader model =
    E.column
        [ E.width E.fill
        ]
        [ Ui.dateNavigationBar model Msg.SelectDate
        , E.row
            [ E.width E.fill
            , E.alignBottom
            , Ui.smallFont
            , Ui.notSelectable
            ]
            [ E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Lundi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Mardi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Mercredi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Jeudi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Vendredi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Samedi"))
            , E.el [ E.width E.fill ] (E.el [ E.centerX ] (E.text "Dimanche"))
            ]
        ]


calendarCell : Model -> Date -> E.Element Msg
calendarCell model day =
    let
        sel =
            day == model.date
    in
    if Date.getMonth day == Date.getMonth model.date then
        E.el
            -- Need to wrap the button in E.el because of elm-ui E.focused bug
            [ E.width E.fill
            , E.height E.fill
            , E.clipY
            , Ui.transition
            ]
            (Input.button
                [ E.width E.fill
                , E.height E.fill
                , E.scrollbarY
                , Border.width 3
                , Border.rounded
                    (if sel then
                        12

                     else
                        6
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
                        , E.scrollbarY
                        ]
                        [ E.el
                            [ E.width E.fill
                            , E.paddingEach { top = 0, bottom = 2, left = 0, right = 0 }
                            , Ui.smallFont
                            , Font.center
                            , Font.color
                                (if sel then
                                    Color.white

                                 else
                                    Color.neutral30
                                )
                            , Background.color
                                (if sel then
                                    Color.primary40

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
                            , E.paddingXY 2 2
                            , E.spacing 12
                            , E.scrollbarY
                            , Background.color
                                (if sel then
                                    Color.white

                                 else
                                    Color.transparent
                                )
                            ]
                            (cellContentFor model day)
                        ]
                , onPress = Just (Msg.SelectDate day)
                }
            )

    else
        E.el
            [ E.width E.fill
            , E.height E.fill
            , Border.color (E.rgba 0 0 0 0)
            ]
            E.none


cellContentFor : Model -> Date -> List (E.Element Msg)
cellContentFor model day =
    let
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
            E.row
                [ E.paddingEach { top = 3, bottom = 4, left = 6, right = 8 }
                , E.paddingEach { top = 1, bottom = 2, left = 4, right = 6 }
                , Ui.smallFont
                , Font.color Color.white
                , Background.color color
                , Border.rounded 16
                , Border.width 2
                , Border.color color
                , E.htmlAttribute <| Html.Attributes.style "display" "inline-flex"
                ]
                [ E.el [ Ui.smallFont ] (E.text (parts.sign ++ parts.units))
                , E.el
                    [ Ui.smallerFont
                    , E.alignBottom
                    , E.paddingXY 0 1
                    ]
                    (E.text ("," ++ parts.cents))
                ]
    in
    (List.map render (Ledger.getTransactionsForDate model.ledger model.account day)
        ++ List.map render (Ledger.getRecurringTransactionsForDate model.recurring model.account day)
    )
        |> List.intersperse (E.text " ")



-- DAY VIEW


dayView : Model -> E.Element Msg
dayView model =
    let
        dayDiff =
            Date.getDayDiff model.today model.date
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clip
        ]
        [ E.column
            [ E.width E.fill
            , E.height E.shrink
            , E.paddingXY 0 12
            , E.spacing 8
            , Font.color Color.neutral30
            , Font.center
            , Ui.bigFont
            , Ui.notSelectable
            ]
            [ E.el [ E.width E.fill, Ui.normalFont, Font.color Color.neutral50 ]
                (E.text <|
                    if model.date == model.today then
                        "— Aujourd'hui —"

                    else if dayDiff == 1 then
                        "— demain —"

                    else if dayDiff == -1 then
                        "— hier —"

                    else if dayDiff > 1 then
                        "— dans " ++ String.fromInt dayDiff ++ " jours —"

                    else if dayDiff < -1 then
                        "— il y a " ++ String.fromInt -dayDiff ++ " jours —"

                    else
                        ""
                )
            , Ui.viewDate model.date
            ]
        , E.column
            [ E.width E.fill
            , E.height <| E.minimum 80 <| E.fill
            , E.scrollbarY
            ]
            (dayContentFor model model.date)
        , E.row
            [ E.width E.fill
            , E.height E.shrink
            , E.spacing 24
            , E.paddingXY 24 12
            ]
            [ Ui.incomeButton
                { label = Ui.incomeIcon
                , onPress = Just (Msg.ForDialog <| Msg.DialogNewTransaction False model.date)
                }
            , Ui.expenseButton
                { label = Ui.expenseIcon
                , onPress = Just (Msg.ForDialog <| Msg.DialogNewTransaction True model.date)
                }
            ]
        ]


dayContentFor : Model -> Date -> List (E.Element Msg)
dayContentFor model day =
    let
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
                    , E.paddingEach { top = 8, bottom = 8, left = 12, right = 12 }
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
                                (Msg.ForDialog << Msg.DialogShowRecurring) transaction.id

                             else
                                (Msg.ForDialog << Msg.DialogEditTransaction) transaction.id
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
                                    [ Ui.viewMoney transaction.amount future
                                    , E.el [ E.height E.fill ] E.none
                                    ]
                                )
                            , E.el
                                [ E.width (E.fillPortion 6)
                                , E.alignTop
                                , Ui.normalFont
                                , Font.color Color.neutral30
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
            [ E.paragraph
                [ E.width E.fill
                , Font.center
                , Font.color Color.neutral50
                , Ui.normalFont
                , E.paddingXY 8 32
                ]
                [ E.text "(Aucune opération)" ]
            ]

        t ->
            List.indexedMap render t
