module Page.Settings exposing (configLocked, view)

import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Font as Font
import Element.Keyed as Keyed
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import String
import Ui
import Ui.Color as Color


view : Model -> E.Element Msg
view model =
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
            { onPress = Just (Msg.ForSettings <| Msg.Export)
            , label = E.row [ E.spacing 12 ] [ Ui.saveIcon, E.text "Faire une copie de sauvegarde" ]
            }
        , Ui.simpleButton
            { onPress = Just (Msg.ForSettings <| Msg.Import)
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
                            , onPress = Just <| Msg.ForSettings <| Msg.EditAccount (Just id)
                            }
                    )
            )
        , Ui.simpleButton
            { onPress = Just <| Msg.ForSettings <| Msg.EditAccount Nothing
            , label = E.row [] [ Ui.plusIcon, E.text "  Nouveau compte" ]
            }
        , Ui.verticalSpacer
        , Ui.paragraph "Avertissement lorsque le solde passe en dessous de:"
        , E.row [ E.spacing 12 ]
            [ Ui.simpleButton
                { label = Ui.minusIcon
                , onPress =
                    Just (Msg.ForDatabase <| Msg.StoreSettings { settings | balanceWarning = settings.balanceWarning - 10 })
                }
            , E.el []
                (E.text (String.fromInt model.settings.balanceWarning))
            , E.el []
                (E.text "€")
            , Ui.simpleButton
                { label = Ui.plusIcon
                , onPress =
                    Just (Msg.ForDatabase <| Msg.StoreSettings { settings | balanceWarning = settings.balanceWarning + 10 })
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
                        Msg.ForDatabase <| Msg.StoreSettings { settings | summaryEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | summaryEnabled = False }
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
                        Msg.ForDatabase <| Msg.StoreSettings { settings | reconciliationEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | reconciliationEnabled = False }
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
                        Msg.ForDatabase <| Msg.StoreSettings { settings | categoriesEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | categoriesEnabled = False }
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
                            , onPress = Just <| Msg.ForSettings <| Msg.EditCategory (Just id)
                            }
                    )
            )
        , Ui.simpleButton
            { onPress = Just <| Msg.ForSettings <| Msg.EditCategory Nothing
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
                            { onPress = Just <| (Msg.ForSettings <| Msg.EditRecurring (Just t.id))
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
            { onPress = Just (Msg.ForSettings <| Msg.EditRecurring Nothing)
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
                        Msg.ForDatabase <| Msg.StoreSettings { settings | settingsLocked = True }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | settingsLocked = False }
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
    let
        settings =
            model.settings

        fontSize =
            model.device.fontSize

        sanitize size =
            if size < 6 then
                6

            else if size > 128 then
                128

            else
                size
    in
    E.column
        [ E.width E.fill, E.spacing 24 ]
        [ Ui.title model.device "Apparence"
        , E.column [ E.spacing 12 ]
            [ Ui.paragraph "Taille du texte:"
            , E.row [ E.spacing 12 ]
                [ Ui.simpleButton
                    { label = Ui.minusIcon
                    , onPress =
                        Just (Msg.ForDatabase <| Msg.StoreSettings { settings | fontSize = sanitize <| fontSize - 1 })
                    }
                , E.el []
                    (E.text (String.fromInt fontSize))
                , Ui.simpleButton
                    { label = Ui.plusIcon
                    , onPress =
                        Just (Msg.ForDatabase <| Msg.StoreSettings { settings | fontSize = sanitize <| fontSize + 1 })
                    }
                , Ui.simpleButton
                    { label = E.text "Taille par défaut"
                    , onPress =
                        Just <| Msg.ForDatabase <| Msg.StoreSettings { settings | fontSize = 0 }
                    }
                ]
            ]
        , Ui.simpleButton
            { label = E.text "Changer la police de caractères"
            , onPress = Just <| Msg.ForSettings <| Msg.EditFont
            }
        , Ui.verticalSpacer
        ]
