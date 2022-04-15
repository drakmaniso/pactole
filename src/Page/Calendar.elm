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
        , E.spacing <|
            if model.context.density == Ui.Comfortable then
                4

            else
                2
        , E.padding <|
            if model.context.device.orientation == E.Landscape then
                4

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
                                , E.spacing <|
                                    if model.context.density == Ui.Comfortable then
                                        4

                                    else
                                        2
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
        , E.row [ E.width E.fill, E.height E.fill, E.spacing 2 ]
            (Date.daysOfWeek model.date
                |> List.map (\day -> calendarCell model day)
            )
        ]


weekDayNames : Model -> E.Element Msg
weekDayNames model =
    let
        device =
            model.context.device
    in
    if
        (model.context.density == Ui.Comfortable && device.orientation == E.Landscape)
            || (device.class == E.Phone && device.orientation == E.Landscape)
    then
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

        device =
            model.context.device

        smallEm =
            model.context.smallEm

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
            , E.clip
            , Border.width <|
                case model.context.density of
                    Ui.Comfortable ->
                        2

                    Ui.Compact ->
                        2

                    Ui.Condensed ->
                        2
            , Ui.transition
            , Border.rounded
                (if sel then
                    (em // 4) + 4

                 else
                    em // 4
                )
            , Border.color
                (if sel then
                    Color.primary40

                 else
                    Color.transparent
                )
            , Background.color
                (if sel then
                    Color.primary95

                 else
                    Color.neutral95
                )
            , E.mouseDown
                [ Background.color
                    (if sel then
                        Color.primary90

                     else
                        Color.neutral90
                    )
                ]
            , E.mouseOver
                [ Background.color
                    (if sel then
                        Color.primary95

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
                    , E.clip
                    ]
                    [ E.el
                        [ E.width E.fill
                        , case model.context.density of
                            Ui.Comfortable ->
                                Ui.smallFont model.context

                            Ui.Compact ->
                                Ui.smallFont model.context

                            Ui.Condensed ->
                                Ui.smallerFont model.context
                        , Font.center
                        , if day == model.today && model.context.density /= Ui.Comfortable then
                            Font.bold

                          else
                            Font.regular
                        , if day == model.today then
                            Font.color Color.black

                          else
                            Font.color Color.neutral30
                        ]
                      <|
                        if day == model.today && model.context.density == Ui.Comfortable then
                            E.text <| "Aujourd'hui"

                        else
                            E.text <| String.fromInt <| Date.getDay day
                    , if
                        model.context.density
                            == Ui.Comfortable
                            || (device.class == E.Phone && device.orientation == E.Landscape)
                      then
                        E.paragraph
                            [ E.width E.fill
                            , E.height E.fill
                            , E.clip
                            , E.paddingEach
                                { left = 0
                                , right = 0
                                , top = smallEm // 2
                                , bottom = 0
                                }
                            , E.spacing <| smallEm // 2
                            , Ui.smallFont model.context
                            , Font.center
                            ]
                            (cellContentFor model day)

                      else
                        E.paragraph [ E.centerX, E.centerY, E.spacing 0, Ui.smallerFont model.context, Font.center ]
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

        device =
            model.context.device

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
            if
                model.context.density
                    == Ui.Comfortable
                    || (device.class == E.Phone && device.orientation == E.Landscape)
            then
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

            else
                let
                    size =
                        case model.context.device.orientation of
                            E.Landscape ->
                                model.context.height // 32

                            E.Portrait ->
                                model.context.height // 70
                in
                E.el
                    [ E.width <| E.px size
                    , E.height <| E.px size
                    , Background.color color
                    , Border.rounded 1000
                    , E.htmlAttribute <| Html.Attributes.style "display" "inline-flex"
                    ]
                    E.none
    in
    (List.map render (Ledger.getTransactionsForDate model.ledger model.account day)
        ++ List.map render (Ledger.getRecurringTransactionsForDate model.recurring model.account day)
    )
        |> List.intersperse
            (case model.context.density of
                Ui.Comfortable ->
                    E.el [ Ui.smallFont model.context ] (E.text " ")

                _ ->
                    E.el
                        [ Ui.smallerFont model.context
                        , E.width <| E.px 2
                        , E.height <| E.px 2
                        ]
                        E.none
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
        , E.inFront <|
            if model.context.device.class == E.Phone then
                E.column
                    [ E.alignBottom
                    , E.alignRight
                    , E.spacing (em // 2)
                    , E.paddingXY (em // 2) (em // 2)
                    , Background.color Color.transparent
                    ]
                    [ Ui.incomeButton model.context
                        { label = Ui.incomeIcon
                        , onPress = Just (Msg.ForTransaction <| Msg.NewTransaction False model.date)
                        }
                    , Ui.expenseButton model.context
                        { label = Ui.expenseIcon
                        , onPress = Just (Msg.ForTransaction <| Msg.NewTransaction True model.date)
                        }
                    ]

            else
                E.row
                    [ E.centerX
                    , E.alignBottom
                    , E.spacing em
                    , E.paddingXY em (em // 2)
                    , Border.roundEach { topLeft = model.context.bigEm, topRight = model.context.bigEm, bottomLeft = 0, bottomRight = 0 }
                    , Background.color Color.translucentWhite
                    ]
                    [ Ui.incomeButton model.context
                        { label = Ui.incomeIcon
                        , onPress = Just (Msg.ForTransaction <| Msg.NewTransaction False model.date)
                        }
                    , Ui.expenseButton model.context
                        { label = Ui.expenseIcon
                        , onPress = Just (Msg.ForTransaction <| Msg.NewTransaction True model.date)
                        }
                    ]
        ]
        [ E.column
            [ E.width E.fill
            , E.height <| E.fill
            , E.paddingXY 0 (em // 4)
            , E.spacing (em // 4)
            , Font.color Color.neutral30
            , Font.center
            , Ui.notSelectable
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
