module Page.Diagnostics exposing (viewContent)

import Element as E
import Element.Font as Font
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color



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
            [ Ui.pageTitle model.device (E.text "System Diagnostics")
            , E.textColumn
                [ Ui.smallFont model.device
                , Font.family [ Font.monospace ]
                , E.padding 24
                , E.spacing 12
                ]
                ([ E.paragraph [] [ E.text "System info:" ]
                 , if model.isStoragePersisted then
                    E.paragraph [] [ E.text "- storage is persisted" ]

                   else
                    E.paragraph [ Font.color Color.warning60 ] [ E.text "Storage is NOT persisted!" ]
                 , E.paragraph [] [ E.text <| "- width = " ++ String.fromInt model.device.width ++ ", height = " ++ String.fromInt model.device.height ]
                 , Ui.verticalSpacer
                 , E.paragraph [] [ E.text "Error log:" ]
                 ]
                    ++ (model.errors |> List.map (\err -> E.paragraph [] [ E.text err ]))
                )
            ]
        ]
