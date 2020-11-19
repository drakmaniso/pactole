module Page.Dialog exposing
    ( msgAmount
    , msgCategory
    , msgConfirm
    , msgDelete
    , msgDescription
    , msgEditDialog
    , msgNewDialog
    , view
    )

import Browser.Dom as Dom
import Date
import Dict
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Json.Encode as Encode
import Ledger
import Model
import Money
import Msg
import Ports
import Task
import Ui



-- UPDATE


msgNewDialog : Bool -> Date.Date -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgNewDialog isExpense date model =
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


msgEditDialog : Int -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgEditDialog id model =
    case Ledger.getTransaction id model.ledger of
        Nothing ->
            ( model, Ports.error "msgEditDialog: unable to get transaction" )

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


msgAmount : String -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgAmount amount model =
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


msgDescription : String -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgDescription string model =
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


msgCategory : Int -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgCategory id model =
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


msgConfirm : Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgConfirm model =
    case model.dialog of
        Just dialog ->
            case ( dialog.id, Money.fromInput dialog.isExpense dialog.amount ) of
                ( Just id, Just amount ) ->
                    ( model
                    , Ports.putTransaction
                        { account = model.account
                        , id = id
                        , date = dialog.date
                        , amount = amount
                        , description = dialog.description
                        , category = dialog.category
                        , checked = False
                        }
                    )

                ( Nothing, Just amount ) ->
                    ( model
                    , Ports.addTransaction
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
            ( model, Ports.error "impossible Confirm message" )


msgDelete : Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgDelete model =
    case model.dialog of
        Just dialog ->
            case dialog.id of
                Just id ->
                    ( model
                    , Ports.deleteTransaction
                        { account = model.account
                        , id = id
                        }
                    )

                Nothing ->
                    ( model, Ports.error "impossible Delete message" )

        Nothing ->
            ( model, Ports.error "impossible Delete message" )



-- VIEW


view : Model.Model -> Element Msg.Msg
view model =
    case model.dialog of
        Just dialog ->
            column
                [ centerX
                , centerY
                , width (px 960)
                , height shrink
                , paddingXY 0 0
                , spacing 0
                , scrollbarY
                , Background.color Ui.bgWhite
                , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = rgba 0 0 0 0.75 }
                ]
                [ titleRow dialog
                , amountRow dialog
                , descriptionRow dialog
                , if dialog.isExpense && model.settings.categoriesEnabled then
                    categoryRow model dialog

                  else
                    none
                , el [ height fill, Background.color Ui.bgWhite ] none
                , buttonsRow dialog
                ]

        Nothing ->
            none


titleRow dialog =
    row
        [ alignLeft
        , width fill
        , paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
        , spacing 12
        , Background.color (Ui.bgTransaction dialog.isExpense)
        ]
        [ el
            [ width fill, Font.center, Ui.bigFont, Font.bold, Font.color Ui.bgWhite ]
            (text
                (if dialog.isExpense then
                    "Dépense"

                 else
                    "Entrée d'argent"
                )
            )
        ]


amountRow dialog =
    row
        [ alignLeft
        , centerY
        , width fill
        , paddingEach { top = 48, bottom = 24, right = 64, left = 64 }
        , spacing 12
        , Background.color Ui.bgWhite
        , centerY
        ]
        [ Input.text
            [ Ui.onEnter Msg.DialogConfirm
            , Ui.bigFont
            , paddingXY 8 12
            , width (shrink |> minimum 220)
            , alignLeft
            , Border.width 1
            , Border.color Ui.bgDark
            , focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , size = 4
                    , blur = 0
                    , color = Ui.fgFocus
                    }
                ]
            , htmlAttribute <| HtmlAttr.id "dialog-amount"
            ]
            { label =
                Input.labelAbove
                    [ width shrink
                    , alignLeft
                    , height fill
                    , Font.color Ui.fgTitle
                    , Ui.normalFont
                    , Font.bold
                    , paddingEach { top = 0, bottom = 0, left = 12, right = 0 }
                    , pointer
                    ]
                    (text "Somme:")
            , text = dialog.amount
            , placeholder = Nothing
            , onChange = Msg.DialogAmount
            }
        , el
            [ Ui.bigFont
            , Font.color Ui.fgBlack
            , paddingXY 0 12
            , width shrink
            , alignLeft
            , alignBottom
            , Border.width 1
            , Border.color (rgba 0 0 0 0)
            ]
            (text "€")
        , if dialog.amountError /= "" then
            Ui.warningParagraph
                [ width fill ]
                [ text dialog.amountError ]

          else
            el [] none
        ]


descriptionRow dialog =
    row
        [ width fill
        , paddingEach { top = 24, bottom = 24, right = 64, left = 64 }
        , spacing 12
        , Background.color Ui.bgWhite
        ]
        [ Input.multiline
            [ Ui.onEnter Msg.DialogConfirm
            , Ui.bigFont
            , paddingXY 8 12
            , Border.width 1
            , Border.color Ui.bgDark
            , focused
                [ Border.shadow
                    { offset = ( 0, 0 )
                    , size = 4
                    , blur = 0
                    , color = Ui.fgFocus
                    }
                ]
            , width fill
            , scrollbarY
            ]
            { label =
                Input.labelAbove
                    [ width shrink
                    , height fill
                    , Font.color Ui.fgTitle
                    , Ui.normalFont
                    , Font.bold
                    , paddingEach { top = 0, bottom = 0, left = 12, right = 0 }
                    , pointer
                    ]
                    (text "Description:")
            , text = dialog.description
            , placeholder = Nothing
            , onChange = Msg.DialogDescription
            , spellcheck = True
            }
        ]


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
    column
        [ width fill
        , height shrink
        , paddingEach { top = 24, bottom = 24, right = 64, left = 64 }
        , spacing 6
        , Background.color Ui.bgWhite
        ]
        [ el
            [ width shrink
            , height fill
            , Font.color Ui.fgTitle
            , Ui.normalFont
            , Font.bold
            , paddingEach { top = 0, bottom = 12, left = 12, right = 0 }
            , pointer
            ]
            (text "Catégorie:")
        , table
            [ width fill
            , spacing 12
            , paddingXY 64 0

            --BUGGY: , scrollbarY
            ]
            { data = categories
            , columns =
                [ { header = none
                  , width = fill
                  , view =
                        \row ->
                            case List.head row of
                                Nothing ->
                                    none

                                Just ( k, v ) ->
                                    Ui.radioButton []
                                        { onPress = Just (Msg.DialogCategory k)
                                        , icon = v.icon
                                        , label = v.name
                                        , active = k == dialog.category
                                        }
                  }
                , { header = none
                  , width = fill
                  , view =
                        \row ->
                            case List.head (List.drop 1 row) of
                                Nothing ->
                                    none

                                Just ( k, v ) ->
                                    Ui.radioButton []
                                        { onPress = Just (Msg.DialogCategory k)
                                        , icon = v.icon
                                        , label = v.name
                                        , active = k == dialog.category
                                        }
                  }
                , { header = none
                  , width = fill
                  , view =
                        \row ->
                            case List.head (List.drop 2 row) of
                                Nothing ->
                                    none

                                Just ( k, v ) ->
                                    Ui.radioButton []
                                        { onPress = Just (Msg.DialogCategory k)
                                        , icon = v.icon
                                        , label = v.name
                                        , active = k == dialog.category
                                        }
                  }
                ]
            }
        ]


buttonsRow dialog =
    row
        [ width fill
        , spacing 24
        , paddingEach { top = 64, bottom = 24, left = 64, right = 64 }
        , Background.color Ui.bgWhite
        ]
        [ Ui.simpleButton
            [ alignRight ]
            { label = text "Annuler", onPress = Just Msg.Close }
        , case dialog.id of
            Just _ ->
                Ui.simpleButton
                    []
                    { label = text "Supprimer", onPress = Just Msg.DialogDelete }

            Nothing ->
                none
        , Ui.mainButton [ width shrink ]
            { label = text "OK"
            , onPress = Just Msg.DialogConfirm
            }
        ]
