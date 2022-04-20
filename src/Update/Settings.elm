module Update.Settings exposing (confirm, update)

import Database
import Date
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import String


update : Msg.SettingsMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.DeleteRecurring idx ->
            ( { model | dialog = Nothing }
            , Database.deleteRecurringTransaction idx
            )

        Msg.ChangeSettingsName name ->
            case model.dialog of
                Just (Model.AccountDialog data) ->
                    ( { model | dialog = Just (Model.AccountDialog { data | name = name }) }
                    , Cmd.none
                    )

                Just (Model.CategoryDialog data) ->
                    ( { model | dialog = Just (Model.CategoryDialog { data | name = name }) }
                    , Cmd.none
                    )

                Just (Model.RecurringDialog data) ->
                    ( { model | dialog = Just (Model.RecurringDialog { data | description = name }) }
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
                Just (Model.RecurringDialog data) ->
                    ( { model | dialog = Just (Model.RecurringDialog { data | isExpense = isExpense }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeIsExpense message"

        Msg.ChangeSettingsAmount amount ->
            case model.dialog of
                Just (Model.RecurringDialog data) ->
                    ( { model | dialog = Just (Model.RecurringDialog { data | amount = amount }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeAmount message"

        Msg.ChangeSettingsAccount account ->
            case model.dialog of
                Just (Model.RecurringDialog data) ->
                    ( { model | dialog = Just (Model.RecurringDialog { data | account = account }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeAccount message"

        Msg.ChangeSettingsDueDate day ->
            case model.dialog of
                Just (Model.RecurringDialog data) ->
                    ( { model | dialog = Just (Model.RecurringDialog { data | dueDate = day }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeDueDate message"

        Msg.ChangeSettingsIcon icon ->
            case model.dialog of
                Just (Model.CategoryDialog data) ->
                    ( { model | dialog = Just (Model.CategoryDialog { data | icon = icon }) }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none ) |> Log.error "unexpected SettingsChangeIcon message"


confirm : Model -> ( Model, Cmd Msg )
confirm model =
    case model.dialog of
        Just (Model.AccountDialog data) ->
            case data.id of
                Just accountId ->
                    ( { model | dialog = Nothing }
                    , Database.renameAccount accountId (sanitizeName data.name)
                    )

                Nothing ->
                    ( { model | dialog = Nothing }
                    , Database.createAccount (sanitizeName data.name)
                    )

        Just (Model.DeleteAccountDialog id) ->
            ( { model | dialog = Nothing }
            , Database.deleteAccount id
            )

        Just (Model.CategoryDialog data) ->
            case data.id of
                Just categoryId ->
                    ( { model | dialog = Nothing }
                    , Database.renameCategory categoryId data.name data.icon
                    )

                Nothing ->
                    ( { model | dialog = Nothing }
                    , Database.createCategory (sanitizeName data.name) data.icon
                    )

        Just (Model.DeleteCategoryDialog id) ->
            ( { model | dialog = Nothing }
            , Database.deleteCategory id
            )

        Just (Model.RecurringDialog data) ->
            let
                dayInput =
                    Maybe.withDefault 1 (String.toInt data.dueDate)

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
            case data.id of
                Just recurringId ->
                    ( { model | dialog = Nothing }
                    , Database.replaceRecurringTransaction
                        { id = recurringId
                        , account = data.account
                        , amount =
                            Result.withDefault Money.zero
                                (Money.fromInput data.isExpense data.amount)
                        , description = data.description
                        , category = data.category
                        , date = dueDate
                        , checked = False
                        }
                    )

                Nothing ->
                    ( { model | dialog = Nothing }
                    , Database.createRecurringTransaction
                        { date = dueDate
                        , account = data.account
                        , amount =
                            Result.withDefault Money.zero
                                (Money.fromInput data.isExpense data.amount)
                        , description = data.description
                        , category = data.category
                        , checked = False
                        }
                    )

        Just Model.ImportDialog ->
            ( { model | dialog = Nothing }
            , Database.importDatabase
            )

        Just Model.ExportDialog ->
            ( { model | dialog = Nothing }
            , Database.exportDatabase model
            )

        Just (Model.UserErrorDialog _) ->
            ( { model | dialog = Nothing }
            , Cmd.none
            )

        Just (Model.FontDialog fontName) ->
            let
                settings =
                    model.settings
            in
            ( { model | dialog = Nothing }
            , Database.storeSettings { settings | font = fontName }
            )

        Just (Model.TransactionDialog _) ->
            ( { model | dialog = Nothing }
            , Cmd.none
            )
                |> Log.error "unexpected SettingsConfirm message"

        Just (Model.DeleteTransactionDialog _) ->
            ( { model | dialog = Nothing }
            , Cmd.none
            )
                |> Log.error "unexpected SettingsConfirm message"

        Nothing ->
            ( { model | dialog = Nothing }
            , Cmd.none
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
