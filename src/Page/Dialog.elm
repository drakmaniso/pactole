module Page.Dialog exposing
    ( update
    , view
    )

import Browser.Dom as Dom
import Database
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
                    ( model, Log.error "msgEditDialog: unable to get transaction" )

                Just t ->
                    ( { model
                        | dialog =
                            Just
                                { id = Just t.id
                                , isExpense = Money.isExpense t.amount
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
                , E.height E.shrink
                , E.paddingXY 0 0
                , E.spacing 0
                , E.scrollbarY
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = E.rgba 0 0 0 0.75 }
                ]
                [ titleRow dialog
                , amountRow dialog
                , descriptionRow dialog
                , if dialog.isExpense && model.settings.categoriesEnabled then
                    categoryRow model dialog

                  else
                    E.none
                , E.el [ E.height E.fill, Background.color Ui.bgWhite ] E.none
                , buttonsRow dialog
                ]

        Nothing ->
            E.none


titleRow : Model.Dialog -> E.Element msg
titleRow dialog =
    E.row
        [ E.alignLeft
        , E.width E.fill
        , E.paddingEach { top = 24, bottom = 24, right = 24, left = 24 }
        , E.spacing 12
        , Background.color (Ui.bgTransaction dialog.isExpense)
        ]
        [ E.el [ E.width (E.px 48) ] E.none
        , E.el
            [ E.width E.fill, Font.center, Ui.bigFont, Font.bold, Font.color Ui.bgWhite ]
            (E.text
                (if dialog.isExpense then
                    "Dépense"

                 else
                    "Entrée d'argent"
                )
            )
        ]


amountRow : Model.Dialog -> E.Element Msg.Msg
amountRow dialog =
    E.row
        [ E.alignLeft
        , E.centerY
        , E.width E.fill
        , E.paddingEach { top = 48, bottom = 24, right = 64, left = 64 }
        , E.spacing 12
        , Background.color Ui.bgWhite
        , E.centerY
        ]
        [ Input.text
            [ Ui.onEnter (Msg.ForDialog <| Msg.DialogConfirm)
            , Ui.bigFont
            , E.paddingXY 8 12
            , E.width (E.shrink |> E.minimum 220)
            , E.alignLeft
            , Border.width 1
            , Border.color Ui.bgDark
            , E.focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , size = 4
                    , blur = 0
                    , color = Ui.fgFocus
                    }
                ]
            , E.htmlAttribute <| HtmlAttr.id "dialog-amount"
            ]
            { label =
                Input.labelAbove
                    [ E.width E.shrink
                    , E.alignLeft
                    , E.height E.fill
                    , Font.color Ui.fgTitle
                    , Ui.normalFont
                    , Font.bold
                    , E.paddingEach { top = 0, bottom = 0, left = 12, right = 0 }
                    , E.pointer
                    ]
                    (E.text "Somme:")
            , text = dialog.amount
            , placeholder = Nothing
            , onChange = Msg.ForDialog << Msg.DialogChangeAmount
            }
        , E.el
            [ Ui.bigFont
            , Font.color Ui.fgBlack
            , E.paddingXY 0 12
            , E.width E.shrink
            , E.alignLeft
            , E.alignBottom
            , Border.width 1
            , Border.color (E.rgba 0 0 0 0)
            ]
            (E.text "€")
        , if dialog.amountError /= "" then
            Ui.warningParagraph
                [ E.width E.fill ]
                [ E.text dialog.amountError ]

          else
            E.el [] E.none
        ]


descriptionRow : Model.Dialog -> E.Element Msg.Msg
descriptionRow dialog =
    E.row
        [ E.width E.fill
        , E.paddingEach { top = 24, bottom = 24, right = 64, left = 64 }
        , E.spacing 12
        , Background.color Ui.bgWhite
        ]
        [ Input.multiline
            [ Ui.onEnter (Msg.ForDialog <| Msg.DialogConfirm)
            , Ui.bigFont
            , E.paddingXY 8 12
            , Border.width 1
            , Border.color Ui.bgDark
            , E.focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , size = 4
                    , blur = 0
                    , color = Ui.fgFocus
                    }
                ]
            , E.width E.fill
            , E.scrollbarY
            ]
            { label =
                Input.labelAbove
                    [ E.width E.shrink
                    , E.height E.fill
                    , Font.color Ui.fgTitle
                    , Ui.normalFont
                    , Font.bold
                    , E.paddingEach { top = 0, bottom = 0, left = 12, right = 0 }
                    , E.pointer
                    ]
                    (E.text "Description:")
            , text = dialog.description
            , placeholder = Nothing
            , onChange = Msg.ForDialog << Msg.DialogChangeDescription
            , spellcheck = True
            }
        ]


categoryRow : Model.Model -> Model.Dialog -> E.Element Msg.Msg
categoryRow model dialog =
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
    E.column
        [ E.width E.fill
        , E.height E.shrink
        , E.paddingEach { top = 24, bottom = 24, right = 64, left = 64 }
        , E.spacing 6
        , Background.color Ui.bgWhite
        ]
        [ E.el
            [ E.width E.shrink
            , E.height E.fill
            , Font.color Ui.fgTitle
            , Ui.normalFont
            , Font.bold
            , E.paddingEach { top = 0, bottom = 12, left = 12, right = 0 }
            , E.pointer
            ]
            (E.text "Catégorie:")
        , E.table
            [ E.width E.fill
            , E.spacing 12
            , E.paddingXY 64 0

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


buttonsRow : Model.Dialog -> E.Element Msg.Msg
buttonsRow dialog =
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
