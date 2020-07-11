module Main exposing (..)

import Array
import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Navigation
import Common
import Date
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
import Money
import Msg
import Page.Calendar as Calendar
import Page.Dialog as Dialog
import Page.Settings as Settings
import Page.Tabular as Tabular
import Ports
import Style
import Task
import Time
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



-- MODEL


type alias Model =
    { common : Common.Model
    , dialog : Maybe Dialog.Model
    , settingsDialog : Maybe Settings.Dialog
    , page : Page
    }


type Page
    = MainPage
    | Settings


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg.Msg )
init flags _ _ =
    let
        ( common, commonCmd ) =
            Common.init flags
    in
    ( { common = common
      , dialog = Nothing
      , settingsDialog = Nothing
      , page = MainPage -- Settings -- MainPage
      }
    , Cmd.batch
        [ commonCmd
        ]
      {-
         , Cmd.batch
             [ Task.perform Msg.Today (Task.map2 Date.fromZoneAndPosix Time.here Time.now)
             ]
      -}
    )



-- UPDATE


update : Msg.Msg -> Model -> ( Model, Cmd Msg.Msg )
update msg model =
    let
        commonMsg handler =
            let
                ( common, cmd ) =
                    handler model.common
            in
            ( { model | common = common }, cmd )

        dialogMsg handler =
            let
                ( common, dialog, cmd ) =
                    handler model.common model.dialog
            in
            ( { model | common = common, dialog = dialog }, cmd )

        settingsMsg handler =
            let
                ( settings, cmd ) =
                    handler model.settingsDialog
            in
            ( { model | settingsDialog = settings }, cmd )
    in
    case msg of
        Msg.Today d ->
            commonMsg (Common.msgToday d)

        Msg.LinkClicked req ->
            case req of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Cmd.none )

        Msg.UrlChanged url ->
            ( model, Cmd.none )

        Msg.Receive ( title, json ) ->
            commonMsg (Common.msgReceive ( title, json ))

        Msg.ToCalendar ->
            commonMsg Common.msgToCalendar

        Msg.ToTabular ->
            commonMsg Common.msgToTabular

        Msg.ToMainPage ->
            ( { model | page = MainPage }, Cmd.none )

        Msg.ToSettings ->
            ( { model | page = Settings }, Cmd.none )

        Msg.Close ->
            --TODO: delegate to Dialog?
            ( { model | dialog = Nothing, settingsDialog = Nothing }, Cmd.none )

        Msg.SelectDate date ->
            commonMsg (Common.msgSelectDate date)

        Msg.SelectAccount account ->
            commonMsg (Common.msgSelectAccount account)

        Msg.CreateAccount account ->
            commonMsg (Common.msgCreateAccount account)

        Msg.KeyDown string ->
            if string == "Alt" || string == "Control" then
                commonMsg (Common.msgShowAdvanced True)

            else
                ( model, Cmd.none )

        Msg.KeyUp string ->
            commonMsg (Common.msgShowAdvanced False)

        Msg.NewDialog isExpense date ->
            dialogMsg (Dialog.msgNewDialog isExpense date)

        Msg.EditDialog id ->
            dialogMsg (Dialog.msgEditDialog id)

        Msg.DialogAmount amount ->
            dialogMsg (Dialog.msgAmount amount)

        Msg.DialogDescription string ->
            dialogMsg (Dialog.msgDescription string)

        Msg.DialogConfirm ->
            dialogMsg Dialog.msgConfirm

        Msg.DialogDelete ->
            dialogMsg Dialog.msgDelete

        Msg.OpenRenameAccount account ->
            ( { model
                | settingsDialog =
                    Just (Settings.openRenameAccount account (Common.accountName account model.common))
              }
            , Cmd.none
            )

        Msg.OpenDeleteAccount account ->
            ( { model
                | settingsDialog =
                    Just (Settings.openDeleteAccount account (Common.accountName account model.common))
              }
            , Cmd.none
            )

        Msg.SettingsChangeName name ->
            settingsMsg (Settings.msgChangeName name)

        Msg.SettingsConfirm ->
            settingsMsg Settings.msgConfirm

        Msg.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ Ports.receive Msg.Receive
        , Browser.Events.onKeyDown (keyDecoder Msg.KeyDown)
        , Browser.Events.onKeyUp (keyDecoder Msg.KeyUp)
        ]


keyDecoder : (String -> Msg.Msg) -> Decode.Decoder Msg.Msg
keyDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.map msg



-- VIEW


view : Model -> Browser.Document Msg.Msg
view model =
    { title = "Pactole"
    , body =
        [ E.layoutWith
            { options =
                [ E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow =
                        Just
                            { color = Style.fgFocus
                            , offset = ( 0, 0 )
                            , blur = 0
                            , size = 4
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
                            , Style.fontFamily
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
                            (Dialog.view dialog)
                        )
                    ]

                Nothing ->
                    case model.settingsDialog of
                        Just dialog ->
                            [ E.inFront
                                (E.el
                                    [ E.width E.fill
                                    , E.height E.fill
                                    , Style.fontFamily
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
                            []
            )
            (case model.page of
                Settings ->
                    Settings.view model.common

                MainPage ->
                    case model.common.mode of
                        Common.InCalendar ->
                            Calendar.view model.common

                        Common.InTabular ->
                            Tabular.view model.common
            )
        ]
    }
