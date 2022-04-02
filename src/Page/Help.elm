module Page.Help exposing (viewContent)

import Element as E
import Model exposing (Model)
import Msg exposing (Msg)
import Ui



-- VIEW


viewContent : Model -> E.Element Msg
viewContent model =
    E.column
        -- This extra column is necessary to circumvent a
        -- scrollbar-related bug in elm-ui
        [ E.width E.fill
        , E.height E.fill
        , E.clipY
        ]
        [ E.column
            [ E.width E.fill
            , E.height E.fill
            , E.padding 3
            , E.scrollbarY
            ]
            [ Ui.pageTitle model.device (E.text "Guide d'utilisation")
            , Ui.textColumn
                [ Ui.verticalSpacer
                , Ui.paragraph
                    """
            Pactole est une application très simple de gestion de budget personel.
            """
                , Ui.paragraph
                    """
            La page principale est divisée en trois parties:
            """
                , Ui.helpImage "images/general-presentation-FR.png"
                    """
            les trois parties de la page principale: à droite, le calendrier;
            en haut à gauche, le solde du compte; et juste en dessous,
            le détail du jour sélectionné.
            """
                , Ui.verticalSpacer
                , Ui.title model.device "Pour utiliser le calendrier"
                , Ui.paragraph
                    """
            Le calendrier affiche une vue d'ensemble de vos opérations pour le mois courant.
            """
                , Ui.paragraph
                    """
            En haut, les deux boutons avec une flèche permettent de voir un autre mois.
            """
                , Ui.paragraph
                    """
            Lorsque vous appuyez sur un jour
            cela affiche la liste des opérations de ce jour dans la
            partie de gauche.
            """
                , Ui.paragraph
                    """
            C'est dans cette liste d'opérations que vous pouvez créer et
            modifier les opérations.
            """
                , Ui.verticalSpacer
                , Ui.title model.device "Pour créer une nouvelle opération"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                Appuyez sur le jour voulu dans le calendrier.
                """
                    , Ui.paragraph
                        """
                    Appuyez sur le bouton "-" si vous voulez créer une dépense. Appuyez
                    sur le bouton "+" si vous voulez créer une entrée d'argent.
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
                    Vous pouvez également entrer une description.
                    """
                    , Ui.paragraph
                        """
                    Appuyez sur le bouton "OK" pour confirmer la création de l'opération.
                    """
                    ]
                , Ui.verticalSpacer
                , Ui.title model.device "Pour supprimer une opération"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                    Appuyez sur le jour où se trouve l'opération dans le calendrier.
                    """
                    , Ui.paragraph
                        """
                    Appuyez sur la ligne correspondant à l'opération (dans la partie de gauche).
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
                , Ui.title model.device "Pour changer le montant ou la description d'une opération"
                , Ui.helpList
                    [ Ui.paragraph
                        """
                    Appuyez sur le jour où se trouve l'opération dans le calendrier.
                    """
                    , Ui.paragraph
                        """
                    Appuyez sur la ligne correspondant à l'opération (dans la partie de gauche).
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
                , Ui.title model.device "Pour changer la date d'une opération"
                , Ui.paragraph
                    """
                Pour déplacer une opération à une date différente, il suffit de supprimer
                l'opération existante et de la recréer à la nouvelle date.
                """
                , Ui.verticalSpacer
                , Ui.title model.device "Pour les fonctions avancées"
                , Ui.paragraphParts
                    [ Ui.text
                        """
                Certaines fonctionnalités supplémentaires de Pactole sont désactivées par
                défaut. Si vous voulez les utiliser, vous pouvez les activer 
                """
                    , Ui.helpMiniButton
                        { label =
                            Ui.text "dans les réglages de l'application"
                        , onPress = Msg.ChangePage Model.SettingsPage
                        }
                    , Ui.text "."
                    ]
                , Ui.verticalSpacer
                ]
            ]
        ]
