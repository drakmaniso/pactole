module Msg exposing (DatabaseMsg(..), Msg(..), SettingsMsg(..), TransactionMsg(..), WelcomeMsg(..))

import Date exposing (Date)
import File exposing (File)
import Json.Decode as Decode
import Ledger
import Model


type Msg
    = OnApplicationStart ()
    | ChangePage Model.Page
    | OpenDialog Model.Dialog
    | CloseDialog
    | ConfirmDialog
    | RequestImportFile
    | ReadImportFile File
    | ProcessImportFile String
    | OnPopState ()
    | OnLeftSwipe ()
    | OnRightSwipe ()
    | OnUserError String
    | DisplayMonth Date.MonthYear
    | IncreaseNbMonthsDisplayed
    | SelectDate Date
    | SelectAccount Int
    | WindowResize { width : Int, height : Int }
    | ForWelcome WelcomeMsg
    | ForDatabase DatabaseMsg
    | ForTransaction TransactionMsg
    | ForSettings SettingsMsg
    | NoOp


type WelcomeMsg
    = SetWantSimplified Bool
    | ProceedWithInstall


type DatabaseMsg
    = FromServiceWorker ( String, Decode.Value )
    | StoreSettings Model.Settings
    | CheckTransaction Ledger.Transaction Bool


type TransactionMsg
    = ChangeTransactionAmount String
    | ChangeTransactionDescription String
    | ChangeTransactionCategory Int


type SettingsMsg
    = ChangeSettingsName String
    | ChangeSettingsAccount Int
    | ChangeSettingsAmount String
    | ChangeSettingsDueDate String
    | ChangeSettingsIsExpense Bool
    | ChangeSettingsIcon String
    | DeleteRecurring Int
