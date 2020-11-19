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
        sharedMsg handler =
            let
                ( shared, cmd ) =
                    handler model
            in
            ( shared, cmd )

        dialogMsg handler =
            let
                ( shared, cmd ) =
                    handler model
            in
            ( shared, cmd )

        settingsMsg handler =
            let
                ( shared, cmd ) =
                    handler model
            in
            ( shared, cmd )
    in
    case msg of
        Msg.Today d ->
            sharedMsg (Msg.msgToday d)

        Msg.LinkClicked req ->
            case req of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Cmd.none )

        Msg.UrlChanged url ->
            ( model, Cmd.none )

        Msg.FromService ( title, json ) ->
            sharedMsg (Msg.msgFromService ( title, json ))

        Msg.ChangePage page ->
            sharedMsg (Msg.msgChangePage page)

        Msg.AttemptSettings ->
            sharedMsg Msg.msgAttemptSettings

        Msg.AttemptTimeout ->
            sharedMsg Msg.msgAttemptTimeout

        Msg.Close ->
            --TODO: delegate to Dialog?
            ( { model | dialog = Nothing, settingsDialog = Nothing }, Cmd.none )

        Msg.SelectDate date ->
            sharedMsg (Msg.msgSelectDate date)

        Msg.SelectAccount account ->
            sharedMsg (Msg.msgSelectAccount account)

        Msg.KeyDown string ->
            if string == "Alt" || string == "Control" || string == "Shift" then
                sharedMsg (Msg.msgShowAdvanced True)

            else if string == "Tab" then
                sharedMsg (Msg.msgShowFocus True)

            else
                ( model, Cmd.none )

        Msg.KeyUp string ->
            sharedMsg (Msg.msgShowAdvanced False)

        Msg.NewDialog isExpense date ->
            dialogMsg (Dialog.msgNewDialog isExpense date)

        Msg.EditDialog id ->
            dialogMsg (Dialog.msgEditDialog id)

        Msg.DialogAmount amount ->
            dialogMsg (Dialog.msgAmount amount)

        Msg.DialogDescription string ->
            dialogMsg (Dialog.msgDescription string)

        Msg.DialogCategory id ->
            dialogMsg (Dialog.msgCategory id)

        Msg.DialogConfirm ->
            dialogMsg Dialog.msgConfirm

        Msg.DialogDelete ->
            dialogMsg Dialog.msgDelete

        Msg.CreateAccount name ->
            sharedMsg (Msg.msgCreateAccount name)

        Msg.OpenRenameAccount id ->
            ( Settings.openRenameAccount id model
            , Cmd.none
            )

        Msg.OpenDeleteAccount id ->
            ( Settings.openDeleteAccount id model
            , Cmd.none
            )

        Msg.CreateCategory name icon ->
            sharedMsg (Msg.msgCreateCategory name icon)

        Msg.OpenRenameCategory id ->
            ( Settings.openRenameCategory id model
            , Cmd.none
            )

        Msg.OpenDeleteCategory id ->
            ( Settings.openDeleteCategory id model
            , Cmd.none
            )

        Msg.SettingsChangeName name ->
            settingsMsg (Settings.msgChangeName name)

        Msg.SettingsChangeIcon icon ->
            settingsMsg (Settings.msgChangeIcon icon)

        Msg.SetSettings settings ->
            sharedMsg (Msg.msgSetSettings settings)

        Msg.SettingsConfirm ->
            settingsMsg Settings.msgConfirm

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

        Msg.NoOp ->
            ( model, Cmd.none )



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
