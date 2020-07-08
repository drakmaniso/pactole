module Page.Settings exposing
    ( Dialog
    , openRenameAccount
    , updateName
    , view
    , viewDialog
    )

import Common
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
    = RenameAccount { account : String, name : String }


openRenameAccount : String -> Dialog
openRenameAccount account =
    RenameAccount { account = account, name = account }


updateName : String -> Maybe Dialog -> ( Maybe Dialog, Cmd Msg.Msg )
updateName name variant =
    case variant of
        Just (RenameAccount model) ->
            ( Just (RenameAccount { model | name = name })
            , Cmd.none
            )

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
                            { data = common.accounts
                            , columns =
                                [ { header = none
                                  , width = fill
                                  , view = \a -> el [ centerY ] (text a)
                                  }
                                , { header = none
                                  , width = shrink
                                  , view =
                                        \a ->
                                            Ui.iconButton []
                                                { icon = Ui.editIcon []
                                                , onPress = Just (Msg.OpenRenameAccount a)
                                                }
                                  }
                                , { header = none
                                  , width = shrink
                                  , view =
                                        \a ->
                                            Ui.iconButton []
                                                { icon = Ui.deleteIcon []
                                                , onPress = Nothing
                                                }
                                  }
                                ]
                            }
                        , Ui.simpleButton []
                            { onPress = Just (Msg.CreateAccount (newAccountName common.accounts 1))
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
                    [ paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
                    , Style.bigFont
                    ]
                    (text ("Renommer \"" ++ model.account ++ "\""))
                , Input.text
                    []
                    { label =
                        Input.labelAbove
                            [ width shrink
                            , height fill
                            , Font.color Style.fgTitle
                            , Style.normalFont
                            , Font.bold
                            , paddingEach { top = 0, bottom = 0, left = 12, right = 0 }
                            , pointer
                            ]
                            (text "Nouveau nom:")
                    , text = model.name
                    , onChange = \n -> Msg.SettingsName n
                    , placeholder = Nothing
                    }
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
                    , Ui.simpleButton []
                        { label = text "Confirmer"
                        , onPress = Just (Msg.RenameAccount model.account model.name)
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
