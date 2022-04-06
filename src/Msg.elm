module Msg exposing (DatabaseMsg(..), DialogMsg(..), InstallMsg(..), Msg(..), SettingsDialogMsg(..))

import Date exposing (Date)
import Json.Decode as Decode
import Ledger
import Model


type Msg
    = ChangePage Model.Page
    | Close
    | SelectDate Date
    | SelectAccount Int
    | WindowResize { width : Int, height : Int }
    | ForInstallation InstallMsg
    | ForDatabase DatabaseMsg
    | ForDialog DialogMsg
    | ForSettingsDialog SettingsDialogMsg
    | NoOp


type InstallMsg
    = InstallChangeName String
    | InstallChangeBalance String
    | InstallProceed
    | InstallImport


type DatabaseMsg
    = DbFromService ( String, Decode.Value )
    | DbStoreSettings Model.Settings
    | DbCheckTransaction Ledger.Transaction Bool


type DialogMsg
    = DialogNewTransaction Bool Date -- isExpense date
    | DialogEditTransaction Int
    | DialogShowRecurring Int
    | DialogChangeAmount String
    | DialogChangeDescription String
    | DialogChangeCategory Int
    | DialogDelete
    | DialogConfirm


type SettingsDialogMsg
    = SettingsEditAccount (Maybe Int)
    | SettingsDeleteAccount Int
    | SettingsEditCategory (Maybe Int)
    | SettingsDeleteCategory Int
    | SettingsChangeName String
    | SettingsChangeAccount Int
    | SettingsChangeAmount String
    | SettingsChangeDueDate String
    | SettingsChangeIsExpense Bool
    | SettingsChangeIcon String
    | SettingsConfirm
    | SettingsEditRecurring (Maybe Int)
    | SettingsDeleteRecurring Int
    | SettingsAskImportConfirmation
    | SettingsAskExportConfirmation
    | SettingsEditFont
