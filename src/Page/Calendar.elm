module Page.Calendar exposing (viewContent, viewSelectedDate)

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
        [ Ui.monthNavigationBar model.context model.monthDisplayed Msg.DisplayMonth
        , weekDayNames model
        , E.el
            [ E.width E.fill
            , E.height E.fill
            , E.clip
            , Background.color Color.white
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
        , Background.color Color.white
        , E.spacing <|
            if model.context.density == Ui.Comfortable then
                4

            else
                2
        , E.htmlAttribute <| Html.Attributes.class anim
        ]
        (Date.weeksOfMonth monthYear
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
                                if Date.getMonth day == monthYear.month then
                                    calendarCell model day

                                else
                                    E.el [ E.width E.fill, E.height E.fill ] E.none
                            )
                            week
                )
        )


weekDayNames : Model -> E.Element Msg
weekDayNames model =
    let
        device =
            model.context.device
    in
    if model.context.density == Ui.Comfortable && device.orientation == E.Landscape then
        E.row
            [ E.width E.fill
            , E.alignBottom
            , Ui.smallFont model.context
            , Ui.notSelectable
            , Font.color Color.neutral20
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

        size =
            case model.context.device.orientation of
                E.Landscape ->
                    model.context.height // 32

                E.Portrait ->
                    model.context.height // 70

        smallEm =
            model.context.smallEm

        sel =
            day == model.dateSelected
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
                        4

                    Ui.Compact ->
                        2

                    Ui.Condensed ->
                        2
            , Border.rounded (em // 4)
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
                [ Border.color
                    (if sel then
                        Color.primary40

                     else
                        Color.neutral90
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
                            Font.color Color.neutral20
                        ]
                      <|
                        if day == model.today && model.context.density == Ui.Comfortable then
                            E.text <| "Aujourd'hui"

                        else
                            E.text <| String.fromInt <| Date.getDay day
                    , if model.context.density == Ui.Comfortable then
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
                        E.el
                            [ E.width E.fill
                            , E.height E.fill
                            , E.clip
                            ]
                        <|
                            E.paragraph
                                [ E.centerX
                                , E.centerY
                                , E.clip
                                , E.spacing 0
                                , Font.size (size + 2)
                                , Font.center
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

        size =
            case model.context.device.orientation of
                E.Landscape ->
                    model.context.height // 32

                E.Portrait ->
                    model.context.height // 70

        render transaction =
            let
                future =
                    Date.compare day model.today == GT

                color =
                    if future then
                        Color.neutral50

                    else
                        Color.transactionColor (Money.isExpense transaction.amount)

                parts =
                    Money.toStrings transaction.amount
            in
            if model.context.density == Ui.Comfortable then
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
                E.el [ E.width E.fill ] <|
                    E.el
                        [ E.width <| E.px size
                        , E.height <| E.px size
                        , E.centerX
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


viewSelectedDate : Model -> E.Element Msg
viewSelectedDate model =
    if Date.getMonthYear model.dateSelected == model.monthDisplayed then
        dayView model model.dateSelected

    else
        E.column [ E.width E.fill, E.height E.fill ]
            [ E.paragraph [ E.alignBottom, Font.center, Font.color Color.neutral50 ]
                [ E.text "(choisir une date)" ]
            , E.el [ E.alignBottom, E.height <| E.px model.context.em ] E.none
            ]


dayView : Model -> Date -> E.Element Msg
dayView model date =
    let
        em =
            model.context.em
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clip
        , E.inFront <|
            if model.context.device.orientation == E.Portrait then
                E.column
                    [ E.alignBottom
                    , E.alignRight
                    , E.spacing (em // 2)
                    , E.paddingXY (em // 2) (em // 2)
                    , Background.color Color.transparent
                    ]
                    [ Ui.incomeButton model.context
                        { label = Ui.incomeIcon
                        , onPress =
                            Msg.OpenDialog <|
                                Model.TransactionDialog
                                    { id = Nothing
                                    , isExpense = False
                                    , isRecurring = False
                                    , date = date
                                    , amount = ( "", Nothing )
                                    , description = ""
                                    , category = 0
                                    }
                        }
                    , Ui.expenseButton model.context
                        { label = Ui.expenseIcon
                        , onPress =
                            Msg.OpenDialog <|
                                Model.TransactionDialog
                                    { id = Nothing
                                    , isExpense = True
                                    , isRecurring = False
                                    , date = date
                                    , amount = ( "", Nothing )
                                    , description = ""
                                    , category = 0
                                    }
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
                        , onPress =
                            Msg.OpenDialog <|
                                Model.TransactionDialog
                                    { id = Nothing
                                    , isExpense = False
                                    , isRecurring = False
                                    , date = date
                                    , amount = ( "", Nothing )
                                    , description = ""
                                    , category = 0
                                    }
                        }
                    , Ui.expenseButton model.context
                        { label = Ui.expenseIcon
                        , onPress =
                            Msg.OpenDialog <|
                                Model.TransactionDialog
                                    { id = Nothing
                                    , isExpense = True
                                    , isRecurring = False
                                    , date = date
                                    , amount = ( "", Nothing )
                                    , description = ""
                                    , category = 0
                                    }
                        }
                    ]
        ]
        [ E.column
            [ E.width E.fill
            , E.height <| E.fill
            , E.paddingXY 0 (em // 4)
            , E.spacing (em // 4)
            , Font.color Color.neutral20
            , Font.center
            , Ui.notSelectable
            , E.scrollbarY
            ]
            [ if model.context.device.orientation == E.Landscape && model.context.height > 28 * em then
                E.el [ E.width E.fill, Font.color Color.neutral50, Ui.smallFont model.context ]
                    (E.text <| Date.fancyDayDescription model.today date)

              else
                E.none
            , E.el
                [ E.width E.fill
                , Font.bold
                , if model.context.density /= Ui.Comfortable then
                    Ui.defaultFontSize model.context

                  else
                    Ui.bigFont model.context
                , Font.center
                ]
              <|
                Ui.viewDate model.context date
            , E.column
                [ E.width E.fill
                ]
                (dayContentFor model date)
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
                    [ E.width <| E.maximum (20 * em) <| E.fill
                    , E.centerX
                    , E.padding <| em // 4 + em // 8
                    , Border.width 4
                    , Border.color Color.transparent
                    , Ui.focusVisibleOnly
                    , E.mouseDown [ Background.color Color.neutral80 ]
                    , E.mouseOver [ Background.color Color.neutral95 ]
                    ]
                    { onPress =
                        Just <|
                            if transaction.isRecurring then
                                Msg.OpenDialog <|
                                    Model.TransactionDialog
                                        { id = Just transaction.id
                                        , isExpense = Money.isExpense transaction.amount
                                        , isRecurring = True
                                        , date = transaction.date
                                        , amount = ( Money.toInput transaction.amount, Nothing )
                                        , description = transaction.description
                                        , category = transaction.category
                                        }

                            else
                                Msg.OpenDialog <|
                                    Model.TransactionDialog
                                        { id = Just transaction.id
                                        , isExpense = Money.isExpense transaction.amount
                                        , isRecurring = False
                                        , date = transaction.date
                                        , amount = ( Money.toInput transaction.amount, Nothing )
                                        , description = transaction.description
                                        , category = transaction.category
                                        }
                    , label =
                        E.row
                            [ E.width E.fill
                            , E.spacing <| em // 2
                            ]
                            [ E.el
                                [ E.height E.fill
                                ]
                                (E.column
                                    []
                                    [ Ui.viewMoney model.context transaction.amount future
                                    , E.el [ E.height E.fill ] E.none
                                    ]
                                )
                            , if model.settings.categoriesEnabled then
                                E.el
                                    [ E.width <| E.px <| em + em // 2
                                    , E.alignTop
                                    , Font.color Color.neutral20
                                    , Ui.iconFont
                                    , Font.center
                                    ]
                                    (E.text category.icon)

                              else
                                E.none
                            , E.el
                                [ E.width (E.fillPortion 2)
                                , E.alignTop
                                , Font.color Color.neutral20
                                , Font.alignLeft
                                ]
                                (E.paragraph [] [ E.text (Ledger.getTransactionDescription transaction) ])
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
                    , Font.color Color.neutral50
                    , E.paddingXY 8 32
                    , Border.color Color.transparent
                    , Border.width 4
                    ]
                    [ E.text "(aucune opération)" ]
            ]

        t ->
            List.indexedMap render t
