module Msg exposing (Msg(..))

import Browser
import Date
import Json.Decode as Decode
import Ledger
import Money
import Url


type Msg
    = Today Date.Date
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ToCalendar
    | ToTabular
    | DialogAmount String
    | DialogDescription String
    | ToMainPage
    | ToSettings
    | Close
    | SelectDay Date.Date
    | ChooseAccount String
    | UpdateAccounts Decode.Value
    | UpdateLedger Decode.Value
    | KeyDown String
    | KeyUp String
    | NewIncome
    | NewExpense
    | Edit Int
    | Delete
    | ConfirmNew (Maybe Money.Money)
    | ConfirmEdit Int (Maybe Money.Money)
    | NoOp
