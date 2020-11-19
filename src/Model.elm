module Model exposing (..)

import Date
import Dict
import Json.Decode as Decode
import Ledger


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


type alias Category =
    { name : String
    , icon : String
    }


type alias Settings =
    { categoriesEnabled : Bool
    , defaultMode : Mode
    , reconciliationEnabled : Bool
    , summaryEnabled : Bool
    , balanceWarning : Int
    , recurringTransactions : List Ledger.NewTransaction
    }


type Mode
    = InCalendar
    | InTabular


type Page
    = MainPage
    | StatsPage
    | ReconcilePage
    | SettingsPage


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


decodeAccount =
    Decode.map2 Tuple.pair
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)


decodeCategory =
    Decode.map3 (\id name icon -> ( id, { name = name, icon = icon } ))
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "icon" Decode.string)


decodeSettings =
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


accountName accountID model =
    Maybe.withDefault
        ("COMPTE_" ++ String.fromInt accountID)
        (Dict.get accountID model.accounts)


category categoryID model =
    Maybe.withDefault
        { name = "CATEGORIE_" ++ String.fromInt categoryID, icon = "" }
        (Dict.get categoryID model.categories)
