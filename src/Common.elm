module Common exposing
    ( Mode(..)
    , Model
    , init
    , msgSelectAccount
    , msgSelectDate
    , msgShowAdvanced
    , msgToCalendar
    , msgToTabular
    , msgToday
    , msgUpdateAccountList
    , msgUpdateLedger
    )

import Array as Array
import Date
import Json.Decode as Decode
import Ledger
import Msg
import Ports
import Time


type alias Model =
    { mode : Mode
    , today : Date.Date
    , date : Date.Date
    , ledger : Ledger.Ledger
    , accounts : List String
    , account : Maybe String
    , showAdvanced : Bool
    }


type Mode
    = InCalendar
    | InTabular


init : Decode.Value -> Model
init flags =
    let
        ( accounts, account ) =
            case Decode.decodeValue (Decode.field "accounts" (Decode.list Decode.string)) flags of
                Ok a ->
                    ( a, List.head a )

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) ( [], Nothing )

        day =
            case Decode.decodeValue (Decode.at [ "today", "day" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) 0

        month =
            case Decode.decodeValue (Decode.at [ "today", "month" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) 0

        year =
            case Decode.decodeValue (Decode.at [ "today", "year" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    Debug.log ("init flags: " ++ Decode.errorToString e) 0

        today =
            case Date.fromParts { day = day, month = month, year = year } of
                Just d ->
                    d

                Nothing ->
                    Debug.log "init flags: invalid date for today" Date.default

        ledger =
            case Decode.decodeValue (Decode.field "ledger" Ledger.decoder) flags of
                Ok l ->
                    l

                Err e ->
                    Debug.log ("init flags ledger: " ++ Decode.errorToString e) Ledger.empty
    in
    { mode = InCalendar
    , today = today -- Date.fromPosix (Time.millisToPosix 0)
    , date = today --Date.fromPosix (Time.millisToPosix 0)
    , ledger = ledger
    , accounts = accounts
    , account = account
    , showAdvanced = False
    }



-- UPDATE MESSAGES


msgToday : Date.Date -> Model -> ( Model, Cmd Msg.Msg )
msgToday d model =
    ( { model | today = d, date = d }, Cmd.none )


msgToCalendar : Model -> ( Model, Cmd Msg.Msg )
msgToCalendar model =
    ( { model | mode = InCalendar }
    , Cmd.none
    )


msgToTabular : Model -> ( Model, Cmd Msg.Msg )
msgToTabular model =
    ( { model | mode = InTabular }
    , Cmd.none
    )


msgSelectDate : Date.Date -> Model -> ( Model, Cmd Msg.Msg )
msgSelectDate date model =
    ( { model | date = date }, Cmd.none )


msgSelectAccount : String -> Model -> ( Model, Cmd Msg.Msg )
msgSelectAccount account model =
    ( { model | account = Just account }, Ports.requestLedger account )


msgUpdateAccountList : Decode.Value -> Model -> ( Model, Cmd Msg.Msg )
msgUpdateAccountList json model =
    let
        ( accounts, account ) =
            case Decode.decodeValue (Decode.list Decode.string) json of
                Ok a ->
                    ( a, List.head a )

                Err e ->
                    Debug.log ("Msg.SetAccounts: " ++ Decode.errorToString e)
                        ( [], Nothing )
    in
    ( { model | accounts = accounts, account = account, ledger = Ledger.empty }, Cmd.none )


msgUpdateLedger : Decode.Value -> Model -> ( Model, Cmd Msg.Msg )
msgUpdateLedger json model =
    let
        ledger =
            case Decode.decodeValue Ledger.decoder json of
                Ok l ->
                    l

                Err e ->
                    Debug.log ("Msg.SetLedger: " ++ Decode.errorToString e)
                        Ledger.empty
    in
    ( { model | ledger = ledger }, Cmd.none )


msgShowAdvanced : Bool -> Model -> ( Model, Cmd Msg.Msg )
msgShowAdvanced show model =
    ( { model | showAdvanced = show }, Cmd.none )



--
