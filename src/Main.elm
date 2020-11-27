module Main exposing (..)

import Array
import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Navigation
import Database
import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Log
import Model
import Money
import Msg
import Page.Calendar as Calendar
import Page.Dialog as Dialog
import Page.Reconcile as Reconcile
import Page.Settings as Settings
import Page.Statistics as Statistics
import Page.Tabular as Tabular
import Process
import Task
import Time
import Ui
import Url



-- MAIN


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
    in
    ( { settings =
            { categoriesEnabled = False
            , defaultMode = Model.InCalendar
            , reconciliationEnabled = False
            , summaryEnabled = False
            , balanceWarning = 100
            , recurringTransactions = []
            }
      , today = today
      , date = today
      , ledger = Ledger.empty
      , accounts = Dict.empty
      , account = Nothing
      , categories = Dict.empty
      , showAdvanced = False
      , advancedCounter = 0
      , showFocus = False
      , page = Model.MainPage
      , dialog = Nothing
      , settingsDialog = Nothing
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
            ( { model | account = Just accountID }, Database.requestLedger accountID )

        Msg.KeyDown string ->
            if string == "Alt" || string == "Control" || string == "Shift" then
                ( { model | showAdvanced = True }, Cmd.none )

            else if string == "Tab" then
                ( { model | showFocus = True }, Cmd.none )

            else
                ( model, Cmd.none )

        Msg.KeyUp string ->
            ( { model | showAdvanced = False }, Cmd.none )

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
        ]


keyDecoder : (String -> Msg.Msg) -> Decode.Decoder Msg.Msg
keyDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.map msg



-- VIEW


view : Model.Model -> Browser.Document Msg.Msg
view model =
    { title = "Pactole"
    , body =
        [ E.layoutWith
            { options =
                [ E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow =
                        if model.showFocus then
                            Just
                                { color = Ui.fgFocus
                                , offset = ( 0, 0 )
                                , blur = 0
                                , size = 4
                                }

                        else
                            Just
                                { color = E.rgba 0 0 0 0
                                , offset = ( 0, 0 )
                                , blur = 0
                                , size = 0
                                }
                    }
                ]
            }
            (case model.dialog of
                Just dialog ->
                    [ E.inFront
                        (E.el
                            [ E.width E.fill
                            , E.height E.fill
                            , Ui.fontFamily
                            , E.padding 16
                            , E.scrollbarY
                            , E.behindContent
                                (Input.button
                                    [ E.width E.fill
                                    , E.height E.fill
                                    , Background.color (E.rgba 0 0 0 0.6)
                                    ]
                                    { label = E.none
                                    , onPress = Just Msg.Close
                                    }
                                )
                            ]
                            (Dialog.view model)
                        )
                    ]

                Nothing ->
                    case model.settingsDialog of
                        Just dialog ->
                            [ E.inFront
                                (E.el
                                    [ E.width E.fill
                                    , E.height E.fill
                                    , Ui.fontFamily
                                    , E.padding 16
                                    , E.scrollbarY
                                    , E.behindContent
                                        (Input.button
                                            [ E.width E.fill
                                            , E.height E.fill
                                            , Background.color (E.rgba 0 0 0 0.6)
                                            ]
                                            { label = E.none
                                            , onPress = Just Msg.Close
                                            }
                                        )
                                    ]
                                    (Settings.viewDialog model)
                                )
                            ]

                        Nothing ->
                            [ E.inFront (E.column [] [])
                            ]
            )
            (case model.page of
                Model.SettingsPage ->
                    Settings.view model

                Model.StatsPage ->
                    Statistics.view model

                Model.ReconcilePage ->
                    Reconcile.view model

                Model.MainPage ->
                    case model.settings.defaultMode of
                        Model.InCalendar ->
                            Calendar.view model

                        Model.InTabular ->
                            Tabular.view model
            )
        ]
    }
