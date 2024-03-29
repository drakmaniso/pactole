module Model exposing
    ( AccountData
    , Category
    , CategoryData
    , Database
    , Dialog(..)
    , Model
    , Page(..)
    , RecurringData
    , Settings
    , TransactionData
    , WelcomeData
    , accountName
    , category
    , completeDefaultSettings
    , decodeAccount
    , decodeCategories
    , decodeSettings
    , encodeAccounts
    , encodeCategories
    , encodeDatabase
    , encodeSettings
    , firstAccount
    , pageKey
    , simplifiedDefaultSettings
    )

import Browser.Dom as Dom
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
    , monthDisplayed : Date.MonthYear
    , monthPrevious : Date.MonthYear
    , dateSelected : Date
    , account : Int
    , page : Page
    , dialog : Maybe Dialog
    , serviceVersion : String
    , context : Ui.Context
    , errors : List String
    , nbMonthsDisplayed : Int
    , reconcileViewport : Maybe Dom.Viewport

    -- Persistent Data
    , settings : Settings
    , ledger : Ledger
    , recurring : Ledger
    , accounts : Dict.Dict Int String
    , categories : Dict.Dict Int Category
    }


type Page
    = LoadingPage
    | WelcomePage WelcomeData
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

        WelcomePage _ ->
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


type alias WelcomeData =
    { wantSimplified : Bool
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


decodeCategories : Decode.Decoder (List ( Int, { name : String, icon : String } ))
decodeCategories =
    Decode.list decodeCategory



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
    , showMonthTotal : Bool
    , font : String
    , fontSize : Int
    , deviceClass : Ui.DeviceClass
    , animationDisabled : Bool
    }


simplifiedDefaultSettings : Settings
simplifiedDefaultSettings =
    { categoriesEnabled = False
    , reconciliationEnabled = False
    , summaryEnabled = False
    , balanceWarning = 100
    , showMonthTotal = False
    , font = "Andika New Basic"
    , fontSize = 0
    , deviceClass = Ui.AutoClass
    , animationDisabled = False
    }


completeDefaultSettings : Settings
completeDefaultSettings =
    { simplifiedDefaultSettings
        | categoriesEnabled = True
        , reconciliationEnabled = True
        , summaryEnabled = True
        , balanceWarning = 100
    }


encodeSettings : Settings -> Decode.Value
encodeSettings settings =
    Encode.object
        [ ( "categoriesEnabled", Encode.bool settings.categoriesEnabled )
        , ( "reconciliationEnabled", Encode.bool settings.reconciliationEnabled )
        , ( "summaryEnabled", Encode.bool settings.summaryEnabled )
        , ( "balanceWarning", Encode.int settings.balanceWarning )
        , ( "showMonthTotal", Encode.bool settings.showMonthTotal )
        , ( "font", Encode.string settings.font )
        , ( "fontSize", Encode.int settings.fontSize )
        , ( "deviceClass", Ui.encodeDeviceClass settings.deviceClass )
        , ( "animationDisabled", Encode.bool settings.animationDisabled )
        ]


decodeSettings : Decode.Decoder Settings
decodeSettings =
    Decode.map2
        (\part1 part2 ->
            { categoriesEnabled = part1.categoriesEnabled
            , reconciliationEnabled = part1.reconciliationEnabled
            , summaryEnabled = part1.summaryEnabled
            , balanceWarning = part1.balanceWarning
            , showMonthTotal = part1.showMonthTotal
            , font = part2.font
            , fontSize = part2.fontSize
            , deviceClass = part2.deviceClass
            , animationDisabled = part2.animationDisabled
            }
        )
        decodeSettingsPart1
        decodeSettingsPart2


decodeSettingsPart1 =
    Decode.map5
        (\cat rec summ balwarn showmonth ->
            { categoriesEnabled = cat
            , reconciliationEnabled = rec
            , summaryEnabled = summ
            , balanceWarning = balwarn
            , showMonthTotal = showmonth
            }
        )
        (Decode.oneOf [ Decode.field "categoriesEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "reconciliationEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "summaryEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "balanceWarning" Decode.int, Decode.succeed 100 ])
        (Decode.oneOf [ Decode.field "showMonthTotal" Decode.bool, Decode.succeed False ])


decodeSettingsPart2 =
    Decode.map4
        (\font fontSize deviceClass animationDisabled ->
            { font = font
            , fontSize = fontSize
            , deviceClass = deviceClass
            , animationDisabled = animationDisabled
            }
        )
        (Decode.oneOf [ Decode.field "font" Decode.string, Decode.succeed "Andika New Basic" ])
        (Decode.oneOf [ Decode.field "fontSize" Decode.int, Decode.succeed 0 ])
        (Decode.oneOf [ Decode.field "deviceClass" Ui.decodeDeviceClass, Decode.succeed Ui.AutoClass ])
        (Decode.oneOf [ Decode.field "animationDisabled" Decode.bool, Decode.succeed False ])



-- DIALOGS


type Dialog
    = TransactionDialog TransactionData
    | DeleteTransactionDialog Int
    | AccountDialog AccountData
    | DeleteAccountDialog Int
    | CategoryDialog CategoryData
    | DeleteCategoryDialog Int
    | RecurringDialog RecurringData
    | ImportDialog Database
    | ExportDialog String
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


type alias Database =
    { settings : Settings
    , accounts : List ( Int, String ) --TODO: should be a Dict
    , categories :
        List
            ( Int
            , { name : String
              , icon : String
              }
            )
    , ledger : Ledger
    , recurring : Ledger
    , serviceVersion : String
    }


encodeDatabase : Database -> Encode.Value
encodeDatabase db =
    Encode.object
        [ ( "settings", encodeSettings db.settings )
        , ( "accounts", encodeAccounts <| Dict.fromList db.accounts )
        , ( "categories", encodeCategories <| Dict.fromList db.categories )
        , ( "ledger", Ledger.encode db.ledger )
        , ( "recurring", Ledger.encode db.recurring )
        , ( "serviceVersion", Encode.string db.serviceVersion )
        ]


firstAccount : List ( Int, String ) -> Int
firstAccount accounts =
    case accounts |> List.sortBy (\( _, name ) -> name) of
        head :: _ ->
            Tuple.first head

        _ ->
            -1
