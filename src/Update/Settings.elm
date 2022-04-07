module Update.Settings exposing (update)

import Database
import Date
import Dict
import Ledger
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ports
import String


update : Msg.SettingsMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.EditAccount (Just id) ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | dialog = Just (Model.AccountDialog { id = Just id, name = name }) }
            , Ports.openDialog ()
            )

        Msg.EditAccount Nothing ->
            ( { model | dialog = Just (Model.AccountDialog { id = Nothing, name = "" }) }
            , Ports.openDialog ()
            )

        Msg.DeleteAccount id ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | dialog = Just (Model.DeleteAccountDialog { id = id, name = name }) }
            , Ports.openDialog ()
            )

        Msg.EditCategory (Just id) ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | dialog = Just (Model.CategoryDialog { id = Just id, name = name, icon = icon }) }
            , Ports.openDialog ()
            )

        Msg.EditCategory Nothing ->
            ( { model | dialog = Just (Model.CategoryDialog { id = Nothing, name = "", icon = " " }) }
            , Ports.openDialog ()
            )

        Msg.DeleteCategory id ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | dialog = Just (Model.DeleteCategoryDialog { id = id, name = name, icon = icon }) }
            , Ports.openDialog ()
            )

        Msg.EditRecurring (Just idx) ->
            case Ledger.getTransaction idx model.recurring of
                Nothing ->
                    Log.error "SettingsEditRecurring: unable to get transaction" ( model, Cmd.none )

                Just recurring ->
                    ( { model
                        | dialog =
                            Just
                                (Model.RecurringDialog
                                    { id = Just idx
                                    , account = recurring.account
                                    , isExpense = Money.isExpense recurring.amount
                                    , amount = Money.toInput recurring.amount
                                    , description = recurring.description
                                    , category = recurring.category
                                    , dueDate = String.fromInt (Date.getDay recurring.date)
                                    }
                                )
                      }
                    , Ports.openDialog ()
                    )

        Msg.EditRecurring Nothing ->
            ( { model
                | dialog =
                    Just
                        (Model.RecurringDialog
                            { id = Nothing
                            , account = model.account
                            , isExpense = False
                            , amount = "0"
                            , description = "(opération mensuelle)"
                            , category = 0
                            , dueDate = "1"
                            }
                        )
              }
            , Ports.openDialog ()
            )

        Msg.DeleteRecurring idx ->
            ( { model | dialog = Nothing }
            , Cmd.batch
                [ Database.deleteRecurringTransaction idx
                , Ports.closeDialog ()
                ]
            )

        Msg.ChangeSettingsName name ->
            case model.dialog of
                Just (Model.AccountDialog submodel) ->
                    ( { model | dialog = Just (Model.AccountDialog { submodel | name = name }) }
                    , Cmd.none
                    )

                Just (Model.CategoryDialog submodel) ->
                    ( { model | dialog = Just (Model.CategoryDialog { submodel | name = name }) }
                    , Cmd.none
                    )

                Just (Model.RecurringDialog submodel) ->
                    ( { model | dialog = Just (Model.RecurringDialog { submodel | description = name }) }
                    , Cmd.none
                    )

                Just (Model.FontDialog _) ->
                    ( { model | dialog = Just (Model.FontDialog name) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )
                        |> Log.error "unexpected SettingsChangeName message"

        Msg.ChangeSettingsIsExpense isExpense ->
            case model.dialog of
                Just (Model.RecurringDialog submodel) ->
                    ( { model | dialog = Just (Model.RecurringDialog { submodel | isExpense = isExpense }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeIsExpense message"

        Msg.ChangeSettingsAmount amount ->
            case model.dialog of
                Just (Model.RecurringDialog submodel) ->
                    ( { model | dialog = Just (Model.RecurringDialog { submodel | amount = amount }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeAmount message"

        Msg.ChangeSettingsAccount account ->
            case model.dialog of
                Just (Model.RecurringDialog submodel) ->
                    ( { model | dialog = Just (Model.RecurringDialog { submodel | account = account }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeAccount message"

        Msg.ChangeSettingsDueDate day ->
            case model.dialog of
                Just (Model.RecurringDialog submodel) ->
                    ( { model | dialog = Just (Model.RecurringDialog { submodel | dueDate = day }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeDueDate message"

        Msg.ChangeSettingsIcon icon ->
            case model.dialog of
                Just (Model.CategoryDialog submodel) ->
                    ( { model | dialog = Just (Model.CategoryDialog { submodel | icon = icon }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeIcon message"

        Msg.Import ->
            ( { model | dialog = Just Model.ImportDialog }
            , Ports.openDialog ()
            )

        Msg.Export ->
            ( { model | dialog = Just Model.ExportDialog }
            , Ports.openDialog ()
            )

        Msg.EditFont ->
            ( { model | dialog = Just <| Model.FontDialog model.settings.font }, Ports.openDialog () )

        Msg.ConfirmSettings ->
            case model.dialog of
                Just (Model.AccountDialog submodel) ->
                    case submodel.id of
                        Just accountId ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.renameAccount accountId (sanitizeName submodel.name)
                                , Ports.closeDialog ()
                                ]
                            )

                        Nothing ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.createAccount (sanitizeName submodel.name)
                                , Ports.closeDialog ()
                                ]
                            )

                Just (Model.DeleteAccountDialog submodel) ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.deleteAccount submodel.id
                        , Ports.closeDialog ()
                        ]
                    )

                Just (Model.CategoryDialog submodel) ->
                    case submodel.id of
                        Just categoryId ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.renameCategory categoryId submodel.name submodel.icon
                                , Ports.closeDialog ()
                                ]
                            )

                        Nothing ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.createCategory (sanitizeName submodel.name) submodel.icon
                                , Ports.closeDialog ()
                                ]
                            )

                Just (Model.DeleteCategoryDialog submodel) ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.deleteCategory submodel.id
                        , Ports.closeDialog ()
                        ]
                    )

                Just (Model.RecurringDialog submodel) ->
                    let
                        dayInput =
                            Maybe.withDefault 1 (String.toInt submodel.dueDate)

                        day =
                            if dayInput < 1 then
                                1

                            else if dayInput > 28 then
                                28

                            else
                                dayInput

                        dueDate =
                            Date.findNextDayOfMonth day model.today
                    in
                    case submodel.id of
                        Just recurringId ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.replaceRecurringTransaction
                                    { id = recurringId
                                    , account = submodel.account
                                    , amount =
                                        Result.withDefault Money.zero
                                            (Money.fromInput submodel.isExpense submodel.amount)
                                    , description = submodel.description
                                    , category = submodel.category
                                    , date = dueDate
                                    , checked = False
                                    }
                                , Ports.closeDialog ()
                                ]
                            )

                        Nothing ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.createRecurringTransaction
                                    { date = dueDate
                                    , account = submodel.account
                                    , amount =
                                        Result.withDefault Money.zero
                                            (Money.fromInput submodel.isExpense submodel.amount)
                                    , description = submodel.description
                                    , category = submodel.category
                                    , checked = False
                                    }
                                , Ports.closeDialog ()
                                ]
                            )

                Just Model.ImportDialog ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.importDatabase
                        , Ports.closeDialog ()
                        ]
                    )

                Just Model.ExportDialog ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.exportDatabase model
                        , Ports.closeDialog ()
                        ]
                    )

                Just (Model.UserErrorDialog _) ->
                    ( { model | dialog = Nothing }
                    , Ports.closeDialog ()
                    )

                Just (Model.FontDialog fontName) ->
                    let
                        settings =
                            model.settings
                    in
                    ( model
                    , Cmd.batch
                        [ Database.storeSettings { settings | font = fontName }
                        , Ports.closeDialog ()
                        ]
                    )

                Just (Model.TransactionDialog _) ->
                    ( { model | dialog = Nothing }
                    , Ports.closeDialog ()
                    )
                        |> Log.error "unexpected SettingsConfirm message"

                Nothing ->
                    ( { model | dialog = Nothing }
                    , Ports.closeDialog ()
                    )



-- UTILS


sanitizeName : String -> String
sanitizeName name =
    let
        trimmedName =
            String.trim name
    in
    if String.isEmpty trimmedName then
        "?"

    else
        trimmedName
