module MoneyTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import List
import Money exposing (Money)
import Test exposing (..)


testInput : String -> Int -> Test
testInput source expected =
    test source <|
        \_ -> expectFromInput False source expected


expectFromInput : Bool -> String -> Int -> Expectation
expectFromInput asExpense source expected =
    let
        parseResult =
            Money.parse asExpense source
    in
    Expect.equal
        (Ok expected)
        (parseResult |> Result.map Money.toIntForTestingPurposeOnly)


intToMoneyString : Int -> String
intToMoneyString n =
    let
        units =
            abs n // 100

        cents =
            remainderBy 100 (abs n)
    in
    if cents /= 0 then
        String.fromInt units ++ "," ++ (String.fromInt cents |> String.padLeft 2 '0')

    else
        String.fromInt units


suite : Test
suite =
    describe "Money.parse"
        [ test "zero" <|
            \_ -> Expect.equal (Ok Money.zero) (Money.parse False "0")
        , testInput "0" 0
        , fuzz (Fuzz.intRange 0 99) "Fuzzing decimals" <|
            \cents ->
                expectFromInput False
                    ("0," ++ (String.fromInt cents |> String.padLeft 2 '0'))
                    cents
        , fuzz2 (Fuzz.intRange 0 10000) (Fuzz.intRange 0 99) "Fuzzing units and cents" <|
            \units cents ->
                expectFromInput False
                    (String.fromInt units ++ "," ++ (String.fromInt cents |> String.padLeft 2 '0'))
                    (100 * units + cents)
        , fuzz3 Fuzz.bool (Fuzz.intRange 0 10000) (Fuzz.intRange 0 99) "Fuzzing sign units and cents" <|
            \isExpense units cents ->
                let
                    sign =
                        if isExpense then
                            -1

                        else
                            1
                in
                expectFromInput isExpense
                    (String.fromInt units ++ "," ++ (String.fromInt cents |> String.padLeft 2 '0'))
                    (sign * (100 * units + cents))
        , fuzz2 (Fuzz.intRange 0 100000) (Fuzz.intRange 0 100000) "Fuzzing addition" <|
            \a b ->
                expectFromInput False
                    (intToMoneyString a ++ " + " ++ intToMoneyString b)
                    (a + b)
        , fuzz2 (Fuzz.intRange 0 100000) (Fuzz.intRange 0 100000) "Fuzzing substraction" <|
            \a b ->
                expectFromInput False
                    (intToMoneyString a ++ " - " ++ intToMoneyString b)
                    (a - b)
        , fuzz2 (Fuzz.intRange 0 100000) (Fuzz.intRange 0 100000) "Fuzzing addition in expense" <|
            \a b ->
                expectFromInput True
                    (intToMoneyString a ++ " + " ++ intToMoneyString b)
                    -(a + b)
        , fuzz2 (Fuzz.intRange 0 100000) (Fuzz.intRange 0 100000) "Fuzzing substraction in expense" <|
            \a b ->
                expectFromInput True
                    (intToMoneyString a ++ " - " ++ intToMoneyString b)
                    -(a - b)
        , fuzz2 (Fuzz.intRange 0 10000) (Fuzz.intRange 0 99) "Fuzzing double parsing" <|
            \units cents ->
                expectFromInput False
                    (case
                        (String.fromInt units ++ "," ++ (String.fromInt cents |> String.padLeft 2 '0'))
                            |> Money.parse False
                     of
                        Ok money ->
                            Money.absToString money

                        Err err ->
                            err
                    )
                    (100 * units + cents)
        , describe "All ints from 0 to 1000"
            (List.range 0 1000 |> List.map (\i -> testInput (String.fromInt i) (i * 100)))
        , describe "All values from 0 to 100.00"
            (List.range 0 10000
                |> List.map
                    (\i ->
                        testInput
                            (String.fromInt (i // 100)
                                ++ ","
                                ++ (String.fromInt (remainderBy 100 i) |> String.padLeft 2 '0')
                            )
                            i
                    )
            )
        ]
