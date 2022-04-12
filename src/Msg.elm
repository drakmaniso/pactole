module Msg exposing (DatabaseMsg(..), InstallMsg(..), Msg(..), SettingsMsg(..), TransactionMsg(..))

import Date exposing (Date)
import Json.Decode as Decode
import Ledger
import Model


type Msg
    = ChangePage Model.Page
    | CloseDialog
    | SelectDate Date
    | SelectAccount Int
    | WindowResize { width : Int, height : Int }
    | ForInstallation InstallMsg
    | ForDatabase DatabaseMsg
    | ForTransaction TransactionMsg
    | ForSettings SettingsMsg
    | ChangeSettings Model.Settings
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
    = NewTransaction Bool Date -- isExpense date
    | EditTransaction Int
    | ShowRecurring Int
    | ChangeTransactionAmount String
    | ChangeTransactionDescription String
    | ChangeTransactionCategory Int
    | DeleteTransaction
    | ConfirmTransaction


type SettingsMsg
    = EditAccount (Maybe Int)
    | DeleteAccount Int
    | EditCategory (Maybe Int)
    | EditRecurring (Maybe Int)
    | Import
    | Export
    | EditFont
    | ChangeSettingsName String
    | ChangeSettingsAccount Int
    | ChangeSettingsAmount String
    | ChangeSettingsDueDate String
    | ChangeSettingsIsExpense Bool
    | ChangeSettingsIcon String
    | DeleteCategory Int
    | DeleteRecurring Int
    | ConfirmSettings
