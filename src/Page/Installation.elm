module Page.Installation exposing (..)

import Element as E
import Element.Background as Background
import Element.Font as Font
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


view : Model -> E.Element Msg
view _ =
    E.row
        [ E.width E.fill
        , E.height E.fill
        , E.clipX
        , E.clipY
        , Background.color Color.white
        , Ui.fontFamily
        , Ui.normalFont
        , Font.color Color.neutral30
        ]
        [ Ui.textColumn
            [ Ui.title "Pactole"
            , Ui.paragraph
                """
                Pactole est une application très simple de gestion de budget personnel. Elle est
                destinée aux personnes pour qui les applications traditionnelles sont trop
                complexes.
                """
            , Ui.spacer
            , Ui.title "Installation"
            , Ui.paragraph
                """
                Pactole n'est pas un site web: c'est une application qui fonctionne dans le 
                navigateur. Cette page va rester accessible même sans connexion internet.
                """
            , Ui.paragraph
                """
                Notez que vos données ne seront pas enregistrées
                en ligne! Elles seront uniquement sur l'appareil que vous utilisez
                actuellement.
                """
            , Ui.paragraphParts
                [ Ui.boldText
                    """Important: il ne faut jamais demander au navigateur de "nettoyer les données"."""
                , Ui.text
                    """
                    Cela effacerait tout les opérations que vous avez entré dans Pactole.
                    """
                ]
            , Ui.spacer
            , Ui.simpleButton
                { label = E.text "Installer Pactole"
                , onPress = Just Msg.Close
                }
            ]
        ]
