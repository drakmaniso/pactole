port module Ports exposing (..)

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Model
import Money


port send : ( String, Encode.Value ) -> Cmd msg


port receive : (( String, Decode.Value ) -> msg) -> Sub msg



-- HELPERS


error : String -> Cmd msg
error msg =
    send ( "error", Encode.string msg )


requestAccounts =
    send ( "request accounts", Encode.object [] )


createAccount name =
    send ( "create account", Encode.string name )


renameAccount : Int -> String -> Cmd msg
renameAccount account newName =
    send
        ( "rename account"
        , Encode.object
            [ ( "id", Encode.int account )
            , ( "name", Encode.string newName )
            ]
        )


deleteAccount : Int -> Cmd msg
deleteAccount account =
    send
        ( "delete account"
        , Encode.int account
        )


requestCategories =
    send ( "request categories", Encode.object [] )


createCategory name icon =
    send
        ( "create category"
        , Encode.object
            [ ( "name", Encode.string name )
            , ( "icon", Encode.string icon )
            ]
        )


renameCategory : Int -> String -> String -> Cmd msg
renameCategory id name icon =
    send
        ( "rename category"
        , Encode.object
            [ ( "id", Encode.int id )
            , ( "name", Encode.string name )
            , ( "icon", Encode.string icon )
            ]
        )


deleteCategory : Int -> Cmd msg
deleteCategory id =
    send
        ( "delete category"
        , Encode.int id
        )


requestLedger : Int -> Cmd msg
requestLedger account =
    send ( "request ledger", Encode.int account )


createTransaction : Maybe Int -> Ledger.NewTransaction -> Cmd msg
createTransaction maybeAccount transaction =
    case maybeAccount of
        Just account ->
            send
                ( "create transaction"
                , Ledger.encodeNewTransaction account transaction
                )

        Nothing ->
            error "create transaction: no current account"


replaceTransaction : Maybe Int -> Ledger.Transaction -> Cmd msg
replaceTransaction maybeAccount transaction =
    case maybeAccount of
        Just account ->
            send
                ( "replace transaction"
                , Ledger.encodeTransaction account transaction
                )

        Nothing ->
            error "replace transaction: no current account"


deleteTransaction : Maybe Int -> Int -> Cmd msg
deleteTransaction account id =
    case account of
        Just acc ->
            send
                ( "delete transaction"
                , Encode.object
                    [ ( "account", Encode.int acc )
                    , ( "id", Encode.int id )
                    ]
                )

        Nothing ->
            error "delete transaction: no current account"


requestSettings =
    send ( "request settings", Encode.object [] )


storeSettings : Model.Settings -> Cmd msg
storeSettings settings =
    send ( "store settings", Model.encodeSettings settings )
