module Page.Installation exposing (..)

import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Model exposing (Model)
import Msg exposing (Msg)
import Page.Settings as Settings
import Ui
import Ui.Color as Color


view :
    Model
    ->
        { summary : E.Element Msg
        , detail : E.Element Msg
        , main : E.Element Msg
        }
view model =
    { summary = Ui.logo model.serviceVersion
    , detail = E.none
    , main =
        E.column
            [ E.width E.fill
            , E.height E.fill
            , E.scrollbarY
            ]
            [ Ui.pageTitle (E.text "Installation")
            , E.column
                [ E.width E.fill
                , E.height E.fill
                , E.paddingXY 24 24
                , Border.widthEach { left = 2, top = 0, bottom = 0, right = 0 }
                , Border.color Color.neutral90
                ]
                [ viewInstallation model
                ]
            ]
    }


viewInstallation model =
    let
        settings =
            model.settings
    in
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
            , Ui.paragraph
                """
                Notez que vos données ne sont pas enregistrées en ligne:
                elles sont uniquement disponibles sur l'appareil que vous utilisez actuellement.
                """
            , Ui.paragraphParts
                [ Ui.text
                    """Afin que le navigateur sache que vous voulez conserver ces données, """
                , Ui.boldText
                    """
                    il est nécessaire d'ajouter cette page à vos marque-pages.
                    """
                ]
            , E.el [ E.paddingXY 36 0 ]
                (E.el
                    [ Background.color Color.focus85
                    , Border.rounded 6
                    , E.padding 12
                    ]
                    (Ui.paragraphParts
                        [ Ui.text "Important: "
                        , Ui.boldText
                            """il ne faut jamais utiliser la fonctionnalité de nettoyage des données
                    du navigateur."""
                        , Ui.text
                            """
                    Cela effacerait tout les opérations que vous avez entré dans Pactole.
                    """
                        ]
                    )
                )
            , Ui.verticalSpacer
            , Ui.title "Configuration initiale"
            , Ui.textInput
                { width = 400
                , label = Ui.labelLeft "Nom du compte:"
                , text = "Mon compte"
                , onChange = \_ -> Msg.NoOp
                }
            , Ui.textInput
                { width = 200
                , label = Ui.labelLeft "Solde initial:"
                , text = ""
                , onChange = \_ -> Msg.NoOp
                }
            , Ui.verticalSpacer
            , Settings.configLocked model
            , Ui.mainButton
                { label = E.text "Installer Pactole"
                , onPress = Just Msg.Close
                }
            , Ui.verticalSpacer
            ]
        ]
