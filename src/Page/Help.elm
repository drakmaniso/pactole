module Page.Help exposing (view)

import Element as E
import Element.Border as Border
import Element.Font as Font
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
                , configLocked model
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
presentation _ =
    Ui.helpTextColumn
        [ Ui.helpParagraph
            [ Ui.helpText
                """
                Pactole est une application très simple de gestion de budget personel. Elle est
                destinée aux personnes pour qui les applications traditionnelles sont trop
                complexes.
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
        , Ui.helpList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    à droite: le calendrier;
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    en haut à gauche: le solde du compte;
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                en dessous du solde: le détail du jour sélectionné dans le calendrier.
                """
                ]
            ]
        , Ui.helpImage "images/icon-512x512.png" "les trois parties de la page principale"
        , Ui.helpSectionTitle "Enregistrer le solde initial"
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Lors de la première utilisation de pactole, vous devez entrer le solde
                actuellement disponible sur votre compte.
                """
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Pour cela il suffit d'ajouter une nouvelle entrée d'argent correspondant
                à ce montant. Vous pouvez la créer à la date d'aujourd'hui, et y mettre
                une description, par exemple "Solde initial".
                """
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                Pour savoir comment ajouter une nouvelle entrée d'argent, lisez la section suivante.
                """
            ]
        , Ui.helpSectionTitle "Enregistrer une nouvelle opération"
        , Ui.helpNumberedList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans le calendrier, sélectionnez le jour où vous voulez enregistrer une
                    opération. Si le mois affiché n'est pas le bon, utilisez les deux boutons en
                    haut du calendrier pour changer le mois.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans la partie de gauche, tout en bas, cliquez sur le bouton "-" si vous
                    voulez enregistrer une dépense, ou bien sur le bouton "+" si vous voulez
                    enregistrer une entrée d'argent.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans la fenêtre de dialogue qui s'ouvre, entrez le montant de l'opération.
                    Vous pouvez également entrer une description.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Enfin, confirmez l'ajout de l'opération en cliquent sur le bouton "OK".
                    """
                ]
            ]
        , Ui.helpSectionTitle "Supprimer une opération"
        , Ui.helpNumberedList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans le calendrier, sélectionnez le jour où se trouve l'opération que vous
                    voulez supprimer.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans la partie de gauche, cliquez sur la ligne correspondant à l'opération.
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
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Dans la fenêtre de dialogue qui s'ouvre, vous pouvez changer le montant et la
                    description.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Lorsque vous avez fini, confirmez les changements en cliquant sur le bouton
                    "OK".
                    """
                ]
            ]
        , Ui.helpSectionTitle "Changer la date d'une opération"
        , Ui.helpNumberedList
            [ Ui.helpListItem
                [ Ui.helpText
                    """
                    Enregistrer une nouvelle opération à la date voulue.
                    """
                ]
            , Ui.helpListItem
                [ Ui.helpText
                    """
                    Supprimer l'ancienne opération.
                    """
                ]
            ]
        , Ui.helpParagraph
            [ Ui.helpText
                """
                """
            ]
        ]
