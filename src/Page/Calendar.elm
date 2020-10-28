module Page.Calendar exposing (view)

import Date
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Ledger
import Money
import Page.Summary as Summary
import Shared
import Time
import Ui



-- VIEW


view : Shared.Model -> E.Element Shared.Msg
view model =
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
                    (Summary.view model)
                , E.el
                    [ E.width E.fill, E.height (E.fillPortion 2) ]
                    (dayView model)
                ]
        , page = calendar model
        }



-- THE CALENDAR


calendar : Shared.Model -> E.Element Shared.Msg
calendar model =
    let
        findTheFirst date =
            if Date.getDay date == 1 then
                date

            else
                findTheFirst (Date.decrementDay date)

        findTheLast date =
            if Date.getDay date == Date.lastDayOf date then
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
                        , E.spacing 2
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
        , E.spacing 2
        , E.padding 0
        , Background.color Ui.bgDark
        ]
        (calendarHeader model
            :: loopThroughMonth (findMonday (findTheFirst model.date))
        )


calendarHeader model =
    E.column
        [ E.width E.fill
        , Background.color Ui.bgWhite
        ]
        [ Ui.dateNavigationBar model
        , E.row
            [ E.width E.fill
            , E.alignBottom
            , Background.color Ui.bgWhite
            , Ui.smallFont
            , Font.color Ui.fgDark
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


calendarCell : Shared.Model -> Date.Date -> E.Element Shared.Msg
calendarCell model day =
    let
        sel =
            day == model.date
    in
    if Date.getMonth day == Date.getMonth model.date then
        E.el
            -- Need to wrap the button in E.el because of elm-ui E.focused bug
            ([ E.width E.fill
             , E.height E.fill
             , E.clipY
             ]
                ++ (if sel then
                        [ Background.color Ui.bgTitle
                        , Border.color Ui.bgTitle
                        , Border.rounded 0
                        , Border.width 4
                        , E.focused
                            [ Border.shadow
                                { offset = ( 0, 0 ), size = 0, blur = 0, color = E.rgba 0 0 0 0 }
                            ]
                        ]

                    else
                        [ Background.color Ui.bgEvenRow
                        , Border.color Ui.bgEvenRow -- (E.rgba 0 0 0 0)
                        , Border.width 4
                        , Border.rounded 0
                        , E.focused
                            [ Border.color Ui.fgFocus
                            , Border.shadow
                                { offset = ( 0, 0 ), size = 0, blur = 0, color = E.rgba 0 0 0 0 }
                            ]
                        ]
                   )
            )
            (Input.button
                [ E.width E.fill
                , E.height E.fill
                , E.scrollbarY
                ]
                { label =
                    E.column
                        [ E.width E.fill
                        , E.height E.fill
                        , E.scrollbarY
                        ]
                        [ E.el
                            [ E.width E.fill
                            , E.paddingEach { top = 0, bottom = 4, left = 0, right = 0 }
                            , Ui.smallFont
                            , Font.center
                            , Font.color
                                (if sel then
                                    Ui.fgWhite

                                 else
                                    Ui.fgBlack
                                )
                            ]
                            (E.text
                                (if day == model.today then
                                    "Aujourd'hui"

                                 else
                                    String.fromInt (Date.getDay day)
                                )
                            )
                        , E.paragraph
                            [ E.width E.fill
                            , E.height E.fill
                            , E.paddingXY 2 8
                            , E.spacing 12
                            , E.scrollbarY
                            , Background.color
                                (if sel then
                                    Ui.bgWhite

                                 else
                                    --E.rgba 0 0 0 0
                                    Ui.bgEvenRow
                                )
                            ]
                            (cellContentFor model day)
                        ]
                , onPress = Just (Shared.SelectDate day)
                }
            )

    else
        E.el
            [ E.width E.fill
            , E.height E.fill
            , Border.color (E.rgba 0 0 0 0)
            , Border.width 4
            , Background.color Ui.bgOddRow -- Ui.bgLight
            ]
            E.none


cellContentFor : Shared.Model -> Date.Date -> List (E.Element Shared.Msg)
cellContentFor model day =
    let
        render transaction =
            let
                parts =
                    Money.toStrings transaction.amount
            in
            E.row
                [ E.paddingEach { top = 3, bottom = 4, left = 6, right = 8 }
                , Ui.smallFont
                , Font.color (E.rgb 1 1 1)
                , if Money.isExpense transaction.amount then
                    Background.color Ui.bgExpense

                  else
                    Background.color Ui.bgIncome
                , Border.rounded 16
                , Border.width 0
                , E.htmlAttribute <| Html.Attributes.style "display" "inline-flex"
                ]
                [ E.el [ Ui.smallFont, Font.medium ] (E.text (parts.sign ++ parts.units))
                , E.el
                    [ Ui.smallerFont
                    , E.alignBottom
                    , E.paddingXY 0 1
                    ]
                    (E.text ("," ++ parts.cents))
                ]
    in
    List.map
        render
        (Ledger.getDateTransactions day model.ledger)
        |> List.intersperse (E.text " ")



-- DAY VIEW


dayView model =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clip
        , Background.color Ui.bgWhite
        ]
        [ E.column
            [ E.width E.fill
            , E.height E.shrink
            , E.paddingXY 0 12
            , E.spacing 8
            , Font.color Ui.fgBlack
            , Font.center
            , Ui.bigFont
            , Border.widthEach { top = 2, bottom = 0, left = 0, right = 0 }
            , Border.color Ui.bgDark
            , Ui.notSelectable
            ]
            [ E.el [ E.width E.fill, Font.bold ]
                (E.text
                    (Date.getWeekdayName model.date
                        ++ " "
                        ++ String.fromInt (Date.getDay model.date)
                        ++ " "
                        ++ Date.getMonthName model.date
                    )
                )
            , if model.date == model.today then
                E.el [ E.width E.fill ] (E.text "— Aujourd'hui —")

              else
                E.none
            ]
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.scrollbarY
            ]
            (dayContentFor model model.date)
        , E.row
            [ E.width E.fill
            , E.height E.shrink
            , E.spacing 24
            , E.paddingXY 24 12
            ]
            [ Ui.coloredButton
                [ E.width (E.fillPortion 2) ]
                { label = Ui.incomeIcon []
                , color = Ui.fgIncome
                , onPress = Just (Shared.NewDialog False model.date)
                }
            , Ui.coloredButton
                [ E.width (E.fillPortion 2) ]
                { label = Ui.expenseIcon []
                , color = Ui.fgExpense
                , onPress = Just (Shared.NewDialog True model.date)
                }
            ]
        ]


dayContentFor : Shared.Model -> Date.Date -> List (E.Element Shared.Msg)
dayContentFor model day =
    let
        render idx transaction =
            let
                parts =
                    Money.toStrings transaction.amount
            in
            E.el
                [ E.width E.fill
                , E.padding 0
                , if Basics.remainderBy 2 idx == 0 then
                    Background.color Ui.bgEvenRow

                  else
                    Background.color Ui.bgOddRow
                ]
                (Input.button
                    [ E.width E.fill
                    , E.paddingEach { top = 8, bottom = 8, left = 0, right = 0 }
                    , Border.width 4
                    , Border.color (E.rgba 0 0 0 0)
                    , E.focused [ Border.color Ui.fgFocus ]
                    ]
                    { onPress = Just (Shared.EditDialog transaction.id)
                    , label =
                        E.row
                            [ E.width E.fill
                            ]
                            [ E.el
                                [ E.width (E.fillPortion 33)
                                , E.height E.fill
                                ]
                                (E.column
                                    [ E.width E.fill ]
                                    [ Ui.viewMoney transaction.amount
                                    , E.el [ E.height E.fill ] E.none
                                    ]
                                )
                            , E.el
                                [ E.width (E.fillPortion 66)
                                , E.alignTop
                                , Ui.normalFont
                                , Font.color (E.rgb 0 0 0)
                                ]
                                (E.paragraph [] [ E.text (Ledger.getDescriptionDisplay transaction) ])
                            ]
                    }
                )
    in
    case Ledger.getDateTransactions day model.ledger of
        [] ->
            [ E.el
                [ E.width E.fill
                , Font.center
                , Font.color Ui.fgDark
                , Ui.normalFont
                , E.paddingXY 8 32
                ]
                (E.text "(Aucune dépense)")
            ]

        t ->
            List.indexedMap render t
