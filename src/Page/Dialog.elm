module Page.Dialog exposing
    ( Model
    , msgAmount
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
import Money
import Ports
import Shared
import Style
import Task
import Ui



-- MODEL


type alias Model =
    { id : Maybe Int
    , isExpense : Bool
    , date : Date.Date
    , amount : String
    , amountError : String
    , description : String
    , category : Int
    }



-- UPDATE


msgNewDialog : Bool -> Date.Date -> Shared.Model -> Maybe Model -> ( Shared.Model, Maybe Model, Cmd Shared.Msg )
msgNewDialog isExpense date shared _ =
    ( shared
    , Just
        { id = Nothing
        , isExpense = isExpense
        , date = date
        , amount = ""
        , amountError = ""
        , description = ""
        , category = 0
        }
    , Task.attempt (\_ -> Shared.NoOp) (Dom.focus "dialog-amount")
    )


msgEditDialog : Int -> Shared.Model -> Maybe Model -> ( Shared.Model, Maybe Model, Cmd Shared.Msg )
msgEditDialog id shared _ =
    case Ledger.getTransaction id shared.ledger of
        Nothing ->
            ( shared, Nothing, Ports.error "msgEditDialog: unable to get transaction" )

        Just t ->
            ( shared
            , Just
                { id = Just t.id
                , isExpense = Money.isExpense t.amount
                , date = t.date
                , amount = Money.toInput t.amount
                , amountError = Money.validate (Money.toInput t.amount)
                , description = t.description
                , category = t.category
                }
            , Cmd.none
            )


msgAmount : String -> Shared.Model -> Maybe Model -> ( Shared.Model, Maybe Model, Cmd Shared.Msg )
msgAmount amount shared model =
    case model of
        Just dialog ->
            ( shared
            , Just
                { dialog
                    | amount = amount
                    , amountError = Money.validate amount
                }
            , Cmd.none
            )

        Nothing ->
            ( shared, Nothing, Cmd.none )


msgDescription : String -> Shared.Model -> Maybe Model -> ( Shared.Model, Maybe Model, Cmd Shared.Msg )
msgDescription string shared model =
    case model of
        Just dialog ->
            ( shared
            , Just
                { dialog
                    | description =
                        String.filter (\c -> c /= Char.fromCode 13 && c /= Char.fromCode 10) string
                }
            , Cmd.none
            )

        Nothing ->
            ( shared, model, Cmd.none )


msgCategory : Int -> Shared.Model -> Maybe Model -> ( Shared.Model, Maybe Model, Cmd Shared.Msg )
msgCategory id shared model =
    case model of
        Just dialog ->
            ( shared
            , Just
                { dialog | category = id }
            , Cmd.none
            )

        Nothing ->
            ( shared, model, Cmd.none )


msgConfirm : Shared.Model -> Maybe Model -> ( Shared.Model, Maybe Model, Cmd Shared.Msg )
msgConfirm shared model =
    case model of
        Just dialog ->
            case ( dialog.id, Money.fromInput dialog.isExpense dialog.amount ) of
                ( Just id, Just amount ) ->
                    ( shared
                    , Nothing
                    , Ports.putTransaction
                        { account = shared.account
                        , id = id
                        , date = dialog.date
                        , amount = amount
                        , description = dialog.description
                        , category = dialog.category
                        , checked = False
                        }
                    )

                ( Nothing, Just amount ) ->
                    ( shared
                    , Nothing
                    , Ports.addTransaction
                        { account = shared.account
                        , date = dialog.date
                        , amount = amount
                        , description = dialog.description
                        , category = dialog.category
                        , checked = False
                        }
                    )

                ( _, Nothing ) ->
                    ( shared, model, Ports.error "invalid amount input" )

        _ ->
            ( shared, model, Ports.error "impossible Confirm message" )


msgDelete : Shared.Model -> Maybe Model -> ( Shared.Model, Maybe Model, Cmd Shared.Msg )
msgDelete shared model =
    case model of
        Just dialog ->
            case dialog.id of
                Just id ->
                    ( shared
                    , Nothing
                    , Ports.deleteTransaction
                        { account = shared.account
                        , id = id
                        }
                    )

                Nothing ->
                    ( shared, model, Ports.error "impossible Delete message" )

        Nothing ->
            ( shared, model, Ports.error "impossible Delete message" )



-- VIEW


view : Shared.Model -> Model -> Element Shared.Msg
view shared dialog =
    column
        [ centerX
        , centerY
        , width (px 800)
        , height shrink
        , paddingXY 0 0
        , spacing 0
        , scrollbarY
        , Background.color Style.bgWhite
        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 32, color = rgba 0 0 0 0.75 }
        ]
        [ titleRow dialog
        , amountRow dialog
        , descriptionRow dialog
        , if dialog.isExpense && shared.settings.categoriesEnabled then
            categoryRow shared dialog

          else
            none
        , el [ height fill, Background.color Style.bgWhite ] none
        , buttonsRow dialog
        ]


titleRow dialog =
    row
        [ alignLeft
        , width fill
        , paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
        , spacing 12
        , Background.color (Style.bgTransaction dialog.isExpense)
        ]
        [ el
            [ width fill, Font.center, Style.bigFont, Font.bold, Font.color Style.bgWhite ]
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
        , width fill
        , paddingEach { top = 48, bottom = 24, right = 64, left = 64 }
        , spacing 12
        , Background.color Style.bgWhite
        , centerY
        ]
        [ Input.text
            [ Ui.onEnter Shared.DialogConfirm
            , Style.bigFont
            , paddingXY 8 12
            , width (shrink |> minimum 220)
            , alignLeft
            , Border.width 1
            , Border.color Style.bgDark
            , htmlAttribute <| HtmlAttr.id "dialog-amount"
            ]
            { label =
                Input.labelAbove
                    [ width shrink
                    , alignLeft
                    , height fill
                    , Font.color Style.fgTitle
                    , Style.normalFont
                    , Font.bold
                    , paddingEach { top = 0, bottom = 0, left = 12, right = 0 }
                    , pointer
                    ]
                    (text "Somme:")
            , text = dialog.amount
            , placeholder = Nothing
            , onChange = Shared.DialogAmount
            }
        , el
            [ Style.bigFont
            , Font.color Style.fgBlack
            , paddingXY 0 12
            , width shrink
            , alignLeft
            , alignBottom
            , Border.width 1
            , Border.color (rgba 0 0 0 0)
            ]
            (text "€")

        {-
           , el
               [ Style.fontIcons
               , alignBottom
               , paddingEach { top = 0, bottom = 4, left = 12, right = 0 }
               , Font.size 48
               , Font.color Style.bgDark
               ]
               (if dialog.amountError /= "" then
                   text "\u{F071}"

                else
                   text ""
               )
           , paragraph
               [ Style.smallFont
               , width fill
               , height shrink
               , alignBottom
               , paddingEach { top = 8, bottom = 8, left = 0, right = 0 }
               , Font.alignLeft
               , Font.color (rgb 0 0 0)
               ]
               [ text dialog.amountError ]
        -}
        , if dialog.amountError /= "" then
            Ui.warningParagraph [ width fill ] [ text dialog.amountError ]

          else
            none
        ]


descriptionRow dialog =
    row
        [ width fill
        , paddingEach { top = 24, bottom = 24, right = 64, left = 64 }
        , spacing 12
        , Background.color Style.bgWhite
        ]
        [ Input.multiline
            [ Ui.onEnter Shared.DialogConfirm
            , Style.bigFont
            , paddingXY 8 12
            , Border.width 1
            , Border.color Style.bgDark
            , width fill
            , scrollbarY
            ]
            { label =
                Input.labelAbove
                    [ width shrink
                    , height fill
                    , Font.color Style.fgTitle
                    , Style.normalFont
                    , Font.bold
                    , paddingEach { top = 0, bottom = 0, left = 12, right = 0 }
                    , pointer
                    ]
                    (text "Description:")
            , text = dialog.description
            , placeholder = Nothing
            , onChange = Shared.DialogDescription
            , spellcheck = True
            }
        ]


categoryRow shared dialog =
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
            shared.categories
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
        , Background.color Style.bgWhite
        ]
        [ el
            [ width shrink
            , height fill
            , Font.color Style.fgTitle
            , Style.normalFont
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
                                    radioButton []
                                        { onPress = Just (Shared.DialogCategory k)
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
                                    radioButton []
                                        { onPress = Just (Shared.DialogCategory k)
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
                                    radioButton []
                                        { onPress = Just (Shared.DialogCategory k)
                                        , label = v.name
                                        , active = k == dialog.category
                                        }
                  }
                ]
            }
        ]


radioButton attributes { onPress, label, active } =
    Input.button
        ([ Style.normalFont
         , Border.rounded 4
         , paddingXY 24 8
         ]
            ++ (if active then
                    [ Font.color Style.fgWhite
                    , Background.color Style.bgTitle
                    ]

                else
                    [ Font.color Style.fgTitle
                    , Background.color Style.bgWhite
                    ]
               )
            ++ attributes
        )
        { onPress = onPress
        , label = text label
        }


buttonsRow dialog =
    row
        [ width fill
        , spacing 24
        , paddingEach { top = 64, bottom = 24, left = 64, right = 64 }
        , Background.color Style.bgWhite
        ]
        [ Ui.simpleButton
            [ alignRight ]
            { label = text "Annuler", onPress = Just Shared.Close }
        , case dialog.id of
            Just _ ->
                Ui.simpleButton
                    []
                    { label = text "Supprimer", onPress = Just Shared.DialogDelete }

            Nothing ->
                none
        , Input.button
            (Style.button shrink
                Style.fgWhite
                Style.bgTitle
                Style.bgTitle
            )
            { label = text "OK"
            , onPress = Just Shared.DialogConfirm
            }
        ]
