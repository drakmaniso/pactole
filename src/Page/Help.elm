module Page.Help exposing (view)

import Element as E
import Element.Border as Border
import Model
import Msg
import Ui
import Ui.Color as Color



-- VIEW


view :
    Model.Model
    ->
        { summary : E.Element Msg.Msg
        , detail : E.Element Msg.Msg
        , main : E.Element Msg.Msg
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
            [ Ui.pageTitle (E.text "Guide d'utilisation")
            , E.column
                [ E.width E.fill
                , E.height E.fill
                , E.paddingXY 24 24
                , Border.widthEach { left = 2, top = 0, bottom = 0, right = 0 }
                , Border.color Color.neutral80
                ]
                [ presentation model
                ]
            ]
    }


configLocked : Model.Model -> E.Element Msg.Msg
configLocked model =
    Ui.helpTextColumn
        [ Ui.configRadio
            { onChange =
                \o ->
                    let
                        settings =
                            model.settings
                    in
                    if o then
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | settingsLocked = True }

                    else
                        Msg.ForDatabase <| Msg.DbStoreSettings { settings | settingsLocked = False }
            , label = "Déverrouiller l'accès aux réglages de l'application:"
            , options =
                [ Ui.radioRowOption True (E.text "Non")
                , Ui.radioRowOption False (E.text "Oui")
                ]
            , selected = Just model.settings.settingsLocked
            }
        ]


presentation : Model.Model -> E.Element Msg.Msg
presentation model =
    let
        settings =
            model.settings
    in
    Ui.helpTextColumn
        [ Ui.helpParagraph
            [ Ui.helpText
                """
                Pactole est une application très simple de gestion de budget personel.
                """
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Ce guide explique comment se servir de l'application.
                """
            ]
        , Ui.helpSectionTitle "Présentation générale"
        , Ui.helpParagraph
            [ Ui.helpText
                """
                La page principale de Pactole est divisée en trois parties:
                """
            ]
        , Ui.helpImage "images/general-presentation-FR.png"
            """
            les trois parties de la page principale: à droite, le calendrier;
            en haut à gauche, le solde du compte; et juste en dessous,
            le détail du jour sélectionné.
            """
        , Ui.helpSectionTitle "Utiliser le calendrier"
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Le calendrier affiche une vue d'ensemble de vos opérations.
                """
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Vous pouvez sélectionner un jour en cliquant dessus. Cela va
                afficher la liste des opérations correspondantes dans la
                partie de gauche.
                """
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Pour voir un autre mois, utilisez les deux boutons avec une flèche,
                en haut du calendrier.
                """
            ]
        , Ui.helpSectionTitle "Enregistrer le solde initial"
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Lors de la première utilisation de Pactole, vous devez entrer le solde
                actuellement disponible sur votre compte.
                """
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Pour cela il suffit de créer une nouvelle opération: une entrée d'argent
                correspondant au montant disponible sur votre compte.
                """
            ]
        , Ui.helpNumberedList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    Sélectionnez la date d'aujourd'hui dans le calendrier.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Appuyez sur le bouton "+". Une boite de dialogue va s'ouvrir.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Entrez le montant disponible sur votre compte. Vous pouvez aussi
                    entrer une description, par exemple "Solde initial".
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Confirmez la création de l'opération en appuyant sur le bouton "OK".
                    """
                ]
            ]
        , Ui.helpSectionTitle "Créer une nouvelle opération"
        , Ui.helpNumberedList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    Sélectionnez le jour voulu dans le calendrier.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Appuyez sur le bouton "-" si vous voulez créer une dépense, ou bien
                    sur le bouton "+" si vous voulez créer une entrée d'argent. Une boite
                    de dialogue va s'ouvrir.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Entrez le montant de l'opération.
                    Vous pouvez également entrer une description.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Confirmez la création de l'opération en cliquant sur le bouton "OK".
                    """
                ]
            ]
        , Ui.helpSectionTitle "Supprimer une opération"
        , Ui.helpNumberedList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans le calendrier, sélectionnez le jour où se trouve l'opération
                    que vous voulez supprimer.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans la partie de gauche, cliquez sur la ligne correspondant à l'opération.
                    Une boite de dialogue va s'ouvrir.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Cliquez sur le bouton "Supprimer".
                    """
                ]
            ]
        , Ui.helpSectionTitle "Changer le montant ou la description d'une opération"
        , Ui.helpNumberedList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans le calendrier, sélectionnez le jour où se trouve l'opération que vous
                    voulez modifier.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans la partie de gauche, cliquez sur la ligne correspondant à l'opération.
                    Une boite de dialogue va s'ouvrir.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Changez le montant et la description de l'opération.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Confirmez les changements en appuyant sur le bouton "OK".
                    """
                ]
            ]
        , Ui.helpSectionTitle "Changer la date d'une opération"
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Pour déplacer une opération à une date différente, il suffit de supprimer
                l'opération existante et de la recréer à la date voulue.
                """
            ]
        , Ui.helpSectionTitle "Fonctions avancées"
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Certaines fonctionnalités supplémentaires de Pactole sont désactivées par
                défaut. Si vous voulez les utiliser, vous pouvez déverrouiller l'accès aux
                réglages de l'application, en cliquant sur ce lien: 
                """
            , Ui.helpMiniButton
                { label =
                    Ui.helpText "déverrouiller les réglages"
                , onPress = Msg.ForDatabase <| Msg.DbStoreSettings { settings | settingsLocked = False }
                }
            , Ui.helpText "."
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                """
            ]
        ]
