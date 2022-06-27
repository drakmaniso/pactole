module Msg exposing (DatabaseMsg(..), InstallMsg(..), Msg(..), SettingsMsg(..), TransactionMsg(..))

import Date exposing (Date)
import Json.Decode as Decode
import Ledger
import Model


type Msg
    = ChangePage Model.Page
    | OpenDialog Model.Dialog
    | CloseDialog
    | ConfirmDialog
    | OnPopState ()
    | OnLeftSwipe ()
    | OnRightSwipe ()
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
    | ImportInstall


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
