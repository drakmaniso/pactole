module Dialog.Transaction exposing (view, viewDeleteTransaction)

import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Ledger
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ui
import Ui.Color as Color


view : Model -> Model.TransactionData -> E.Element Msg
view model data =
    Ui.dialog model.context
        { content =
            E.column
                [ Ui.onEnter Msg.ConfirmDialog
                , E.width E.fill
                , E.height E.fill
                , E.spacing <| model.context.em
                ]
                [ viewDate model data
                , Ui.verticalSpacer
                , viewAmount model data
                , viewDescription model data
                , viewCategories model data
                ]
        , close =
            if data.isRecurring then
                { label = E.text "Fermer"
                , icon = Ui.closeIcon
                , color = Ui.PlainButton
                , onPress = Msg.CloseDialog
                }

            else
                { label = E.text "Annuler"
                , icon = Ui.closeIcon
                , color = Ui.PlainButton
                , onPress = Msg.CloseDialog
                }
        , actions =
            if data.isRecurring then
                []

            else
                case data.id of
                    Just id ->
                        [ { label = E.text "Supprimer"
                          , icon = Ui.deleteIcon
                          , color = Ui.PlainButton
                          , onPress = Msg.OpenDialog <| Model.DeleteTransactionDialog id
                          }
                        , { label = E.text "  OK  "
                          , icon = E.text "  OK  "
                          , color = Ui.MainButton
                          , onPress = Msg.ConfirmDialog
                          }
                        ]

                    Nothing ->
                        [ { label = E.text "  OK  "
                          , icon = E.text "  OK  "
                          , color = Ui.MainButton
                          , onPress = Msg.ConfirmDialog
                          }
                        ]
        }


viewDate : Model -> Model.TransactionData -> E.Element Msg
viewDate model _ =
    E.el [ E.width E.fill, E.paddingEach { left = 0, right = 0, top = 0, bottom = 0 // 2 } ]
        (E.el [ E.centerX ] (Ui.viewDate model.context model.date))


viewAmount : Model -> Model.TransactionData -> E.Element Msg
viewAmount model data =
    let
        em =
            model.context.em

        section =
            case model.context.device.orientation of
                E.Landscape ->
                    Ui.dialogSectionRow

                E.Portrait ->
                    Ui.dialogSection

        isFuture =
            Date.compare data.date model.today == GT

        titleColor =
            if isFuture then
                Color.neutral30

            else
                Color.transactionColor data.isExpense

        titleText =
            case ( data.isRecurring, isFuture, data.isExpense ) of
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
    if data.isRecurring then
        section model.context
            titleText
            (E.el
                [ Font.bold
                , E.width (E.shrink |> E.minimum (6 * em))
                , E.alignLeft
                , Border.width 1
                , Border.color Color.transparent
                , Font.color titleColor
                , E.padding 0
                ]
                (E.text
                    ((if data.isExpense then
                        "-"

                      else
                        "+"
                     )
                        ++ Tuple.first data.amount
                        ++ " €"
                    )
                )
            )

    else
        section model.context
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
                        (if data.isExpense then
                            E.text "-"

                         else
                            E.text "+"
                        )
                    )
                , Ui.moneyInput model.context
                    { label = Input.labelHidden "Somme"
                    , color = titleColor
                    , state = data.amount
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
viewDescription model data =
    let
        section =
            case model.context.device.orientation of
                E.Landscape ->
                    Ui.dialogSectionRow

                E.Portrait ->
                    Ui.dialogSection
    in
    if data.isRecurring then
        section model.context
            "Description:"
            (E.el
                [ Border.width 1
                , Border.color Color.transparent
                , Font.color Color.neutral40
                ]
                (E.text data.description)
            )

    else
        section model.context
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
                , text = data.description
                , placeholder = Nothing
                , onChange = Msg.ForTransaction << Msg.ChangeTransactionDescription
                , spellcheck = True
                }
            )


viewCategories : Model -> Model.TransactionData -> E.Element Msg
viewCategories model data =
    if data.isRecurring || not data.isExpense || not model.settings.categoriesEnabled then
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
        Ui.dialogSection model.context
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
                                            , active = k == data.category
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
                                            , active = k == data.category
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
                                            , active = k == data.category
                                            }
                      }
                    ]
                }
            )



-- DELETE CONFIRMATION DIALOG


viewDeleteTransaction : Model -> Int -> E.Element Msg
viewDeleteTransaction model id =
    let
        transaction =
            Ledger.getTransaction id model.ledger
    in
    case transaction of
        Just t ->
            Ui.dialog model.context
                { content =
                    E.column [ E.width E.fill, E.spacing <| model.context.em ]
                        [ if Money.isExpense t.amount then
                            E.paragraph [ Font.bold, E.centerX, Font.center ] [ E.text "Supprimer la dépense?" ]

                          else
                            E.paragraph [ Font.bold, E.centerX, Font.center ] [ E.text "Supprimer l'entrée d'argent?" ]
                        , E.paragraph []
                            [ E.text "Montant: "
                            , Ui.viewMoney model.context t.amount False
                            ]
                        , E.paragraph []
                            [ E.text "Description: "
                            , E.text t.description
                            ]
                        ]
                , close =
                    { label = E.text "Annuler"
                    , icon = Ui.closeIcon
                    , color = Ui.PlainButton
                    , onPress = Msg.CloseDialog
                    }
                , actions =
                    [ { label = E.text "Supprimer"
                      , icon = E.text "Supprimer"
                      , color = Ui.DangerButton
                      , onPress = Msg.ConfirmDialog
                      }
                    ]
                }

        Nothing ->
            Ui.dialog model.context
                { content =
                    Ui.paragraph "Erreur..."
                , close =
                    { label = E.text "Fermer"
                    , icon = Ui.closeIcon
                    , color = Ui.PlainButton
                    , onPress = Msg.CloseDialog
                    }
                , actions =
                    []
                }
