module Page.Summary exposing (viewDesktop, viewMobile)

import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


viewDesktop : Model -> E.Element Msg
viewDesktop model =
    Keyed.el
        [ E.width E.fill
        , E.height E.fill
        ]
        ( "summary"
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.spacing <| model.context.em // 4
            ]
            [ viewAccounts model
            , viewBalance model
            ]
        )


viewAccounts : Model -> E.Element Msg
viewAccounts model =
    let
        em =
            model.context.em
    in
    case model.accounts |> Dict.toList |> List.sortBy (\( _, name ) -> name) of
        [ ( _, "(sans nom)" ) ] ->
            E.el [ Ui.notSelectable, Font.center, Ui.bigFont model.context, E.centerX, E.centerY ]
                (E.text "")

        [ ( _, name ) ] ->
            E.el [ Ui.notSelectable, Font.center, Ui.bigFont model.context, E.centerX, E.centerY ]
                (E.text name)

        accounts ->
            E.column
                [ Font.center
                , E.centerX
                , E.centerY
                , E.height <| E.minimum (em * 2 + 4) <| E.shrink -- to prevent relayout when alt-tabbing
                ]
                [ E.el [ E.height E.fill ] E.none
                , Input.radioRow
                    [ E.width E.shrink
                    , Border.width 4
                    , Border.color Color.transparent
                    , Ui.focusVisibleOnly
                    , E.centerX
                    , E.centerY
                    , E.spacing 4
                    ]
                    { onChange = Msg.SelectAccount
                    , selected = Just model.account
                    , label = Input.labelHidden "Compte"
                    , options =
                        List.map
                            (\( account, name ) ->
                                radioRowOption model.context
                                    account
                                    (E.text name)
                            )
                            accounts
                    }
                , E.el [ E.height E.fill ] E.none
                ]


viewBalance : Model -> E.Element msg
viewBalance model =
    let
        em =
            model.context.em

        balance =
            Ledger.getBalance model.ledger model.account model.today

        parts =
            Money.toStringParts balance

        sign =
            if parts.sign == "+" then
                ""

            else
                "-"

        color =
            if Money.isGreaterOrEqualThan balance 0 then
                Color.neutral20

            else
                Color.warning60
    in
    E.column
        [ E.centerX
        , E.centerY
        , E.paddingXY model.context.em (model.context.em // 4)
        , Border.rounded (model.context.em // 4)
        , if Money.isGreaterOrEqualThan balance model.settings.balanceWarning then
            Border.color Color.transparent

          else
            Border.color Color.warning60
        , Border.width 4
        ]
        [ if model.context.device.orientation == E.Landscape && model.context.height > 28 * em then
            E.el
                [ Ui.smallFont model.context
                , E.centerX
                , Font.color Color.neutral50
                , Ui.notSelectable
                ]
                (E.text "Solde actuel:")

          else
            E.none
        , E.paragraph
            [ E.centerX, Font.color color, Ui.notSelectable ]
            [ E.el
                [ Ui.biggestFont model.context
                , Font.bold
                ]
                (E.text (sign ++ parts.units))
            , E.el
                [ Ui.bigFont model.context
                , Font.bold
                ]
                (E.text ("," ++ parts.cents))
            , E.el
                [ Ui.bigFont model.context
                ]
                (E.text " €")
            ]
        ]


viewMobile : Model -> E.Element Msg
viewMobile model =
    Keyed.el
        [ E.width E.fill ]
        ( "summary"
        , E.row
            [ E.width E.fill
            , E.clipX
            , E.spacing <| model.context.em // 4
            , E.padding <| model.context.em // 4
            , Background.color Color.primary95
            ]
            [ viewMobileAccounts model
            , viewMobileBalance model
            ]
        )


viewMobileAccounts : Model -> E.Element Msg
viewMobileAccounts model =
    case model.accounts |> Dict.toList |> List.sortBy (\( _, name ) -> name) of
        [ ( _, "(sans nom)" ) ] ->
            E.el
                [ Ui.notSelectable
                , Font.center
                , E.alignLeft
                , E.centerY
                , E.padding (model.context.em // 4)
                ]
                (E.text <| "")

        [ ( _, name ) ] ->
            E.el
                [ Ui.notSelectable
                , Font.center
                , E.alignLeft
                , E.centerY
                , E.padding (model.context.em // 4)
                ]
                (E.text <| name)

        accounts ->
            E.el [ Font.center, E.alignLeft, E.centerY ] <|
                Input.radioRow
                    [ E.width E.shrink
                    , E.padding (model.context.em // 4)
                    , Border.width 4
                    , Border.color Color.transparent
                    , Ui.focusVisibleOnly
                    , E.alignLeft
                    , E.centerY
                    ]
                    { onChange = Msg.SelectAccount
                    , selected = Just model.account
                    , label = Input.labelHidden "Compte"
                    , options =
                        List.map
                            (\( account, name ) ->
                                radioRowOption model.context
                                    account
                                    (E.text name)
                            )
                            accounts
                    }


viewMobileBalance : Model -> E.Element msg
viewMobileBalance model =
    let
        balance =
            Ledger.getBalance model.ledger model.account model.today

        parts =
            Money.toStringParts balance

        sign =
            if parts.sign == "+" then
                ""

            else
                "-"

        color =
            if Money.isGreaterOrEqualThan balance 0 then
                Color.neutral20

            else
                Color.warning60
    in
    E.row
        [ E.alignRight
        , E.centerY
        , E.padding (model.context.em // 4)
        , Border.rounded (model.context.em // 4)
        , if Money.isGreaterOrEqualThan balance model.settings.balanceWarning then
            Border.color Color.transparent

          else
            Border.color Color.warning60
        , Border.width 4
        , Font.color color
        , Ui.notSelectable
        ]
        [ E.paragraph
            [ Font.alignRight, E.alignRight, Font.color color, Ui.notSelectable ]
            [ E.el
                [ Ui.smallFont model.context
                , E.centerX
                , Ui.notSelectable
                ]
                (E.text "Solde: ")
            , E.el
                [ Ui.defaultFontSize model.context, Font.bold ]
                (E.text (sign ++ parts.units))
            , E.el
                [ Ui.smallFont model.context, Font.bold ]
                (E.text ("," ++ parts.cents))
            , E.el
                [ Ui.smallFont model.context ]
                (E.text " €")
            ]
        ]


radioRowOption : Ui.Context -> value -> E.Element msg -> Input.Option value msg
radioRowOption context value element =
    Input.optionWith
        value
        (\state ->
            E.el
                ([ E.centerX
                 , E.centerY
                 , E.paddingEach
                    { left = context.em // 4
                    , right = context.em // 4
                    , bottom = context.em // 8
                    , top = context.em // 8 + 4
                    }
                 , Border.widthEach { bottom = 4, top = 0, left = 0, right = 0 }
                 ]
                    ++ (case state of
                            Input.Idle ->
                                [ Font.color Color.neutral20
                                , Font.regular
                                , Border.color Color.transparent
                                , E.mouseDown [ Background.color Color.neutral80 ]
                                , E.mouseOver [ Background.color Color.neutral95 ]
                                ]

                            Input.Focused ->
                                []

                            Input.Selected ->
                                [ Font.color Color.neutral20
                                , Border.color Color.primary40
                                , Font.bold
                                ]
                       )
                )
                element
        )
