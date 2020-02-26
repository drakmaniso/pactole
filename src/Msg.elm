module Msg exposing (Msg(..))

import Browser
import Calendar
import Json.Decode
import Url


type Msg
    = Today Calendar.Date
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ToCalendar
    | ToTabular
    | ToSettings
    | Close
    | SelectDay Calendar.Date
    | ChooseAccount String
    | OnStoreChange String
    | OnLedgerChange Json.Decode.Value
    | KeyDown String
