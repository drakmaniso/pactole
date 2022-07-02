module Page.Help exposing (view)

import Element as E
import Html.Attributes
import Model exposing (Model)
import Msg exposing (Msg)
import Ui


view : Model -> E.Element Msg
view model =
    let
        em =
            model.context.em
    in
    E.column
        [ E.width E.fill
        , E.height E.fill
        ]
        [ E.row [ E.width E.fill, E.paddingXY (em // 2) 0 ] <|
            [ E.el [ E.width <| E.minimum (3 * em) <| E.shrink ] E.none
            , Ui.pageTitle model.context (E.text "AIDE")
            , E.el [ E.width <| E.minimum (3 * em) <| E.shrink ] <| Ui.flatButton { label = Ui.settingsIcon, onPress = Just <| Msg.ChangePage Model.SettingsPage }
            ]
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
                    Pactole est une application très simple de gestion de budget.
                    Elle est destinée aux personnes pour qui les applications 
                    traditionnelles sont trop complexes.
                    """
                , Ui.verticalSpacer
                , Ui.title model.context "Comment utiliser le calendrier?"
                , Ui.paragraph
                    """
                    Le calendrier affiche une vue d'ensemble de toutes les opérations bancaires faites
                    dans le mois.
                    """
                , Ui.paragraph
                    (case model.context.device.orientation of
                        E.Landscape ->
                            """
                            Vous pouvez choisir un jour en appuyant dessus.
                            La liste des opérations de ce jour s'affiche dans la
                            partie à gauche du calendrier.
                            """

                        E.Portrait ->
                            """
                            Vous pouvez choisir un jour en appuyant dessus.
                            La liste des opérations de ce jour s'affiche en dessous
                            du calendrier.
                            """
                    )
                , Ui.paragraph
                    """
                    Vous pouvez voir le mois suivant ou le mois précédent en utilisant les flêches situées
                    au dessus du calendrier.
                    """
                , Ui.verticalSpacer
                , Ui.title model.context "Comment entrer une nouvelle opération?"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                        Dans le calendrier, appuyez sur le jour voulu.
                        """
                    , Ui.paragraph
                        """
                        Appuyez sur le bouton "-" pour créer une nouvelle dépense,
                        ou bien sur le bouton "+" pour créer une nouvelle entrée d'argent.
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
                , Ui.title model.context "Comment supprimer une opération?"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                        Dans le calendrier, appuyez sur le jour où se trouve l'opération.
                        """
                    , Ui.paragraph <|
                        case model.context.device.orientation of
                            E.Landscape ->
                                """
                                Dans la partie de gauche, appuyez sur l'opération que vous voulez supprimer.
                                """

                            E.Portrait ->
                                """
                                En dessous du calendrier, appuyez sur l'opération que vous voulez supprimer.
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
                , Ui.title model.context "Comment modifier une opération?"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                        Dans le calendrier, appuyez sur le jour où se trouve l'opération.
                        """
                    , Ui.paragraph <|
                        case model.context.device.orientation of
                            E.Landscape ->
                                """
                                Dans la partie de gauche, appuyez sur l'opération que vous voulez supprimer.
                                """

                            E.Portrait ->
                                """
                                En dessous du calendrier, appuyez sur l'opération que vous voulez supprimer.
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
                , Ui.title model.context "Comment changer la date d'une opération?"
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
                , Ui.title model.context "Fonctionnalités avancées"
                , Ui.paragraphParts
                    [ Ui.text
                        """
                        Certaines fonctionnalités supplémentaires de Pactole sont désactivées par
                        défaut. Si vous voulez les utiliser, vous pouvez les activer dans les 
                        """
                    , Ui.linkButton
                        { label =
                            E.paragraph [] [ Ui.settingsIcon, Ui.text " réglages de l'application" ]
                        , onPress = Just <| Msg.ChangePage Model.SettingsPage
                        }
                    , Ui.text "."
                    ]
                , Ui.verticalSpacer
                ]
            ]
        ]
