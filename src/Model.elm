module Model exposing
    ( Category
    , Dialog
    , Model
    , Page(..)
    , Settings
    , SettingsDialog(..)
    , account
    , category
    , decodeAccount
    , decodeCategory
    , decodeSettings
    , encodeSettings
    )

import Date
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger



-- MODEL


type alias Model =
    { settings : Settings
    , today : Date.Date
    , date : Date.Date
    , ledger : Ledger.Ledger
    , recurring : Ledger.Ledger
    , accounts : Dict.Dict Int String
    , account : Int
    , categories : Dict.Dict Int Category
    , showAdvanced : Bool
    , advancedCounter : Int
    , showFocus : Bool
    , page : Page
    , dialog : Maybe Dialog
    , settingsDialog : Maybe SettingsDialog
    }


type Page
    = MainPage
    | StatsPage
    | ReconcilePage
    | SettingsPage



-- TYPE CATEGORY


type alias Category =
    { name : String
    , icon : String
    }


category : Int -> Model -> { name : String, icon : String }
category categoryID model =
    Maybe.withDefault
        { name = "CATEGORIE_" ++ String.fromInt categoryID, icon = "" }
        (Dict.get categoryID model.categories)


decodeCategory : Decode.Decoder ( Int, { name : String, icon : String } )
decodeCategory =
    Decode.map3 (\id name icon -> ( id, { name = name, icon = icon } ))
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "icon" Decode.string)



-- TYPE ACCOUNT


decodeAccount : Decode.Decoder ( Int, String )
decodeAccount =
    Decode.map2 Tuple.pair
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)


account : Int -> Model -> String
account accountID model =
    Maybe.withDefault
        ("COMPTE_" ++ String.fromInt accountID)
        (Dict.get accountID model.accounts)



-- TYPE SETTINGS


type alias Settings =
    { categoriesEnabled : Bool
    , reconciliationEnabled : Bool
    , summaryEnabled : Bool
    , balanceWarning : Int
    , recurringTransactions : List Ledger.NewTransaction
    }


encodeSettings : Settings -> Decode.Value
encodeSettings settings =
    Encode.object
        [ ( "categoriesEnabled", Encode.bool settings.categoriesEnabled )
        , ( "reconciliationEnabled", Encode.bool settings.reconciliationEnabled )
        , ( "summaryEnabled", Encode.bool settings.summaryEnabled )
        , ( "balanceWarning", Encode.int settings.balanceWarning )
        , ( "recurringTransactions", Encode.list Ledger.encodeNewTransaction settings.recurringTransactions )
        ]


decodeSettings : Decode.Decoder Settings
decodeSettings =
    Decode.map5
        (\cat rec summ balwarn rectrans ->
            { categoriesEnabled = cat
            , reconciliationEnabled = rec
            , summaryEnabled = summ
            , balanceWarning = balwarn
            , recurringTransactions = rectrans
            }
        )
        (Decode.oneOf [ Decode.field "categoriesEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "reconciliationEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "summaryEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "balanceWarning" Decode.int, Decode.succeed 100 ])
        (Decode.oneOf
            [ Decode.field "recurringTransactions" (Decode.list Ledger.decodeNewTransaction)
            , Decode.succeed []
            ]
        )



-- DIALOGS


type alias Dialog =
    { id : Maybe Int
    , isExpense : Bool
    , date : Date.Date
    , amount : String
    , amountError : String
    , description : String
    , category : Int
    }


type SettingsDialog
    = RenameAccount { id : Int, name : String }
    | DeleteAccount { id : Int, name : String }
    | RenameCategory { id : Int, name : String, icon : String }
    | DeleteCategory { id : Int, name : String, icon : String }
    | EditRecurring
        { idx : Int
        , account : Int
        , isExpense : Bool
        , amount : String
        , description : String
        , category : Int
        , dueDate : String
        }
