module Msg exposing (..)

import Array as Array
import Browser
import Browser.Dom as Dom
import Date
import Dict
import Json.Decode as Decode
import Ledger
import Model exposing (Model)
import Money
import Ports
import Process
import Task
import Time
import Tuple
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
    | NewDialog Bool Date.Date -- NewDialog isExpense date
    | EditDialog Int
    | DialogAmount String
    | DialogDescription String
    | DialogCategory Int
    | DialogDelete
    | DialogConfirm
    | CreateAccount String
    | OpenRenameAccount Int
    | OpenDeleteAccount Int
    | CreateCategory String String
    | OpenRenameCategory Int
    | OpenDeleteCategory Int
    | SettingsChangeName String
    | SettingsChangeIcon String
    | SetSettings Model.Settings
    | SettingsConfirm
    | CheckTransaction Ledger.Transaction Bool
    | NoOp



-- UPDATE MESSAGES


msgToday : Date.Date -> Model -> ( Model, Cmd Msg )
msgToday d model =
    ( { model | today = d, date = d }, Cmd.none )


msgSelectDate : Date.Date -> Model -> ( Model, Cmd Msg )
msgSelectDate date model =
    ( { model | date = date }, Cmd.none )


msgSelectAccount : Int -> Model -> ( Model, Cmd Msg )
msgSelectAccount accountID model =
    ( { model | account = Just accountID }, Ports.getLedger accountID )


msgCreateAccount : String -> Model -> ( Model, Cmd Msg )
msgCreateAccount name model =
    ( model, Ports.createAccount name )


msgCreateCategory : String -> String -> Model -> ( Model, Cmd Msg )
msgCreateCategory name icon model =
    ( model, Ports.createCategory name icon )


msgShowAdvanced : Bool -> Model -> ( Model, Cmd Msg )
msgShowAdvanced show model =
    ( { model | showAdvanced = show }, Cmd.none )


msgShowFocus : Bool -> Model -> ( Model, Cmd Msg )
msgShowFocus show model =
    ( { model | showFocus = show }, Cmd.none )


msgChangePage : Model.Page -> Model -> ( Model, Cmd Msg )
msgChangePage page model =
    ( { model | page = page }
    , Task.attempt (\_ -> NoOp) (Dom.blur "unfocus-on-page-change")
    )


msgAttemptSettings : Model -> ( Model, Cmd Msg )
msgAttemptSettings model =
    ( { model
        | advancedCounter =
            if model.advancedCounter > 3 then
                3

            else
                model.advancedCounter + 1
        , showAdvanced = model.advancedCounter >= 3
      }
    , Task.perform
        (\_ -> AttemptTimeout)
        (Process.sleep 3000.0
            |> Task.andThen (\_ -> Task.succeed ())
        )
    )


msgAttemptTimeout model =
    ( { model
        | advancedCounter =
            if model.advancedCounter <= 0 then
                0

            else
                model.advancedCounter - 1
        , showAdvanced = model.advancedCounter <= 0
      }
    , Cmd.none
    )


msgSetSettings : Model.Settings -> Model -> ( Model, Cmd Msg )
msgSetSettings settings model =
    let
        modeString =
            case settings.defaultMode of
                Model.InCalendar ->
                    "calendar"

                Model.InTabular ->
                    "tabular"

        settingsString =
            { categoriesEnabled = settings.categoriesEnabled
            , modeString = modeString
            , reconciliationEnabled = settings.reconciliationEnabled
            , summaryEnabled = settings.summaryEnabled
            , balanceWarning = settings.balanceWarning
            , recurringTransactions = settings.recurringTransactions
            }
    in
    ( model
      --{ model | settings = settings }
    , Ports.setSettings settingsString
    )



-- SERVICE WORKER MESSAGES


msgFromService : ( String, Decode.Value ) -> Model -> ( Model, Cmd Msg )
msgFromService ( title, content ) model =
    case title of
        "start application" ->
            ( model
            , Cmd.batch
                [ Ports.getAccountList
                , Ports.getCategoryList
                , Ports.getSettings
                ]
            )

        "set account list" ->
            case Decode.decodeValue (Decode.list Model.decodeAccount) content of
                Ok (head :: tail) ->
                    let
                        accounts =
                            head :: tail

                        accountID =
                            --TODO: use current account if set
                            Tuple.first head
                    in
                    ( { model | accounts = Dict.fromList accounts, account = Just accountID }
                    , Ports.getLedger accountID
                    )

                Err e ->
                    --TODO: error
                    ( model, Ports.error ("while decoding account list: " ++ Decode.errorToString e) )

                _ ->
                    --TODO: error
                    ( model, Ports.error "received account list is empty" )

        "set category list" ->
            case Decode.decodeValue (Decode.list Model.decodeCategory) content of
                Ok categories ->
                    ( { model | categories = Dict.fromList categories }, Cmd.none )

                Err e ->
                    --TODO: error
                    ( model, Ports.error ("while decoding category list: " ++ Decode.errorToString e) )

        "set settings" ->
            case Decode.decodeValue Model.decodeSettings content of
                Ok settings ->
                    ( { model | settings = settings }, Cmd.none )

                Err e ->
                    --TODO: error
                    ( model, Ports.error ("while decoding settings: " ++ Decode.errorToString e) )

        "ledger updated" ->
            case ( model.account, Decode.decodeValue Decode.int content ) of
                ( Just currentID, Ok updatedID ) ->
                    if updatedID == currentID then
                        ( model, Ports.getLedger updatedID )

                    else
                        ( model, Cmd.none )

                ( Nothing, _ ) ->
                    ( model, Cmd.none )

                ( _, Err e ) ->
                    ( model, Ports.error (Decode.errorToString e) )

        "set ledger" ->
            case Decode.decodeValue Ledger.decode content of
                Ok ledger ->
                    ( { model | ledger = ledger }
                    , Cmd.none
                    )

                Err e ->
                    ( model, Ports.error (Decode.errorToString e) )

        "settings updated" ->
            case Decode.decodeValue Model.decodeSettings content of
                Ok settings ->
                    ( { model | settings = settings }
                    , Cmd.none
                    )

                Err e ->
                    ( model, Ports.error (Decode.errorToString e) )

        _ ->
            --TODO: error
            ( model, Ports.error ("in message from service: unknown title \"" ++ title ++ "\"") )
