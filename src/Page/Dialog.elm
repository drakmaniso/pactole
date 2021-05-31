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
                                , amountError = Money.validate (Money.toInput t.amount)
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
                                , amountError = Money.validate (Money.toInput t.amount)
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
                                    , amountError = Money.validate amount
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
                    case ( dialog.id, Money.fromInput dialog.isExpense dialog.amount ) of
                        ( Just id, Just amount ) ->
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

                        ( Nothing, Just amount ) ->
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

                        ( _, Nothing ) ->
                            ( model, Cmd.none )

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
                [ E.centerX
                , E.centerY
                , E.width (E.px 960)

                --, E.clip
                , E.scrollbarY
                , E.paddingXY 0 0
                , E.spacing 0
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                ]
                [ viewTitle model dialog
                , E.column
                    [ -- E.scrollbarY
                      E.width E.fill
                    ]
                    [ viewAmount dialog
                    , viewDescription dialog
                    , viewCategories model dialog
                    , E.el [ E.height E.fill, Background.color Ui.bgWhite ] E.none
                    ]
                , viewButtons dialog
                ]

        Nothing ->
            E.none


viewTitle : Model.Model -> Model.Dialog -> E.Element msg
viewTitle model dialog =
    let
        isFuture =
            Date.compare dialog.date model.today == GT

        bgTitle =
            if isFuture then
                Ui.bgDark

            else
                Ui.bgTransaction dialog.isExpense

        text =
            case ( dialog.isRecurring, isFuture, dialog.isExpense ) of
                ( True, _, True ) ->
                    "Dépense mensuelle"

                ( True, _, False ) ->
                    "Entrée d'argent mensuelle"

                ( False, True, True ) ->
                    "Future dépense"

                ( False, True, False ) ->
                    "Future entrée d'argent"

                ( False, False, True ) ->
                    "Dépense"

                ( False, False, False ) ->
                    "Entrée d'argent"
    in
    E.row
        [ E.alignLeft
        , E.width E.fill
        , E.paddingEach { top = 24, bottom = 24, right = 24, left = 24 }
        , E.spacing 12
        , Background.color bgTitle
        , Ui.notSelectable
        ]
        [ E.el [ E.width (E.px 48) ] E.none
        , E.el
            [ E.width E.fill, Font.center, Ui.bigFont, Font.bold, Font.color Ui.bgWhite ]
            (E.text text)
        ]


viewAmount : Model.Dialog -> E.Element Msg.Msg
viewAmount dialog =
    if dialog.isRecurring then
        Ui.titledRow "Somme:"
            []
            [ E.el
                [ Ui.bigFont
                , E.width (E.shrink |> E.minimum 220)
                , E.alignLeft
                , Border.width 1
                , Border.color Ui.transparent
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
            ]

    else
        Ui.titledRow "Somme:"
            []
            [ E.el
                [ Ui.bigFont
                , Font.color Ui.fgBlack
                , E.paddingEach { top = 12, bottom = 12, left = 0, right = 6 }
                , E.width E.shrink
                , E.alignLeft
                , Border.width 1
                , Border.color (E.rgba 0 0 0 0)
                , Ui.notSelectable
                ]
                (E.text
                    (if dialog.isExpense then
                        "-"

                     else
                        "+"
                    )
                )
            , Input.text
                [ Ui.onEnter (Msg.ForDialog <| Msg.DialogConfirm)
                , Ui.bigFont
                , E.paddingXY 8 12
                , E.width (E.shrink |> E.minimum 220)
                , E.alignLeft
                , Border.width 4
                , Border.color Ui.bgWhite
                , Background.color Ui.bgEvenRow
                , Ui.innerShadow
                , E.focused
                    [ Border.color Ui.fgFocus
                    ]
                , E.htmlAttribute <| HtmlAttr.id "dialog-amount"
                , E.htmlAttribute <| HtmlAttr.autocomplete False
                ]
                { label = Input.labelHidden "Somme"
                , text = dialog.amount
                , placeholder = Nothing
                , onChange = Msg.ForDialog << Msg.DialogChangeAmount
                }
            , E.el
                [ Ui.bigFont
                , Font.color Ui.fgBlack
                , E.paddingEach { top = 12, bottom = 12, left = 6, right = 24 }
                , E.width E.shrink
                , E.alignLeft
                , Border.width 1
                , Border.color (E.rgba 0 0 0 0)
                , Ui.notSelectable
                ]
                (E.text "€")
            , if dialog.amountError /= "" then
                Ui.warningParagraph
                    [ E.width E.fill, E.height (E.shrink |> E.minimum 48) ]
                    [ E.text dialog.amountError ]

              else
                E.el [ E.height (E.shrink |> E.minimum 48) ] E.none
            ]


viewDescription : Model.Dialog -> E.Element Msg.Msg
viewDescription dialog =
    if dialog.isRecurring then
        Ui.titledRow "Description:"
            []
            [ E.el
                [ Ui.bigFont
                , Border.width 1
                , Border.color Ui.transparent
                ]
                (E.text dialog.description)
            ]

    else
        Ui.titledRow "Description:"
            []
            [ Input.multiline
                [ Ui.onEnter (Msg.ForDialog <| Msg.DialogConfirm)
                , Ui.bigFont
                , Border.width 4
                , Border.color Ui.bgWhite
                , Background.color Ui.bgEvenRow
                , Ui.innerShadow
                , E.focused
                    [ Border.color Ui.fgFocus
                    ]
                , E.width E.fill
                ]
                { label = Input.labelHidden "Description:"
                , text = dialog.description
                , placeholder = Nothing
                , onChange = Msg.ForDialog << Msg.DialogChangeDescription
                , spellcheck = True
                }
            ]


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
                            ( 0, { name = "Aucune", icon = "" } )
                                :: l
                                |> groupBy3 []
                                |> List.reverse
                       )
        in
        Ui.titledRow "Catégorie:"
            []
            [ E.table
                [ E.width E.fill
                , E.spacing 12
                , E.paddingEach { top = 0, bottom = 0, left = 0, right = 0 }

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
                                        Ui.radioButton []
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
                                        Ui.radioButton []
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
                                        Ui.radioButton []
                                            { onPress = Just (Msg.ForDialog <| Msg.DialogChangeCategory k)
                                            , icon = v.icon
                                            , label = v.name
                                            , active = k == dialog.category
                                            }
                      }
                    ]
                }
            ]


viewButtons : Model.Dialog -> E.Element Msg.Msg
viewButtons dialog =
    if dialog.isRecurring then
        E.row
            [ E.width E.fill
            , E.spacing 24
            , E.paddingEach { top = 64, bottom = 24, left = 64, right = 64 }
            , Background.color Ui.bgWhite
            ]
            [ Ui.mainButton [ E.alignRight, E.width E.shrink ]
                { label = E.text "OK"
                , onPress = Just Msg.Close
                }
            ]

    else
        E.row
            [ E.width E.fill
            , E.spacing 24
            , E.paddingEach { top = 64, bottom = 24, left = 64, right = 64 }
            , Background.color Ui.bgWhite
            ]
            [ Ui.simpleButton
                [ E.alignRight ]
                { label = E.text "Annuler", onPress = Just Msg.Close }
            , case dialog.id of
                Just _ ->
                    Ui.simpleButton
                        []
                        { label = E.text "Supprimer", onPress = Just (Msg.ForDialog <| Msg.DialogDelete) }

                Nothing ->
                    E.none
            , Ui.mainButton [ E.width E.shrink ]
                { label = E.text "OK"
                , onPress = Just (Msg.ForDialog <| Msg.DialogConfirm)
                }
            ]
