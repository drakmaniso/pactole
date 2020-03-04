module View.Tabular exposing (view)

import Date
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Ledger
import Model
import Msg
import View.Style as Style


view : Model.Model -> Element Msg.Msg
view model =
    row
        [ width fill
        , height fill
        , Background.color Style.bgPage
        , inFront (el [ alignTop, alignRight ] (Input.button [] { label = text "[Config]", onPress = Just Msg.ToSettings }))
        ]
        [ column
            [ width (fillPortion 3), height fill ]
            [ el [ centerX, alignTop ] (text "Opérations")
            , row
                [ width fill, height fill ]
                []
            ]
        , column
            [ width (fillPortion 6), height fill, Background.color Style.bgWhite ]
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

        txt =
            el []
                (text
                    ("transaction: "
                        ++ Date.toString transaction.date
                        ++ " amount="
                        ++ Ledger.formatAmount transaction.amount
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
