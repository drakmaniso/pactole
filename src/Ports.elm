port module Ports exposing (..)

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Money
import Msg


port send : ( String, Encode.Value ) -> Cmd msg


port receive : (( String, Decode.Value ) -> msg) -> Sub msg



-- HELPERS


error : String -> Cmd Msg.Msg
error msg =
    send ( "error", Encode.string msg )


getAccountList =
    send ( "get account list", Encode.object [] )


openAccount : String -> Cmd Msg.Msg
openAccount account =
    send ( "open account", Encode.string account )


updateTransaction : { account : Maybe String, id : Int, date : Date.Date, amount : Money.Money, description : String } -> Cmd Msg.Msg
updateTransaction { account, id, date, amount, description } =
    case account of
        Just acc ->
            send
                ( "update transaction"
                , Encode.object
                    [ ( "account", Encode.string acc )
                    , ( "id", Encode.int id )
                    , ( "date", Encode.int (Date.toInt date) )
                    , ( "amount", Money.encoder amount )
                    , ( "description", Encode.string description )
                    ]
                )

        Nothing ->
            error "update transaction: no current account"


newTransaction : { account : Maybe String, date : Date.Date, amount : Money.Money, description : String } -> Cmd Msg.Msg
newTransaction { account, date, amount, description } =
    case account of
        Just acc ->
            send
                ( "new transaction"
                , Encode.object
                    [ ( "account", Encode.string acc )
                    , ( "date", Encode.int (Date.toInt date) )
                    , ( "amount", Money.encoder amount )
                    , ( "description", Encode.string description )
                    ]
                )

        Nothing ->
            error "new transaction: no current account"
