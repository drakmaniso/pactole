module Dialog.Transaction exposing (view)

import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Model exposing (Model)
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


view : Model -> E.Element Msg
view model =
    case model.dialog of
        Just (Model.TransactionDialog dialog) ->
            E.column
                [ Ui.onEnter (Msg.ForTransaction <| Msg.ConfirmTransaction)
                , E.width E.fill
                , E.height E.fill
                , E.spacing <| model.context.em
                ]
                [ viewDate model dialog
                , viewAmount model dialog
                , viewDescription model dialog
                , viewCategories model dialog
                , viewButtons dialog
                ]

        _ ->
            E.none


viewDate : Model -> Model.TransactionData -> E.Element Msg
viewDate model _ =
    E.el [ E.width E.fill, E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 // 2 } ]
        (E.el [ E.centerX ] (Ui.viewDate model.context model.date))


viewAmount : Model -> Model.TransactionData -> E.Element Msg
viewAmount model dialog =
    let
        em =
            model.context.em

        isFuture =
            Date.compare dialog.date model.today == GT

        titleColor =
            if isFuture then
                Color.neutral30

            else
                Color.transactionColor dialog.isExpense

        titleText =
            case ( dialog.isRecurring, isFuture, dialog.isExpense ) of
                ( True, _, True ) ->
                    "Dépense mensuelle:"

                ( True, _, False ) ->
                    "Entrée d'argent mensuelle:"

                ( False, True, True ) ->
                    "Future dépense:"

                ( False, True, False ) ->
                    "Future entrée d'argent:"

                ( False, False, True ) ->
                    "Dépense:"

                ( False, False, False ) ->
                    "Entrée d'argent:"
    in
    if dialog.isRecurring then
        Ui.dialogSectionRow Color.neutral30
            titleText
            (E.el
                [ Ui.bigFont model.context
                , Font.bold
                , E.width (E.shrink |> E.minimum (6 * em))
                , E.alignLeft
                , Border.width 1
                , Border.color Color.transparent
                , Font.color titleColor
                , E.padding 0
                ]
                (E.text
                    ((if dialog.isExpense then
                        "-"

                      else
                        "+"
                     )
                        ++ Tuple.first dialog.amount
                        ++ " €"
                    )
                )
            )

    else
        Ui.dialogSectionRow Color.neutral30
            titleText
            (E.row [ E.width E.fill, E.padding 0, Font.color titleColor, Font.bold ]
                [ E.el
                    [ E.width E.shrink
                    , E.alignLeft
                    , Border.width 1
                    , Border.color (E.rgba 0 0 0 0)
                    , Ui.notSelectable
                    ]
                    (E.el []
                        (if dialog.isExpense then
                            E.text "-"

                         else
                            E.text "+"
                        )
                    )
                , Ui.moneyInput model.context
                    { label = Input.labelHidden "Somme"
                    , color = titleColor
                    , state = dialog.amount
                    , onChange = Msg.ForTransaction << Msg.ChangeTransactionAmount
                    }
                , E.el
                    [ E.width E.shrink
                    , E.alignLeft
                    , Border.width 1
                    , Border.color (E.rgba 0 0 0 0)
                    , Ui.notSelectable
                    ]
                    (E.el [ Font.color titleColor, Font.bold ] (E.text "€"))
                ]
            )


viewDescription : Model -> Model.TransactionData -> E.Element Msg
viewDescription model dialog =
    if dialog.isRecurring then
        Ui.dialogSectionRow Color.neutral30
            "Description:"
            (E.el
                [ Ui.bigFont model.context
                , Border.width 1
                , Border.color Color.transparent
                , Font.color Color.neutral40
                ]
                (E.text dialog.description)
            )

    else
        Ui.dialogSectionRow Color.neutral30
            "Description:"
            (Input.multiline
                [ Border.width 4
                , Border.color Color.white
                , Background.color Color.neutral98
                , Ui.innerShadow
                , E.focused
                    [ Border.color Color.focus85
                    ]
                , E.width E.fill
                , Font.color Color.neutral20
                ]
                { label = Input.labelHidden "Description:"
                , text = dialog.description
                , placeholder = Nothing
                , onChange = Msg.ForTransaction << Msg.ChangeTransactionDescription
                , spellcheck = True
                }
            )


viewCategories : Model -> Model.TransactionData -> E.Element Msg
viewCategories model dialog =
    if dialog.isRecurring || not dialog.isExpense || not model.settings.categoriesEnabled then
        E.none

    else
        let
            groupBy3 accum list =
                let
                    group =
                        List.take 3 list
                in
                if List.isEmpty group then
                    accum

                else
                    groupBy3 (group :: accum) (List.drop 3 list)

            categories =
                model.categories
                    |> Dict.toList
                    |> (\l ->
                            ( 0, { name = "Aucune", icon = " " } )
                                :: l
                                |> groupBy3 []
                                |> List.reverse
                       )
        in
        Ui.dialogSection Color.neutral30
            "Catégorie:"
            (E.table [ E.width E.fill ]
                { data = categories
                , columns =
                    [ { header = E.none
                      , width = E.fill
                      , view =
                            \row ->
                                case List.head row of
                                    Nothing ->
                                        E.none

                                    Just ( k, v ) ->
                                        Ui.radioButton
                                            { onPress = Just (Msg.ForTransaction <| Msg.ChangeTransactionCategory k)
                                            , icon = v.icon
                                            , label = v.name
                                            , active = k == dialog.category
                                            }
                      }
                    , { header = E.none
                      , width = E.fill
                      , view =
                            \row ->
                                case List.head (List.drop 1 row) of
                                    Nothing ->
                                        E.none

                                    Just ( k, v ) ->
                                        Ui.radioButton
                                            { onPress = Just (Msg.ForTransaction <| Msg.ChangeTransactionCategory k)
                                            , icon = v.icon
                                            , label = v.name
                                            , active = k == dialog.category
                                            }
                      }
                    , { header = E.none
                      , width = E.fill
                      , view =
                            \row ->
                                case List.head (List.drop 2 row) of
                                    Nothing ->
                                        E.none

                                    Just ( k, v ) ->
                                        Ui.radioButton
                                            { onPress = Just (Msg.ForTransaction <| Msg.ChangeTransactionCategory k)
                                            , icon = v.icon
                                            , label = v.name
                                            , active = k == dialog.category
                                            }
                      }
                    ]
                }
            )


viewButtons : Model.TransactionData -> E.Element Msg
viewButtons dialog =
    if dialog.isRecurring then
        E.row
            [ E.width E.fill
            , E.spacing 24
            , Background.color Color.white
            , E.paddingEach { left = 0, right = 0, top = 12, bottom = 0 }
            ]
            [ E.el [ E.width E.fill ] E.none
            , Ui.mainButton
                { label = E.text "  OK  "
                , onPress = Just Msg.CloseDialog
                }
            ]

    else
        E.el
            [ E.width E.fill
            , Background.color Color.white
            , E.paddingEach { left = 0, right = 0, top = 12, bottom = 0 }
            ]
            (E.row [ E.alignRight, E.spacing 24 ]
                [ Ui.simpleButton
                    { label = E.text "Annuler", onPress = Just Msg.CloseDialog }
                , case dialog.id of
                    Just _ ->
                        Ui.simpleButton
                            { label = E.text "Supprimer", onPress = Just (Msg.ForTransaction <| Msg.DeleteTransaction) }

                    Nothing ->
                        E.none
                , Ui.mainButton
                    { label = E.text "  OK  "
                    , onPress = Just (Msg.ForTransaction <| Msg.ConfirmTransaction)
                    }
                ]
            )
