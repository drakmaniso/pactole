module Main exposing (..)

import Array
import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Navigation
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
import Model
import Money
import Msg
import Page.Calendar as Calendar
import Page.Dialog as Dialog
import Page.Reconcile as Reconcile
import Page.Settings as Settings
import Page.Statistics as Statistics
import Page.Tabular as Tabular
import Ports
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
        , onUrlChange = Msg.UrlChanged
        , onUrlRequest = Msg.LinkClicked
        }



-- INIT


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model.Model, Cmd Msg.Msg )
init flags _ _ =
    let
        day =
            case Decode.decodeValue (Decode.at [ "today", "day" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    0

        month =
            case Decode.decodeValue (Decode.at [ "today", "month" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    0

        year =
            case Decode.decodeValue (Decode.at [ "today", "year" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    0

        ( today, cmd ) =
            case Date.fromParts { day = day, month = month, year = year } of
                Just d ->
                    ( d, Cmd.none )

                Nothing ->
                    ( Date.default, Ports.error "init flags: invalid date for today" )
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
    let
        settingsMsg handler =
            let
                ( shared, cmd ) =
                    handler model
            in
            ( shared, cmd )
    in
    case msg of
        Msg.Today d ->
            ( { model | today = d, date = d }, Cmd.none )

        Msg.LinkClicked req ->
            case req of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Cmd.none )

        Msg.UrlChanged url ->
            ( model, Cmd.none )

        Msg.FromService ( title, json ) ->
            msgFromService ( title, json ) model

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
            ( { model | account = Just accountID }, Ports.getLedger accountID )

        Msg.KeyDown string ->
            if string == "Alt" || string == "Control" || string == "Shift" then
                ( { model | showAdvanced = True }, Cmd.none )

            else if string == "Tab" then
                ( { model | showFocus = True }, Cmd.none )

            else
                ( model, Cmd.none )

        Msg.KeyUp string ->
            ( { model | showAdvanced = False }, Cmd.none )

        Msg.CreateAccount name ->
            ( model, Ports.createAccount name )

        Msg.CreateCategory name icon ->
            ( model, Ports.createCategory name icon )

        Msg.SetSettings settings ->
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

        Msg.CheckTransaction transaction checked ->
            ( model
            , Ports.putTransaction
                { account = model.account
                , id = transaction.id
                , date = transaction.date
                , amount = transaction.amount
                , description = transaction.description
                , category = transaction.category
                , checked = checked
                }
            )

        Msg.ForDialog m ->
            Dialog.update m model

        Msg.ForSettingsDialog m ->
            Settings.update m model

        Msg.NoOp ->
            ( model, Cmd.none )



-- SERVICE WORKER MESSAGES


msgFromService : ( String, Decode.Value ) -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
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



-- SUBSCRIPTIONS


subscriptions : Model.Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ Ports.receive Msg.FromService
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
                                (E.el
                                    [ E.width E.fill
                                    , E.height E.fill
                                    , Background.color (E.rgba 0 0 0 0.6)
                                    ]
                                    E.none
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
                                    (Settings.viewDialog dialog)
                                )
                            ]

                        Nothing ->
                            [ E.width E.fill
                            , E.height E.fill
                            , E.scrollbarY
                            , E.inFront (E.column [] [])
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
