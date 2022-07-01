module Page.Help exposing (view)

import Element as E
import Html.Attributes
import Model exposing (Model)
import Msg exposing (Msg)
import Ui


view : Model -> E.Element Msg
view model =
    E.column
        [ E.width E.fill
        , E.height E.fill
        ]
        [ Ui.pageTitle model.context (E.text "AIDE")
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.scrollbarY
            , E.htmlAttribute <| Html.Attributes.class "scrollbox"
            ]
            [ Ui.textColumn model.context
                [ Ui.verticalSpacer
                , Ui.paragraph
                    """
                    Pactole est une application très simple pour gérer votre argent.
                    """
                , Ui.paragraph
                    """
                    Elle vous permet d'entrer des opérations bancaires: vos dépenses et vos
                    entrées d'argent.
                    """
                , Ui.paragraph
                    """
                    Le calendrier affiche une vue d'ensemble de toutes les opérations faites
                    dans le mois.
                    """
                , Ui.paragraph
                    (case model.context.device.orientation of
                        E.Landscape ->
                            """
                            À gauche, il y a le solde actuel de votre compte,
                            et la liste des opérations pour le jour choisi dans le calendrier.
                            """

                        E.Portrait ->
                            """
                            En dessous, il y a la liste des opérations pour le
                            jour choisi dans le calendrier.
                            """
                    )
                , Ui.verticalSpacer
                , Ui.title model.context "Pour utiliser le calendrier"
                , Ui.paragraph
                    """
                    Vous pouvez voir un autre mois en utilisant les deux flêches situées
                    au dessus du calendrier.
                    """
                , Ui.paragraph
                    """
                    Vous pouvez choisir un jour en appuyant dessus. Cela va afficher le détail
                    des opérations faites ce jour-là.
                    """
                , Ui.verticalSpacer
                , Ui.title model.context "Pour entrer une nouvelle opération"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                        Appuyez sur le jour voulu dans le calendrier.
                        """
                    , Ui.paragraph
                        """
                        Si c'est une dépense, appuyez sur le bouton "-".
                        Si c'est une entrée d'argent, appuyez sur le bouton "+".
                        """
                    , Ui.paragraph
                        """
                        Une boite de dialogue va s'ouvrir.
                        """
                    , Ui.paragraph
                        """
                        Entrez le montant de l'opération.
                        """
                    , Ui.paragraph
                        """
                        Entrez une description.
                        """
                    , Ui.paragraph
                        """
                        Appuyez sur le bouton "OK" pour confirmer la création de l'opération.
                        """
                    ]
                , Ui.verticalSpacer
                , Ui.title model.context "Pour supprimer une opération"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                        Dans le calendrier: appuyez sur le jour où se trouve l'opération.
                        """
                    , Ui.paragraph <|
                        case model.context.device.orientation of
                            E.Landscape ->
                                """
                                Dans la partie de gauche: appuyez sur l'opération que vous voulez supprimer.
                                """

                            E.Portrait ->
                                """
                                En dessous du calendrier: appuyez sur l'opération que vous voulez supprimer.
                                """
                    , Ui.paragraph
                        """
                        Une boite de dialogue va s'ouvrir.
                        """
                    , Ui.paragraph
                        """
                        Appuyez sur le bouton "Supprimer".
                        """
                    ]
                , Ui.verticalSpacer
                , Ui.title model.context "Pour faire des changements sur une opération"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                        Dans le calendrier: appuyez sur le jour où se trouve l'opération.
                        """
                    , Ui.paragraph <|
                        case model.context.device.orientation of
                            E.Landscape ->
                                """
                                Dans la partie de gauche: appuyez sur l'opération que vous voulez supprimer.
                                """

                            E.Portrait ->
                                """
                                En dessous du calendrier: appuyez sur l'opération que vous voulez supprimer.
                                """
                    , Ui.paragraph
                        """
                        Une boite de dialogue va s'ouvrir.
                        """
                    , Ui.paragraph
                        """
                        Changez le montant et la description de l'opération.
                        """
                    , Ui.paragraph
                        """
                        Appuyez sur le bouton "OK" pour confirmer les changements.
                        """
                    ]
                , Ui.verticalSpacer
                , Ui.title model.context "Pour changer la date d'une opération"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                        Supprimez l'opération existante.
                        """
                    , Ui.paragraph
                        """
                        Entrez une nouvelle opération à la date voulue.
                        """
                    ]
                , Ui.verticalSpacer
                , Ui.title model.context "Pour les fonctions avancées"
                , Ui.paragraphParts
                    [ Ui.text
                        """
                        Certaines fonctionnalités supplémentaires de Pactole sont désactivées par
                        défaut. Si vous voulez les utiliser, vous pouvez les activer 
                        """
                    , Ui.linkButton
                        { label =
                            Ui.text "dans les réglages de l'application"
                        , onPress = Just <| Msg.ChangePage Model.SettingsPage
                        }
                    , Ui.text "."
                    ]
                , Ui.verticalSpacer
                ]
            ]
        ]
