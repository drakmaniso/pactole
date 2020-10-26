module Page.Settings exposing
    ( Dialog
    , msgChangeName
    , msgConfirm
    , openDeleteAccount
    , openDeleteCategory
    , openRenameAccount
    , openRenameCategory
    , view
    , viewDialog
    )

import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Ports
import Shared
import Ui



-- MODEL


type Dialog
    = RenameAccount { id : Int, name : String }
    | DeleteAccount { id : Int, name : String }
    | RenameCategory { id : Int, name : String, icon : String }
    | DeleteCategory { id : Int, name : String, icon : String }


openRenameAccount : Int -> Shared.Model -> Dialog
openRenameAccount id shared =
    let
        name =
            Maybe.withDefault "ERROR"
                (Dict.get id shared.accounts)
    in
    RenameAccount { id = id, name = name }


openDeleteAccount : Int -> Shared.Model -> Dialog
openDeleteAccount id shared =
    let
        name =
            Maybe.withDefault "ERROR"
                (Dict.get id shared.accounts)
    in
    DeleteAccount { id = id, name = name }


openRenameCategory : Int -> Shared.Model -> Dialog
openRenameCategory id shared =
    let
        { name, icon } =
            Maybe.withDefault { name = "ERROR", icon = "" }
                (Dict.get id shared.categories)
    in
    RenameCategory { id = id, name = name, icon = icon }


openDeleteCategory : Int -> Shared.Model -> Dialog
openDeleteCategory id shared =
    let
        { name, icon } =
            Maybe.withDefault { name = "ERROR", icon = "" }
                (Dict.get id shared.categories)
    in
    DeleteCategory { id = id, name = name, icon = icon }


msgChangeName : String -> Maybe Dialog -> ( Maybe Dialog, Cmd Shared.Msg )
msgChangeName name variant =
    case variant of
        Just (RenameAccount model) ->
            ( Just (RenameAccount { model | name = name })
            , Cmd.none
            )

        Just (RenameCategory model) ->
            ( Just (RenameCategory { model | name = name })
            , Cmd.none
            )

        Just other ->
            ( Just other
            , Ports.error "updateName: not in Rename Dialog"
            )

        Nothing ->
            ( Nothing, Cmd.none )


msgConfirm variant =
    case variant of
        Just (RenameAccount model) ->
            ( Nothing, Ports.renameAccount model.id model.name )

        Just (DeleteAccount model) ->
            ( Nothing, Ports.deleteAccount model.id )

        Just (RenameCategory model) ->
            ( Nothing, Ports.renameCategory model.id model.name model.icon )

        Just (DeleteCategory model) ->
            ( Nothing, Ports.deleteCategory model.id )

        Nothing ->
            ( Nothing, Cmd.none )



-- VIEW


view : Shared.Model -> E.Element Shared.Msg
view shared =
    Ui.pageWithSidePanel []
        { panel =
            [ E.row
                [ E.centerX ]
                [ Ui.simpleButton []
                    { onPress = Just (Shared.ChangePage Shared.MainPage)
                    , label =
                        E.row []
                            [ Ui.backIcon []
                            , E.text "  Retour"
                            ]
                    }
                ]
            ]
        , page =
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
                                { data = Dict.toList shared.accounts
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
                                                    , onPress = Just (Shared.OpenRenameAccount (Tuple.first a))
                                                    }
                                      }
                                    , { header = E.none
                                      , width = E.shrink
                                      , view =
                                            \a ->
                                                Ui.iconButton []
                                                    { icon = Ui.deleteIcon []
                                                    , onPress = Just (Shared.OpenDeleteAccount (Tuple.first a))
                                                    }
                                      }
                                    ]
                                }
                            , Ui.simpleButton []
                                { onPress = Just (Shared.CreateAccount (newAccountName (Dict.values shared.accounts) 1))
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
                                       shared.settings
                               in
                               case o of
                                   Shared.InCalendar ->
                                       Shared.SetSettings { settings | defaultMode = Shared.InCalendar }

                                   Shared.InTabular ->
                                       Shared.SetSettings { settings | defaultMode = Shared.InTabular }
                       , label = "Affichage les opérations par:"
                       , options =
                           [ Ui.radioRowOption Shared.InCalendar (E.text "Calendrier")
                           , Ui.radioRowOption Shared.InTabular (E.text "Liste")
                           ]
                       , selected = Just shared.settings.defaultMode
                       }
                -}
                , configWarning shared
                , configSummary shared
                , configReconciliation shared
                , configCategoriesEnabled shared
                , configCategories shared
                ]
            ]
        }


accountRow shared account =
    E.row [ E.spacing 48 ]
        [ E.el [] (E.text account)
        , Ui.iconButton []
            { icon = Ui.editIcon []
            , onPress = Nothing
            }
        , Ui.iconButton []
            { icon = Ui.deleteIcon []
            , onPress = Nothing
            }
        ]


configWarning shared =
    let
        settings =
            shared.settings
    in
    Ui.configCustom []
        { label = "Avertissement solde bas:"
        , content =
            E.row [ E.spacing 12 ]
                [ Ui.iconButton [ Border.color Ui.fgDark, Border.width Ui.borderWidth ]
                    { icon = Ui.minusIcon []
                    , onPress =
                        Just (Shared.SetSettings { settings | balanceWarning = settings.balanceWarning - 10 })
                    }
                , E.el [ Ui.bigFont ]
                    (E.text (String.fromInt shared.settings.balanceWarning))
                , E.el [ Ui.normalFont ]
                    (E.text "€")
                , Ui.iconButton [ Border.color Ui.fgDark, Border.width Ui.borderWidth ]
                    { icon = Ui.plusIcon []
                    , onPress =
                        Just (Shared.SetSettings { settings | balanceWarning = settings.balanceWarning + 10 })
                    }
                ]
        }


configSummary shared =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        shared.settings
                in
                case o of
                    True ->
                        Shared.SetSettings { settings | summaryEnabled = True }

                    False ->
                        Shared.SetSettings { settings | summaryEnabled = False }
        , label = "Activer la page de bilan:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just shared.settings.summaryEnabled
        }


configReconciliation shared =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        shared.settings
                in
                case o of
                    True ->
                        Shared.SetSettings { settings | reconciliationEnabled = True }

                    False ->
                        Shared.SetSettings { settings | reconciliationEnabled = False }
        , label = "Activer la page de pointage:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just shared.settings.reconciliationEnabled
        }


configCategoriesEnabled shared =
    Ui.configRadio []
        { onChange =
            \o ->
                let
                    settings =
                        shared.settings
                in
                case o of
                    True ->
                        Shared.SetSettings { settings | categoriesEnabled = True }

                    False ->
                        Shared.SetSettings { settings | categoriesEnabled = False }
        , label = "Utiliser des catégories:"
        , options =
            [ Ui.radioRowOption True (E.text "Oui")
            , Ui.radioRowOption False (E.text "Non")
            ]
        , selected = Just shared.settings.categoriesEnabled
        }


configCategories shared =
    Ui.configCustom []
        { label =
            if shared.settings.categoriesEnabled then
                "Catégories:"

            else
                "Catégories (désactivées):"
        , content =
            E.column [ E.spacing 24 ]
                [ E.table [ E.spacing 6 ]
                    { data = Dict.toList shared.categories
                    , columns =
                        [ { header = E.none
                          , width = E.fill
                          , view = \a -> E.el [ E.centerY ] (E.text (Tuple.second a).name)
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \a ->
                                    Ui.iconButton []
                                        { icon = Ui.editIcon []
                                        , onPress = Just (Shared.OpenRenameCategory (Tuple.first a))
                                        }
                          }
                        , { header = E.none
                          , width = E.shrink
                          , view =
                                \a ->
                                    Ui.iconButton []
                                        { icon = Ui.deleteIcon []
                                        , onPress = Just (Shared.OpenDeleteCategory (Tuple.first a))
                                        }
                          }
                        ]
                    }
                , Ui.simpleButton []
                    { onPress = Just (Shared.CreateCategory "Nouvelle catégorie" "")
                    , label = E.row [] [ Ui.plusIcon [], E.text "  Ajouter" ]
                    }
                ]
        }



-- CALLBACKS


createNewAccount shared =
    Ports.createAccount (newAccountName shared.accounts 1)



-- DIALOG


viewDialog : Dialog -> E.Element Shared.Msg
viewDialog variant =
    case variant of
        RenameAccount model ->
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
                        [ Ui.onEnter Shared.SettingsConfirm
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
                                (E.text ("Renommer le compte \"" ++ model.name ++ "\":"))
                        , text = model.name
                        , onChange = \n -> Shared.SettingsChangeName n
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
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Confirmer"
                        , onPress = Just Shared.SettingsConfirm
                        }
                    ]
                ]

        DeleteCategory model ->
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
                    (E.text ("Supprimer la catégorie \"" ++ model.name ++ "\" ?"))
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
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Supprimer"
                        , onPress = Just Shared.SettingsConfirm
                        }
                    ]
                ]

        RenameCategory model ->
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
                        [ Ui.onEnter Shared.SettingsConfirm
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
                                (E.text ("Renommer la catégorie \"" ++ model.name ++ "\":"))
                        , text = model.name
                        , onChange = \n -> Shared.SettingsChangeName n
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
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Confirmer"
                        , onPress = Just Shared.SettingsConfirm
                        }
                    ]
                ]

        DeleteAccount model ->
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
                    (E.text ("Supprimer le compte \"" ++ model.name ++ "\" ?"))
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
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = E.text "Supprimer"
                        , onPress = Just Shared.SettingsConfirm
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
