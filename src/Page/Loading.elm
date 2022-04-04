module Page.Loading exposing (viewContent, viewPanel)

import Element as E
import Element.Border as Border
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color



-- VIEW


viewPanel : Model -> E.Element Msg
viewPanel _ =
    E.none


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
            , E.scrollbarY
            , Border.widthEach { left = 2, top = 0, bottom = 0, right = 0 }
            , Border.color Color.neutral90
            ]
            [ E.column
                [ E.width E.fill
                , E.height E.fill
                , E.paddingXY 24 24
                ]
                [ Ui.textColumn model.device
                    [ Ui.paragraph "Chargement de Pactole..."
                    ]
                ]
            ]
        ]
