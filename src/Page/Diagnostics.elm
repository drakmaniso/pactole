module Page.Diagnostics exposing (view)

import Element as E
import Element.Font as Font
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


view : Model -> E.Element Msg
view model =
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
            [ Ui.pageTitle model.context (E.text "System Diagnostics")
            , E.textColumn
                [ E.width E.fill
                , Ui.smallFont model.context
                , Font.family [ Font.monospace ]
                , E.padding <| model.context.em
                , E.spacing <| model.context.em // 2
                ]
                [ E.paragraph [] [ E.text "System info:" ]
                , if model.isStoragePersisted then
                    E.paragraph [] [ E.text "- storage is persisted" ]

                  else
                    E.paragraph [ Font.color Color.warning60 ] [ E.text "- storage is NOT persisted!" ]
                , E.paragraph [] [ E.text <| "- width = " ++ String.fromInt model.context.width ++ ", height = " ++ String.fromInt model.context.height ]
                , E.paragraph []
                    [ E.text <|
                        "- orientation = "
                            ++ (case model.context.device.orientation of
                                    E.Landscape ->
                                        "landscape"

                                    E.Portrait ->
                                        "portrait"
                               )
                    ]
                , E.paragraph []
                    [ E.text <|
                        "- device class = "
                            ++ (case model.context.device.class of
                                    E.Phone ->
                                        "phone"

                                    E.Tablet ->
                                        "tablet"

                                    E.Desktop ->
                                        "desktop"

                                    E.BigDesktop ->
                                        "big desktop"
                               )
                    ]
                , E.paragraph []
                    [ E.text <|
                        "- font sizes = "
                            ++ String.fromInt model.context.smallEm
                            ++ ", "
                            ++ String.fromInt model.context.em
                            ++ ", "
                            ++ String.fromInt model.context.bigEm
                    ]
                , Ui.verticalSpacer
                , Ui.textInput
                    { label = Ui.labelLeft "test input:", text = "", onChange = \_ -> Msg.NoOp }
                , Ui.verticalSpacer
                , errorLog model
                ]
            ]
        ]


errorLog : Model -> E.Element msg
errorLog model =
    if List.isEmpty model.errors then
        Ui.paragraph "No errors."

    else
        E.column [ E.spacing model.context.em ]
            (Ui.paragraph "Error log:\n"
                :: (model.errors |> List.map (\err -> E.paragraph [ Font.color Color.warning60 ] [ E.text err ]))
            )
