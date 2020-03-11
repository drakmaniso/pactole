module Main exposing (..)

import Array
import Browser
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
import Model
import Msg
import Ports
import Task
import Time
import Url
import View.Calendar
import View.Income
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


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model.Model, Cmd Msg.Msg )
init flags _ _ =
    ( Model.init flags
    , Cmd.batch
        [ Task.perform Msg.Today (Task.map2 Date.fromZoneAndPosix Time.here Time.now)
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

        Msg.ToIncome ->
            ( { model | dialog = Model.Dialog }, Cmd.none )

        Msg.DialogAmount string ->
            ( { model | dialogAmount = string }, Cmd.none )

        Msg.DialogDescription string ->
            ( { model | dialogDescription = string }, Cmd.none )

        Msg.ToMainPage ->
            ( { model | page = Model.MainPage }, Cmd.none )

        Msg.ToSettings ->
            ( { model | page = Model.Settings }, Cmd.none )

        Msg.Close ->
            ( { model | dialog = Model.None }, Cmd.none )

        Msg.SelectDay d ->
            ( { model | date = d, selected = True }, Cmd.none )

        Msg.ChooseAccount name ->
            ( { model | account = Just name }, Ports.selectAccount name )

        Msg.SetAccounts json ->
            let
                ( accounts, account ) =
                    case Decode.decodeValue (Decode.list Decode.string) json of
                        Ok a ->
                            ( a, List.head a )

                        Err e ->
                            Debug.log ("Msg.SetAccounts: " ++ Decode.errorToString e)
                                ( [], Nothing )
            in
            ( { model | accounts = accounts, account = account, ledger = Ledger.empty }, Cmd.none )

        Msg.SetLedger json ->
            let
                ledger =
                    case Decode.decodeValue Ledger.decoder json of
                        Ok l ->
                            l

                        Err e ->
                            Debug.log ("Msg.SetLedger: " ++ Decode.errorToString e)
                                Ledger.empty
            in
            ( { model | ledger = ledger }, Cmd.none )

        Msg.KeyDown string ->
            ( if string == "Alt" || string == "Control" then
                { model | showAdvanced = True }

              else
                model
            , Cmd.none
            )

        Msg.KeyUp string ->
            ( { model | showAdvanced = False }
            , Cmd.none
            )

        Msg.Edit id ->
            let
                transac =
                    Ledger.getTransaction id model.ledger

                dialog =
                    case transac of
                        Nothing ->
                            Model.None

                        Just t ->
                            if Ledger.isExpense t then
                                Model.Dialog

                            else
                                Model.Dialog
            in
            case transac of
                Nothing ->
                    ( model, Debug.log "*** Unable to get transaction" Cmd.none )

                Just t ->
                    ( { model
                        | dialogDescription = Ledger.getDescriptionInput t
                        , dialogAmount = Ledger.getAmountInput t
                        , dialog = dialog
                      }
                    , Cmd.none
                    )



-- SUBSCRIPTIONS


subscriptions : Model.Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ Ports.accounts Msg.SetAccounts
        , Ports.ledger Msg.SetLedger
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
    let
        root =
            case model.page of
                Model.Settings ->
                    View.Settings.view

                Model.MainPage ->
                    case model.mode of
                        Model.Calendar ->
                            View.Calendar.view

                        Model.Tabular ->
                            View.Tabular.view

        dialog contentView =
            E.el
                [ E.width E.fill
                , E.height E.fill
                , View.Style.fontFamily
                , E.padding 16
                , E.behindContent
                    (Input.button
                        [ E.width E.fill
                        , E.height E.fill
                        , Background.color (E.rgba 0 0 0 0.6)
                        , E.htmlAttribute <| Html.Attributes.style "z-index" "1000"
                        ]
                        { label = E.none, onPress = Just Msg.Close }
                    )
                ]
                contentView
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

                Model.Dialog ->
                    [ E.inFront (dialog (View.Income.view model))
                    ]
            )
            (root model)
        ]
    }
