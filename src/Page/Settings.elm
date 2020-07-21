module Page.Settings exposing
    ( Dialog
    , msgChangeName
    , msgConfirm
    , openDeleteAccount
    , openRenameAccount
    , view
    , viewDialog
    )

import Common
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes
import Msg
import Ports
import Style
import Ui



-- MODEL


type Dialog
    = RenameAccount { account : Int, name : String }
    | DeleteAccount { account : Int, name : String }


openRenameAccount : Int -> String -> Dialog
openRenameAccount id name =
    RenameAccount { account = id, name = name }


openDeleteAccount : Int -> String -> Dialog
openDeleteAccount id name =
    DeleteAccount { account = id, name = name }


msgChangeName : String -> Maybe Dialog -> ( Maybe Dialog, Cmd Msg.Msg )
msgChangeName name variant =
    case variant of
        Just (RenameAccount model) ->
            ( Just (RenameAccount { model | name = name })
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
            ( Nothing, Ports.renameAccount model.account model.name )

        Just (DeleteAccount model) ->
            ( Nothing, Ports.deleteAccount model.account )

        Nothing ->
            ( Nothing, Cmd.none )



-- VIEW


view : Common.Model -> Element Msg.Msg
view common =
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
                            { data = Dict.toList common.accounts
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
                            { onPress = Just (Msg.CreateAccount (newAccountName (Dict.values common.accounts) 1))
                            , label = text "Nouveau compte"
                            }
                        ]
                }
            , Ui.configRadio []
                { onChange =
                    \o ->
                        case o of
                            Common.InCalendar ->
                                Msg.ToCalendar

                            Common.InTabular ->
                                Msg.ToTabular
                , label = "Mode d'affichage des opérations:"
                , options =
                    [ Input.option Common.InCalendar (text "Calendrier")
                    , Input.option Common.InTabular (text "Liste")
                    ]
                , selected = Just common.mode
                }
            ]
        }


accountRow common account =
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


createNewAccount common =
    Ports.createAccount (newAccountName common.accounts 1)



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
