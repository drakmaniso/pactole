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
import Page.Calendar
import Page.Dialog
import Page.Settings
import Page.Tabular
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
{-
   type Model
       = Loading
       | Calendar Common.Model Calendar.Model Dialog.Model
       | Tabular Common.Model Tabular.Model Dialog.Model
       | Settings Common.Model
-}


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Common.Model, Cmd Msg.Msg )
init flags _ _ =
    ( Common.init flags
    , Cmd.batch
        [ Task.perform Msg.Today (Task.map2 Date.fromZoneAndPosix Time.here Time.now)
        ]
    )



-- UPDATE


update : Msg.Msg -> Common.Model -> ( Common.Model, Cmd Msg.Msg )
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
            ( { model | mode = Common.Calendar }, Cmd.none )

        Msg.ToTabular ->
            ( { model | mode = Common.Tabular }, Cmd.none )

        Msg.DialogAmount string ->
            ( { model
                | dialogAmount = string
                , dialogAmountInfo = Money.validate string
              }
            , Cmd.none
            )

        Msg.DialogDescription string ->
            ( { model | dialogDescription = string }, Cmd.none )

        Msg.ToMainPage ->
            ( { model | page = Common.MainPage }, Cmd.none )

        Msg.ToSettings ->
            ( { model | page = Common.Settings }, Cmd.none )

        Msg.Close ->
            ( { model | dialog = Nothing }, Cmd.none )

        Msg.SelectDay d ->
            ( { model | date = d, selected = True }, Cmd.none )

        Msg.ChooseAccount name ->
            ( { model | account = Just name }, Ports.requestLedger name )

        Msg.UpdateAccounts json ->
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

        Msg.UpdateLedger json ->
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

        Msg.NewIncome ->
            ( { model
                | dialog = Just Common.NewIncome
                , dialogAmount = ""
                , dialogAmountInfo = ""
                , dialogDescription = ""
              }
            , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-amount")
            )

        Msg.NewExpense ->
            ( { model
                | dialog = Just Common.NewExpense
                , dialogAmount = ""
                , dialogAmountInfo = ""
                , dialogDescription = ""
              }
            , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-amount")
            )

        Msg.Edit id ->
            case Ledger.getTransaction id model.ledger of
                Nothing ->
                    ( model, Debug.log "*** Unable to get transaction" Cmd.none )

                Just t ->
                    ( { model
                        | dialogDescription = t.description
                        , dialogAmount = Money.toInput t.amount
                        , dialogAmountInfo = Money.validate (Money.toInput t.amount)
                        , dialog =
                            if Money.isExpense t.amount then
                                Just (Common.EditExpense t.id)

                            else
                                Just (Common.EditIncome t.id)
                      }
                    , Cmd.none
                    )

        Msg.ConfirmNew input ->
            case input of
                Nothing ->
                    ( model, Cmd.none )

                Just amount ->
                    let
                        newLedger =
                            Ledger.addTransaction
                                { date = model.date
                                , amount = amount
                                , description = model.dialogDescription
                                }
                                model.ledger
                    in
                    ( { model | ledger = newLedger, dialog = Nothing }
                    , Ports.storeLedger
                        ( Maybe.withDefault "ERROR" model.account, Ledger.encode newLedger )
                    )

        Msg.ConfirmEdit id input ->
            case input of
                Nothing ->
                    ( model, Cmd.none )

                Just amount ->
                    let
                        newLedger =
                            Ledger.updateTransaction
                                { id = id
                                , date = model.date
                                , amount = amount
                                , description = model.dialogDescription
                                }
                                model.ledger
                    in
                    ( { model | ledger = newLedger, dialog = Nothing }
                    , Ports.storeLedger
                        ( Maybe.withDefault "ERROR" model.account, Ledger.encode newLedger )
                    )

        Msg.Delete ->
            let
                delete id =
                    let
                        newLedger =
                            Ledger.deleteTransaction id model.ledger
                    in
                    ( { model | ledger = newLedger, dialog = Nothing }
                    , Ports.storeLedger
                        ( Maybe.withDefault "ERROR" model.account, Ledger.encode newLedger )
                    )
            in
            case model.dialog of
                Just (Common.EditExpense id) ->
                    delete id

                Just (Common.EditIncome id) ->
                    delete id

                _ ->
                    Debug.log "IMPOSSIBLE DELETE MSG" ( model, Cmd.none )

        Msg.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Common.Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ Ports.updateAccounts Msg.UpdateAccounts
        , Ports.updateLedger Msg.UpdateLedger
        , Browser.Events.onKeyDown (keyDecoder Msg.KeyDown)
        , Browser.Events.onKeyUp (keyDecoder Msg.KeyUp)
        ]


keyDecoder : (String -> Msg.Msg) -> Decode.Decoder Msg.Msg
keyDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.map msg



-- VIEW


view : Common.Model -> Browser.Document Msg.Msg
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

                Just d ->
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
                            (Page.Dialog.view d model)
                        )
                    ]
            )
            (case model.page of
                Common.Settings ->
                    Page.Settings.view model

                Common.MainPage ->
                    case model.mode of
                        Common.Calendar ->
                            Page.Calendar.view model

                        Common.Tabular ->
                            Page.Tabular.view model
            )
        ]
    }
