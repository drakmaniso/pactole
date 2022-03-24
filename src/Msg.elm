module Msg exposing (DatabaseMsg(..), DialogMsg(..), Msg(..), SettingsDialogMsg(..))

import Date
import Json.Decode as Decode
import Ledger
import Model


type Msg
    = ChangePage Model.Page
    | Close
    | CloseErrorBanner
    | SelectDate Date.Date
    | SelectAccount Int
    | KeyDown String
    | WindowResize { width : Int, height : Int }
    | ForDatabase DatabaseMsg
    | ForDialog DialogMsg
    | ForSettingsDialog SettingsDialogMsg
    | NoOp


type DatabaseMsg
    = DbFromService ( String, Decode.Value )
    | DbCreateAccount String
    | DbCreateCategory String String
    | DbStoreSettings Model.Settings
    | DbCheckTransaction Ledger.Transaction Bool
    | DbExport
    | DbImport


type DialogMsg
    = DialogNewTransaction Bool Date.Date -- isExpense date
    | DialogEditTransaction Int
    | DialogShowRecurring Int
    | DialogChangeAmount String
    | DialogChangeDescription String
    | DialogChangeCategory Int
    | DialogDelete
    | DialogConfirm


type SettingsDialogMsg
    = SettingsRenameAccount Int
    | SettingsDeleteAccount Int
    | SettingsRenameCategory Int
    | SettingsDeleteCategory Int
    | SettingsChangeName String
    | SettingsChangeAccount Int
    | SettingsChangeAmount String
    | SettingsChangeDueDate String
    | SettingsChangeIsExpense Bool
    | SettingsChangeIcon String
    | SettingsConfirm
    | SettingsNewRecurring
    | SettingsEditRecurring Int Int Ledger.Transaction
    | SettingsDeleteRecurring Int
    | SettingsAskImportConfirmation
    | SettingsAskExportConfirmation
