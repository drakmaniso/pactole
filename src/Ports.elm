port module Ports exposing (..)

import Date
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
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


createTransaction : { account : Maybe Int, date : Date.Date, amount : Money.Money, description : String, category : Int, checked : Bool } -> Cmd msg
createTransaction { account, date, amount, description, category, checked } =
    case account of
        Just acc ->
            send
                ( "create transaction"
                , Encode.object
                    [ ( "account", Encode.int acc )
                    , ( "date", Encode.int (Date.toInt date) )
                    , ( "amount", Money.encoder amount )
                    , ( "description", Encode.string description )
                    , ( "category", Encode.int category )
                    , ( "checked", Encode.bool checked )
                    ]
                )

        Nothing ->
            error "create transaction: no current account"


replaceTransaction : { account : Maybe Int, id : Int, date : Date.Date, amount : Money.Money, description : String, category : Int, checked : Bool } -> Cmd msg
replaceTransaction { account, id, date, amount, description, category, checked } =
    case account of
        Just acc ->
            send
                ( "replace transaction"
                , Encode.object
                    [ ( "account", Encode.int acc )
                    , ( "id", Encode.int id )
                    , ( "date", Encode.int (Date.toInt date) )
                    , ( "amount", Money.encoder amount )
                    , ( "description", Encode.string description )
                    , ( "category", Encode.int category )
                    , ( "checked", Encode.bool checked )
                    ]
                )

        Nothing ->
            error "replace transaction: no current account"


deleteTransaction : { account : Maybe Int, id : Int } -> Cmd msg
deleteTransaction { account, id } =
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


storeSettings : { categoriesEnabled : Bool, modeString : String, reconciliationEnabled : Bool, summaryEnabled : Bool, balanceWarning : Int, recurringTransactions : List Ledger.NewTransaction } -> Cmd msg
storeSettings { categoriesEnabled, modeString, reconciliationEnabled, summaryEnabled, balanceWarning, recurringTransactions } =
    send
        ( "store settings"
        , Encode.object
            [ ( "categoriesEnabled", Encode.bool categoriesEnabled )
            , ( "defaultMode", Encode.string modeString )
            , ( "reconciliationEnabled", Encode.bool reconciliationEnabled )
            , ( "summaryEnabled", Encode.bool summaryEnabled )
            , ( "balanceWarning", Encode.int balanceWarning )
            , ( "recurringTransactions", Encode.list Ledger.encodeNewTransaction recurringTransactions )
            ]
        )
