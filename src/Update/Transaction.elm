module Update.Transaction exposing (..)

import Browser.Dom as Dom
import Database
import Ledger
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ports
import Task


update : Msg.TransactionMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.NewTransaction isExpense date ->
            ( { model
                | dialog =
                    Just <|
                        Model.TransactionDialog
                            { id = Nothing
                            , isExpense = isExpense
                            , isRecurring = False
                            , date = date
                            , amount = ( "", Nothing )
                            , description = ""
                            , category = 0
                            }
              }
            , Cmd.batch
                [ Ports.openDialog ()
                , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-focus")
                ]
            )

        Msg.EditTransaction id ->
            case Ledger.getTransaction id model.ledger of
                Nothing ->
                    Log.error "DialogEditTransaction: unable to get transaction" ( model, Cmd.none )

                Just t ->
                    ( { model
                        | dialog =
                            Just <|
                                Model.TransactionDialog
                                    { id = Just t.id
                                    , isExpense = Money.isExpense t.amount
                                    , isRecurring = False
                                    , date = t.date
                                    , amount = ( Money.toInput t.amount, Nothing )
                                    , description = t.description
                                    , category = t.category
                                    }
                      }
                    , Ports.openDialog ()
                    )

        Msg.ShowRecurring id ->
            case Ledger.getTransaction id model.recurring of
                Nothing ->
                    Log.error "DialogShowRecurring: unable to get recurring transaction" ( model, Cmd.none )

                Just t ->
                    ( { model
                        | dialog =
                            Just <|
                                Model.TransactionDialog
                                    { id = Just t.id
                                    , isExpense = Money.isExpense t.amount
                                    , isRecurring = True
                                    , date = t.date
                                    , amount = ( Money.toInput t.amount, Nothing )
                                    , description = t.description
                                    , category = t.category
                                    }
                      }
                    , Ports.openDialog ()
                    )

        Msg.ChangeTransactionAmount amount ->
            case model.dialog of
                Just (Model.TransactionDialog dialog) ->
                    ( { model
                        | dialog = Just <| Model.TransactionDialog { dialog | amount = ( amount, Nothing ) }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected DialogChangeAmount message"

        Msg.ChangeTransactionDescription string ->
            case model.dialog of
                Just (Model.TransactionDialog dialog) ->
                    ( { model
                        | dialog =
                            Just <|
                                Model.TransactionDialog
                                    { dialog
                                        | description =
                                            String.filter (\c -> c /= Char.fromCode 13 && c /= Char.fromCode 10) string
                                    }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected DialogChangeDescription message"

        Msg.ChangeTransactionCategory id ->
            case model.dialog of
                Just (Model.TransactionDialog dialog) ->
                    ( { model
                        | dialog =
                            Just <|
                                Model.TransactionDialog
                                    { dialog | category = id }
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected DialogChangeCategory message"

        Msg.ConfirmTransaction ->
            case model.dialog of
                Just (Model.TransactionDialog dialog) ->
                    case
                        ( dialog.id
                        , Money.fromInput dialog.isExpense (Tuple.first dialog.amount)
                        )
                    of
                        ( Just id, Ok amount ) ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.replaceTransaction
                                    { id = id
                                    , account = model.account
                                    , date = dialog.date
                                    , amount = amount
                                    , description = dialog.description
                                    , category = dialog.category
                                    , checked = False
                                    }
                                , Ports.closeDialog ()
                                ]
                            )

                        ( Nothing, Ok amount ) ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.createTransaction
                                    { account = model.account
                                    , date = dialog.date
                                    , amount = amount
                                    , description = dialog.description
                                    , category = dialog.category
                                    , checked = False
                                    }
                                , Ports.closeDialog ()
                                ]
                            )

                        ( _, Err amountError ) ->
                            let
                                newDialog =
                                    { dialog | amount = ( Tuple.first dialog.amount, Just amountError ) }
                            in
                            ( { model
                                | dialog = Just <| Model.TransactionDialog newDialog
                              }
                            , Cmd.none
                            )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected DialogConfirm message"

        Msg.DeleteTransaction ->
            case model.dialog of
                Just (Model.TransactionDialog dialog) ->
                    case dialog.id of
                        Just id ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch [ Database.deleteTransaction id, Ports.closeDialog () ]
                            )

                        Nothing ->
                            Log.error "impossible Delete message" ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected Delete message"
