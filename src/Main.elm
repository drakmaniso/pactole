module Main exposing (init, keyDecoder, main, subscriptions, update, view)

import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Navigation
import Database
import Date
import Dict
import Json.Decode as Decode
import Ledger
import Log
import Model
import Msg
import Page.Calendar as Calendar
import Page.Dialog as Dialog
import Page.Help as Help
import Page.Reconcile as Reconcile
import Page.Settings as Settings
import Page.Statistics as Statistics
import Process
import Task
import Ui
import Url



-- MAIN


main : Program Decode.Value Model.Model Msg.Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = \_ -> Msg.NoOp
        , onUrlRequest = \_ -> Msg.NoOp
        }



-- INIT


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model.Model, Cmd Msg.Msg )
init flags _ _ =
    let
        day =
            case Decode.decodeValue (Decode.at [ "today", "day" ] Decode.int) flags of
                Ok v ->
                    v

                Err _ ->
                    --TODO
                    0

        month =
            case Decode.decodeValue (Decode.at [ "today", "month" ] Decode.int) flags of
                Ok v ->
                    v

                Err _ ->
                    --TODO
                    0

        year =
            case Decode.decodeValue (Decode.at [ "today", "year" ] Decode.int) flags of
                Ok v ->
                    v

                Err _ ->
                    --TODO
                    0

        ( today, cmd ) =
            case Date.fromParts { day = day, month = month, year = year } of
                Just d ->
                    ( d, Cmd.none )

                Nothing ->
                    ( Date.default, Log.error "init flags: invalid date for today" )

        width =
            Decode.decodeValue (Decode.at [ "width" ] Decode.int) flags |> Result.withDefault 800

        height =
            Decode.decodeValue (Decode.at [ "height" ] Decode.int) flags |> Result.withDefault 600
    in
    ( { settings =
            { categoriesEnabled = False
            , reconciliationEnabled = False
            , summaryEnabled = False
            , balanceWarning = 100
            , settingsLocked = False
            }
      , today = today
      , date = today
      , ledger = Ledger.empty
      , recurring = Ledger.empty
      , accounts = Dict.empty
      , account = -1 --TODO!!!
      , categories = Dict.empty
      , showAdvanced = False
      , advancedCounter = 0
      , showFocus = False
      , page = Model.MainPage
      , dialog = Nothing
      , settingsDialog = Nothing
      , serviceVersion = "unknown"
      , device = Ui.device width height
      }
    , cmd
      {-
         , Cmd.batch
             [ Task.perform Msg.Today (Task.map2 Date.fromZoneAndPosix Time.here Time.now)
             ]
      -}
    )



-- UPDATE


update : Msg.Msg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.ChangePage page ->
            ( { model | page = page }
            , Task.attempt (\_ -> Msg.NoOp) (Dom.blur "unfocus-on-page-change")
            )

        Msg.AttemptSettings ->
            ( { model
                | advancedCounter =
                    if model.advancedCounter > 3 then
                        3

                    else
                        model.advancedCounter + 1
                , showAdvanced = model.advancedCounter >= 3
              }
            , Task.perform
                (\_ -> Msg.AttemptTimeout)
                (Process.sleep 3000.0
                    |> Task.andThen (\_ -> Task.succeed ())
                )
            )

        Msg.AttemptTimeout ->
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

        Msg.Close ->
            --TODO: delegate to Dialog?
            ( { model | dialog = Nothing, settingsDialog = Nothing }, Cmd.none )

        Msg.SelectDate date ->
            ( { model | date = date }, Cmd.none )

        Msg.SelectAccount accountID ->
            ( { model | account = accountID }, Cmd.none )

        Msg.KeyDown string ->
            if string == "Alt" || string == "Control" || string == "Shift" then
                ( { model | showAdvanced = True }, Cmd.none )

            else if string == "Tab" then
                ( { model | showFocus = True }, Cmd.none )

            else
                ( model, Cmd.none )

        Msg.KeyUp _ ->
            ( { model | showAdvanced = False }, Cmd.none )

        Msg.WindowResize size ->
            ( { model
                | device = Ui.device size.width size.height
              }
            , Cmd.none
            )

        Msg.ForDatabase m ->
            Database.update m model

        Msg.ForDialog m ->
            Dialog.update m model

        Msg.ForSettingsDialog m ->
            Settings.update m model

        Msg.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model.Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ Database.receive
        , Browser.Events.onKeyDown (keyDecoder Msg.KeyDown)
        , Browser.Events.onKeyUp (keyDecoder Msg.KeyUp)
        , Browser.Events.onResize (\width height -> Msg.WindowResize { width = width, height = height })
        ]


keyDecoder : (String -> Msg.Msg) -> Decode.Decoder Msg.Msg
keyDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.map msg



-- VIEW


view : Model.Model -> Browser.Document Msg.Msg
view model =
    let
        activeDialog =
            case model.dialog of
                Just _ ->
                    Just (Dialog.view model)

                Nothing ->
                    model.settingsDialog |> Maybe.map (\_ -> Settings.viewDialog model)

        activePage =
            case model.page of
                Model.HelpPage ->
                    Help.view model

                Model.SettingsPage ->
                    Settings.view model

                Model.StatsPage ->
                    Statistics.view model

                Model.ReconcilePage ->
                    Reconcile.view model

                Model.MainPage ->
                    Calendar.view model
    in
    Ui.document "Pactole" activePage activeDialog Msg.Close model.showFocus
