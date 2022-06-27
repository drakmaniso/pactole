module Date exposing
    ( Date
    , MonthYear
    , compare
    , daysOfWeek
    , decode
    , decrementDay
    , decrementMonth
    , decrementMonthYear
    , decrementWeek
    , default
    , encode
    , fancyDayDescription
    , fancyWeekDescription
    , findNextDayOfMonth
    , firstDayOf
    , firstDayOfMonth
    , followingMonth
    , fromParts
    , getDay
    , getDayDiff
    , getMonth
    , getMonthName
    , getMonthNumber
    , getMonthYear
    , getMonthYearName
    , getWeekday
    , getWeekdayName
    , getYear
    , incrementDay
    , incrementMonth
    , incrementMonthYear
    , incrementWeek
    , lastDayOf
    , lastDayOfMonth
    , mondayOfWeek
    , previousMonth
    , toShortString
    , toString
    , weeksOfMonth
    )

import Array
import Calendar
import Json.Decode as Decode
import Json.Encode as Encode
import Time


type Date
    = Date Calendar.Date


type alias MonthYear =
    { month : Time.Month
    , year : Int
    }


getMonthYear : Date -> MonthYear
getMonthYear (Date date) =
    { month = Calendar.getMonth date, year = Calendar.getYear date }


previousMonth : Time.Month -> Time.Month
previousMonth month =
    case month of
        Time.Jan ->
            Time.Dec

        Time.Feb ->
            Time.Jan

        Time.Mar ->
            Time.Feb

        Time.Apr ->
            Time.Mar

        Time.May ->
            Time.Apr

        Time.Jun ->
            Time.May

        Time.Jul ->
            Time.Jun

        Time.Aug ->
            Time.Jul

        Time.Sep ->
            Time.Aug

        Time.Oct ->
            Time.Sep

        Time.Nov ->
            Time.Oct

        Time.Dec ->
            Time.Nov


followingMonth : Time.Month -> Time.Month
followingMonth month =
    case month of
        Time.Jan ->
            Time.Feb

        Time.Feb ->
            Time.Mar

        Time.Mar ->
            Time.Apr

        Time.Apr ->
            Time.May

        Time.May ->
            Time.Jun

        Time.Jun ->
            Time.Jul

        Time.Jul ->
            Time.Aug

        Time.Aug ->
            Time.Sep

        Time.Sep ->
            Time.Oct

        Time.Oct ->
            Time.Nov

        Time.Nov ->
            Time.Dec

        Time.Dec ->
            Time.Jan


default : Date
default =
    Date (Calendar.fromPosix (Time.millisToPosix 0))


toString : Date -> String
toString (Date date) =
    String.padLeft 2 '0' (String.fromInt (Calendar.getDay date))
        ++ "/"
        ++ String.padLeft 2 '0' (String.fromInt (getMonthNumber (Calendar.getMonth date)))
        ++ "/"
        ++ String.fromInt (Calendar.getYear date)


toShortString : Date -> String
toShortString (Date date) =
    String.padLeft 2 '0' (String.fromInt (Calendar.getDay date))
        ++ "/"
        ++ String.padLeft 2 '0' (String.fromInt (getMonthNumber (Calendar.getMonth date)))


fromParts : { year : Int, month : Int, day : Int } -> Maybe Date
fromParts { year, month, day } =
    Array.get month Calendar.months
        |> Maybe.andThen
            (\m ->
                Maybe.map Date
                    (Calendar.fromRawParts { day = day, month = m, year = year })
            )



{-
   fromZoneAndPosix : Time.Zone -> Time.Posix -> Date
   fromZoneAndPosix zone time =
       let
           y =
               Time.toYear zone time

           m =
               Time.toMonth zone time

           d =
               Time.toDay zone time
       in
       case Calendar.fromRawParts { day = d, month = m, year = y } of
           Just date ->
               Date date

           Nothing ->
               Date (Calendar.fromPosix (Time.millisToPosix 0))
-}


fromPosix : Time.Posix -> Date
fromPosix time =
    Date (Calendar.fromPosix time)


decrementWeek : Date -> Date
decrementWeek (Date date) =
    Date
        (date
            |> Calendar.decrementDay
            |> Calendar.decrementDay
            |> Calendar.decrementDay
            |> Calendar.decrementDay
            |> Calendar.decrementDay
            |> Calendar.decrementDay
            |> Calendar.decrementDay
        )


incrementWeek : Date -> Date
incrementWeek (Date date) =
    Date
        (date
            |> Calendar.incrementDay
            |> Calendar.incrementDay
            |> Calendar.incrementDay
            |> Calendar.incrementDay
            |> Calendar.incrementDay
            |> Calendar.incrementDay
            |> Calendar.incrementDay
        )


getMonthNumber : Time.Month -> Int
getMonthNumber m =
    case m of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12


getMonthName : Time.Month -> String
getMonthName month =
    case month of
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


getWeekdayName : Date -> String
getWeekdayName (Date d) =
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


getMonthYearName : MonthYear -> String
getMonthYearName monthYear =
    let
        n =
            getMonthName monthYear.month
    in
    n ++ " " ++ String.fromInt monthYear.year


toInt : Date -> Int
toInt (Date date) =
    let
        y =
            Calendar.getYear date

        m =
            Calendar.getMonth date |> Calendar.monthToInt

        d =
            Calendar.getDay date
    in
    d + 100 * m + 10000 * y


encode : Date -> Encode.Value
encode date =
    toInt date |> Encode.int


fromInt : Int -> Date
fromInt n =
    let
        y =
            n // 10000

        m =
            (n - y * 10000) // 100

        d =
            n - y * 10000 - m * 100

        mm =
            Array.get (m - 1) Calendar.months

        raw =
            mm
                |> Maybe.andThen
                    (\mmm ->
                        Calendar.fromRawParts
                            { year = y
                            , month = mmm
                            , day = d
                            }
                    )
    in
    case raw of
        Nothing ->
            --TODO: propagate error?
            fromPosix (Time.millisToPosix 0)

        Just date ->
            Date date


decode : Decode.Decoder Date
decode =
    Decode.map fromInt Decode.int


decrementMonth : Date -> Date
decrementMonth (Date date) =
    Date (Calendar.decrementMonth date)


decrementMonthYear : MonthYear -> MonthYear
decrementMonthYear monthYear =
    { month = previousMonth monthYear.month
    , year =
        if monthYear.month == Time.Jan then
            monthYear.year - 1

        else
            monthYear.year
    }


incrementMonth : Date -> Date
incrementMonth (Date date) =
    Date (Calendar.incrementMonth date)


incrementMonthYear : MonthYear -> MonthYear
incrementMonthYear monthYear =
    { month = followingMonth monthYear.month
    , year =
        if monthYear.month == Time.Dec then
            monthYear.year + 1

        else
            monthYear.year
    }


getDay : Date -> Int
getDay (Date date) =
    Calendar.getDay date


decrementDay : Date -> Date
decrementDay (Date date) =
    Date (Calendar.decrementDay date)


incrementDay : Date -> Date
incrementDay (Date date) =
    Date (Calendar.incrementDay date)


lastDayOf : Date -> Date
lastDayOf (Date date) =
    case Calendar.setDay (Calendar.lastDayOf date) date of
        Just d ->
            Date d

        Nothing ->
            default


firstDayOf : Date -> Date
firstDayOf (Date date) =
    case Calendar.setDay 1 date of
        Just d ->
            Date d

        Nothing ->
            default


findNextDayOfMonth : Int -> Date -> Date
findNextDayOfMonth day date =
    let
        d =
            incrementDay date
    in
    if getDay d == day then
        d

    else
        findNextDayOfMonth day d


getWeekday : Date -> Time.Weekday
getWeekday (Date date) =
    Calendar.getWeekday date


compare : Date -> Date -> Order
compare (Date a) (Date b) =
    Calendar.compare a b


getMonth : Date -> Time.Month
getMonth (Date date) =
    Calendar.getMonth date


getYear : Date -> Int
getYear (Date date) =
    Calendar.getYear date


getDayDiff : Date -> Date -> Int
getDayDiff (Date date1) (Date date2) =
    Calendar.getDayDiff date1 date2


firstDayOfMonth : MonthYear -> Date
firstDayOfMonth monthYear =
    case Calendar.fromRawParts { day = 1, month = monthYear.month, year = monthYear.year } of
        Just d ->
            Date d

        Nothing ->
            default


lastDayOfMonth : MonthYear -> Date
lastDayOfMonth monthYear =
    let
        firstDay =
            case firstDayOfMonth monthYear of
                Date d ->
                    d
    in
    case Calendar.fromRawParts { day = Calendar.lastDayOf firstDay, month = monthYear.month, year = monthYear.year } of
        Just d ->
            Date d

        Nothing ->
            default


mondayOfWeek : Date -> Date
mondayOfWeek date =
    case getWeekday date of
        Time.Mon ->
            date

        _ ->
            mondayOfWeek (decrementDay date)


daysOfWeek : Date -> List Date
daysOfWeek date =
    let
        step d =
            case getWeekday d of
                Time.Sun ->
                    [ d ]

                _ ->
                    d :: (step <| incrementDay d)
    in
    step <| mondayOfWeek date


weeksOfMonth : MonthYear -> List (List Date)
weeksOfMonth monthYear =
    let
        firstDay =
            mondayOfWeek <| firstDayOfMonth monthYear

        lastDay =
            lastDayOfMonth monthYear

        step d =
            case ( compare d lastDay, getWeekday d ) of
                ( GT, Time.Mon ) ->
                    []

                _ ->
                    daysOfWeek d
                        :: (step <| incrementWeek d)
    in
    step firstDay


fancyDayDescription : Date -> Date -> String
fancyDayDescription today date =
    let
        dayDiff =
            getDayDiff today date
    in
    if date == today then
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


fancyWeekDescription : Date -> Date -> String
fancyWeekDescription today date =
    let
        thisMonday =
            mondayOfWeek today

        dateMonday =
            mondayOfWeek date

        wdelta =
            getDayDiff thisMonday dateMonday
    in
    if wdelta < -14 then
        "il y a " ++ (String.fromInt <| abs wdelta // 7) ++ " semaines"

    else if wdelta < -7 then
        "il y a 15 jours"

    else if wdelta < 0 then
        "la semaine dernière"

    else if wdelta < 7 then
        "cette semaine"

    else if wdelta < 14 then
        "la semaine prochaine"

    else if wdelta < 21 then
        "dans 15 jours"

    else
        "dans " ++ (String.fromInt <| wdelta // 7) ++ " semaines"
