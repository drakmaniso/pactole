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
    , page : Page
    }


type Page
    = MainPage
    | Settings


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg.Msg )
init flags _ _ =
    ( { common = Common.init flags
      , dialog = Nothing
      , page = MainPage
      }
    , Cmd.none
      {-
         , Cmd.batch
             [ Task.perform Msg.Today (Task.map2 Date.fromZoneAndPosix Time.here Time.now)
             ]
      -}
    )



-- UPDATE


update : Msg.Msg -> Model -> ( Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.Today d ->
            let
                ( common, cmd ) =
                    Common.msgToday d model.common
            in
            ( { model | common = common }, cmd )

        Msg.LinkClicked req ->
            case req of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Cmd.none )

        Msg.UrlChanged url ->
            ( model, Cmd.none )

        Msg.ToCalendar ->
            let
                ( common, cmd ) =
                    Common.msgToCalendar model.common
            in
            ( { model | common = common }, cmd )

        Msg.ToTabular ->
            let
                ( common, cmd ) =
                    Common.msgToTabular model.common
            in
            ( { model | common = common }, cmd )

        Msg.ToMainPage ->
            ( { model | page = MainPage }, Cmd.none )

        Msg.ToSettings ->
            ( { model | page = Settings }, Cmd.none )

        Msg.Close ->
            --TODO: delegate to Dialog?
            ( { model | dialog = Nothing }, Cmd.none )

        Msg.SelectDate date ->
            let
                ( common, cmd ) =
                    Common.msgSelectDate date model.common
            in
            ( { model | common = common }, cmd )

        Msg.SelectAccount account ->
            let
                ( common, cmd ) =
                    Common.msgSelectAccount account model.common
            in
            ( { model | common = common }, cmd )

        Msg.UpdateAccountList json ->
            let
                ( common, cmd ) =
                    Common.msgUpdateAccountList json model.common
            in
            ( { model | common = common }, cmd )

        Msg.UpdateLedger json ->
            let
                ( common, cmd ) =
                    Common.msgUpdateLedger json model.common
            in
            ( { model | common = common }, cmd )

        Msg.KeyDown string ->
            if string == "Alt" || string == "Control" then
                let
                    ( common, cmd ) =
                        Common.msgShowAdvanced True model.common
                in
                ( { model | common = common }, cmd )

            else
                ( model, Cmd.none )

        Msg.KeyUp string ->
            let
                ( common, cmd ) =
                    Common.msgShowAdvanced False model.common
            in
            ( { model | common = common }, cmd )

        Msg.NewDialog isExpense date ->
            let
                ( dialog, cmd ) =
                    Dialog.msgNewDialog isExpense date
            in
            ( { model | dialog = dialog }, cmd )

        Msg.EditDialog id ->
            let
                ( dialog, cmd ) =
                    Dialog.msgEditDialog id model.common
            in
            ( { model | dialog = dialog }, cmd )

        Msg.DialogAmount amount ->
            let
                ( dialog, cmd ) =
                    Dialog.msgAmount amount model.dialog
            in
            ( { model | dialog = dialog }, cmd )

        Msg.DialogDescription string ->
            let
                ( dialog, cmd ) =
                    Dialog.msgDescription string model.dialog
            in
            ( { model | dialog = dialog }, cmd )

        Msg.DialogConfirm ->
            let
                ( dialog, common, cmd ) =
                    Dialog.msgConfirm model.common model.dialog
            in
            ( { model | common = common, dialog = dialog }, cmd )

        Msg.DialogDelete ->
            let
                ( dialog, common, cmd ) =
                    Dialog.msgDelete model.common model.dialog
            in
            ( { model | common = common, dialog = dialog }, cmd )

        Msg.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ Ports.updateAccountList Msg.UpdateAccountList
        , Ports.updateLedger Msg.UpdateLedger
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
                Nothing ->
                    []

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
