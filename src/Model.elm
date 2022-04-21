module Model exposing
    ( AccountData
    , Category
    , CategoryData
    , Dialog(..)
    , InstallationData
    , Model
    , Page(..)
    , RecurringData
    , Settings
    , TransactionData
    , accountName
    , category
    , decodeAccount
    , decodeCategory
    , decodeSettings
    , defaultSettings
    , encodeAccounts
    , encodeCategories
    , encodeSettings
    , pageKey
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
    , serviceVersion : String
    , context : Ui.Context
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
    | CalendarPage
    | StatisticsPage
    | ReconcilePage
    | HelpPage
    | SettingsPage
    | DiagnosticsPage


pageKey : Page -> String
pageKey page =
    case page of
        LoadingPage ->
            "loading-page"

        InstallationPage _ ->
            "installation-page"

        CalendarPage ->
            "calendar-page"

        StatisticsPage ->
            "statistics-page"

        ReconcilePage ->
            "reconcile-page"

        HelpPage ->
            "help-page"

        SettingsPage ->
            "settings-page"

        DiagnosticsPage ->
            "diagnostics-page"


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
    , font : String
    , fontSize : Int
    , deviceClass : Ui.DeviceClass
    }


defaultSettings : Settings
defaultSettings =
    { categoriesEnabled = False
    , reconciliationEnabled = False
    , summaryEnabled = False
    , balanceWarning = 100
    , font = "Andika New Basic"
    , fontSize = 0
    , deviceClass = Ui.AutoClass
    }


encodeSettings : Settings -> Decode.Value
encodeSettings settings =
    Encode.object
        [ ( "categoriesEnabled", Encode.bool settings.categoriesEnabled )
        , ( "reconciliationEnabled", Encode.bool settings.reconciliationEnabled )
        , ( "summaryEnabled", Encode.bool settings.summaryEnabled )
        , ( "balanceWarning", Encode.int settings.balanceWarning )
        , ( "font", Encode.string settings.font )
        , ( "fontSize", Encode.int settings.fontSize )
        , ( "deviceClass", Ui.encodeDeviceClass settings.deviceClass )
        ]


decodeSettings : Decode.Decoder Settings
decodeSettings =
    Decode.map7
        (\cat rec summ balwarn font fontSize deviceClass ->
            { categoriesEnabled = cat
            , reconciliationEnabled = rec
            , summaryEnabled = summ
            , balanceWarning = balwarn
            , font = font
            , fontSize = fontSize
            , deviceClass = deviceClass
            }
        )
        (Decode.oneOf [ Decode.field "categoriesEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "reconciliationEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "summaryEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "balanceWarning" Decode.int, Decode.succeed 100 ])
        (Decode.oneOf [ Decode.field "font" Decode.string, Decode.succeed "Andika New Basic" ])
        (Decode.oneOf [ Decode.field "fontSize" Decode.int, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.field "deviceClass" Ui.decodeDeviceClass, Decode.succeed Ui.AutoClass ])



-- DIALOGS


type Dialog
    = TransactionDialog TransactionData
    | DeleteTransactionDialog Int
    | AccountDialog AccountData
    | DeleteAccountDialog Int
    | CategoryDialog CategoryData
    | DeleteCategoryDialog Int
    | RecurringDialog RecurringData
    | ImportDialog
    | ExportDialog
    | FontDialog String
    | UserErrorDialog String


type alias TransactionData =
    { id : Maybe Int
    , isExpense : Bool
    , isRecurring : Bool
    , date : Date
    , amount : ( String, Maybe String )
    , description : String
    , category : Int
    }


type alias AccountData =
    { id : Maybe Int
    , name : String
    }


type alias CategoryData =
    { id : Maybe Int
    , name : String
    , icon : String
    }


type alias RecurringData =
    { id : Maybe Int
    , account : Int
    , isExpense : Bool
    , amount : String
    , description : String
    , category : Int
    , dueDate : String
    }
