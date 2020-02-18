port module Main exposing (..)

import Array
import Browser
import Browser.Navigation as Navigation
import Calendar
import Element exposing (..)
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
import Msg
import Task
import Time
import Url
import View.Calendar
import View.Settings
import View.Tabular



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


init : () -> Url.Url -> Navigation.Key -> ( Model.Model, Cmd Msg.Msg )
init flags _ _ =
    ( Model.init
    , Task.perform Msg.Today (Task.map2 posixToDate Time.here Time.now)
    )



-- UPDATE


update : Msg.Msg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.Today d ->
            ( { model | today = d, date = d, selected = True }, Cmd.none )

        Msg.LinkClicked req ->
            case req of
                Browser.Internal url ->
                    ( model, Cmd.none )

                Browser.External href ->
                    ( model, Cmd.none )

        Msg.UrlChanged url ->
            ( model, Cmd.none )

        Msg.ToCalendar ->
            ( { model | mode = Model.Calendar }, Cmd.none )

        Msg.ToTabular ->
            ( { model | mode = Model.Tabular }, Cmd.none )

        Msg.ToSettings ->
            ( { model | dialog = Model.Settings }, Cmd.none )

        Msg.Close ->
            ( { model | dialog = Model.None }, Cmd.none )

        Msg.SelectDay d ->
            ( { model | date = d, selected = True }, Cmd.none )

        Msg.ChooseAccount a ->
            ( { model | account = a }, Cmd.none )

        Msg.UpdateAccounts json ->
            case Decode.decodeValue (Decode.list Decode.string) json of
                Ok accounts ->
                    case accounts of
                        first :: _ ->
                            ( { model | accounts = accounts, account = first }, Cmd.none )

                        _ ->
                            let
                                _ =
                                    Debug.log "empty UpdateAccounts json value" ""
                            in
                            ( model, Cmd.none )

                Err e ->
                    let
                        _ =
                            Debug.log "Invalid UpdateAccounts json value" e
                    in
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model.Model -> Sub Msg.Msg
subscriptions _ =
    getAccounts Msg.UpdateAccounts



-- VIEW


view : Model.Model -> Browser.Document Msg.Msg
view model =
    let
        root =
            case model.mode of
                Model.Calendar ->
                    View.Calendar.view

                Model.Tabular ->
                    View.Tabular.view

        dialog =
            el
                [ width fill
                , height fill
                , padding 16
                , behindContent
                    (Input.button
                        [ width fill
                        , height fill
                        , Background.color (rgba 0 0 0 0.75)
                        , htmlAttribute <| Html.Attributes.style "z-index" "1000"
                        ]
                        { label = none, onPress = Just Msg.Close }
                    )
                ]
                (View.Settings.view model)
    in
    { title = "Pactole 2"
    , body =
        case model.dialog of
            Model.None ->
                [ layout
                    []
                    (root model)
                ]

            Model.Settings ->
                [ layout
                    [ inFront dialog
                    ]
                    (root model)
                ]
    }



-- DATE TOOLS
-- Needed to obtain a date in the local time zone
-- (the Calendar package can only create UTC)


posixToDate : Time.Zone -> Time.Posix -> Calendar.Date
posixToDate zone time =
    let
        y =
            Time.toYear zone time

        m =
            Time.toMonth zone time

        d =
            Time.toDay zone time
    in
    case Calendar.fromRawParts { day = d, month = m, year = y } of
        Just date ->
            date

        Nothing ->
            Calendar.fromPosix (Time.millisToPosix 0)


port storeAccounts : Encode.Value -> Cmd msg


port getAccounts : (Decode.Value -> msg) -> Sub msg
