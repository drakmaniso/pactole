module Page.Welcome exposing (view)

import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Keyed as Keyed
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


view : Model -> Model.WelcomeData -> E.Element Msg
view model installation =
    Keyed.el [ E.width E.fill, E.height E.fill, E.scrollbarY ]
        ( "Installation"
        , E.column
            [ E.width E.fill
            , E.height E.fill
            ]
            [ E.column
                [ E.width E.fill
                , E.height E.fill
                , E.padding (model.context.em // 2)
                , E.scrollbarY
                , Ui.scrollboxShadows
                ]
                [ viewInstallation model installation
                ]
            ]
        )


viewInstallation : Model -> Model.WelcomeData -> E.Element Msg
viewInstallation model installation =
    E.row
        [ E.width E.fill
        , E.height E.fill
        ]
        [ Ui.textColumn model.context
            [ titleBanner model
            , E.row [ E.width E.fill, E.spacing 12 ]
                [ E.el
                    [ E.width (E.px 12)
                    , E.height E.fill
                    , Background.color Color.focus85
                    ]
                    E.none
                , Ui.paragraphParts
                    [ Ui.text
                        """
                        Important: vos données ne seront
                        enregistrées que sur cet appareil.
                        """
                    ]
                ]
            , Ui.paragraphParts
                [ Ui.boldText
                    """
                        Aucune donnée personnelle n'est envoyée sur internet.
                        """
                ]
            , Ui.toggleSwitch model.context
                { onChange =
                    \o ->
                        if o then
                            Msg.ForWelcome <| Msg.SetWantSimplified True

                        else
                            Msg.ForWelcome <| Msg.SetWantSimplified False
                , label = "Interface simplifiée"
                , checked = installation.wantSimplified
                }
            , Ui.paragraphParts
                [ Ui.smallText model.context
                    """
                    Note: si vous choisissez l'interface simplifiée, vous pouvez
                    accéder aux réglages en passant par la page d'aide, et réactiver
                    les fonctionnalités voulues.
                    """
                ]
            , E.row [ E.width E.fill ]
                [ E.el [ E.width E.fill ] E.none
                , Ui.roundButton model.context
                    { label = E.text "Commencer"
                    , color = Ui.MainButton
                    , onPress = Msg.ProceedWithInstall |> Msg.ForWelcome
                    }
                ]
            ]
        ]


titleBanner : Model -> E.Element Msg
titleBanner model =
    E.row
        [ E.width E.fill
        , Font.color Color.primary40
        , E.spacing 24
        ]
        [ E.image [ E.alignLeft, E.centerY, E.height <| E.px 64, E.width <| E.px 64 ]
            { src = "images/logo-512x512.png"
            , description = "Pactole Logo"
            }
        , E.column
            [ E.alignLeft
            , E.centerY
            ]
            [ E.el
                [ Ui.biggestFont model.context
                , Font.bold
                , E.paddingEach { bottom = 4, top = 0, left = 0, right = 0 }
                ]
              <|
                E.text "Pactole"
            , E.el
                [ Ui.smallFont model.context
                , Font.color Color.primary50
                , Border.widthEach { top = 4, bottom = 0, left = 0, right = 0 }
                , Border.color Color.primary70
                , E.paddingEach { top = 4, bottom = 0, left = 0, right = 0 }
                ]
              <|
                E.text "gestion de budget"
            ]
        ]
