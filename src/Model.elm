module Model exposing
    ( Category
    , Dialog
    , InstallationData
    , Model
    , Page(..)
    , Settings
    , SettingsDialog(..)
    , accountName
    , category
    , decodeAccount
    , decodeCategory
    , decodeSettings
    , defaultSettings
    , encodeAccounts
    , encodeCategories
    , encodeSettings
    )

import Date exposing (Date)
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger exposing (Ledger)
import Ui



-- MODEL


type alias Model =
    { today : Date
    , isStoragePersisted : Bool
    , date : Date
    , account : Int
    , page : Page
    , dialog : Maybe Dialog
    , settingsDialog : Maybe SettingsDialog
    , serviceVersion : String
    , device : Ui.Device
    , errors : List String

    -- Persistent Data
    , settings : Settings
    , ledger : Ledger
    , recurring : Ledger
    , accounts : Dict.Dict Int String
    , categories : Dict.Dict Int Category
    }


type Page
    = LoadingPage
    | InstallationPage InstallationData
    | MainPage
    | StatsPage
    | ReconcilePage
    | HelpPage
    | SettingsPage
    | DiagnosticsPage


type alias InstallationData =
    { firstAccount : String
    , initialBalance : ( String, Maybe String )
    }



-- CATEGORY


type alias Category =
    { name : String
    , icon : String
    }


category : Int -> Model -> { name : String, icon : String }
category categoryID model =
    Maybe.withDefault
        { name = "CATEGORIE_" ++ String.fromInt categoryID, icon = "" }
        (Dict.get categoryID model.categories)


encodeCategories : Dict.Dict Int Category -> Encode.Value
encodeCategories categories =
    Encode.list
        (\( id, cat ) ->
            Encode.object
                [ ( "id", Encode.int id )
                , ( "name", Encode.string cat.name )
                , ( "icon", Encode.string cat.icon )
                ]
        )
        (Dict.toList categories)


decodeCategory : Decode.Decoder ( Int, { name : String, icon : String } )
decodeCategory =
    Decode.map3 (\id name icon -> ( id, { name = name, icon = icon } ))
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "icon" Decode.string)



-- ACCOUNT


encodeAccounts : Dict.Dict Int String -> Encode.Value
encodeAccounts accounts =
    Encode.list
        (\( id, name ) ->
            Encode.object
                [ ( "id", Encode.int id )
                , ( "name", Encode.string name )
                ]
        )
        (Dict.toList accounts)


decodeAccount : Decode.Decoder ( Int, String )
decodeAccount =
    Decode.map2 Tuple.pair
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)


accountName : Int -> Model -> String
accountName accountID model =
    Maybe.withDefault
        ("COMPTE_" ++ String.fromInt accountID)
        (Dict.get accountID model.accounts)



-- SETTINGS


type alias Settings =
    { categoriesEnabled : Bool
    , reconciliationEnabled : Bool
    , summaryEnabled : Bool
    , balanceWarning : Int
    , settingsLocked : Bool
    , font : String
    }


defaultSettings : Settings
defaultSettings =
    { categoriesEnabled = False
    , reconciliationEnabled = False
    , summaryEnabled = False
    , balanceWarning = 100
    , settingsLocked = False
    , font = "Work Sans"
    }


encodeSettings : Settings -> Decode.Value
encodeSettings settings =
    Encode.object
        [ ( "categoriesEnabled", Encode.bool settings.categoriesEnabled )
        , ( "reconciliationEnabled", Encode.bool settings.reconciliationEnabled )
        , ( "summaryEnabled", Encode.bool settings.summaryEnabled )
        , ( "balanceWarning", Encode.int settings.balanceWarning )
        , ( "settingsLocked", Encode.bool settings.settingsLocked )
        , ( "font", Encode.string settings.font )
        ]


decodeSettings : Decode.Decoder Settings
decodeSettings =
    Decode.map6
        (\cat rec summ balwarn setlock font ->
            { categoriesEnabled = cat
            , reconciliationEnabled = rec
            , summaryEnabled = summ
            , balanceWarning = balwarn
            , settingsLocked = setlock
            , font = font
            }
        )
        (Decode.oneOf [ Decode.field "categoriesEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "reconciliationEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "summaryEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "balanceWarning" Decode.int, Decode.succeed 100 ])
        (Decode.oneOf [ Decode.field "settingsLocked" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "font" Decode.string, Decode.succeed "Work Sans" ])



-- DIALOGS


type alias Dialog =
    { id : Maybe Int
    , isExpense : Bool
    , isRecurring : Bool
    , date : Date
    , amount : ( String, Maybe String )
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
    | AskImportConfirmation
    | AskExportConfirmation
    | UserError String
