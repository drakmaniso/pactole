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
                [ width fill, height (fillPortion 33) ]
                (Summary.view model)
            ]
        , column
            [ width (fillPortion 75), height fill, Background.color Style.bgLight ]
            (transactionView model)
        ]


transactionView : Model.Model -> List (Element Msg.Msg)
transactionView model =
    Tuple.second
        (List.foldl
            makeRow
            ( Nothing, [] )
            (Ledger.transactions model.ledger)
        )
        |> List.reverse


makeRow transaction ( prevDate, accum ) =
    let
        dateTxt =
            el []
                (text
                    ("--"
                        ++ Date.toString transaction.date
                    )
                )

        parts =
            Ledger.amountParts transaction.amount

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
