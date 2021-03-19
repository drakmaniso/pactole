module Money exposing
    ( Money
    , add
    , decoder
    , encoder
    , fromInput
    , isExpense
    , isGreaterThan
    , isZero
    , toInput
    , toStrings
    , validate
    , zero
    )

import Json.Decode as Decode
import Json.Encode as Encode


type Money
    = Money Int -- Money (units*100 + cents)


zero : Money
zero =
    Money 0


isZero : Money -> Bool
isZero (Money money) =
    money == 0


isExpense : Money -> Bool
isExpense (Money money) =
    money < 0


isGreaterThan : Money -> Int -> Bool
isGreaterThan (Money money) other =
    money > other * 100


add : Money -> Money -> Money
add (Money a) (Money b) =
    Money (a + b)


toStrings : Money -> { sign : String, units : String, cents : String }
toStrings (Money m) =
    { sign =
        if m < 0 then
            "-"

        else
            "+"
    , units =
        abs (m // 100)
            |> String.fromInt
    , cents =
        abs (remainderBy 100 m)
            |> String.fromInt
            |> String.padLeft 2 '0'
    }


toInput : Money -> String
toInput (Money money) =
    let
        units =
            abs (money // 100)

        cents =
            abs (remainderBy 100 money)
    in
    if cents == 0 then
        String.fromInt units

    else
        String.fromInt units ++ "," ++ String.padLeft 2 '0' (String.fromInt cents)


validate : String -> String
validate input =
    let
        trimmed =
            String.filter (\c -> c /= ' ') input
    in
    if trimmed == "" then
        "Entrer un nombre."

    else if String.any (\c -> not (Char.isDigit c || c == ',')) trimmed then
        "Utiliser uniquement des chiffres et une virgule."

    else
        case String.indices "," trimmed of
            [] ->
                ""

            [ i ] ->
                if i /= (String.length trimmed - 3) then
                    "Mettre deux chiffres après la virgule."

                else
                    ""

            _ ->
                "Utiliser une seule virgule."


fromInput : Bool -> String -> Maybe Money
fromInput expense input =
    if validate input == "" then
        let
            sign =
                if expense then
                    -1

                else
                    1
        in
        case String.split "," input of
            [ unitsStr ] ->
                Maybe.map
                    (\v -> Money (sign * v * 100))
                    (String.toInt unitsStr)

            [ unitsStr, centsStr ] ->
                let
                    units =
                        Maybe.map
                            (\v -> v * 100)
                            (String.toInt unitsStr)

                    cents =
                        String.toInt centsStr
                in
                Maybe.map2 (\a b -> sign * (a + b)) units cents
                    |> Maybe.map Money

            _ ->
                Nothing

    else
        Nothing


encoder : Money -> Encode.Value
encoder (Money money) =
    Encode.int money


decoder : Decode.Decoder Money
decoder =
    Decode.map Money Decode.int
