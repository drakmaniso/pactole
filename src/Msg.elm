module Msg exposing (DatabaseMsg(..), DialogMsg(..), Msg(..), SettingsDialogMsg(..))

import Date
import Json.Decode as Decode
import Ledger
import Model


type Msg
    = ChangePage Model.Page
    | AttemptSettings
    | AttemptTimeout
    | Close
    | SelectDate Date.Date
    | SelectAccount Int
    | KeyDown String
    | KeyUp String
    | ForDatabase DatabaseMsg
    | ForDialog DialogMsg
    | ForSettingsDialog SettingsDialogMsg
    | NoOp


type DatabaseMsg
    = FromService ( String, Decode.Value )
    | CreateAccount String
    | CreateCategory String String
    | StoreSettings Model.Settings
    | CheckTransaction Ledger.Transaction Bool


type DialogMsg
    = NewDialog Bool Date.Date -- NewDialog isExpense date
    | EditDialog Int
    | DialogAmount String
    | DialogDescription String
    | DialogCategory Int
    | DialogDelete
    | DialogConfirm


type SettingsDialogMsg
    = OpenRenameAccount Int
    | OpenDeleteAccount Int
    | OpenRenameCategory Int
    | OpenDeleteCategory Int
    | SettingsChangeName String
    | SettingsChangeAccount Int
    | SettingsChangeAmount String
    | SettingsChangeDueDate String
    | SettingsChangeIsExpense Bool
    | SettingsChangeIcon String
    | SettingsConfirm
    | NewRecurringTransaction
    | OpenEditRecurring Int Int Ledger.NewTransaction
    | DeleteRecurring Int
