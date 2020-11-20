module Msg exposing (..)

import Browser
import Date
import Json.Decode as Decode
import Ledger
import Model
import Url


type Msg
    = Today Date.Date
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | FromService ( String, Decode.Value )
    | ChangePage Model.Page
    | AttemptSettings
    | AttemptTimeout
    | Close
    | SelectDate Date.Date
    | SelectAccount Int
    | KeyDown String
    | KeyUp String
    | CreateAccount String
    | CreateCategory String String
    | SetSettings Model.Settings
    | CheckTransaction Ledger.Transaction Bool
    | ForDialog DialogMsg
    | ForSettingsDialog SettingsDialogMsg
    | NoOp


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
    | SettingsChangeIcon String
    | SettingsConfirm
