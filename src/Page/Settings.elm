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
import Msg
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


msgChangeName : String -> Maybe Dialog -> ( Maybe Dialog, Cmd Msg.Msg )
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


view : Shared.Model -> Element Msg.Msg
view shared =
    Ui.pageWithSidePanel []
        { panel =
            [ Ui.simpleButton []
                { onPress = Just Msg.ToMainPage
                , label =
                    Ui.row []
                        [ Ui.backIcon []
                        , text "  Retour"
                        ]
                }
            , el [ width fill, height fill ] none
            ]
        , page =
            [ Ui.pageTitle []
                (text "Configuration")
            , Ui.configCustom []
                { label = "Comptes enregistrés sur cet ordinateur:"
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
                                                , onPress = Just (Msg.OpenRenameAccount (Tuple.first a))
                                                }
                                  }
                                , { header = none
                                  , width = shrink
                                  , view =
                                        \a ->
                                            Ui.iconButton []
                                                { icon = Ui.deleteIcon []
                                                , onPress = Just (Msg.OpenDeleteAccount (Tuple.first a))
                                                }
                                  }
                                ]
                            }
                        , Ui.simpleButton []
                            { onPress = Just (Msg.CreateAccount (newAccountName (Dict.values shared.accounts) 1))
                            , label = text "Nouveau compte"
                            }
                        ]
                }
            , Ui.configCustom []
                { label = "Catégories:"
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
                                                , onPress = Just (Msg.OpenRenameCategory (Tuple.first a))
                                                }
                                  }
                                , { header = none
                                  , width = shrink
                                  , view =
                                        \a ->
                                            Ui.iconButton []
                                                { icon = Ui.deleteIcon []
                                                , onPress = Just (Msg.OpenDeleteCategory (Tuple.first a))
                                                }
                                  }
                                ]
                            }
                        , Ui.simpleButton []
                            { onPress = Just (Msg.CreateCategory "Nouvelle catégorie" "")
                            , label = text "Nouvelle catégorie"
                            }
                        ]
                }
            , Ui.configRadio []
                { onChange =
                    \o ->
                        case o of
                            Shared.InCalendar ->
                                Msg.ToCalendar

                            Shared.InTabular ->
                                Msg.ToTabular
                , label = "Mode d'affichage des opérations:"
                , options =
                    [ Input.option Shared.InCalendar (text "Calendrier")
                    , Input.option Shared.InTabular (text "Liste")
                    ]
                , selected = Just shared.mode
                }
            ]
        }


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



-- CALLBACKS


createNewAccount shared =
    Ports.createAccount (newAccountName shared.accounts 1)



-- DIALOG


viewDialog : Dialog -> Element Msg.Msg
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
                        [ Ui.onEnter Msg.SettingsConfirm
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
                        , onChange = \n -> Msg.SettingsChangeName n
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
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = text "Confirmer"
                        , onPress = Just Msg.SettingsConfirm
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
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = text "Supprimer"
                        , onPress = Just Msg.SettingsConfirm
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
                        [ Ui.onEnter Msg.SettingsConfirm
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
                        , onChange = \n -> Msg.SettingsChangeName n
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
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = text "Confirmer"
                        , onPress = Just Msg.SettingsConfirm
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
                        , onPress = Just Msg.Close
                        }
                    , Ui.mainButton []
                        { label = text "Supprimer"
                        , onPress = Just Msg.SettingsConfirm
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
