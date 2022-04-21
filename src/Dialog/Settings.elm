module Dialog.Settings exposing
    ( viewAccountDialog
    , viewCategoryDialog
    , viewDeleteAccountDialog
    , viewDeleteCategoryDialog
    , viewExportDialog
    , viewFontDialog
    , viewImportDialog
    , viewRecurringDialog
    , viewUserErrorDialog
    )

import Database
import Dict
import Element as E
import Element.Font as Font
import Model exposing (Model)
import Msg exposing (Msg)
import Ui


viewAccountDialog : Model -> Model.AccountData -> E.Element Msg
viewAccountDialog model data =
    Ui.dialog model.context
        { key = "account dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.onEnter Msg.ConfirmDialog ]
                    (Ui.textInput
                        { label = Ui.labelLeft model.context "Nom du compte:"
                        , text = data.name
                        , onChange = \n -> Msg.ForSettings <| Msg.ChangeSettingsName n
                        }
                    )
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            case data.id of
                Just accountId ->
                    [ { label = E.text "Supprimer"
                      , icon = Ui.deleteIcon
                      , color = Ui.PlainButton
                      , onPress = Msg.OpenDialog <| Model.DeleteAccountDialog accountId
                      }
                    , { label = E.text "  OK  "
                      , icon = E.text "  OK  "
                      , color = Ui.MainButton
                      , onPress = Msg.ConfirmDialog
                      }
                    ]

                Nothing ->
                    [ { label = E.text "  OK  "
                      , icon = E.text "  OK  "
                      , color = Ui.MainButton
                      , onPress = Msg.ConfirmDialog
                      }
                    ]
        }


viewDeleteAccountDialog : Model -> Int -> E.Element Msg
viewDeleteAccountDialog model id =
    let
        name =
            Model.accountName id model
    in
    Ui.dialog model.context
        { key = "delete account dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.paragraph
                    [ Ui.bigFont model.context
                    ]
                    [ E.text ("Supprimer le compte \"" ++ name ++ "\" ?") ]
                , E.el []
                    (Ui.warningParagraph
                        [ E.el [ Font.bold ] (E.text " Toutes les opérations de ce compte ")
                        , E.el [ Font.bold ] (E.text "vont être définitivement supprimées!")
                        ]
                    )
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            [ { label = E.text "Supprimer"
              , icon = E.text "Supprimer"
              , color = Ui.DangerButton
              , onPress = Msg.ConfirmDialog
              }
            ]
        }


viewCategoryDialog : Model -> Model.CategoryData -> E.Element Msg
viewCategoryDialog model submodel =
    Ui.dialog model.context
        { key = "category dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el [ Ui.onEnter Msg.ConfirmDialog ]
                    (Ui.textInput
                        { label = Ui.labelLeft model.context "Catégorie:"
                        , text = submodel.name
                        , onChange = \n -> Msg.ForSettings <| Msg.ChangeSettingsName n
                        }
                    )
                , E.el []
                    (E.wrappedRow
                        [ E.spacing 6 ]
                        (List.map
                            (\icon ->
                                Ui.radioButton model.context
                                    { onPress = Just (Msg.ForSettings <| Msg.ChangeSettingsIcon icon)
                                    , icon = icon
                                    , label = ""
                                    , active = submodel.icon == icon
                                    }
                            )
                            iconChoice
                        )
                    )
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            case submodel.id of
                Just categoryId ->
                    [ { label = E.text "Supprimer"
                      , icon = Ui.deleteIcon
                      , color = Ui.PlainButton
                      , onPress = Msg.OpenDialog <| Model.DeleteCategoryDialog categoryId
                      }
                    , { label = E.text "  OK  "
                      , icon = E.text "  OK  "
                      , color = Ui.MainButton
                      , onPress = Msg.ConfirmDialog
                      }
                    ]

                Nothing ->
                    [ { label = E.text "  OK  "
                      , icon = E.text "  OK  "
                      , color = Ui.MainButton
                      , onPress = Msg.ConfirmDialog
                      }
                    ]
        }


viewDeleteCategoryDialog : Model -> Int -> E.Element Msg
viewDeleteCategoryDialog model id =
    let
        { name } =
            Model.category id model
    in
    Ui.dialog model.context
        { key = "deleta category dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.paragraph
                    [ Ui.bigFont model.context
                    , Font.bold
                    ]
                    [ E.text ("Supprimer la catégorie \"" ++ name ++ "\" ?") ]
                , Ui.paragraph
                    """Les opérations déjà associées à cette catégorie passeront 
                            dans la catégorie "Aucune"
                            """
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            [ { label = E.text "Supprimer"
              , icon = E.text "Supprimer"
              , color = Ui.DangerButton
              , onPress = Msg.ConfirmDialog
              }
            ]
        }


viewRecurringDialog : Model -> Model.RecurringData -> E.Element Msg
viewRecurringDialog model submodel =
    Ui.dialog model.context
        { key = "recurring dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                , Ui.onEnter Msg.ConfirmDialog
                ]
                [ Ui.textInput
                    { label = Ui.labelLeft model.context "Jour du mois: "
                    , text = submodel.dueDate
                    , onChange = \n -> Msg.ForSettings <| Msg.ChangeSettingsDueDate n
                    }
                , E.row [ E.spacingXY 24 0 ]
                    (E.el [] (E.text "Compte: ")
                        :: List.map
                            (\( k, v ) ->
                                Ui.radioButton model.context
                                    { onPress = Just (Msg.ForSettings <| Msg.ChangeSettingsAccount k)
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
                        [ Ui.radioButton model.context
                            { onPress = Just (Msg.ForSettings <| Msg.ChangeSettingsIsExpense False)
                            , icon = "" --"\u{F067}"
                            , label = "Entrée d'argent"
                            , active = not submodel.isExpense
                            }
                        , Ui.radioButton model.context
                            { onPress = Just (Msg.ForSettings <| Msg.ChangeSettingsIsExpense True)
                            , icon = "" --"\u{F068}"
                            , label = "Dépense"
                            , active = submodel.isExpense
                            }
                        ]
                    ]
                , Ui.textInput
                    { label = Ui.labelLeft model.context "Montant:"
                    , text = submodel.amount
                    , onChange = \n -> Msg.ForSettings <| Msg.ChangeSettingsAmount n
                    }
                , Ui.textInput
                    { label = Ui.labelLeft model.context "Description:"
                    , text = submodel.description
                    , onChange = \n -> Msg.ForSettings <| Msg.ChangeSettingsName n
                    }
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            case submodel.id of
                Just recurringId ->
                    [ { label = E.text "Supprimer"
                      , icon = Ui.deleteIcon
                      , color = Ui.DangerButton
                      , onPress = Msg.ForSettings <| Msg.DeleteRecurring recurringId
                      }
                    , { label = E.text "  OK  "
                      , icon = E.text "  OK  "
                      , color = Ui.MainButton
                      , onPress = Msg.ConfirmDialog
                      }
                    ]

                Nothing ->
                    [ { label = E.text "  OK  "
                      , icon = E.text "  OK  "
                      , color = Ui.MainButton
                      , onPress = Msg.ConfirmDialog
                      }
                    ]
        }


viewImportDialog : Model -> E.Element Msg
viewImportDialog model =
    Ui.dialog model.context
        { key = "import dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.paragraph
                    [ Ui.bigFont model.context
                    , Font.bold
                    ]
                    [ E.text "Remplacer toutes les données?" ]
                , E.el []
                    (Ui.warningParagraph
                        [ E.el [ Font.bold ] (E.text "Toutes les opérations et les réglages vont être ")
                        , E.el [ Font.bold ] (E.text "définitivement supprimés!")
                        , E.text " Ils seront remplacés par le contenu du fichier sélectionné."
                        ]
                    )
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            [ { label = E.text "Tout Remplacer"
              , icon = E.text "Tout Remplacer"
              , color = Ui.DangerButton
              , onPress = Msg.ConfirmDialog
              }
            ]
        }


viewExportDialog : Model -> E.Element Msg
viewExportDialog model =
    Ui.dialog model.context
        { key = "export dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.paragraph
                    [ Ui.bigFont model.context
                    , Font.bold
                    ]
                    [ E.text "Sauvegarder les données?" ]
                , E.paragraph
                    []
                    [ E.text "Toutes les données de Pactole vont être enregistrées dans le dans le fichier suivant:"
                    ]
                , E.row
                    [ Ui.bigFont model.context
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
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            [ { label = E.text "Sauvegarder"
              , icon = E.text "Sauvegarder"
              , color = Ui.MainButton
              , onPress = Msg.ConfirmDialog
              }
            ]
        }


viewUserErrorDialog : Model -> String -> E.Element Msg
viewUserErrorDialog model errorMsg =
    Ui.dialog model.context
        { key = "user error dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ E.el
                    [ Ui.bigFont model.context
                    , Font.bold
                    ]
                    (E.text "Erreur")
                , E.el []
                    (Ui.warningParagraph
                        [ E.text errorMsg
                        ]
                    )
                ]
        , close =
            { label = E.text "  OK  "
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.ConfirmDialog
            }
        , actions = []
        }


viewFontDialog : Model -> String -> E.Element Msg
viewFontDialog model fontName =
    Ui.dialog model.context
        { key = "font dialog"
        , content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                , Ui.onEnter Msg.ConfirmDialog
                ]
                [ E.wrappedRow [ E.spacing 12 ]
                    [ Ui.textInput
                        { label = Ui.labelLeft model.context "Police de caractère:"
                        , text = fontName
                        , onChange = \n -> Msg.ForSettings <| Msg.ChangeSettingsName n
                        }
                    , Ui.roundButton model.context
                        { label = Ui.text "Réinitialiser"
                        , color = Ui.PlainButton
                        , onPress = Msg.ForSettings <| Msg.ChangeSettingsName "Andika New Basic"
                        }
                    ]
                , Ui.paragraph
                    """
                            Exemple de polices faciles à lire: "Verdana", "Comic Sans MS", "Andika", "OpenDyslexic".
                            """
                , Ui.paragraph
                    """
                            Notez que la police doit d'abord être installée sur l'appareil avant de
                            pouvoir être utilisée dans l'application.
                            """
                ]
        , close =
            { label = E.text "Annuler"
            , icon = Ui.closeIcon
            , color = Ui.PlainButton
            , onPress = Msg.CloseDialog
            }
        , actions =
            [ { label = E.text "  OK  "
              , icon = E.text "  OK  "
              , color = Ui.MainButton
              , onPress = Msg.ConfirmDialog
              }
            ]
        }



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
