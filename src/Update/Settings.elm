module Update.Settings exposing (confirm, update)

import Database
import Date
import Dict
import File.Download
import Json.Encode as Encode
import Ledger
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ports
import String
import Ui


update : Msg.SettingsMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.DeleteRecurring idx ->
            ( { model | dialog = Nothing }
            , Database.deleteRecurringTransaction idx
            )

        Msg.ChangeSettingsName name ->
            case model.dialog of
                Just (Model.ExportDialog _) ->
                    ( { model | dialog = Just (Model.ExportDialog name) }
                    , Cmd.none
                    )

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
                    , Cmd.batch
                        [ Database.renameAccount accountId (sanitizeName data.name)
                        , Ports.historyGo -1
                        ]
                    )

                Nothing ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.createAccount (sanitizeName data.name)
                        , Ports.historyGo -1
                        ]
                    )

        Just (Model.DeleteAccountDialog id) ->
            ( { model | dialog = Nothing }
            , Cmd.batch
                [ Database.deleteAccount id
                , Ports.historyGo -1
                ]
            )

        Just (Model.CategoryDialog data) ->
            case data.id of
                Just categoryId ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.renameCategory categoryId data.name data.icon
                        , Ports.historyGo -1
                        ]
                    )

                Nothing ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.createCategory (sanitizeName data.name) data.icon
                        , Ports.historyGo -1
                        ]
                    )

        Just (Model.DeleteCategoryDialog id) ->
            ( { model | dialog = Nothing }
            , Cmd.batch
                [ Database.deleteCategory id
                , Ports.historyGo -1
                ]
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
                    , Cmd.batch
                        [ Database.replaceRecurringTransaction
                            { id = recurringId
                            , account = data.account
                            , amount =
                                Result.withDefault Money.zero
                                    (Money.parse data.isExpense data.amount)
                            , description = data.description
                            , category = data.category
                            , date = dueDate
                            , checked = False
                            }
                        , Ports.historyGo -1
                        ]
                    )

                Nothing ->
                    ( { model | dialog = Nothing }
                    , Cmd.batch
                        [ Database.createRecurringTransaction
                            { date = dueDate
                            , account = data.account
                            , amount =
                                Result.withDefault Money.zero
                                    (Money.parse data.isExpense data.amount)
                            , description = data.description
                            , category = data.category
                            , checked = False
                            }
                        , Ports.historyGo -1
                        ]
                    )

        Just (Model.ImportDialog db) ->
            ( { model
                | dialog = Nothing
                , settings = db.settings
                , accounts = Dict.fromList db.accounts
                , account = Model.firstAccount db.accounts
                , categories = Dict.fromList db.categories
                , ledger = db.ledger
                , recurring = db.recurring
                , page = Model.CalendarPage
                , context =
                    Ui.classifyContext
                        { width = model.context.width
                        , height = model.context.height
                        , fontSize = db.settings.fontSize
                        , deviceClass = db.settings.deviceClass
                        , animationDisabled = db.settings.animationDisabled
                        }
              }
            , Cmd.batch
                [ Ports.toServiceWorker
                    ( "install database"
                    , Model.encodeDatabase db
                    )
                , Ports.historyGo -1
                ]
            )

        Just (Model.ExportDialog filename) ->
            let
                sanitizedName =
                    if String.right 8 filename /= ".pactole" then
                        filename ++ ".pactole"

                    else
                        filename
            in
            ( { model | dialog = Nothing }
            , File.Download.string sanitizedName "application/vnd.drakmaniso.pactole" <|
                Encode.encode 4 <|
                    Encode.object
                        [ ( "settings", Model.encodeSettings model.settings )
                        , ( "recurring", Ledger.encode model.recurring )
                        , ( "accounts", Model.encodeAccounts model.accounts )
                        , ( "categories", Model.encodeCategories model.categories )
                        , ( "ledger", Ledger.encode model.ledger )
                        , ( "serviceVersion", Encode.string model.serviceVersion )
                        ]
            )

        Just (Model.UserErrorDialog _) ->
            ( { model | dialog = Nothing }
            , Ports.historyGo -1
            )

        Just (Model.FontDialog fontName) ->
            let
                settings =
                    model.settings
            in
            ( { model | dialog = Nothing }
            , Cmd.batch
                [ Database.storeSettings { settings | font = fontName }
                , Ports.historyGo -1
                ]
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
