module Msg exposing (DatabaseMsg(..), DialogFocus(..), Msg(..), SettingsMsg(..), TransactionMsg(..), WelcomeMsg(..))

import Browser.Dom as Dom
import Date exposing (Date)
import File exposing (File)
import Json.Decode as Decode
import Ledger
import Model


type Msg
    = OnApplicationStart ()
    | ChangePage Model.Page
    | OpenDialog DialogFocus Model.Dialog
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
    | SetReconcileViewport Model.Page (Result Dom.Error Dom.Viewport)
    | ForWelcome WelcomeMsg
    | ForDatabase DatabaseMsg
    | ForTransaction TransactionMsg
    | ForSettings SettingsMsg
    | NoOp


type DialogFocus
    = FocusInput
    | DontFocusInput


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
