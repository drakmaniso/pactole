module Page.Settings exposing (view)

import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Font as Font
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
        [ E.width E.fill
        , E.height E.fill
        , E.padding 3
        ]
        [ Ui.pageTitle model.context (E.text "Configuration")
        , Ui.textColumn model.context
            [ Ui.verticalSpacer
            , configBackup model
            , configAccounts model
            , configOptional model
            , configRecurring model
            , configAppearance model
            , Ui.verticalSpacer
            , Ui.verticalSpacer
            , secretDiagnosticsButton model
            ]
        ]


configBackup : Model -> E.Element Msg
configBackup model =
    E.column
        [ E.width E.fill
        , E.spacing 24
        ]
        [ Ui.title model.context "Données de l'application"
        , Ui.paragraph
            """
            Les données de Pactole ne sont pas enregistrées en ligne.
            Elles sont disponibles uniquement sur l'appareil que vous êtes en train d'utiliser.
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
                    Cela effacerait toutes les opérations que vous avez entrées dans Pactole.
                    """
                ]
            ]
        , Ui.paragraph
            """
            Si vous voulez transférer vos données sur un nouvel appareil, vous pouvez
            faire une copie de sauvegarde, transférer le fichier et le récupérer sur le nouvel appareil.
            """
        , Ui.roundButton model.context
            { onPress = Msg.OpenDialog <| Model.ExportDialog
            , color = Ui.PlainButton
            , label = E.row [ E.spacing 12 ] [ Ui.saveIcon, E.text "Faire une copie de sauvegarde" ]
            }
        , Ui.roundButton model.context
            { onPress = Msg.RequestImportFile
            , color = Ui.PlainButton
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
        [ Ui.title model.context "Configuration des comptes"
        , Ui.paragraph "Liste des comptes:"
        , E.column [ E.padding 6, E.spacing 6, E.width <| E.minimum 100 <| E.fill ]
            (model.accounts
                |> Dict.toList
                |> List.sortBy (\( _, name ) -> name)
                |> List.map
                    (\( id, name ) ->
                        Ui.flatButton
                            { label = E.text name
                            , onPress = Just <| Msg.OpenDialog <| Model.AccountDialog { id = Just id, name = name }
                            }
                    )
            )
        , Ui.roundButton model.context
            { onPress = Msg.OpenDialog <| Model.AccountDialog { id = Nothing, name = "" }
            , color = Ui.PlainButton
            , label = E.row [] [ Ui.plusIcon, E.text "  Nouveau compte" ]
            }
        , Ui.verticalSpacer
        , Ui.paragraph "Avertissement lorsque le solde passe en dessous de:"
        , E.row [ E.spacing 12 ]
            [ Ui.flatButton
                { label = Ui.minusIcon
                , onPress =
                    Just (Msg.ForDatabase <| Msg.StoreSettings { settings | balanceWarning = settings.balanceWarning - 10 })
                }
            , E.el []
                (E.text (String.fromInt model.settings.balanceWarning))
            , E.el []
                (E.text "€")
            , Ui.flatButton
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
        [ Ui.title model.context "Fonctions optionnelles"
        , Ui.toggleSwitch model.context
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.StoreSettings { settings | summaryEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | summaryEnabled = False }
            , label = "page de bilan"
            , checked = model.settings.summaryEnabled
            }
        , Ui.toggleSwitch model.context
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.StoreSettings { settings | reconciliationEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | reconciliationEnabled = False }
            , label = "page de pointage"
            , checked = model.settings.reconciliationEnabled
            }
        , Ui.toggleSwitch model.context
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.StoreSettings { settings | categoriesEnabled = True }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | categoriesEnabled = False }
            , label = "catégories pour les dépenses"
            , checked = model.settings.categoriesEnabled
            }
        , Ui.paragraph "Liste des catégories:"
        , E.column [ E.padding 6, E.spacing 6, E.width <| E.minimum 100 <| E.fill ]
            (model.categories
                |> Dict.toList
                |> List.sortBy (\( _, { name } ) -> name)
                |> List.map
                    (\( id, { name, icon } ) ->
                        Ui.flatButton
                            { label =
                                E.row []
                                    [ Ui.viewIcon icon
                                    , E.text <| " " ++ name
                                    ]
                            , onPress = Just <| Msg.OpenDialog <| Model.CategoryDialog { id = Just id, name = name, icon = icon }
                            }
                    )
            )
        , Ui.roundButton model.context
            { onPress = Msg.OpenDialog <| Model.CategoryDialog { id = Nothing, name = "", icon = " " }
            , color = Ui.PlainButton
            , label = E.row [] [ Ui.plusIcon, E.text "  Nouvelle catégorie" ]
            }
        , Ui.verticalSpacer
        ]


configRecurring : Model -> E.Element Msg
configRecurring model =
    E.column [ E.spacing 24 ]
        [ Ui.title model.context "Opération mensuelles"
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
                            { onPress =
                                Just <|
                                    Msg.OpenDialog <|
                                        Model.RecurringDialog
                                            { id = Just t.id
                                            , account = t.account
                                            , isExpense = Money.isExpense t.amount
                                            , amount = Money.toInput t.amount
                                            , description = t.description
                                            , category = t.category
                                            , dueDate = String.fromInt <| Date.getDay t.date
                                            }
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
        , Ui.roundButton model.context
            { onPress =
                Msg.OpenDialog <|
                    Model.RecurringDialog
                        { id = Nothing
                        , account = model.account
                        , isExpense = False
                        , amount = "0"
                        , description = ""
                        , category = 0
                        , dueDate = "1"
                        }
            , color = Ui.PlainButton
            , label = E.row [] [ Ui.plusIcon, E.text "  Nouvelle opération mensuelle" ]
            }
        , Ui.verticalSpacer
        ]


configAppearance : Model -> E.Element Msg
configAppearance model =
    let
        settings =
            model.settings

        fontSize =
            model.settings.fontSize

        sanitize size =
            if size < -128 then
                -128

            else if size > 128 then
                128

            else
                size

        detected =
            let
                autoDevice =
                    E.classifyDevice model.context
            in
            case autoDevice.class of
                E.Phone ->
                    "téléphone"

                E.Tablet ->
                    "tablette"

                E.Desktop ->
                    "ordinateur"

                E.BigDesktop ->
                    "ordinateur"
    in
    E.column
        [ E.width E.fill, E.spacing 24 ]
        [ Ui.title model.context "Apparence"
        , Ui.toggleSwitch model.context
            { onChange =
                \o ->
                    if o then
                        Msg.ForDatabase <| Msg.StoreSettings { settings | animationDisabled = False }

                    else
                        Msg.ForDatabase <| Msg.StoreSettings { settings | animationDisabled = True }
            , label = "animations"
            , checked = not model.settings.animationDisabled
            }
        , E.wrappedRow [ E.spacing 12 ]
            [ Ui.paragraph "Taille du texte:"
            , Ui.flatButton
                { label = Ui.minusIcon
                , onPress =
                    Just <|
                        Msg.ForDatabase <|
                            Msg.StoreSettings
                                { settings | fontSize = sanitize <| fontSize - 1 }
                }
            , E.el [] <|
                E.text (String.fromInt <| model.context.em)
            , E.el [] <| E.text "px"
            , Ui.flatButton
                { label = Ui.plusIcon
                , onPress =
                    Just <|
                        Msg.ForDatabase <|
                            Msg.StoreSettings
                                { settings | fontSize = sanitize <| fontSize + 1 }
                }
            , if fontSize /= 0 then
                Ui.flatButton
                    { label = E.el [ Ui.iconFont ] <| E.text "\u{F0E2}"
                    , onPress =
                        Just <|
                            Msg.ForDatabase <|
                                Msg.StoreSettings
                                    { settings | fontSize = 0 }
                    }

              else
                E.none
            ]
        , Ui.roundButton model.context
            { label = E.text "Changer la police de caractères"
            , color = Ui.PlainButton
            , onPress = Msg.OpenDialog <| Model.FontDialog model.settings.font
            }
        , Ui.verticalSpacer
        , Ui.radio model.context
            { label = Ui.labelAbove model.context "Type d'appareil:"
            , onChange =
                \deviceClass ->
                    Msg.ForDatabase <|
                        Msg.StoreSettings <|
                            { settings | deviceClass = deviceClass }
            , selected = Just model.settings.deviceClass
            , options =
                [ Ui.radioOption model.context Ui.AutoClass (E.paragraph [] [ E.text <| "Détection automatique (" ++ detected ++ ")" ])
                , Ui.radioOption model.context Ui.Phone (E.text "Téléphone")
                , Ui.radioOption model.context Ui.Tablet (E.text "Tablette")
                , Ui.radioOption model.context Ui.Desktop (E.text "Ordinateur")
                ]
            }
        , Ui.verticalSpacer
        ]


secretDiagnosticsButton : Model -> E.Element Msg
secretDiagnosticsButton model =
    E.el
        [ E.centerX, Ui.smallFont model.context ]
    <|
        Ui.linkButton
            { label = E.text ("version " ++ model.serviceVersion)
            , onPress = Just (Msg.ChangePage Model.DiagnosticsPage)
            }
