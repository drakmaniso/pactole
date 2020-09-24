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
import Style
import Time
import Ui



-- VIEW


view : Shared.Model -> E.Element Shared.Msg
view model =
    Ui.pageWithSidePanel []
        { panel =
            [ E.el
                [ E.width E.fill, E.height (E.fillPortion 1) ]
                (Summary.view model)
            , E.el
                [ E.width E.fill, E.height (E.fillPortion 2) ]
                (dayView model)
            ]
        , page =
            [ calendar model
            ]
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
        , Background.color Style.bgDark
        ]
        (calendarHeader model
            :: loopThroughMonth (findMonday (findTheFirst model.date))
        )


calendarHeader model =
    E.column
        [ E.width E.fill
        , Background.color Style.bgWhite
        ]
        [ Ui.dateNavigationBar model
        , E.row
            [ E.width E.fill
            , E.alignBottom
            , Background.color Style.bgWhite
            ]
            [ E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Lundi"))
            , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Mardi"))
            , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Mercredi"))
            , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Jeudi"))
            , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Vendredi"))
            , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Samedi"))
            , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Dimanche"))
            ]
        ]


calendarFooter model =
    E.row
        [ E.width E.fill
        , E.alignBottom
        , Background.color Style.bgWhite
        ]
        [ E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Lundi"))
        , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Mardi"))
        , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Mercredi"))
        , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Jeudi"))
        , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Vendredi"))
        , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Samedi"))
        , E.el [ E.width E.fill ] (E.el Style.weekDayName (E.text "Dimanche"))
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
                        Style.dayCellSelected

                    else
                        Style.dayCell
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
                            , Style.smallFont
                            , Font.center
                            , Font.color
                                (if sel then
                                    Style.fgWhite

                                 else
                                    Style.fgBlack
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
                                    Style.bgWhite

                                 else
                                    E.rgba 0 0 0 0
                                )
                            ]
                            (cellContentFor model day)
                        ]
                , onPress = Just (Shared.SelectDate day)
                }
            )

    else
        E.el
            (E.width
                E.fill
                :: E.height E.fill
                :: Style.dayCellNone
            )
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
                , Style.smallFont
                , Font.color (E.rgb 1 1 1)
                , if Money.isExpense transaction.amount then
                    Background.color Style.bgExpense

                  else
                    Background.color Style.bgIncome
                , Border.rounded 16
                , Border.width 0
                , E.htmlAttribute <| Html.Attributes.style "display" "inline-flex"
                ]
                [ E.el [ Style.smallFont, Font.medium ] (E.text (parts.sign ++ parts.units))
                , E.el
                    [ Style.smallerFont
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
        , Background.color Style.bgWhite
        ]
        [ E.column
            [ E.width E.fill
            , E.height E.shrink
            , E.paddingXY 4 12
            , E.spacing 8
            , Font.color Style.fgBlack
            , Font.center
            , Style.bigFont
            , Border.widthEach { top = 2, bottom = 0, left = 0, right = 0 }
            , Border.color Style.bgDark
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
            ]
            (dayContentFor model model.date)
        , E.row
            [ E.width E.fill
            , E.height E.shrink
            , E.spacing 24
            , E.paddingXY 24 12
            ]
            [ Input.button
                (Style.iconButton (E.fillPortion 2) Style.fgIncome Style.bgWhite Style.fgIncome)
                { label = E.text "\u{F067}", onPress = Just (Shared.NewDialog False model.date) }
            , Input.button
                (Style.iconButton (E.fillPortion 2) Style.fgExpense Style.bgWhite Style.fgExpense)
                { label = E.text "\u{F068}", onPress = Just (Shared.NewDialog True model.date) }
            ]
        ]


dayContentFor : Shared.Model -> Date.Date -> List (E.Element Shared.Msg)
dayContentFor model day =
    let
        render transaction =
            let
                parts =
                    Money.toStrings transaction.amount
            in
            E.el
                [ E.width E.fill
                ]
                (Input.button
                    [ E.width E.fill
                    , E.paddingEach { top = 8, bottom = 8, left = 6, right = 6 }
                    , Border.width 4
                    , Border.color (E.rgba 0 0 0 0)
                    , E.focused [ Border.color Style.fgFocus ]
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
                                , Style.normalFont
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
                , Font.color Style.fgDark
                , Style.normalFont
                , E.paddingXY 8 32
                ]
                (E.text "(Aucune dépense)")
            ]

        t ->
            List.map render t
