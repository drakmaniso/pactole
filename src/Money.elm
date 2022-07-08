module Money exposing
    ( Money
    , add
    , decode
    , encode
    , isExpense
    , isGreaterOrEqualThan
    , isZero
    , parse
    , toString
    , toStrings
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


isGreaterOrEqualThan : Money -> Int -> Bool
isGreaterOrEqualThan (Money money) other =
    money >= other * 100


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


toString : Money -> String
toString (Money money) =
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


encode : Money -> Encode.Value
encode (Money money) =
    Encode.int money


decode : Decode.Decoder Money
decode =
    Decode.map Money Decode.int



-- PARSER/CALCULATOR


parse : Bool -> String -> Result String Money
parse asExpense source =
    let
        sign =
            if asExpense then
                -1

            else
                1
    in
    case parseCalc ( String.toList source, ExpectingUnits { amount = zero, sign = 1 } ) of
        ( _, Total (Money amount) ) ->
            Ok (Money <| sign * amount)

        ( _, Problem msg ) ->
            Err msg

        _ ->
            Err "(erreur interne)"


type ParserState
    = ExpectingUnits { amount : Money, sign : Int }
    | ParsingUnits { amount : Money, sign : Int, units : Int }
    | ExpectingComma { amount : Money, sign : Int, units : Int }
    | ExpectingFirstDecimal { amount : Money, sign : Int, units : Int }
    | ExpectingSecondDecimal { amount : Money, sign : Int, units : Int, firstDecimal : Int }
    | ExpectingOperation { amount : Money }
    | Total Money
    | Problem String


parseCalc : ( List Char, ParserState ) -> ( List Char, ParserState )
parseCalc ( source, state ) =
    case state of
        ExpectingUnits { amount, sign } ->
            case takeDigit (skipSpaces source) of
                Just ( d, rest ) ->
                    parseCalc
                        ( rest
                        , ParsingUnits { amount = amount, sign = sign, units = d }
                        )

                Nothing ->
                    case skipSpaces source of
                        ',' :: _ ->
                            ( source, Problem "Entrez au moins un chiffre avant la virgule" )

                        '-' :: _ ->
                            ( source, Problem "Ne mettez pas de signe avant le nombre" )

                        '+' :: _ ->
                            ( source, Problem "Ne mettez pas de signe avant le nombre" )

                        _ :: _ ->
                            ( source, Problem "N'utilisez que des chiffres et une virgule" )

                        [] ->
                            ( source, Problem "Entrez un nombre" )

        ParsingUnits { amount, sign, units } ->
            case takeDigit source of
                Just ( d, rest ) ->
                    parseCalc
                        ( rest
                        , ParsingUnits { amount = amount, sign = sign, units = 10 * units + d }
                        )

                Nothing ->
                    parseCalc
                        ( source
                        , ExpectingComma { amount = amount, sign = sign, units = units }
                        )

        ExpectingComma { amount, sign, units } ->
            case source of
                ',' :: rest ->
                    parseCalc
                        ( rest
                        , ExpectingFirstDecimal { amount = amount, sign = sign, units = units }
                        )

                _ ->
                    parseCalc
                        ( source
                        , ExpectingOperation { amount = add amount (Money <| sign * 100 * units) }
                        )

        ExpectingFirstDecimal { amount, sign, units } ->
            case takeDigit source of
                Just ( d, rest ) ->
                    parseCalc
                        ( rest
                        , ExpectingSecondDecimal { amount = amount, sign = sign, units = units, firstDecimal = d }
                        )

                Nothing ->
                    case source of
                        ' ' :: _ ->
                            ( source, Problem "Ne mettez pas d'espace après la virgule" )

                        _ ->
                            ( source, Problem "Entrez deux chiffres après la virgule" )

        ExpectingSecondDecimal { amount, sign, units, firstDecimal } ->
            case takeDigit source of
                Just ( d, rest ) ->
                    case takeDigit rest of
                        Just _ ->
                            ( source, Problem "Ne mettez que deux chiffres après la virgule" )

                        Nothing ->
                            parseCalc
                                ( rest
                                , ExpectingOperation
                                    { amount = add amount (Money <| sign * (100 * units + 10 * firstDecimal + d)) }
                                )

                Nothing ->
                    ( source, Problem "Entrez deux chiffres après la virgule" )

        ExpectingOperation { amount } ->
            case skipSpaces source of
                c :: rest ->
                    if c == '+' then
                        parseCalc
                            ( rest
                            , ExpectingUnits { amount = amount, sign = 1 }
                            )

                    else if c == '-' then
                        parseCalc
                            ( rest
                            , ExpectingUnits { amount = amount, sign = -1 }
                            )

                    else if c == ',' then
                        ( source, Problem "Ne mettez pas d'espace avant la virgule" )

                    else if Char.isDigit c then
                        ( source, Problem "Ne mettez pas d'espace entre les chiffres" )

                    else
                        ( source, Problem "Utilisez uniquement des chiffres et une virgule" )

                [] ->
                    ( [], Total amount )

        Total amount ->
            ( source, Total amount )

        Problem txt ->
            ( source, Problem txt )


skipSpaces : List Char -> List Char
skipSpaces source =
    case source of
        c :: rest ->
            if c == ' ' then
                skipSpaces rest

            else
                source

        [] ->
            []


takeDigit : List Char -> Maybe ( Int, List Char )
takeDigit source =
    case source of
        c :: rest ->
            if Char.isDigit c then
                Just ( Char.toCode c - Char.toCode '0', rest )

            else
                Nothing

        [] ->
            Nothing
