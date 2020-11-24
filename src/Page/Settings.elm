module Page.Settings exposing
    ( update
    , view
    , viewDialog
    )

import Database
import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Ledger
import Log
import Model
import Money
import Msg
import Ui



-- UPDATE


update : Msg.SettingsDialogMsg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.OpenRenameAccount id ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | settingsDialog = Just (Model.RenameAccount { id = id, name = name }) }
            , Cmd.none
            )

        Msg.OpenDeleteAccount id ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | settingsDialog = Just (Model.DeleteAccount { id = id, name = name }) }
            , Cmd.none
            )

        Msg.OpenRenameCategory id ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | settingsDialog = Just (Model.RenameCategory { id = id, name = name, icon = icon }) }
            , Cmd.none
            )

        Msg.OpenDeleteCategory id ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | settingsDialog = Just (Model.DeleteCategory { id = id, name = name, icon = icon }) }
            , Cmd.none
            )

        Msg.NewRecurringTransaction ->
            let
                t =
                    { date = model.today
                    , amount = Money.zero
                    , description = "Nouvelle operation"
                    , category = 0
                    , checked = False
                    }

                settings =
                    model.settings

                account =
                    case model.account of
                        Just a ->
                            a

                        Nothing ->
                            0

                newSettings =
                    { settings
                        | recurringTransactions =
                            settings.recurringTransactions ++ [ ( account, t ) ]
                    }
            in
            ( model, Database.storeSettings newSettings )

        Msg.OpenEditRecurring idx account transaction ->
            ( { model
                | settingsDialog =
                    Just
                        (Model.EditRecurring
                            { idx = idx
                            , account = account
                            , amount = Money.toInput transaction.amount
                            , description = transaction.description
                            , category = transaction.category
                            , dueDate = Date.getDay transaction.date
                            }
                        )
              }
            , Cmd.none
            )

        Msg.DeleteRecurring idx ->
            let
                remove i xs =
                    List.take i xs ++ List.drop (i + 1) xs

                settings =
                    model.settings

                newSettings =
                    { settings
                        | recurringTransactions =
                            remove idx settings.recurringTransactions
                    }
            in
            ( model, Database.storeSettings newSettings )

        Msg.SettingsChangeName name ->
            case model.settingsDialog of
                Just (Model.RenameAccount submodel) ->
                    ( { model | settingsDialog = Just (Model.RenameAccount { submodel | name = name }) }
                    , Cmd.none
                    )

                Just (Model.RenameCategory submodel) ->
                    ( { model | settingsDialog = Just (Model.RenameCategory { submodel | name = name }) }
                    , Cmd.none
                    )

                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | description = name }) }
                    , Cmd.none
                    )

                Just other ->
                    ( { model | settingsDialog = Just other }
                    , Log.error "invalid context for Msg.SettingsChangeName"
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
                    ( { model | settingsDialog = Just other }
                    , Log.error "invalid context for Msg.SettingsChangeAccount"
                    )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsChangeIcon icon ->
            case model.settingsDialog of
                Just (Model.RenameCategory submodel) ->
                    ( { model | settingsDialog = Just (Model.RenameCategory { submodel | icon = icon }) }
                    , Cmd.none
                    )

                Just other ->
                    ( { model | settingsDialog = Just other }
                    , Log.error "invalid context for Msg.SettingsChangeIcon"
                    )

                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )

        Msg.SettingsConfirm ->
            case model.settingsDialog of
                Just (Model.RenameAccount submodel) ->
                    ( { model | settingsDialog = Nothing }, Database.renameAccount submodel.id submodel.name )

                Just (Model.DeleteAccount submodel) ->
                    ( { model | settingsDialog = Nothing }, Database.deleteAccount submodel.id )

                Just (Model.RenameCategory submodel) ->
                    ( { model | settingsDialog = Nothing }, Database.renameCategory submodel.id submodel.name submodel.icon )

                Just (Model.DeleteCategory submodel) ->
                    ( { model | settingsDialog = Nothing }, Database.deleteCategory submodel.id )

                Just (Model.EditRecurring submodel) ->
                    let
                        replace i x xs =
                            List.take i xs ++ (x :: List.drop (i + 1) xs)

                        settings =
                            model.settings

                        newSettings =
                            { settings
                                | recurringTransactions =
                                    replace submodel.idx
                                        ( submodel.account
                                        , { amount =
                                                Maybe.withDefault Money.zero
                                                    (Money.fromInput False submodel.amount)
                                          , description = submodel.description
                                          , category = submodel.category
                                          , date = model.today
                                          , checked = False
                                          }
                                        )
                                        settings.recurringTransactions
                            }
                    in
                    ( { model | settingsDialog = Nothing }
                    , Database.storeSettings newSettings
                    )

                {-
                   Just other ->
                       ( { model | settingsDialog = Just other }
                         -- TODO
                       , Log.error "invalid context for Msg.SettingsChangeConfirm"
                       )
                -}
                Nothing ->
                    ( { model | settingsDialog = Nothing }, Cmd.none )



-- VIEW


view : Model.Model -> E.Element Msg.Msg
view model =
    Ui.pageWithSidePanel []
        { panel =
            E.row
                [ E.centerX ]
                [ Ui.simpleButton []
                    { onPress = Just (Msg.ChangePage Model.MainPage)
                    , label =
                        E.row []
                            [ Ui.backIcon []
                            , E.text "  Retour"
                            ]
                    }
                ]
        , page =
            E.column
                [ E.width E.fill
                , E.height E.fill
                , E.paddingXY 48 0
                , E.scrollbarY
                ]
                [ Ui.pageTitle [ E.centerY, Font.color Ui.fgTitle ]
                    (E.text "Configuration")
                , E.row
                    [ E.width E.fill ]
                    [ E.paragraph
                        [ E.width (E.fillPortion 4)
                        , E.paddingEach { top = 24, bottom = 24, left = 12, right = 12 }
                        ]
                        [ E.text "Rappel: l'application enregistre ses données uniquement sur cet ordinateur; "
                        , E.text "rien n'est envoyé sur internet."
                        ]
                    , E.el [ E.width (E.fillPortion 2) ] E.none
                    ]
                , Ui.configCustom []
                    { label = "Personnes utilisant l'application:"
                    , content =
                        E.column [ E.spacing 24 ]
                            [ E.table [ E.spacing 6 ]
                                { data = Dict.toList model.accounts
                                , columns =
                                    [ { header = E.none
                                      , width = E.fill
                                      , view = \a -> E.el [ E.centerY ] (E.text (Tuple.second a))
                                      }
                                    , { header = E.none
                                      , width = E.shrink
                                      , view =
                                            \a ->
                                                Ui.iconButton []
                                                    { icon = Ui.editIcon []
                                                    , onPress = Just (Msg.ForSettingsDialog <| Msg.OpenRenameAccount (Tuple.first a))
                                                    }
                                      }
                                    , { header = E.none
                                      , width = E.shrink
                                      , view =
                                            \a ->
                                                Ui.iconButton []
                                                    { icon = Ui.deleteIcon []
                                                    , onPress = Just (Msg.ForSettingsDialog <| Msg.OpenDeleteAccount (Tuple.first a))
                                                    }
                                      }
                                    ]
                                }
                            , Ui.simpleButton []
                                { onPress = Just (Msg.ForDatabase <| Msg.CreateAccount (newAccountName (Dict.values model.accounts) 1))
                                , label = E.row [] [ Ui.plusIcon [], E.text "  Ajouter" ]
                                }
                            ]
                    }

                {-
                   , Ui.configRadio []
                       { onChange =
                           \o ->
                               let
                                   settings =
                                       model.settings
                               in
                               case o of
                                   Msg.InCalendar ->
                                       Msg.SetSettings { settings | defaultMode = Msg.InCalendar }

                                   Msg.InTabular ->
                                       Msg.SetSettings { settings | defaultMode = Msg.InTabular }
                       , label = "Affichage les opérations par:"
                       , options =
                           [ Ui.radioRowOption Msg.InCalendar (E.text "Calendrier")
                           , Ui.radioRowOption Msg.InTabular (E.text "Liste")
                           ]
                       , selected = Just model.settings.defaultMode
                       }
                -}
                , configWarning model
                , configSummary model
                , configReconciliation model
                , configCategoriesEnabled model
                , configCategories model
                , configRecurring model
                ]
        }


configWarning model =
    let
        settings =
            model.settings
    in
    Ui.configCustom []
        { label = "Avertissement lorsque le solde passe sous:"
        , content =
            E.row [ E.spacing 12 ]
                [ Ui.iconButton [ Border.color Ui.fgDark, Border.width Ui.borderWidth ]
                    { icon = Ui.minusIcon []
                    , onPress =
                        Just (Msg.ForDatabase <| Msg.StoreSettings { settings | balanceWarning = settings.balanceWarning - 10 })
                    }
                , E.el [ Ui.bigFont ]
                    (E.text (String.fromInt model.settings.balanceWarning))
                , E.el [ Ui.normalFont ]
                    (E.text "€")
                , Ui.iconButton [ Border.color Ui.fgDark, Border.width Ui.borderWidth ]
                    { icon = Ui.plusIcon []
                    , onPress =
                        Just (Msg.ForDatabase <| Msg.StoreSettings { settings | balanceWarning = settings.balanceWarning + 10 })
                    }
                ]
        }


configSummary model =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        model.settings
                in
                case o of
                    True ->
                        Msg.ForDatabase <| Msg.StoreSettings { settings | summaryEnabled = True }

                    False ->
                        Msg.ForDatabase <| Msg.StoreSettings { settings | summaryEnabled = False }
        , label = "Activer la page de bilan:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just model.settings.summaryEnabled
        }


configReconciliation model =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        model.settings
                in
                case o of
                    True ->
                        Msg.ForDatabase <| Msg.StoreSettings { settings | reconciliationEnabled = True }

                    False ->
                        Msg.ForDatabase <| Msg.StoreSettings { settings | reconciliationEnabled = False }
        , label = "Activer la page de pointage:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just model.settings.reconciliationEnabled
        }


configCategoriesEnabled model =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        model.settings
                in
                case o of
                    True ->
                        Msg.ForDatabase <| Msg.StoreSettings { settings | categoriesEnabled = True }

                    False ->
                        Msg.ForDatabase <| Msg.StoreSettings { settings | categoriesEnabled = False }
        , label = "Activer les catégories:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just model.settings.categoriesEnabled
        }


configCategories model =
    Ui.configCustom []
        { label =
            if model.settings.categoriesEnabled then
                "Catégories:"

            else
                "Catégories (désactivées):"
        , content =
            E.column [ E.spacing 24 ]
                [ E.table [ E.spacing 12 ]
                    { data = Dict.toList model.categories
                    , columns =
                        [ { header = E.none
                          , width = E.shrink
                          , view =
                                \a ->
                                    E.el [ E.centerY, Ui.iconFont ]
                                        (E.text (Tuple.second a).icon)
                          }
                        , { header = E.none
                          , width = E.fill
                          , view = \a -> E.el [ E.centerY ] (E.text (Tuple.second a).name)
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \a ->
                                    Ui.iconButton []
                                        { icon = Ui.editIcon []
                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.OpenRenameCategory (Tuple.first a))
                                        }
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \a ->
                                    Ui.iconButton []
                                        { icon = Ui.deleteIcon []
                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.OpenDeleteCategory (Tuple.first a))
                                        }
                          }
                        ]
                    }
                , Ui.simpleButton []
                    { onPress = Just (Msg.ForDatabase <| Msg.CreateCategory "Nouvelle catégorie" "")
                    , label = E.row [] [ Ui.plusIcon [], E.text "  Ajouter" ]
                    }
                ]
        }


configRecurring : Model.Model -> E.Element Msg.Msg
configRecurring model =
    let
        headerTxt txt =
            E.el [ Font.center, Ui.smallFont, Font.color Ui.fgDark ] (E.text txt)
    in
    Ui.configCustom []
        { label = "Operations recurrentes:"
        , content =
            E.column [ E.spacing 24 ]
                [ E.table [ E.spacingXY 12 6 ]
                    { data =
                        List.indexedMap
                            (\i ( a, t ) -> ( i, a, t ))
                            model.settings.recurringTransactions
                    , columns =
                        [ { header = headerTxt "Compte"
                          , width = E.shrink
                          , view =
                                \( i, a, t ) ->
                                    E.el [ Font.center, E.centerY ] (E.text (Model.account a model))
                          }
                        , { header = headerTxt "Montant"
                          , width = E.shrink
                          , view =
                                \( i, a, t ) ->
                                    let
                                        m =
                                            Money.toStrings t.amount
                                    in
                                    E.el [ Font.alignRight, E.centerY ] (E.text (m.sign ++ m.units ++ "," ++ m.cents))
                          }
                        , { header = headerTxt "Description"
                          , width = E.fill
                          , view =
                                \( i, a, t ) ->
                                    E.el [ E.centerY ] (E.text t.description)
                          }
                        , { header = headerTxt "Echeance"
                          , width = E.fill
                          , view =
                                \( i, a, t ) ->
                                    E.el [ Font.center, E.centerY ] (E.text (Date.toString t.date))
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \( i, a, t ) ->
                                    Ui.iconButton []
                                        { icon = Ui.editIcon []
                                        , onPress =
                                            Just
                                                (Msg.ForSettingsDialog <|
                                                    Msg.OpenEditRecurring i a t
                                                )
                                        }
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \( i, _, _ ) ->
                                    Ui.iconButton []
                                        { icon = Ui.deleteIcon []
                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.DeleteRecurring i)
                                        }
                          }
                        ]
                    }
                , Ui.simpleButton []
                    { onPress = Just (Msg.ForSettingsDialog <| Msg.NewRecurringTransaction)
                    , label = E.row [] [ Ui.plusIcon [], E.text "  Ajouter" ]
                    }
                ]
        }



-- DIALOG


viewDialog : Model.Model -> E.Element Msg.Msg
viewDialog model =
    case model.settingsDialog of
        Nothing ->
            E.none

        Just (Model.RenameAccount submodel) ->
            E.column
                [ E.centerX
                , E.centerY
                , E.width (E.px 800)
                , E.height E.shrink
                , E.paddingXY 0 0
                , E.spacing 0
                , E.scrollbarY
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                ]
                [ E.el
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 } ]
                    (Input.text
                        [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        , Ui.bigFont
                        , E.focused
                            [ Border.shadow
                                { offset = ( 0, 0 )
                                , size = 4
                                , blur = 0
                                , color = Ui.fgFocus
                                }
                            ]
                        ]
                        { label =
                            Input.labelAbove
                                [ E.width E.shrink
                                , Font.color Ui.fgTitle
                                , Ui.normalFont
                                , Font.bold
                                , E.paddingEach { top = 12, bottom = 0, left = 12, right = 0 }
                                , E.pointer
                                ]
                                (E.text ("Renommer le compte \"" ++ submodel.name ++ "\":"))
                        , text = submodel.name
                        , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeName n
                        , placeholder = Nothing
                        }
                    )
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    , E.paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ E.alignRight ]
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Confirmer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.DeleteCategory submodel) ->
            E.column
                [ E.centerX
                , E.centerY
                , E.width (E.px 800)
                , E.height E.shrink
                , E.paddingXY 0 0
                , E.spacing 0
                , E.scrollbarY
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                ]
                [ E.el
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
                    , Ui.bigFont
                    ]
                    (E.text ("Supprimer la catégorie \"" ++ submodel.name ++ "\" ?"))
                , E.paragraph
                    [ E.paddingEach { top = 24, bottom = 24, right = 96, left = 96 }
                    ]
                    [ E.text "Les opérations dans cette catégorie deviendront \"Sans Catégorie\""
                    ]
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    , E.paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ E.alignRight ]
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Supprimer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.RenameCategory submodel) ->
            E.column
                [ E.centerX
                , E.centerY
                , E.width (E.px 800)
                , E.height E.fill
                , E.paddingXY 0 0
                , E.spacing 0
                , E.clip
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                ]
                [ E.el
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 } ]
                    (Input.text
                        [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        , Ui.bigFont
                        ]
                        { label =
                            Input.labelAbove
                                [ E.width E.shrink
                                , Font.color Ui.fgTitle
                                , Ui.normalFont
                                , Font.bold
                                , E.paddingEach { top = 12, bottom = 0, left = 12, right = 0 }
                                , E.pointer
                                ]
                                (E.text ("Renommer la catégorie \"" ++ submodel.name ++ "\":"))
                        , text = submodel.name
                        , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeName n
                        , placeholder = Nothing
                        }
                    )
                , E.el
                    [ E.height (E.fill |> E.minimum 200)
                    , E.scrollbarY
                    ]
                    (E.wrappedRow
                        [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
                        , E.spacing 6
                        ]
                        {- label =
                           Input.labelAbove
                               [ E.width E.shrink
                               , Font.color Ui.fgTitle
                               , Ui.normalFont
                               , Font.bold
                               , E.paddingEach { top = 12, bottom = 0, left = 12, right = 0 }
                               , E.pointer
                               ]
                               (E.text "Choisir une icône: ")
                        -}
                        (List.map
                            (\icon ->
                                Ui.radioButton
                                    [ E.width (E.shrink |> E.minimum 80)
                                    , Font.center
                                    ]
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
                    , E.paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ E.alignRight ]
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Confirmer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.DeleteAccount submodel) ->
            E.column
                [ E.centerX
                , E.centerY
                , E.width (E.px 800)
                , E.height E.shrink
                , E.paddingXY 0 0
                , E.spacing 0
                , E.scrollbarY
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                ]
                [ E.el
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
                    , Ui.bigFont
                    ]
                    (E.text ("Supprimer le compte \"" ++ submodel.name ++ "\" ?"))
                , Ui.warningParagraph
                    [ E.paddingEach { top = 24, bottom = 24, right = 96, left = 96 }
                    ]
                    [ E.text "  Toutes les opérations associées à ce compte seront "
                    , E.el [ Font.bold ] (E.text "définitivement supprimées!")
                    ]
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    , E.paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ E.alignRight ]
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Supprimer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]

        Just (Model.EditRecurring submodel) ->
            E.column
                [ E.centerX
                , E.centerY
                , E.width (E.px 800)
                , E.height E.shrink
                , E.paddingXY 0 0
                , E.spacing 0
                , E.scrollbarY
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                ]
                [ E.el
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 } ]
                    (E.row []
                        (List.map
                            (\( k, v ) ->
                                Ui.radioButton []
                                    { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsChangeAccount k)
                                    , icon = ""
                                    , label = v
                                    , active = k == submodel.account
                                    }
                            )
                            (Dict.toList model.accounts)
                        )
                    )
                , E.el
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 } ]
                    (Input.text
                        [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        , Ui.bigFont
                        , E.focused
                            [ Border.shadow
                                { offset = ( 0, 0 )
                                , size = 4
                                , blur = 0
                                , color = Ui.fgFocus
                                }
                            ]
                        ]
                        { label =
                            Input.labelAbove
                                [ E.width E.shrink
                                , Font.color Ui.fgTitle
                                , Ui.normalFont
                                , Font.bold
                                , E.paddingEach { top = 12, bottom = 0, left = 12, right = 0 }
                                , E.pointer
                                ]
                                (E.text "Description:")
                        , text = submodel.description
                        , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeName n
                        , placeholder = Nothing
                        }
                    )
                , E.row
                    [ E.width E.fill
                    , E.spacing 24
                    , E.paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ E.alignRight ]
                        { label = E.text "Annuler"
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Confirmer"
                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        }
                    ]
                ]



-- UTILS


newAccountName : List String -> Int -> String
newAccountName accounts number =
    let
        name =
            "Compte " ++ String.fromInt number
    in
    if List.member name accounts then
        newAccountName accounts (number + 1)

    else
        name



-- ICONS


iconChoice =
    [ ""
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
