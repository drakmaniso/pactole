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
import Ledger
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)
import Ports
import Task
import Ui
import Ui.Color as Color



-- UPDATE


update : Msg.DialogMsg -> Model -> ( Model, Cmd Msg )
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
                        , amount = ( "", Nothing )
                        , description = ""
                        , category = 0
                        }
              }
            , Cmd.batch
                [ Ports.openDialog ()
                , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-amount")
                ]
            )

        Msg.DialogEditTransaction id ->
            case Ledger.getTransaction id model.ledger of
                Nothing ->
                    Log.error "DialogEditTransaction: unable to get transaction" ( model, Cmd.none )

                Just t ->
                    ( { model
                        | dialog =
                            Just
                                { id = Just t.id
                                , isExpense = Money.isExpense t.amount
                                , isRecurring = False
                                , date = t.date
                                , amount = ( Money.toInput t.amount, Nothing )
                                , description = t.description
                                , category = t.category
                                }
                      }
                    , Ports.openDialog ()
                    )

        Msg.DialogShowRecurring id ->
            case Ledger.getTransaction id model.recurring of
                Nothing ->
                    Log.error "DialogShowRecurring: unable to get recurring transaction" ( model, Cmd.none )

                Just t ->
                    ( { model
                        | dialog =
                            Just
                                { id = Just t.id
                                , isExpense = Money.isExpense t.amount
                                , isRecurring = True
                                , date = t.date
                                , amount = ( Money.toInput t.amount, Nothing )
                                , description = t.description
                                , category = t.category
                                }
                      }
                    , Ports.openDialog ()
                    )

        Msg.DialogChangeAmount amount ->
            case model.dialog of
                Just dialog ->
                    ( { model
                        | dialog = Just { dialog | amount = ( amount, Nothing ) }
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
                        , Money.fromInput dialog.isExpense (Tuple.first dialog.amount)
                        )
                    of
                        ( Just id, Ok amount ) ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.replaceTransaction
                                    { id = id
                                    , account = model.account
                                    , date = dialog.date
                                    , amount = amount
                                    , description = dialog.description
                                    , category = dialog.category
                                    , checked = False
                                    }
                                , Ports.closeDialog ()
                                ]
                            )

                        ( Nothing, Ok amount ) ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch
                                [ Database.createTransaction
                                    { account = model.account
                                    , date = dialog.date
                                    , amount = amount
                                    , description = dialog.description
                                    , category = dialog.category
                                    , checked = False
                                    }
                                , Ports.closeDialog ()
                                ]
                            )

                        ( _, Err amountError ) ->
                            let
                                newDialog =
                                    { dialog | amount = ( Tuple.first dialog.amount, Just amountError ) }
                            in
                            ( { model
                                | dialog = Just newDialog
                              }
                            , Cmd.none
                            )

                _ ->
                    Log.error "impossible Confirm message" ( model, Cmd.none )

        Msg.DialogDelete ->
            case model.dialog of
                Just dialog ->
                    case dialog.id of
                        Just id ->
                            ( { model | dialog = Nothing }
                            , Cmd.batch [ Database.deleteTransaction id, Ports.closeDialog () ]
                            )

                        Nothing ->
                            Log.error "impossible Delete message" ( model, Cmd.none )

                Nothing ->
                    Log.error "impossible Delete message" ( model, Cmd.none )



-- VIEW


view : Model -> E.Element Msg
view model =
    case model.dialog of
        Just dialog ->
            E.column
                [ Ui.onEnter (Msg.ForDialog <| Msg.DialogConfirm)
                , E.width E.fill
                , E.height E.fill
                , E.spacing 36
                ]
                [ viewDate model dialog
                , viewAmount model dialog
                , viewDescription model dialog
                , viewCategories model dialog
                , viewButtons dialog
                ]

        Nothing ->
            E.none


viewDate : Model -> Model.Dialog -> E.Element Msg
viewDate model _ =
    E.el [ E.width E.fill, E.paddingEach { left = 0, right = 0, top = 0, bottom = 12 } ]
        (E.el [ E.centerX ] (Ui.viewDate model.device model.date))


viewAmount : Model -> Model.Dialog -> E.Element Msg
viewAmount model dialog =
    let
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
                [ Ui.bigFont model.device
                , Font.bold
                , E.width (E.shrink |> E.minimum 220)
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
                    [ E.paddingEach { top = 12, bottom = 12, left = 0, right = 0 }
                    , E.width E.shrink
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
                , Ui.moneyInput model.device
                    { label = Input.labelHidden "Somme"
                    , color = titleColor
                    , state = dialog.amount
                    , onChange = Msg.ForDialog << Msg.DialogChangeAmount
                    }
                , E.el
                    [ E.paddingEach { top = 12, bottom = 12, left = 6, right = 24 }
                    , E.width E.shrink
                    , E.alignLeft
                    , Border.width 1
                    , Border.color (E.rgba 0 0 0 0)
                    , Ui.notSelectable
                    ]
                    (E.el [ Font.color titleColor, Font.bold ] (E.text "€"))
                ]
            )


viewDescription : Model -> Model.Dialog -> E.Element Msg
viewDescription model dialog =
    if dialog.isRecurring then
        Ui.dialogSectionRow Color.neutral30
            "Description:"
            (E.el
                [ Ui.bigFont model.device
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
                , onChange = Msg.ForDialog << Msg.DialogChangeDescription
                , spellcheck = True
                }
            )


viewCategories : Model -> Model.Dialog -> E.Element Msg
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


viewButtons : Model.Dialog -> E.Element Msg
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
                , onPress = Just Msg.Close
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
            )
