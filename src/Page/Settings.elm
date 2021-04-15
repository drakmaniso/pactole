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
import Log
import Model
import Money
import Msg
import Ui



-- UPDATE


update : Msg.SettingsDialogMsg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.SettingsRenameAccount id ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | settingsDialog = Just (Model.RenameAccount { id = id, name = name }) }
            , Cmd.none
            )

        Msg.SettingsDeleteAccount id ->
            let
                name =
                    Maybe.withDefault "ERROR"
                        (Dict.get id model.accounts)
            in
            ( { model | settingsDialog = Just (Model.DeleteAccount { id = id, name = name }) }
            , Cmd.none
            )

        Msg.SettingsRenameCategory id ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | settingsDialog = Just (Model.RenameCategory { id = id, name = name, icon = icon }) }
            , Cmd.none
            )

        Msg.SettingsDeleteCategory id ->
            let
                { name, icon } =
                    Maybe.withDefault { name = "ERROR", icon = "" }
                        (Dict.get id model.categories)
            in
            ( { model | settingsDialog = Just (Model.DeleteCategory { id = id, name = name, icon = icon }) }
            , Cmd.none
            )

        Msg.SettingsNewRecurring ->
            let
                t =
                    { date = Date.findNextDayOfMonth 1 model.today
                    , account = model.account
                    , amount = Money.zero
                    , description = "(opération mensuelle)"
                    , category = 0
                    , checked = False
                    }

                settings =
                    model.settings

                newSettings =
                    { settings
                        | recurringTransactions =
                            settings.recurringTransactions ++ [ t ]
                    }
            in
            ( model, Database.storeSettings newSettings )

        Msg.SettingsEditRecurring idx account transaction ->
            ( { model
                | settingsDialog =
                    Just
                        (Model.EditRecurring
                            { idx = idx
                            , account = account
                            , isExpense = Money.isExpense transaction.amount
                            , amount = Money.toInput transaction.amount
                            , description = transaction.description
                            , category = transaction.category
                            , dueDate = String.fromInt (Date.getDay transaction.date)
                            }
                        )
              }
            , Cmd.none
            )

        Msg.SettingsDeleteRecurring idx ->
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

        Msg.SettingsChangeIsExpense isExpense ->
            case model.settingsDialog of
                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | isExpense = isExpense }) }
                    , Cmd.none
                    )

                Just other ->
                    ( { model | settingsDialog = Just other }
                    , Log.error "invalid context for Msg.SettingsChangeIsExpense"
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
                    ( { model | settingsDialog = Just other }
                    , Log.error "invalid context for Msg.SettingsChangeAmount"
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

        Msg.SettingsChangeDueDate day ->
            case model.settingsDialog of
                Just (Model.EditRecurring submodel) ->
                    ( { model | settingsDialog = Just (Model.EditRecurring { submodel | dueDate = day }) }
                    , Cmd.none
                    )

                Just other ->
                    ( { model | settingsDialog = Just other }
                    , Log.error "invalid context for Msg.SettingsChangeDueDate"
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

                        newSettings =
                            { settings
                                | recurringTransactions =
                                    replace submodel.idx
                                        { account = submodel.account
                                        , amount =
                                            Maybe.withDefault Money.zero
                                                (Money.fromInput submodel.isExpense submodel.amount)
                                        , description = submodel.description
                                        , category = submodel.category
                                        , date = dueDate
                                        , checked = False
                                        }
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
            E.column
                [ E.width E.fill
                , E.height E.fill
                , E.clipX
                , E.clipY
                ]
                [ E.el
                    [ E.centerX ]
                    (Ui.simpleButton []
                        { onPress = Just (Msg.ChangePage Model.MainPage)
                        , label =
                            E.row []
                                [ Ui.backIcon []
                                , E.text "  Retour"
                                ]
                        }
                    )
                , E.el
                    [ E.width E.fill, E.height E.fill ]
                    E.none
                ]
        , page =
            E.column
                -- This extra column is necessary to circumvent a
                -- scrollbar-related bug in elm-ui
                [ E.width E.fill
                , E.height E.fill
                , E.clipY
                ]
                [ E.column
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
                                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsRenameAccount (Tuple.first a))
                                                        }
                                          }
                                        , { header = E.none
                                          , width = E.shrink
                                          , view =
                                                \a ->
                                                    Ui.iconButton []
                                                        { icon = Ui.deleteIcon []
                                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsDeleteAccount (Tuple.first a))
                                                        }
                                          }
                                        ]
                                    }
                                , Ui.simpleButton []
                                    { onPress = Just (Msg.ForDatabase <| Msg.DbCreateAccount (newAccountName (Dict.values model.accounts) 1))
                                    , label = E.row [] [ Ui.plusIcon [], E.text "  Ajouter" ]
                                    }
                                ]
                        }
                    , configWarning model
                    , configSummary model
                    , configReconciliation model
                    , configCategoriesEnabled model
                    , configCategories model
                    , configRecurring model
                    ]
                ]
        }


configWarning : Model.Model -> E.Element Msg.Msg
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
                        Just (Msg.ForDatabase <| Msg.DbStoreSettings { settings | balanceWarning = settings.balanceWarning - 10 })
                    }
                , E.el [ Ui.bigFont ]
                    (E.text (String.fromInt model.settings.balanceWarning))
                , E.el [ Ui.normalFont ]
                    (E.text "€")
                , Ui.iconButton [ Border.color Ui.fgDark, Border.width Ui.borderWidth ]
                    { icon = Ui.plusIcon []
                    , onPress =
                        Just (Msg.ForDatabase <| Msg.DbStoreSettings { settings | balanceWarning = settings.balanceWarning + 10 })
                    }
                ]
        }


configSummary : Model.Model -> E.Element Msg.Msg
configSummary model =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        model.settings
                in
                if o then
                    Msg.ForDatabase <| Msg.DbStoreSettings { settings | summaryEnabled = True }

                else
                    Msg.ForDatabase <| Msg.DbStoreSettings { settings | summaryEnabled = False }
        , label = "Activer la page de bilan:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just model.settings.summaryEnabled
        }


configReconciliation : Model.Model -> E.Element Msg.Msg
configReconciliation model =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        model.settings
                in
                if o then
                    Msg.ForDatabase <| Msg.DbStoreSettings { settings | reconciliationEnabled = True }

                else
                    Msg.ForDatabase <| Msg.DbStoreSettings { settings | reconciliationEnabled = False }
        , label = "Activer la page de pointage:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just model.settings.reconciliationEnabled
        }


configCategoriesEnabled : Model.Model -> E.Element Msg.Msg
configCategoriesEnabled model =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        model.settings
                in
                if o then
                    Msg.ForDatabase <| Msg.DbStoreSettings { settings | categoriesEnabled = True }

                else
                    Msg.ForDatabase <| Msg.DbStoreSettings { settings | categoriesEnabled = False }
        , label = "Activer les catégories:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just model.settings.categoriesEnabled
        }


configCategories : Model.Model -> E.Element Msg.Msg
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
                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsRenameCategory (Tuple.first a))
                                        }
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \a ->
                                    Ui.iconButton []
                                        { icon = Ui.deleteIcon []
                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsDeleteCategory (Tuple.first a))
                                        }
                          }
                        ]
                    }
                , Ui.simpleButton []
                    { onPress = Just (Msg.ForDatabase <| Msg.DbCreateCategory "Nouvelle catégorie" "")
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
        { label = "Opérations mensuelles:"
        , content =
            E.column [ E.spacing 24 ]
                [ E.table [ E.spacingXY 12 6 ]
                    { data =
                        List.indexedMap
                            (\i t -> ( i, t ))
                            model.settings.recurringTransactions
                    , columns =
                        [ { header = headerTxt "Échéance"
                          , width = E.fill
                          , view =
                                \( _, t ) ->
                                    E.el [ Font.center, E.centerY ] (E.text (Date.toString t.date))
                          }
                        , { header = headerTxt "Compte"
                          , width = E.shrink
                          , view =
                                \( _, t ) ->
                                    E.el [ Font.center, E.centerY ] (E.text (Model.account t.account model))
                          }
                        , { header = headerTxt "Montant"
                          , width = E.shrink
                          , view =
                                \( _, t ) ->
                                    let
                                        m =
                                            Money.toStrings t.amount
                                    in
                                    E.el [ Font.alignRight, E.centerY ] (E.text (m.sign ++ m.units ++ "," ++ m.cents))
                          }
                        , { header = headerTxt "Description"
                          , width = E.fill
                          , view =
                                \( _, t ) ->
                                    E.el [ E.centerY ] (E.text t.description)
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \( i, t ) ->
                                    Ui.iconButton []
                                        { icon = Ui.editIcon []
                                        , onPress =
                                            Just
                                                (Msg.ForSettingsDialog <|
                                                    Msg.SettingsEditRecurring i t.account t
                                                )
                                        }
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \( i, _ ) ->
                                    Ui.iconButton []
                                        { icon = Ui.deleteIcon []
                                        , onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsDeleteRecurring i)
                                        }
                          }
                        ]
                    }
                , Ui.simpleButton []
                    { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsNewRecurring)
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
                    (Input.text
                        [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        , Ui.bigFont
                        , E.width (E.shrink |> E.minimum 120)
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
                            Input.labelLeft
                                [ E.width E.shrink
                                , Font.color Ui.fgTitle
                                , Ui.normalFont
                                , Font.bold
                                , E.paddingEach { right = 24, top = 0, left = 12, bottom = 0 }
                                , E.pointer
                                ]
                                (E.text "Jour du mois: ")
                        , text = submodel.dueDate
                        , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeDueDate n
                        , placeholder = Nothing
                        }
                    )
                , E.el
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 } ]
                    (E.row [ E.spacingXY 24 0 ]
                        (E.el
                            [ E.width E.fill
                            , Font.color Ui.fgTitle
                            , Ui.normalFont
                            , E.paddingEach { right = 24, top = 0, left = 12, bottom = 0 }
                            , Font.bold
                            ]
                            (E.el [ Font.bold ] (E.text "Compte: "))
                            :: List.map
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
                , E.row
                    [ E.paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
                    , E.spacingXY 24 0
                    ]
                    [ E.el
                        [ Font.color Ui.fgTitle
                        , Ui.normalFont
                        , E.paddingEach { right = 24, top = 0, left = 12, bottom = 0 }
                        , Font.bold
                        ]
                        (E.el [ Font.bold ] (E.text "Montant: "))
                    , E.column [ E.alignBottom ]
                        [ Ui.radioButton [ E.alignBottom ]
                            { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsChangeIsExpense False)
                            , icon = "\u{F067}"
                            , label = ""
                            , active = not submodel.isExpense
                            }
                        , Ui.radioButton [ E.alignBottom ]
                            { onPress = Just (Msg.ForSettingsDialog <| Msg.SettingsChangeIsExpense True)
                            , icon = "\u{F068}"
                            , label = ""
                            , active = submodel.isExpense
                            }
                        ]
                    , Input.text
                        [ Ui.onEnter (Msg.ForSettingsDialog <| Msg.SettingsConfirm)
                        , Ui.bigFont
                        , E.width (E.shrink |> E.minimum 220)
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
                            Input.labelHidden "Montant:"
                        , text = submodel.amount
                        , onChange = \n -> Msg.ForSettingsDialog <| Msg.SettingsChangeAmount n
                        , placeholder = Nothing
                        }
                    ]
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


iconChoice : List String
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
