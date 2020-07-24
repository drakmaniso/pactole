module Main exposing (..)

import Array
import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Navigation
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
import Shared
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
    { shared : Shared.Model
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
        ( shared, commonCmd ) =
            Shared.init flags
    in
    ( { shared = shared
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
        sharedMsg handler =
            let
                ( shared, cmd ) =
                    handler model.shared
            in
            ( { model | shared = shared }, cmd )

        dialogMsg handler =
            let
                ( shared, dialog, cmd ) =
                    handler model.shared model.dialog
            in
            ( { model | shared = shared, dialog = dialog }, cmd )

        settingsMsg handler =
            let
                ( settings, cmd ) =
                    handler model.settingsDialog
            in
            ( { model | settingsDialog = settings }, cmd )
    in
    case msg of
        Msg.Today d ->
            sharedMsg (Shared.msgToday d)

        Msg.LinkClicked req ->
            case req of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Cmd.none )

        Msg.UrlChanged url ->
            ( model, Cmd.none )

        Msg.FromService ( title, json ) ->
            sharedMsg (Shared.msgFromService ( title, json ))

        Msg.ToCalendar ->
            sharedMsg Shared.msgToCalendar

        Msg.ToTabular ->
            sharedMsg Shared.msgToTabular

        Msg.ToMainPage ->
            ( { model | page = MainPage }, Cmd.none )

        Msg.ToSettings ->
            ( { model | page = Settings }, Cmd.none )

        Msg.Close ->
            --TODO: delegate to Dialog?
            ( { model | dialog = Nothing, settingsDialog = Nothing }, Cmd.none )

        Msg.SelectDate date ->
            sharedMsg (Shared.msgSelectDate date)

        Msg.SelectAccount account ->
            sharedMsg (Shared.msgSelectAccount account)

        Msg.KeyDown string ->
            if string == "Alt" || string == "Control" then
                sharedMsg (Shared.msgShowAdvanced True)

            else
                ( model, Cmd.none )

        Msg.KeyUp string ->
            sharedMsg (Shared.msgShowAdvanced False)

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
            sharedMsg (Shared.msgCreateAccount name)

        Msg.OpenRenameAccount id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openRenameAccount id model.shared)
              }
            , Cmd.none
            )

        Msg.OpenDeleteAccount id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openDeleteAccount id model.shared)
              }
            , Cmd.none
            )

        Msg.CreateCategory name icon ->
            sharedMsg (Shared.msgCreateCategory name icon)

        Msg.OpenRenameCategory id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openRenameCategory id model.shared)
              }
            , Cmd.none
            )

        Msg.OpenDeleteCategory id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openDeleteCategory id model.shared)
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
        [ Ports.receive Msg.FromService
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
                            (Dialog.view model.shared dialog)
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
                    Settings.view model.shared

                MainPage ->
                    case model.shared.mode of
                        Shared.InCalendar ->
                            Calendar.view model.shared

                        Shared.InTabular ->
                            Tabular.view model.shared
            )
        ]
    }
