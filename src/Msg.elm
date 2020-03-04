module Msg exposing (Msg(..))

import Browser
import Date
import Json.Decode
import Url


type Msg
    = Today Date.Date
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ToCalendar
    | ToTabular
    | ToSettings
    | Close
    | SelectDay Date.Date
    | ChooseAccount String
    | OnAccounts Json.Decode.Value
    | KeyDown String
