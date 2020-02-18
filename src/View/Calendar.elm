module View.Calendar exposing (view)

import Calendar
import Debug
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Ledger
import Model
import Msg
import Time


view : Model.Model -> Element Msg.Msg
view model =
    row
        [ width fill
        , height fill
        , paddingXY 8 4
        , htmlAttribute <| Html.Attributes.style "z-index" "-1"
        , Background.color (rgb 0.85 0.82 0.75)
        , inFront
            (el
                [ alignTop, alignRight ]
                (Input.button
                    [ Font.family [ Font.typeface "Font Awesome 5 Free" ]
                    , Font.size 26
                    , padding 8
                    ]
                    { label = text "\u{F013}", onPress = Just Msg.ToSettings }
                )
            )
        ]
        [ column
            [ width (fillPortion 25), height fill, padding 16, alignTop ]
            [ el
                [ width fill, height (fillPortion 33) ]
                (summaryView model)
            , dayView model
            ]
        , el
            [ width (fillPortion 75), height fill ]
            (monthView model)
        ]



-- MONTH VIEW


monthView : Model.Model -> Element Msg.Msg
monthView model =
    column
        [ width fill, height fill, spacing 4 ]
        ([ row
            [ width fill, alignTop, paddingXY 0 8 ]
            [ Input.button
                [ width (fillPortion 1), height fill ]
                { label =
                    el [ centerX, Font.size 32, Font.family [ Font.typeface "Font Awesome 5 Free" ] ] (text "\u{F060}")
                , onPress = Just (Msg.SelectDay (Calendar.decrementMonth model.date))
                }
            , el
                [ width (fillPortion 3), height fill ]
                (el [ centerX, Font.size 28, Font.bold ] (text (getMonthFullName model model.date)))
            , Input.button
                [ width (fillPortion 1), height fill ]
                { label =
                    el [ centerX, Font.size 32, Font.family [ Font.typeface "Font Awesome 5 Free" ] ] (text "\u{F061}")
                , onPress = Just (Msg.SelectDay (Calendar.incrementMonth model.date))
                }
            ]
         ]
            ++ dayGridView model
            ++ [ row
                    [ width fill, alignBottom ]
                    [ el [ width fill ] (el [ centerX, Font.size 16 ] (text "Lundi"))
                    , el [ width fill ] (el [ centerX, Font.size 16 ] (text "Mardi"))
                    , el [ width fill ] (el [ centerX, Font.size 16 ] (text "Mercredi"))
                    , el [ width fill ] (el [ centerX, Font.size 16 ] (text "Jeudi"))
                    , el [ width fill ] (el [ centerX, Font.size 16 ] (text "Vendredi"))
                    , el [ width fill ] (el [ centerX, Font.size 16 ] (text "Samedi"))
                    , el [ width fill ] (el [ centerX, Font.size 16 ] (text "Dimanche"))
                    ]
               ]
        )


dayGridView : Model.Model -> List (Element Msg.Msg)
dayGridView model =
    let
        findTheFirst day =
            if Calendar.getDay day == 1 then
                day

            else
                findTheFirst (Calendar.decrementDay day)

        findTheLast day =
            if Calendar.getDay day == Calendar.lastDayOf day then
                day

            else
                findTheLast (Calendar.incrementDay day)

        lastDay =
            findTheLast model.date

        findMonday day =
            case Calendar.getWeekday day of
                Time.Mon ->
                    day

                _ ->
                    findMonday (Calendar.decrementDay day)

        walkWeeks day =
            case ( Calendar.compare day lastDay, Calendar.getWeekday day ) of
                ( GT, Time.Mon ) ->
                    []

                _ ->
                    row
                        [ width fill, height fill, scrollbarY, spacing 4 ]
                        (walkDays day)
                        :: walkWeeks (incrementWeek day)

        walkDays day =
            case Calendar.getWeekday day of
                Time.Sun ->
                    [ dayCell model day ]

                _ ->
                    dayCell model day :: walkDays (Calendar.incrementDay day)
    in
    walkWeeks (findMonday (findTheFirst model.date))


dayCell : Model.Model -> Calendar.Date -> Element Msg.Msg
dayCell model day =
    let
        sel =
            model.selected && day == model.date

        style =
            [ width fill
            , height fill
            , scrollbarY

            -- BUGGY: , focused [ Border.shadow {offset = (0, 0), size = 4, blur = 8, color = (rgba 0 0 0 0.20)} ]
            ]
                ++ (if sel then
                        [ Background.color (rgb 1 1 1)
                        , Border.rounded 8
                        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 8, color = rgba 0 0 0 0.2 }
                        , htmlAttribute <| Html.Attributes.style "z-index" "0"
                        ]

                    else
                        [ Background.color (rgb 0.94 0.92 0.87), Border.rounded 2 ]
                   )
    in
    if Calendar.getMonth day == Calendar.getMonth model.date then
        Input.button
            style
            { label =
                Element.column
                    [ width fill, height fill, scrollbarY ]
                    [ el
                        ([ width fill
                         , paddingXY 8 4
                         , Font.bold
                         , Font.center
                         ]
                            ++ (if sel then
                                    [ Font.color (rgb 1 1 1), Background.color (rgb 0.3 0.6 0.7) ]

                                else
                                    []
                               )
                        )
                        (text
                            (if day == model.today then
                                "Aujourd'hui"

                             else
                                String.fromInt (Calendar.getDay day)
                            )
                        )
                    , Element.wrappedRow
                        [ width fill
                        , height fill
                        , scrollbarY
                        ]
                        (dayCellTransactions model day)
                    ]
            , onPress = Just (Msg.SelectDay day)
            }

    else
        el
            [ width fill, height fill ]
            none


dayCellTransactions : Model.Model -> Calendar.Date -> List (Element Msg.Msg)
dayCellTransactions model day =
    let
        render (Ledger.Transaction date (Ledger.Money amount) desc cat rec) =
            el
                [ paddingXY 8 2
                , Font.size 16
                , Font.color (rgb 1 1 1)
                , if amount < 0 then
                    Background.color (rgb 0.8 0.25 0.2)

                  else
                    Background.color (rgb 0.2 0.7 0.1)
                , Border.rounded 16
                , Border.color (rgb 0.94 0.92 0.87)
                , Border.width 2
                ]
                (text (String.fromInt (amount // 100)))

        (Ledger.Ledger transacs) =
            model.ledger
    in
    List.map
        render
        (List.filter
            (\(Ledger.Transaction d _ _ _ _) -> d == day)
            transacs
        )



-- SUMMARY VIEW


summaryView model =
    column
        [ centerX ]
        [ Input.radioRow
            [ width fill ]
            { onChange = Msg.ChooseAccount
            , selected = Just model.account
            , label = Input.labelHidden "Compte"
            , options =
                List.map
                    (\acc -> Input.optionWith acc (accountOption acc))
                    model.accounts
            }
        ]


accountOption : String -> Input.OptionState -> Element msg
accountOption value state =
    el
        ([ centerX
         , paddingXY 16 8
         , Border.rounded 3
         ]
            ++ (case state of
                    Input.Idle ->
                        [ Font.color (rgb 0.3 0.6 0.7) ]

                    Input.Focused ->
                        []

                    Input.Selected ->
                        [ Font.color (rgb 1 1 1), Background.color (rgb 0.3 0.6 0.7) ]
               )
        )
        (text value)



-- DAY VIEW


dayView model =
    column
        [ width fill
        , height (fillPortion 66)
        , Border.rounded 16
        , clip
        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 8, color = rgba 0 0 0 0.2 }
        , Background.color (rgb 1 1 1)
        ]
        [ el
            [ width fill
            , paddingXY 4 12
            , Background.color (rgb 0.3 0.6 0.7)
            , Font.color (rgb 1 1 1)
            , Font.center
            , Font.bold
            , Font.size 26
            ]
            (if model.date == model.today then
                text "Aujourd'hui"

             else
                text (getWeekdayName model.date ++ " " ++ String.fromInt (Calendar.getDay model.date))
            )
        ]



-- DATE TOOLS


incrementWeek date =
    date
        |> Calendar.incrementDay
        |> Calendar.incrementDay
        |> Calendar.incrementDay
        |> Calendar.incrementDay
        |> Calendar.incrementDay
        |> Calendar.incrementDay
        |> Calendar.incrementDay


getMonthName : Time.Month -> String
getMonthName m =
    case m of
        Time.Jan ->
            "Janvier"

        Time.Feb ->
            "Février"

        Time.Mar ->
            "Mars"

        Time.Apr ->
            "Avril"

        Time.May ->
            "Mai"

        Time.Jun ->
            "Juin"

        Time.Jul ->
            "Juillet"

        Time.Aug ->
            "Août"

        Time.Sep ->
            "Septembre"

        Time.Oct ->
            "Octobre"

        Time.Nov ->
            "Novembre"

        Time.Dec ->
            "Décembre"


getWeekdayName d =
    case Calendar.getWeekday d of
        Time.Mon ->
            "Lundi"

        Time.Tue ->
            "Mardi"

        Time.Wed ->
            "Mercredi"

        Time.Thu ->
            "Jeudi"

        Time.Fri ->
            "Vendredi"

        Time.Sat ->
            "Samedi"

        Time.Sun ->
            "Dimanche"


getMonthFullName model d =
    let
        n =
            getMonthName (Calendar.getMonth model.date)
    in
    if Calendar.getYear d == Calendar.getYear model.today then
        n

    else
        n ++ " " ++ String.fromInt (Calendar.getYear d)
