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
        , onUrlChange = Shared.UrlChanged
        , onUrlRequest = Shared.LinkClicked
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


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model, Cmd Shared.Msg )
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
             [ Task.perform Shared.Today (Task.map2 Date.fromZoneAndPosix Time.here Time.now)
             ]
      -}
    )



-- UPDATE


update : Shared.Msg -> Model -> ( Model, Cmd Shared.Msg )
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
        Shared.Today d ->
            sharedMsg (Shared.msgToday d)

        Shared.LinkClicked req ->
            case req of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Cmd.none )

        Shared.UrlChanged url ->
            ( model, Cmd.none )

        Shared.FromService ( title, json ) ->
            sharedMsg (Shared.msgFromService ( title, json ))

        Shared.ToMainPage ->
            ( { model | page = MainPage }, Cmd.none )

        Shared.ToSettings ->
            ( { model | page = Settings }, Cmd.none )

        Shared.Close ->
            --TODO: delegate to Dialog?
            ( { model | dialog = Nothing, settingsDialog = Nothing }, Cmd.none )

        Shared.SelectDate date ->
            sharedMsg (Shared.msgSelectDate date)

        Shared.SelectAccount account ->
            sharedMsg (Shared.msgSelectAccount account)

        Shared.KeyDown string ->
            if string == "Alt" || string == "Control" || string == "Shift" then
                sharedMsg (Shared.msgShowAdvanced True)

            else
                ( model, Cmd.none )

        Shared.KeyUp string ->
            sharedMsg (Shared.msgShowAdvanced False)

        Shared.NewDialog isExpense date ->
            dialogMsg (Dialog.msgNewDialog isExpense date)

        Shared.EditDialog id ->
            dialogMsg (Dialog.msgEditDialog id)

        Shared.DialogAmount amount ->
            dialogMsg (Dialog.msgAmount amount)

        Shared.DialogDescription string ->
            dialogMsg (Dialog.msgDescription string)

        Shared.DialogCategory id ->
            dialogMsg (Dialog.msgCategory id)

        Shared.DialogConfirm ->
            dialogMsg Dialog.msgConfirm

        Shared.DialogDelete ->
            dialogMsg Dialog.msgDelete

        Shared.CreateAccount name ->
            sharedMsg (Shared.msgCreateAccount name)

        Shared.OpenRenameAccount id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openRenameAccount id model.shared)
              }
            , Cmd.none
            )

        Shared.OpenDeleteAccount id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openDeleteAccount id model.shared)
              }
            , Cmd.none
            )

        Shared.CreateCategory name icon ->
            sharedMsg (Shared.msgCreateCategory name icon)

        Shared.OpenRenameCategory id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openRenameCategory id model.shared)
              }
            , Cmd.none
            )

        Shared.OpenDeleteCategory id ->
            ( { model
                | settingsDialog =
                    Just (Settings.openDeleteCategory id model.shared)
              }
            , Cmd.none
            )

        Shared.SettingsChangeName name ->
            settingsMsg (Settings.msgChangeName name)

        Shared.SetSettings settings ->
            sharedMsg (Shared.msgSetSettings settings)

        Shared.SettingsConfirm ->
            settingsMsg Settings.msgConfirm

        Shared.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Shared.Msg
subscriptions _ =
    Sub.batch
        [ Ports.receive Shared.FromService
        , Browser.Events.onKeyDown (keyDecoder Shared.KeyDown)
        , Browser.Events.onKeyUp (keyDecoder Shared.KeyUp)
        ]


keyDecoder : (String -> Shared.Msg) -> Decode.Decoder Shared.Msg
keyDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.map msg



-- VIEW


view : Model -> Browser.Document Shared.Msg
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
                                            , onPress = Just Shared.Close
                                            }
                                        )
                                    ]
                                    (Settings.viewDialog dialog)
                                )
                            ]

                        Nothing ->
                            [ E.width E.fill, E.height E.fill, E.scrollbarY ]
            )
            (case model.page of
                Settings ->
                    Settings.view model.shared

                MainPage ->
                    case model.shared.settings.defaultMode of
                        Shared.InCalendar ->
                            Calendar.view model.shared

                        Shared.InTabular ->
                            Tabular.view model.shared
            )
        ]
    }
