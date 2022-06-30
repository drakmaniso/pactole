module Msg exposing (DatabaseMsg(..), InstallMsg(..), Msg(..), SettingsMsg(..), TransactionMsg(..))

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
    | SelectDate Date
    | SelectAccount Int
    | WindowResize { width : Int, height : Int }
    | ForInstallation InstallMsg
    | ForDatabase DatabaseMsg
    | ForTransaction TransactionMsg
    | ForSettings SettingsMsg
    | NoOp


type InstallMsg
    = ChangeInstallName String
    | ChangeInstallBalance String
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
