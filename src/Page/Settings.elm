module Page.Settings exposing
    ( configLocked
    , update
    , viewContent
    , viewDialog
    )

import Database
import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Font as Font
import Element.Keyed as Keyed
import Ledger
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ports
import String
import Ui
import Ui.Color as Color



-- UPDATE


update : Msg.SettingsDialogMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.SettingsEditAccount (Just id) ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | settingsDialog = Just (Model.EditAccount { id = Just id, name = name }) }
            , Ports.openDialog ()
            )

        Msg.SettingsEditAccount Nothing ->
            ( { model | settingsDialog = Just (Model.EditAccount { id = Nothing, name = "" }) }
            , Ports.openDialog ()
            )

        Msg.SettingsDeleteAccount id ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | settingsDialog = Just (Model.DeleteAccount { id = id, name = name }) }
            , Ports.openDialog ()
            )

        Msg.SettingsEditCategory (Just id) ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | settingsDialog = Just (Model.EditCategory { id = Just id, name = name, icon = icon }) }
            , Ports.openDialog ()
            )

        Msg.SettingsEditCategory Nothing ->
            ( { model | settingsDialog = Just (Model.EditCategory { id = Nothing, name = "", icon = " " }) }
            , Ports.openDialog ()
            )

        Msg.SettingsDeleteCategory id ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | settingsDialog = Just (Model.DeleteCategory { id = id, name = name, icon = icon }) }
            , Ports.openDialog ()
            )

        Msg.SettingsEditRecurring (Just idx) ->
            case Ledger.getTransaction idx model.recurring of
                Nothing ->
                    Log.error "SettingsEditRecurring: unable to get transaction" ( model, Cmd.none )

                Just recurring ->
                    ( { model
                        | settingsDialog =
                            Just
                                (Model.EditRecurring
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

        Msg.SettingsEditRecurring Nothing ->
            ( { model
                | settingsDialog =
                    Just
                        (Model.EditRecurring
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

        Msg.SettingsDeleteRecurring idx ->
            ( { model | settingsDialog = Nothing }
            , Cmd.batch
                [ Database.deleteRecurringTransaction idx
                , Ports.closeDialog ()
                ]
            )

        Msg.SettingsChangeName name ->
            case model.settingsDialog of
                Just (Model.EditAccount submodel) ->
                    ( { model | settingsDialog = Just (Model.EditAccount { submodel | name = name }) }
                    , Cmd.none
                    )

                Just (Model.EditCategory submodel) ->
                    ( { model | settingsDialog = Just (Model.EditCategory { submodel | name = name }) }
                    , Cmd.none
                    )

                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | description = name }) }
                    , Cmd.none
                    )

                Just (Model.EditFont _) ->
                    ( { model | settingsDialog = Just (Model.EditFont name) }
                    , Cmd.none
                    )

                Just other ->
                    Log.error "invalid context for Msg.SettingsChangeName"
                        ( { model | settingsDialog = Just other }
                        , Cmd.none
                        )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsChangeIsExpense isExpense ->
            case model.settingsDialog of
                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | isExpense = isExpense }) }
                    , Cmd.none
                    )

                Just other ->
                    Log.error "invalid context for Msg.SettingsChangeIsExpense"
                        ( { model | settingsDialog = Just other }
                        , Cmd.none
                        )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsChangeAmount amount ->
            case model.settingsDialog of
                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | amount = amount }) }
                    , Cmd.none
                    )

                Just other ->
                    Log.error "invalid context for Msg.SettingsChangeAmount"
                        ( { model | settingsDialog = Just other }
                        , Cmd.none
                        )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsChangeAccount account ->
            case model.settingsDialog of
                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | account = account }) }
                    , Cmd.none
                    )

                Just other ->
                    Log.error "invalid context for Msg.SettingsChangeAccount"
                        ( { model | settingsDialog = Just other }
                        , Cmd.none
                        )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsChangeDueDate day ->
            case model.settingsDialog of
                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | dueDate = day }) }
                    , Cmd.none
                    )

                Just other ->
                    Log.error "invalid context for Msg.SettingsChangeDueDate"
                        ( { model | settingsDialog = Just other }
                        , Cmd.none
                        )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsChangeIcon icon ->
            case model.settingsDialog of
                Just (Model.EditCategory submodel) ->
                    ( { model | settingsDialog = Just (Model.EditCategory { submodel | icon = icon }) }
                    , Cmd.none
                    )

                Just other ->
                    Log.error "invalid context for Msg.SettingsChangeIcon"
                        ( { model | settingsDialog = Just other }
                        , Cmd.none
                        )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsAskImportConfirmation ->
            ( { model | settingsDialog = Just Model.AskImportConfirmation }
            , Ports.openDialog ()
            )

        Msg.SettingsAskExportConfirmation ->
            ( { model | settingsDialog = Just Model.AskExportConfirmation }
            , Ports.openDialog ()
            )

        Msg.SettingsEditFont ->
            ( { model | settingsDialog = Just <| Model.EditFont model.settings.font }, Ports.openDialog () )

        Msg.SettingsConfirm ->
            case model.settingsDialog of
                Just (Model.EditAccount submodel) ->
                    case submodel.id of
                        Just accountId ->
                            ( { model | settingsDialog = Nothing }
                            , Cmd.batch [ Database.renameAccount accountId (sanitizeName submodel.name), Ports.closeDialog () ]
                            )

                        Nothing ->
                            ( { model | settingsDialog = Nothing }
                            , Cmd.batch [ Database.createAccount (sanitizeName submodel.name), Ports.closeDialog () ]
                            )

                Just (Model.DeleteAccount submodel) ->
                    ( { model | settingsDialog = Nothing }
                    , Cmd.batch [ Database.deleteAccount submodel.id, Ports.closeDialog () ]
                    )

                Just (Model.EditCategory submodel) ->
                    case submodel.id of
                        Just categoryId ->
                            ( { model | settingsDialog = Nothing }
                            , Cmd.batch [ Database.renameCategory categoryId submodel.name submodel.icon, Ports.closeDialog () ]
                            )

                        Nothing ->
                            ( { model | settingsDialog = Nothing }
                            , Cmd.batch
                                [ Database.createCategory (sanitizeName submodel.name) submodel.icon
                                , Ports.closeDialog ()
                                ]
                            )

                Just (Model.DeleteCategory submodel) ->
                    ( { model | settingsDialog = Nothing }
                    , Cmd.batch [ Database.deleteCategory submodel.id, Ports.closeDialog () ]
                    )

                Just (Model.EditRecurring submodel) ->
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
                            ( { model | settingsDialog = Nothing }
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
                            ( { model | settingsDialog = Nothing }
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

                Just Model.AskImportConfirmation ->
                    ( { model | settingsDialog = Nothing }
                    , Cmd.batch [ Database.importDatabase, Ports.closeDialog () ]
                    )

                Just Model.AskExportConfirmation ->
                    ( { model | settingsDialog = Nothing }
                    , Cmd.batch [ Database.exportDatabase model, Ports.closeDialog () ]
                    )

                Just (Model.UserError _) ->
                    ( { model | settingsDialog = Nothing }
                    , Ports.closeDialog ()
                    )

                Just (Model.EditFont fontName) ->
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

                Nothing ->
                    ( { model | settingsDialog = Nothing }
                    , Ports.closeDialog ()
                    )


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



-- VIEW


viewContent : Model -> E.Element Msg
viewContent model =
    E.column
        -- This extra column is necessary to circumvent a
        -- scrollbar-related bug in elm-ui
        [ E.width E.fill
        , E.height E.fill
        , E.clipY
        ]
        [ Keyed.el [ E.width E.fill, E.height E.fill, E.scrollbarY ]
            ( "Settings"
            , E.column
                [ E.width E.fill
                , E.height E.fill
                , E.padding 3
                , E.scrollbarY
                ]
                [ Ui.pageTitle model.device (E.text "Configuration")
                , Ui.textColumn model.device
                    [ Ui.verticalSpacer
                    , configBackup model
                    , configAccounts model
                    , configOptional model
                    , configRecurring model
                    , configFont model
                    , configLocked model
                    , Ui.verticalSpacer
                    , Ui.verticalSpacer
                    ]
                ]
            )
        ]


configBackup : Model -> E.Element Msg
configBackup model =
    E.column
        [ E.width E.fill
        , E.spacing 24
        ]
        [ Ui.title model.device "Données de l'application"
        , Ui.paragraph
            """
            Les données de Pactole ne sont pas enregistrées en ligne.
            Elles sont disponible uniquement sur l'appareil que vous êtes en train d'utiliser.
            """
        , E.row [ E.width E.fill, E.spacing 12 ]
            [ E.el
                [ E.width (E.px 12)
                , E.height E.fill
                , Background.color Color.focus85
                ]
                E.none
            , Ui.paragraphParts
                [ Ui.text "Rappel: "
                , Ui.boldText
                    """il ne faut jamais utiliser la fonctionnalité de nettoyage des données
                    du navigateur."""
                , Ui.text
                    """
                    Cela effacerait tout les opérations que vous avez entré dans Pactole.
                    """
                ]
            ]
        , Ui.paragraph
            """
            Si vous voulez transférer vos données sur un nouvel appareil, vous pouvez
            faire une copie de sauvegarde, transférer le fichier et le récupérer sur le nouvel appareil.
            """
        , Ui.simpleButton
            { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsAskExportConfirmation)
            , label = E.row [ E.spacing 12 ] [ Ui.saveIcon, E.text "Faire une copie de sauvegarde" ]
            }
        , Ui.simpleButton
            { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsAskImportConfirmation)
            , label = E.row [ E.spacing 12 ] [ Ui.loadIcon, E.text "Récupérer une sauvegarde" ]
            }
        , Ui.verticalSpacer
        ]


configAccounts : Model -> E.Element Msg
configAccounts model =
    let
        settings =
            model.settings
    in
    E.column [ E.spacing 24 ]
        [ Ui.title model.device "Configuration des comptes"
        , Ui.paragraph "Liste des comptes:"
        , E.column [ E.padding 6, E.spacing 6, E.width <| E.minimum 100 <| E.fill ]
            (model.accounts
                |> Dict.toList
                |> List.map
                    (\( id, name ) ->
                        Ui.flatButton
                            { label = E.text name
                            , onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsEditAccount (Just id)
                            }
                    )
            )
        , Ui.simpleButton
            { onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsEditAccount Nothing
            , label = E.row [] [ Ui.plusIcon, E.text "  Nouveau compte" ]
            }
        , Ui.verticalSpacer
        , Ui.paragraph "Avertissement lorsque le solde passe en dessous de:"
        , E.row [ E.spacing 12 ]
            [ Ui.simpleButton
                { label = Ui.minusIcon
                , onPress =
                    Just (Msg.ForDatabase <| Msg.DbStoreSettings { settings | balanceWarning = settings.balanceWarning - 10 })
                }
            , E.el []
                (E.text (String.fromInt model.settings.balanceWarning))
            , E.el []
                (E.text "€")
            , Ui.simpleButton
                { label = Ui.plusIcon
                , onPress =
                    Just (Msg.ForDatabase <| Msg.DbStoreSettings { settings | balanceWarning = settings.balanceWarning + 10 })
                }
            ]
        , Ui.verticalSpacer
        ]


configOptional : Model -> E.Element Msg
configOptional model =
    let
        settings =
            model.settings
    in
    E.column [ E.spacing 24 ]
        [ Ui.title model.device "Fonctions optionnelles"
        , Ui.configRadio
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | summaryEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | summaryEnabled = False }
            , label = "Page de bilan:"
            , options =
                [ Ui.radioRowOption False (E.text "Désactivée")
                , Ui.radioRowOption True (E.text "Activée")
                ]
            , selected = Just model.settings.summaryEnabled
            }
        , Ui.configRadio
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | reconciliationEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | reconciliationEnabled = False }
            , label = "Page de pointage:"
            , options =
                [ Ui.radioRowOption False (E.text "Désactivée")
                , Ui.radioRowOption True (E.text "Activée")
                ]
            , selected = Just model.settings.reconciliationEnabled
            }
        , Ui.configRadio
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | categoriesEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | categoriesEnabled = False }
            , label = "Catégories de dépense:"
            , options =
                [ Ui.radioRowOption False (E.text "Désactivées")
                , Ui.radioRowOption True (E.text "Activées")
                ]
            , selected = Just model.settings.categoriesEnabled
            }
        , Ui.paragraph "Liste des catégories:"
        , E.column [ E.padding 6, E.spacing 6, E.width <| E.minimum 100 <| E.fill ]
            (model.categories
                |> Dict.toList
                |> List.map
                    (\( id, { name, icon } ) ->
                        Ui.flatButton
                            { label =
                                E.row []
                                    [ Ui.viewIcon icon
                                    , E.text <| " " ++ name
                                    ]
                            , onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsEditCategory (Just id)
                            }
                    )
            )
        , Ui.simpleButton
            { onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsEditCategory Nothing
            , label = E.row [] [ Ui.plusIcon, E.text "  Nouvelle catégorie" ]
            }
        , Ui.verticalSpacer
        ]


configRecurring : Model -> E.Element Msg
configRecurring model =
    E.column [ E.spacing 24 ]
        [ Ui.title model.device "Opération mensuelles"
        , E.column [ E.spacing 6, E.padding 6 ]
            (model.recurring
                |> Ledger.getAllTransactions
                |> List.map
                    (\t ->
                        let
                            m =
                                Money.toStrings t.amount
                        in
                        Ui.flatButton
                            { onPress = Just <| (Msg.ForSettingsDialog <| Msg.SettingsEditRecurring (Just t.id))
                            , label =
                                E.row [ E.spacing 24, E.width E.fill ]
                                    [ E.el [ E.width E.fill ] <|
                                        E.text <|
                                            Model.accountName t.account model
                                    , E.el [ E.width E.fill ] <|
                                        E.text <|
                                            Date.toString t.date
                                    , E.el [ E.width E.fill, Font.alignRight ] <|
                                        E.text <|
                                            (m.sign ++ m.units ++ "," ++ m.cents)
                                    , E.el [ E.width E.fill ] <|
                                        E.text t.description
                                    ]
                            }
                    )
            )
        , Ui.simpleButton
            { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsEditRecurring Nothing)
            , label = E.row [] [ Ui.plusIcon, E.text "  Nouvelle opération mensuelle" ]
            }
        , Ui.verticalSpacer
        ]


configLocked : Model -> E.Element Msg
configLocked model =
    let
        settings =
            model.settings
    in
    E.column
        [ E.width E.fill, E.spacing 24 ]
        [ Ui.title model.device "Accès aux réglages"
        , Ui.paragraph
            """
            Si l'utilisateur principal de l'application n'est pas à l'aise avec
            toutes les fonctionnalités, vous pouvez cacher l'accès aux réglages
            afin de prévenir toute fausse manipulation.
            """
        , Ui.configRadio
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | settingsLocked = True }

                    else
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | settingsLocked = False }
            , label = "Accès aux réglages:"
            , options =
                [ Ui.radioRowOption False (E.text "Visible")
                , Ui.radioRowOption True (E.text "Caché")
                ]
            , selected = Just model.settings.settingsLocked
            }
        , Ui.paragraph
            """
            Note: dans tous les cas, les réglages restent accessibles en utilisant
            le lien présent dans la page d'aide de l'application.
            """
        , Ui.verticalSpacer
        ]


configFont : Model -> E.Element Msg
configFont model =
    E.column
        [ E.width E.fill, E.spacing 24 ]
        [ Ui.title model.device "Apparence"
        , Ui.simpleButton
            { label = E.text "Changer la police de caractères"
            , onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsEditFont
            }
        , Ui.verticalSpacer
        ]



-- DIALOG


viewDialog : Model -> E.Element Msg
viewDialog model =
    case model.settingsDialog of
        Nothing ->
            E.none

        Just (Model.EditAccount submodel) ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm) ]
                    (Ui.textInput
                        { label = Ui.labelLeft "Nom du compte:"
                        , text = submodel.name
                        , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeName n
                        , width = 400
                        }
                    )
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , case submodel.id of
                        Just accountId ->
                            Ui.dangerButton
                                { label = E.text "Supprimer"
                                , onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsDeleteAccount accountId
                                }

                        Nothing ->
                            E.none
                    , Ui.mainButton
                        { label = E.text "OK"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.DeleteCategory submodel) ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.bigFont model.device
                    , Font.bold
                    ]
                    (E.text ("Supprimer la catégorie \"" ++ submodel.name ++ "\" ?"))
                , Ui.paragraph
                    """Les opérations déjà associées à cette catégorie passeront 
                    dans la catégorie "Aucune"
                    """
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.dangerButton
                        { label = E.text "Supprimer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.EditCategory submodel) ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm) ]
                    (Ui.textInput
                        { label = Ui.labelLeft "Catégorie:"
                        , text = submodel.name
                        , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeName n
                        , width = 200
                        }
                    )
                , E.el []
                    (E.wrappedRow
                        [ E.spacing 6 ]
                        (List.map
                            (\icon ->
                                Ui.radioButton
                                    { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsChangeIcon icon)
                                    , icon = icon
                                    , label = ""
                                    , active = submodel.icon == icon
                                    }
                            )
                            iconChoice
                        )
                    )
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , case submodel.id of
                        Just categoryId ->
                            Ui.dangerButton
                                { label = E.text "Supprimer"
                                , onPress =
                                    Just <|
                                        Msg.ForSettingsDialog <|
                                            Msg.SettingsDeleteCategory categoryId
                                }

                        Nothing ->
                            E.none
                    , Ui.mainButton
                        { label = E.text "OK"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.DeleteAccount submodel) ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.bigFont model.device
                    ]
                    (E.text ("Supprimer le compte \"" ++ submodel.name ++ "\" ?"))
                , E.el []
                    (Ui.warningParagraph
                        [ E.el [ Font.bold ] (E.text " Toutes les opérations de ce compte ")
                        , E.el [ Font.bold ] (E.text "vont être définitivement supprimées!")
                        ]
                    )
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.dangerButton
                        { label = E.text "Supprimer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.EditRecurring submodel) ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                , Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                ]
                [ Ui.textInput
                    { label = Ui.labelLeft "Jour du mois: "
                    , text = submodel.dueDate
                    , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeDueDate n
                    , width = 400
                    }
                , E.row [ E.spacingXY 24 0 ]
                    (E.el [] (E.text "Compte: ")
                        :: List.map
                            (\( k, v ) ->
                                Ui.radioButton
                                    { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsChangeAccount k)
                                    , icon = ""
                                    , label = v
                                    , active = k == submodel.account
                                    }
                            )
                            (Dict.toList model.accounts)
                    )
                , E.row
                    [ E.spacingXY 24 0
                    ]
                    [ E.el [] (E.text "Type: ")
                    , E.row []
                        [ Ui.radioButton
                            { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsChangeIsExpense False)
                            , icon = "" --"\u{F067}"
                            , label = "Entrée d'argent"
                            , active = not submodel.isExpense
                            }
                        , Ui.radioButton
                            { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsChangeIsExpense True)
                            , icon = "" --"\u{F068}"
                            , label = "Dépense"
                            , active = submodel.isExpense
                            }
                        ]
                    ]
                , Ui.textInput
                    { label = Ui.labelLeft "Montant:"
                    , text = submodel.amount
                    , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeAmount n
                    , width = 400
                    }
                , Ui.textInput
                    { label = Ui.labelLeft "Description:"
                    , text = submodel.description
                    , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeName n
                    , width = 400
                    }
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , case submodel.id of
                        Just recurringId ->
                            Ui.dangerButton
                                { label = E.text "Supprimer"
                                , onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsDeleteRecurring recurringId
                                }

                        Nothing ->
                            E.none
                    , Ui.mainButton
                        { label = E.text "Confirmer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just Model.AskImportConfirmation ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.bigFont model.device
                    , Font.bold
                    ]
                    (E.text "Remplacer toutes les données?")
                , E.el []
                    (Ui.warningParagraph
                        [ E.el [ Font.bold ] (E.text "Toutes les opérations et les réglages vont être ")
                        , E.el [ Font.bold ] (E.text "définitivement supprimés!")
                        , E.text " Ils seront remplacés par le contenu du fichier sélectionné."
                        ]
                    )
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.dangerButton
                        { label = E.text "Supprimer et Remplacer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just Model.AskExportConfirmation ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.bigFont model.device
                    , Font.bold
                    ]
                    (E.text "Sauvegarder les données?")
                , E.paragraph
                    []
                    [ E.text "Toutes les données de Pactole vont être enregistrées dans le dans le fichier suivant:"
                    ]
                , E.row
                    [ Ui.bigFont model.device
                    , E.width E.fill
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , E.text (Database.exportFileName model)
                    , E.el [ E.width E.fill ] E.none
                    ]
                , E.paragraph
                    []
                    [ E.text "Il sera placé dans le dossier des téléchargements."
                    ]
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton
                        { label = E.text "Sauvegarder"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.EditFont submodel) ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.column []
                    [ E.el
                        [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm) ]
                        (Ui.textInput
                            { label = Ui.labelLeft "Police de caractère:"
                            , text = submodel
                            , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeName n
                            , width = 400
                            }
                        )
                    , Ui.simpleButton
                        { label = Ui.text "réinitialiser"
                        , onPress = Just <| Msg.ForSettingsDialog <| Msg.SettingsChangeName "Andika New Basic"
                        }
                    ]
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.simpleButton
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton
                        { label = E.text "OK"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.UserError error) ->
            E.column
                [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.bigFont model.device
                    , Font.bold
                    ]
                    (E.text "Erreur")
                , E.el []
                    (Ui.warningParagraph
                        [ E.text error
                        ]
                    )
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    ]
                    [ E.el [ E.width E.fill ] E.none
                    , Ui.mainButton
                        { label = E.text "OK"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]



-- ICONS


iconChoice : List String
iconChoice =
    [ " "
    , "\u{F6BE}" -- cat
    , "\u{F520}" -- crow
    , "\u{F6D3}" -- dog
    , "\u{F578}" -- fish
    , "\u{F1B0}" -- paw
    , "\u{F001}" -- music
    , "\u{F55E}" -- bus-alt
    , "\u{F1B9}" -- car
    , "\u{F5E4}" -- car-side

    --, "\u{F8FF}" -- caravan
    , "\u{F52F}" -- gas-pump
    , "\u{F21C}" -- motorcycle
    , "\u{F0D1}" -- truck
    , "\u{F722}" -- tractor
    , "\u{F5D1}" -- apple-alt
    , "\u{F6BB}" -- campground
    , "\u{F44E}" -- football-ball
    , "\u{F6EC}" -- hiking
    , "\u{F6FC}" -- mountain
    , "\u{F1BB}" -- tree
    , "\u{F015}" -- home
    , "\u{F19C}" -- university
    , "\u{F1FD}" -- birthday-cake
    , "\u{F06B}" -- gift
    , "\u{F095}" -- phone
    , "\u{F77C}" -- baby
    , "\u{F77D}" -- baby-carriage
    , "\u{F553}" -- tshirt
    , "\u{F696}" -- socks
    , "\u{F303}" -- pencil-alt
    , "\u{F53F}" -- palette
    , "\u{F206}" -- bicycle
    , "\u{F787}" -- carrot
    , "\u{F522}" -- dice
    , "\u{F11B}" -- gamepad
    , "\u{F71E}" -- toilet-paper
    , "\u{F0F9}" -- ambulance
    , "\u{F0F1}" -- stethoscope
    , "\u{F0F0}" -- user-md
    , "\u{F193}" -- wheelchair
    , "\u{F084}" -- key
    , "\u{F48D}" -- smoking
    , "\u{F5C4}" -- swimmer
    , "\u{F5CA}" -- umbrella-beach
    , "\u{F4B8}" -- couch

    --, "\u{E005}" -- faucet
    , "\u{F0EB}" -- lightbulb
    , "\u{F1E6}" -- plug
    , "\u{F2CC}" -- shower
    , "\u{F083}" -- camera-retro
    , "\u{F008}" -- film
    , "\u{F0AD}" -- wrench
    , "\u{F13D}" -- anchor
    , "\u{F7A6}" -- guitar
    , "\u{F1E3}" -- futbol
    , "\u{F1FC}" -- paint-brush
    , "\u{F290}" -- shopping-bag
    , "\u{F291}" -- shopping-basket
    , "\u{F07A}" -- shopping-cart
    , "\u{F7D9}" -- tools
    , "\u{F3A5}" -- gem
    , "\u{F135}" -- rocket
    , "\u{F004}" -- heart
    , "\u{F005}" -- star
    , "\u{F0C0}" -- users
    , "\u{F45D}" -- table-tennis
    , "\u{F108}" -- dekstop
    , "\u{F11C}" -- keyboard

    --
    , "\u{F2E7}"
    , "\u{F02D}"
    , "\u{F030}"
    , "\u{F03E}"
    , "\u{F072}"
    , "\u{F091}"
    , "\u{F128}"
    ]
