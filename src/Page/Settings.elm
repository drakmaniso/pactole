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
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Ports
import Shared
import Style
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


view : Shared.Model -> Element Shared.Msg
view shared =
    column
        [ width fill
        , height fill
        , Background.color Style.bgPage
        , Style.fontFamily
        , Style.normalFont
        , scrollbarY
        ]
        [ row
            [ width fill

            {- , Border.widthEach { top = 0, left = 0, bottom = 2, right = 0 }
               , Border.color Style.bgDark
            -}
            , Background.color Style.bgTitle
            , padding 12
            ]
            [ Ui.simpleButton []
                { onPress = Just Shared.ToMainPage
                , label =
                    Ui.row []
                        [ Ui.backIcon []
                        , text "  Retour"
                        ]
                }
            , el [ width fill, height fill ] none
            , Ui.pageTitle [ centerY, Font.color Style.fgWhite ]
                (text "Configuration")
            , el [ width fill, height fill ] none
            ]
        , row
            [ width fill, height fill, scrollbarY ]
            [ el [ width (fillPortion 1) ] none
            , column
                [ width (fillPortion 6)
                , height fill
                , centerX
                ]
                [ row
                    [ width fill ]
                    [ paragraph
                        [ width (fillPortion 4)
                        , paddingEach { top = 24, bottom = 24, left = 12, right = 12 }
                        ]
                        [ text "Rappel: l'application enregistre ses données uniquement sur cet ordinateur; "
                        , text "rien n'est envoyé sur internet."
                        ]
                    , el [ width (fillPortion 2) ] none
                    ]
                , Ui.configCustom []
                    { label = "Personnes utilisant l'application:"
                    , content =
                        column [ spacing 24 ]
                            [ table [ spacing 6 ]
                                { data = Dict.toList shared.accounts
                                , columns =
                                    [ { header = none
                                      , width = fill
                                      , view = \a -> el [ centerY ] (text (Tuple.second a))
                                      }
                                    , { header = none
                                      , width = shrink
                                      , view =
                                            \a ->
                                                Ui.iconButton []
                                                    { icon = Ui.editIcon []
                                                    , onPress = Just (Shared.OpenRenameAccount (Tuple.first a))
                                                    }
                                      }
                                    , { header = none
                                      , width = shrink
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
                                , label = Ui.row [] [ Ui.plusIcon [], text "  Ajouter" ]
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
                           [ Ui.radioRowOption Shared.InCalendar (text "Calendrier")
                           , Ui.radioRowOption Shared.InTabular (text "Liste")
                           ]
                       , selected = Just shared.settings.defaultMode
                       }
                -}
                , configSummary shared
                , configReconciliation shared
                , configCategoriesEnabled shared
                , if shared.settings.categoriesEnabled then
                    configCategories shared

                  else
                    el [] none
                ]
            , el [ width (fillPortion 1) ] none
            ]
        ]


accountRow shared account =
    row [ spacing 48 ]
        [ el [] (text account)
        , Ui.iconButton []
            { icon = Ui.editIcon []
            , onPress = Nothing
            }
        , Ui.iconButton []
            { icon = Ui.deleteIcon []
            , onPress = Nothing
            }
        ]


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
            [ Ui.radioRowOption True (text "Oui")
            , Ui.radioRowOption False (text "Non")
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
            [ Ui.radioRowOption True (text "Oui")
            , Ui.radioRowOption False (text "Non")
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
            [ Ui.radioRowOption True (text "Oui")
            , Ui.radioRowOption False (text "Non")
            ]
        , selected = Just shared.settings.categoriesEnabled
        }


configCategories shared =
    Ui.configCustom []
        { label = "Catégories utilisées:"
        , content =
            column [ spacing 24 ]
                [ table [ spacing 6 ]
                    { data = Dict.toList shared.categories
                    , columns =
                        [ { header = none
                          , width = fill
                          , view = \a -> el [ centerY ] (text (Tuple.second a).name)
                          }
                        , { header = none
                          , width = shrink
                          , view =
                                \a ->
                                    Ui.iconButton []
                                        { icon = Ui.editIcon []
                                        , onPress = Just (Shared.OpenRenameCategory (Tuple.first a))
                                        }
                          }
                        , { header = none
                          , width = shrink
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
                    , label = Ui.row [] [ Ui.plusIcon [], text "  Ajouter" ]
                    }
                ]
        }



-- CALLBACKS


createNewAccount shared =
    Ports.createAccount (newAccountName shared.accounts 1)



-- DIALOG


viewDialog : Dialog -> Element Shared.Msg
viewDialog variant =
    case variant of
        RenameAccount model ->
            column
                [ centerX
                , centerY
                , width (px 800)
                , height shrink
                , paddingXY 0 0
                , spacing 0
                , scrollbarY
                , Background.color Style.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = rgba 0 0 0 0.75 }
                ]
                [ el
                    [ paddingEach { top = 24, bottom = 24, right = 48, left = 48 } ]
                    (Input.text
                        [ Ui.onEnter Shared.SettingsConfirm
                        , Style.bigFont
                        ]
                        { label =
                            Input.labelAbove
                                [ width shrink
                                , Font.color Style.fgTitle
                                , Style.normalFont
                                , Font.bold
                                , paddingEach { top = 12, bottom = 0, left = 12, right = 0 }
                                , pointer
                                ]
                                (text ("Renommer le compte \"" ++ model.name ++ "\":"))
                        , text = model.name
                        , onChange = \n -> Shared.SettingsChangeName n
                        , placeholder = Nothing
                        }
                    )
                , Ui.row
                    [ width fill
                    , spacing 24
                    , paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ alignRight ]
                        { label = text "Annuler"
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = text "Confirmer"
                        , onPress = Just Shared.SettingsConfirm
                        }
                    ]
                ]

        DeleteCategory model ->
            column
                [ centerX
                , centerY
                , width (px 800)
                , height shrink
                , paddingXY 0 0
                , spacing 0
                , scrollbarY
                , Background.color Style.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = rgba 0 0 0 0.75 }
                ]
                [ el
                    [ paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
                    , Style.bigFont
                    ]
                    (text ("Supprimer la catégorie \"" ++ model.name ++ "\" ?"))
                , paragraph
                    [ paddingEach { top = 24, bottom = 24, right = 96, left = 96 }
                    ]
                    [ text "(les opérations associées à cette catégorie ne seront pas affectées)"
                    ]
                , Ui.row
                    [ width fill
                    , spacing 24
                    , paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ alignRight ]
                        { label = text "Annuler"
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = text "Supprimer"
                        , onPress = Just Shared.SettingsConfirm
                        }
                    ]
                ]

        RenameCategory model ->
            column
                [ centerX
                , centerY
                , width (px 800)
                , height shrink
                , paddingXY 0 0
                , spacing 0
                , scrollbarY
                , Background.color Style.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = rgba 0 0 0 0.75 }
                ]
                [ el
                    [ paddingEach { top = 24, bottom = 24, right = 48, left = 48 } ]
                    (Input.text
                        [ Ui.onEnter Shared.SettingsConfirm
                        , Style.bigFont
                        ]
                        { label =
                            Input.labelAbove
                                [ width shrink
                                , Font.color Style.fgTitle
                                , Style.normalFont
                                , Font.bold
                                , paddingEach { top = 12, bottom = 0, left = 12, right = 0 }
                                , pointer
                                ]
                                (text ("Renommer la catégorie \"" ++ model.name ++ "\":"))
                        , text = model.name
                        , onChange = \n -> Shared.SettingsChangeName n
                        , placeholder = Nothing
                        }
                    )
                , Ui.row
                    [ width fill
                    , spacing 24
                    , paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ alignRight ]
                        { label = text "Annuler"
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = text "Confirmer"
                        , onPress = Just Shared.SettingsConfirm
                        }
                    ]
                ]

        DeleteAccount model ->
            column
                [ centerX
                , centerY
                , width (px 800)
                , height shrink
                , paddingXY 0 0
                , spacing 0
                , scrollbarY
                , Background.color Style.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = rgba 0 0 0 0.75 }
                ]
                [ el
                    [ paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
                    , Style.bigFont
                    ]
                    (text ("Supprimer le compte \"" ++ model.name ++ "\" ?"))
                , Ui.warningParagraph
                    [ paddingEach { top = 24, bottom = 24, right = 96, left = 96 }
                    ]
                    [ text "  Note: toutes les opérations associées à ce compte seront définitivement supprimées."
                    ]
                , Ui.row
                    [ width fill
                    , spacing 24
                    , paddingEach { top = 64, bottom = 24, right = 64, left = 64 }
                    ]
                    [ Ui.simpleButton
                        [ alignRight ]
                        { label = text "Annuler"
                        , onPress = Just Shared.Close
                        }
                    , Ui.mainButton []
                        { label = text "Supprimer"
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
