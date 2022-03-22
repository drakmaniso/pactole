module Page.Dialog exposing
    ( update
    , view
    )

import Browser.Dom as Dom
import Database
import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Ledger
import Log
import Model
import Money
import Msg
import Task
import Ui
import Ui.Color as Color



-- UPDATE


update : Msg.DialogMsg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.DialogNewTransaction isExpense date ->
            ( { model
                | dialog =
                    Just
                        { id = Nothing
                        , isExpense = isExpense
                        , isRecurring = False
                        , date = date
                        , amount = ""
                        , amountError = ""
                        , description = ""
                        , category = 0
                        }
              }
            , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-amount")
            )

        Msg.DialogEditTransaction id ->
            case Ledger.getTransaction id model.ledger of
                Nothing ->
                    ( model, Log.error "DialogEditTransaction: unable to get transaction" )

                Just t ->
                    ( { model
                        | dialog =
                            Just
                                { id = Just t.id
                                , isExpense = Money.isExpense t.amount
                                , isRecurring = False
                                , date = t.date
                                , amount = Money.toInput t.amount
                                , amountError = ""
                                , description = t.description
                                , category = t.category
                                }
                      }
                    , Cmd.none
                    )

        Msg.DialogShowRecurring id ->
            case Ledger.getTransaction id model.recurring of
                Nothing ->
                    ( model, Log.error "DialogShowRecurring: unable to get recurring transaction" )

                Just t ->
                    ( { model
                        | dialog =
                            Just
                                { id = Just t.id
                                , isExpense = Money.isExpense t.amount
                                , isRecurring = True
                                , date = t.date
                                , amount = Money.toInput t.amount
                                , amountError = ""
                                , description = t.description
                                , category = t.category
                                }
                      }
                    , Cmd.none
                    )

        Msg.DialogChangeAmount amount ->
            case model.dialog of
                Just dialog ->
                    ( { model
                        | dialog =
                            Just
                                { dialog
                                    | amount = amount
                                    , amountError = ""
                                }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        Msg.DialogChangeDescription string ->
            case model.dialog of
                Just dialog ->
                    ( { model
                        | dialog =
                            Just
                                { dialog
                                    | description =
                                        String.filter (\c -> c /= Char.fromCode 13 && c /= Char.fromCode 10) string
                                }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        Msg.DialogChangeCategory id ->
            case model.dialog of
                Just dialog ->
                    ( { model
                        | dialog =
                            Just
                                { dialog | category = id }
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        Msg.DialogConfirm ->
            case model.dialog of
                Just dialog ->
                    case
                        ( dialog.id
                        , Money.fromInput dialog.isExpense dialog.amount
                        , Money.validate dialog.amount
                        )
                    of
                        ( Just id, Just amount, "" ) ->
                            ( { model | dialog = Nothing }
                            , Database.replaceTransaction
                                { id = id
                                , account = model.account
                                , date = dialog.date
                                , amount = amount
                                , description = dialog.description
                                , category = dialog.category
                                , checked = False
                                }
                            )

                        ( Nothing, Just amount, "" ) ->
                            ( { model | dialog = Nothing }
                            , Database.createTransaction
                                { account = model.account
                                , date = dialog.date
                                , amount = amount
                                , description = dialog.description
                                , category = dialog.category
                                , checked = False
                                }
                            )

                        ( _, _, amountError ) ->
                            let
                                newDialog =
                                    { dialog | amountError = amountError }
                            in
                            ( { model
                                | dialog = Just newDialog
                              }
                            , Cmd.none
                            )

                _ ->
                    ( model, Log.error "impossible Confirm message" )

        Msg.DialogDelete ->
            case model.dialog of
                Just dialog ->
                    case dialog.id of
                        Just id ->
                            ( { model | dialog = Nothing }
                            , Database.deleteTransaction id
                            )

                        Nothing ->
                            ( model, Log.error "impossible Delete message" )

                Nothing ->
                    ( model, Log.error "impossible Delete message" )



-- VIEW


view : Model.Model -> E.Element Msg.Msg
view model =
    case model.dialog of
        Just dialog ->
            E.column
                [ Ui.onEnter (Msg.ForDialog <| Msg.DialogConfirm)
                , E.centerX
                , E.centerY
                , E.width (E.px 960)

                --, E.clip
                , E.scrollbarY
                , E.paddingXY 48 24
                , E.spacing 36
                , Background.color Color.white
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                , Border.rounded 6
                ]
                [ viewAmount model dialog
                , viewDescription model dialog
                , viewCategories model dialog
                , E.el [ E.height E.fill, Background.color Color.white ] E.none
                , viewButtons dialog
                ]

        Nothing ->
            E.none


viewAmount : Model.Model -> Model.Dialog -> E.Element Msg.Msg
viewAmount model dialog =
    let
        isFuture =
            Date.compare dialog.date model.today == GT

        titleColor =
            if isFuture then
                Color.neutral40

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
        Ui.section titleColor
            titleText
            (E.el
                [ Ui.bigFont
                , E.width (E.shrink |> E.minimum 220)
                , E.alignLeft
                , Border.width 1
                , Border.color Color.transparent
                , Font.color titleColor
                ]
                (E.text
                    ((if dialog.isExpense then
                        "-"

                      else
                        "+"
                     )
                        ++ dialog.amount
                        ++ " €"
                    )
                )
            )

    else
        Ui.section titleColor
            titleText
            (E.row [ E.width E.fill, E.paddingXY 24 0 ]
                [ E.el
                    [ Ui.bigFont
                    , Font.color Color.neutral40
                    , E.paddingEach { top = 12, bottom = 12, left = 0, right = 6 }
                    , E.width E.shrink
                    , E.alignLeft
                    , Border.width 1
                    , Border.color (E.rgba 0 0 0 0)
                    , Ui.notSelectable
                    ]
                    (E.el [ Font.color titleColor, Font.bold ] (E.text "-"))
                , Input.text
                    [ Ui.bigFont
                    , E.paddingXY 8 12
                    , E.width (E.shrink |> E.minimum 220)
                    , E.alignLeft
                    , Border.width 4
                    , Border.color Color.white
                    , Background.color Color.neutral95
                    , Ui.innerShadow
                    , E.focused
                        [ Border.color Color.focusColor
                        ]
                    , E.htmlAttribute <| HtmlAttr.id "dialog-amount"
                    , E.htmlAttribute <| HtmlAttr.autocomplete False
                    , Font.color titleColor
                    , Font.bold
                    ]
                    { label = Input.labelHidden "Somme"
                    , text = dialog.amount
                    , placeholder = Nothing
                    , onChange = Msg.ForDialog << Msg.DialogChangeAmount
                    }
                , E.el
                    [ Ui.bigFont
                    , Font.color Color.neutral40
                    , E.paddingEach { top = 12, bottom = 12, left = 6, right = 24 }
                    , E.width E.shrink
                    , E.alignLeft
                    , Border.width 1
                    , Border.color (E.rgba 0 0 0 0)
                    , Ui.notSelectable
                    ]
                    (E.el [ Font.color titleColor, Font.bold ] (E.text "€"))
                , if dialog.amountError /= "" then
                    Ui.warningParagraph
                        [ E.text dialog.amountError ]

                  else
                    E.el [ E.height (E.shrink |> E.minimum 48) ] E.none
                ]
            )


viewDescription : Model.Model -> Model.Dialog -> E.Element Msg.Msg
viewDescription _ dialog =
    if dialog.isRecurring then
        Ui.section Color.neutral40
            "Description:"
            (E.el
                [ Ui.bigFont
                , Border.width 1
                , Border.color Color.transparent
                , Font.color Color.neutral40
                ]
                (E.text dialog.description)
            )

    else
        Ui.section Color.neutral40
            "Description:"
            (Input.multiline
                [ Ui.bigFont
                , Border.width 4
                , Border.color Color.white
                , Background.color Color.neutral95
                , Ui.innerShadow
                , E.focused
                    [ Border.color Color.focusColor
                    ]
                , E.width E.fill
                , Font.color Color.neutral20
                ]
                { label = Input.labelHidden "Description:"
                , text = dialog.description
                , placeholder = Nothing
                , onChange = Msg.ForDialog << Msg.DialogChangeDescription
                , spellcheck = True
                }
            )


viewCategories : Model.Model -> Model.Dialog -> E.Element Msg.Msg
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
        Ui.section Color.neutral40
            "Catégorie:"
            (E.table
                [ E.width E.fill
                , E.spacing 6

                --BUGGY: , scrollbarY
                ]
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
                                            { onPress = Just (Msg.ForDialog <| Msg.DialogChangeCategory k)
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
                                            { onPress = Just (Msg.ForDialog <| Msg.DialogChangeCategory k)
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
                                            { onPress = Just (Msg.ForDialog <| Msg.DialogChangeCategory k)
                                            , icon = v.icon
                                            , label = v.name
                                            , active = k == dialog.category
                                            }
                      }
                    ]
                }
            )


viewButtons : Model.Dialog -> E.Element Msg.Msg
viewButtons dialog =
    if dialog.isRecurring then
        E.row
            [ E.width E.fill
            , E.spacing 24
            , Background.color Color.white
            ]
            [ E.el [ E.width E.fill ] E.none
            , Ui.mainButton
                { label = E.text "  OK  "
                , onPress = Just Msg.Close
                }
            ]

    else
        E.row
            [ E.width E.fill
            , E.spacing 24
            , Background.color Color.white
            ]
            [ E.el [ E.width E.fill ] E.none
            , Ui.simpleButton
                { label = E.text "Annuler", onPress = Just Msg.Close }
            , case dialog.id of
                Just _ ->
                    Ui.simpleButton
                        { label = E.text "Supprimer", onPress = Just (Msg.ForDialog <| Msg.DialogDelete) }

                Nothing ->
                    E.none
            , Ui.mainButton
                { label = E.text "  OK  "
                , onPress = Just (Msg.ForDialog <| Msg.DialogConfirm)
                }
            ]
