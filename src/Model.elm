module Model exposing
    ( Category
    , Dialog
    , Mode(..)
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
    , getRecurringTransactionsFor
    , hasRecurringTransactionsForMonth
    )

import Date
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Money



-- MODEL


type alias Model =
    { settings : Settings
    , today : Date.Date
    , date : Date.Date
    , ledger : Ledger.Ledger
    , accounts : Dict.Dict Int String
    , account : Maybe Int
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
    , defaultMode : Mode
    , reconciliationEnabled : Bool
    , summaryEnabled : Bool
    , balanceWarning : Int
    , recurringTransactions : List ( Int, Ledger.NewTransaction )
    }


type Mode
    = InCalendar
    | InTabular


encodeSettings : Settings -> Decode.Value
encodeSettings settings =
    let
        modeString =
            case settings.defaultMode of
                InCalendar ->
                    "calendar"

                InTabular ->
                    "tabular"

        encodeRecurring ( accountID, transaction ) =
            Ledger.encodeNewTransaction accountID transaction
    in
    Encode.object
        [ ( "categoriesEnabled", Encode.bool settings.categoriesEnabled )
        , ( "defaultMode", Encode.string modeString )
        , ( "reconciliationEnabled", Encode.bool settings.reconciliationEnabled )
        , ( "summaryEnabled", Encode.bool settings.summaryEnabled )
        , ( "balanceWarning", Encode.int settings.balanceWarning )
        , ( "recurringTransactions", Encode.list encodeRecurring settings.recurringTransactions )
        ]


decodeSettings : Decode.Decoder { categoriesEnabled : Bool, defaultMode : Mode, reconciliationEnabled : Bool, summaryEnabled : Bool, balanceWarning : Int, recurringTransactions : List ( Int, Ledger.NewTransaction ) }
decodeSettings =
    let
        decodeMode =
            Decode.map
                (\str ->
                    case str of
                        "calendar" ->
                            InCalendar

                        _ ->
                            InTabular
                )
                Decode.string
    in
    Decode.map6
        (\cat mod rec summ balwarn rectrans ->
            { categoriesEnabled = cat
            , defaultMode = mod
            , reconciliationEnabled = rec
            , summaryEnabled = summ
            , balanceWarning = balwarn
            , recurringTransactions = rectrans
            }
        )
        (Decode.oneOf [ Decode.field "categoriesEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "defaultMode" decodeMode, Decode.succeed InCalendar ])
        (Decode.oneOf [ Decode.field "reconciliationEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "summaryEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "balanceWarning" Decode.int, Decode.succeed 100 ])
        (Decode.oneOf
            [ Decode.field "recurringTransactions" (Decode.list Ledger.decodeNewTransaction)
            , Decode.succeed []
            ]
        )


getRecurringTransactionsFor : Model -> Date.Date -> List Ledger.NewTransaction
getRecurringTransactionsFor model date =
    model.settings.recurringTransactions
        |> List.filter (\( accountID, _ ) -> accountID == Maybe.withDefault -1 model.account)
        |> List.map Tuple.second
        |> List.filter (\t -> Date.compare t.date date == EQ)


hasRecurringTransactionsForMonth : Model -> Date.Date -> Bool
hasRecurringTransactionsForMonth model date =
    model.settings.recurringTransactions
        |> List.any
            (\( accountID, t ) ->
                accountID
                    == Maybe.withDefault -1 model.account
                    && Date.getMonth t.date
                    == Date.getMonth date
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
