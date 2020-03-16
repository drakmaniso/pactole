module View.Tabular exposing (view)

import Date
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Ledger
import Model
import Msg
import View.Style as Style
import View.Summary as Summary


view : Model.Model -> Element Msg.Msg
view model =
    row
        [ width fill
        , height fill
        , clipX
        , clipY
        , htmlAttribute <| Html.Attributes.style "z-index" "-1"
        , Background.color Style.bgPage
        , Style.fontFamily
        ]
        [ column
            [ width (fillPortion 25), height fill, padding 16, alignTop ]
            [ el
                [ width fill, height (fillPortion 1) ]
                (Summary.view model)
            , el
                [ width fill, height (fillPortion 2) ]
                none
            ]
        , column
            [ width (fillPortion 75)
            , height fill
            , Border.widthEach { top = 0, bottom = 0, left = 3, right = 0 }
            , Border.color Style.bgDark
            ]
            (transactionView model)
        ]


transactionView : Model.Model -> List (Element Msg.Msg)
transactionView model =
    Tuple.second
        (List.foldl
            makeRow
            ( Nothing, [] )
            (Ledger.getAllTransactions model.ledger)
        )
        |> List.reverse


makeRow transaction ( prevDate, accum ) =
    let
        dateTxt =
            el
                [ paddingEach { left = 12, right = 12, top = 24, bottom = 12 }
                , Style.bigFont
                , Font.color Style.fgTitle
                ]
                (text
                    (Date.getWeekdayName transaction.date
                        ++ " "
                        ++ String.fromInt (Date.getDay transaction.date)
                        ++ " "
                        ++ Date.getMonthName transaction.date
                     --TODO: add year for previous years
                    )
                )

        parts =
            Ledger.getAmountParts transaction

        txt =
            el []
                (text
                    ("transaction: "
                        ++ Date.toString transaction.date
                        ++ " amount="
                        ++ parts.units
                    )
                )
    in
    case prevDate of
        Nothing ->
            ( Just transaction.date, txt :: dateTxt :: accum )

        Just date ->
            case Date.compare date transaction.date of
                EQ ->
                    ( Just transaction.date, txt :: accum )

                _ ->
                    ( Just transaction.date, txt :: dateTxt :: accum )
