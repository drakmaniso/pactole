module Page.Installation exposing (update, viewContent, viewPanel)

import Database
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Keyed as Keyed
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Page.Settings as Settings
import Ui
import Ui.Color as Color



-- UPDATE


update : Msg.InstallMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.page of
        Model.InstallationPage installation ->
            case msg of
                Msg.InstallProceed ->
                    case Money.fromInput False (Tuple.first installation.initialBalance) of
                        Ok initialBalance ->
                            ( { model | page = Model.MainPage }
                            , Database.proceedWithInstallation
                                { firstAccount = installation.firstAccount
                                , initialBalance = initialBalance
                                , date = model.today
                                }
                            )

                        Err error ->
                            ( { model
                                | page =
                                    Model.InstallationPage
                                        { installation
                                            | initialBalance = ( Tuple.first installation.initialBalance, Just error )
                                        }
                              }
                            , Cmd.none
                            )

                Msg.InstallChangeName newName ->
                    ( { model | page = Model.InstallationPage { installation | firstAccount = newName } }
                    , Cmd.none
                    )

                Msg.InstallChangeBalance newBalance ->
                    ( { model | page = Model.InstallationPage { installation | initialBalance = ( newBalance, Nothing ) } }
                    , Cmd.none
                    )

                Msg.InstallImport ->
                    ( model, Database.importDatabase )

        _ ->
            ( model, Cmd.none )
                |> Log.error "what?"



-- VIEW


viewPanel : Model -> Model.InstallationData -> E.Element Msg
viewPanel model _ =
    E.column [ E.width E.fill, E.height E.fill ]
        [ Ui.logo model.serviceVersion
        , E.el [ E.height E.fill ] E.none
        ]


viewContent : Model -> Model.InstallationData -> E.Element Msg
viewContent model installation =
    Keyed.el [ E.width E.fill, E.height E.fill, E.scrollbarY ]
        ( "Installation"
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.scrollbarY
            , Border.widthEach { left = 2, top = 0, bottom = 0, right = 0 }
            , Border.color Color.neutral90
            ]
            [ E.column
                [ E.width E.fill
                , E.height E.fill
                , E.paddingXY 24 24
                ]
                [ viewInstallation model installation
                ]
            ]
        )


viewInstallation : Model -> Model.InstallationData -> E.Element Msg
viewInstallation model installation =
    E.row
        [ E.width E.fill
        , E.height E.fill
        , Background.color Color.white
        , Ui.fontFamily
        , Ui.normalFont
        , Font.color Color.neutral30
        ]
        [ Ui.textColumn
            [ Ui.paragraph
                """
                Pactole est une application très simple de gestion de budget personnel. Elle est
                destinée aux personnes pour qui les applications traditionnelles sont trop
                complexes.
                """
            , Ui.verticalSpacer
            , Ui.title "Installation"
            , Ui.paragraph
                """
                Pactole est une application qui fonctionne dans le navigateur. 
                Ce n'est pas un site web: la page reste accessible même sans connexion internet.
                """
            , Ui.paragraphParts
                [ Ui.text
                    """Afin que le navigateur sache que vous voulez conserver les données de l'application, """
                , Ui.boldText
                    """
                    il est nécessaire d'ajouter cette page à vos marque-pages. 
                    """
                ]
            , Ui.paragraph
                """
                Si vous utilisez Firefox, le navigateur vous demandera l'autorisation de "conserver les
                données dans le stockage persistant": répondre par l'affirmative    .
                """
            , Ui.paragraph
                """
                Si vous utilisez Chrome, Edge ou Safari, vous
                pouvez ajouter l'application à votre écran d'accueil pour un accès plus rapide.
                """
            , Ui.paragraph
                """
                Notez que vos données ne sont pas enregistrées en ligne:
                elles sont uniquement disponibles sur l'appareil que vous utilisez actuellement.
                """
            , E.row [ E.width E.fill, E.spacing 12 ]
                [ E.el
                    [ E.width (E.px 12)
                    , E.height E.fill
                    , Background.color Color.focus85
                    ]
                    E.none
                , Ui.paragraphParts
                    [ Ui.text "Important: "
                    , Ui.boldText
                        """il ne faut jamais utiliser la fonctionnalité de nettoyage des données
                    du navigateur."""
                    , Ui.text
                        """
                    Cela effacerait tout les opérations que vous avez entré dans Pactole.
                    """
                    ]
                ]
            , Ui.verticalSpacer
            , Ui.title "Configuration initiale"
            , Ui.textInput
                { width = 400
                , label = Ui.labelLeft "Nom du compte:"
                , text = installation.firstAccount
                , onChange = \txt -> Msg.InstallChangeName txt |> Msg.ForInstallation
                }
            , Ui.moneyInput
                { label = Ui.labelLeft "Solde initial:"
                , color = Color.neutral20
                , state = installation.initialBalance
                , onChange = Msg.ForInstallation << Msg.InstallChangeBalance
                }
            , Ui.verticalSpacer
            , Settings.configLocked model
            , E.wrappedRow [ E.spacing 36 ]
                [ Ui.mainButton
                    { label = E.text "Installer Pactole"
                    , onPress = Just (Msg.InstallProceed |> Msg.ForInstallation)
                    }
                , Ui.simpleButton
                    { label = E.text "Récupérer une sauvegarde"
                    , onPress = Just (Msg.InstallImport |> Msg.ForInstallation)
                    }
                ]
            , Ui.verticalSpacer
            ]
        ]
