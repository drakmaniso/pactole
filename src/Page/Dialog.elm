module Page.Dialog exposing
    ( Model
    , msgAmount
    , msgConfirm
    , msgDelete
    , msgDescription
    , msgEditDialog
    , msgNewDialog
    , view
    )

import Browser.Dom as Dom
import Common
import Date
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html.Attributes as HtmlAttr
import Json.Encode as Encode
import Ledger
import Money
import Msg
import Ports
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
    }



-- UPDATE


msgNewDialog : Bool -> Date.Date -> Common.Model -> Maybe Model -> ( Common.Model, Maybe Model, Cmd Msg.Msg )
msgNewDialog isExpense date common _ =
    ( common
    , Just
        { id = Nothing
        , isExpense = isExpense
        , date = date
        , amount = ""
        , amountError = ""
        , description = ""
        }
    , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-amount")
    )


msgEditDialog : Int -> Common.Model -> Maybe Model -> ( Common.Model, Maybe Model, Cmd Msg.Msg )
msgEditDialog id common _ =
    case Ledger.getTransaction id common.ledger of
        Nothing ->
            ( common, Nothing, Ports.error "msgEditDialog: unable to get transaction" )

        Just t ->
            ( common
            , Just
                { id = Just t.id
                , isExpense = Money.isExpense t.amount
                , date = t.date
                , amount = Money.toInput t.amount
                , amountError = Money.validate (Money.toInput t.amount)
                , description = t.description
                }
            , Cmd.none
            )


msgAmount : String -> Common.Model -> Maybe Model -> ( Common.Model, Maybe Model, Cmd Msg.Msg )
msgAmount amount common model =
    case model of
        Just dialog ->
            ( common
            , Just
                { dialog
                    | amount = amount
                    , amountError = Money.validate amount
                }
            , Cmd.none
            )

        Nothing ->
            ( common, Nothing, Cmd.none )


msgDescription : String -> Common.Model -> Maybe Model -> ( Common.Model, Maybe Model, Cmd Msg.Msg )
msgDescription string common model =
    case model of
        Just dialog ->
            ( common
            , Just
                { dialog
                    | description =
                        String.filter (\c -> c /= Char.fromCode 13 && c /= Char.fromCode 10) string
                }
            , Cmd.none
            )

        Nothing ->
            ( common, model, Cmd.none )


msgConfirm : Common.Model -> Maybe Model -> ( Common.Model, Maybe Model, Cmd Msg.Msg )
msgConfirm common model =
    case model of
        Just dialog ->
            case ( dialog.id, Money.fromInput dialog.isExpense dialog.amount ) of
                ( Just id, Just amount ) ->
                    ( common
                    , Nothing
                    , Ports.putTransaction
                        { account = common.account
                        , id = id
                        , date = dialog.date
                        , amount = amount
                        , description = dialog.description
                        , category = ""
                        , checked = False
                        }
                    )

                ( Nothing, Just amount ) ->
                    ( common
                    , Nothing
                    , Ports.addTransaction
                        { account = common.account
                        , date = dialog.date
                        , amount = amount
                        , description = dialog.description
                        , category = ""
                        , checked = False
                        }
                    )

                ( _, Nothing ) ->
                    ( common, model, Ports.error "invalid amount input" )

        _ ->
            ( common, model, Ports.error "impossible Confirm message" )


msgDelete : Common.Model -> Maybe Model -> ( Common.Model, Maybe Model, Cmd Msg.Msg )
msgDelete common model =
    case model of
        Just dialog ->
            case dialog.id of
                Just id ->
                    ( common
                    , Nothing
                    , Ports.deleteTransaction
                        { account = common.account
                        , id = id
                        }
                    )

                Nothing ->
                    ( common, model, Ports.error "impossible Delete message" )

        Nothing ->
            ( common, model, Ports.error "impossible Delete message" )



-- VIEW


view : Model -> Element Msg.Msg
view dialog =
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
        ]
        [ Input.text
            [ Ui.onEnter Msg.DialogConfirm
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
            , onChange = Msg.DialogAmount
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
        ]


descriptionRow dialog =
    row
        [ width fill
        , paddingEach { top = 24, bottom = 24, right = 64, left = 64 }
        , spacing 12
        , Background.color Style.bgWhite
        ]
        [ Input.multiline
            [ Ui.onEnter Msg.DialogConfirm
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
            , onChange = Msg.DialogDescription
            , spellcheck = True
            }
        ]


buttonsRow dialog =
    row
        [ width fill
        , spacing 24
        , paddingEach { top = 64, bottom = 24, left = 64, right = 64 }
        , Background.color Style.bgWhite
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
        , Input.button
            (Style.button shrink
                Style.fgWhite
                Style.bgTitle
                Style.bgTitle
            )
            { label = text "OK"
            , onPress = Just Msg.DialogConfirm
            }
        ]
