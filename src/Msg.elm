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
    | Receive ( String, Decode.Value )
    | ToCalendar
    | ToTabular
    | ToMainPage
    | ToSettings
    | Close
    | SelectDate Date.Date
    | SelectAccount String
    | KeyDown String
    | KeyUp String
    | NewDialog Bool Date.Date -- NewDialog isExpense date
    | EditDialog Int
    | DialogAmount String
    | DialogDescription String
    | DialogDelete
    | DialogConfirm
    | NoOp
