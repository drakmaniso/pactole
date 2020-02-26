port module Main exposing (..)

import Array
import Browser
import Browser.Events
import Browser.Navigation as Navigation
import Calendar
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
import Msg
import Task
import Time
import Url
import View.Calendar
import View.Settings
import View.Style
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


init : String -> Url.Url -> Navigation.Key -> ( Model.Model, Cmd Msg.Msg )
init flags _ _ =
    ( Model.init flags
    , Cmd.batch
        [ Task.perform Msg.Today (Task.map2 posixToDate Time.here Time.now)
        , getLedger "Christelle"
        ]
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

        Msg.OnStoreChange store ->
            ( model, Cmd.none )

        Msg.OnLedgerChange json ->
            let
                name =
                    Decode.decodeValue (Decode.field "name" Decode.string) json

                ledger =
                    Decode.decodeValue (Decode.field "ledger" Ledger.decoder) json

                newmodel =
                    case ( name, ledger ) of
                        ( Ok n, Ok l ) ->
                            if n == model.account then
                                { model | ledger = Debug.log "sdfsdfsdf" l }

                            else
                                model

                        ( Err e, _ ) ->
                            Debug.log (Decode.errorToString e) model

                        ( _, Err e ) ->
                            Debug.log ("OnLedgerChange " ++ Decode.errorToString e) model
            in
            ( newmodel, Cmd.none )

        {-
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
        -}
        Msg.KeyDown string ->
            -- TODO
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model.Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ onStoreChange Msg.OnStoreChange
        , onLedgerChange Msg.OnLedgerChange
        , Browser.Events.onKeyDown keyDownDecoder
        ]


keyDownDecoder : Decode.Decoder Msg.Msg
keyDownDecoder =
    Decode.field "key" Decode.string
        |> Decode.map Msg.KeyDown



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
            E.el
                [ E.width E.fill
                , E.height E.fill
                , E.padding 16
                , E.behindContent
                    (Input.button
                        [ E.width E.fill
                        , E.height E.fill
                        , Background.color (E.rgba 0 0 0 0.75)
                        , E.htmlAttribute <| Html.Attributes.style "z-index" "1000"
                        ]
                        { label = E.none, onPress = Just Msg.Close }
                    )
                ]
                (View.Settings.view model)
    in
    { title = "Pactole"
    , body =
        [ E.layoutWith
            { options =
                [ E.focusStyle
                    { borderColor = Just View.Style.bgTitle
                    , backgroundColor = Nothing
                    , shadow =
                        Just
                            { color = View.Style.bgTitle
                            , offset = ( 0, 0 )
                            , blur = 0
                            , size = 2
                            }
                    }
                ]
            }
            (case model.dialog of
                Model.None ->
                    []

                Model.Settings ->
                    [ E.inFront dialog
                    ]
            )
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



-- PORTS


port onStoreChange : (String -> msg) -> Sub msg


port storeCache : Maybe Encode.Value -> Cmd msg


port getLedger : String -> Cmd msg


port onLedgerChange : (Decode.Value -> msg) -> Sub msg



-- port storeAccounts : Encode.Value -> Cmd msg
-- port getAccounts : (Decode.Value -> msg) -> Sub msg
