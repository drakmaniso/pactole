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
import Ledger
import Money
import Msg
import Ports
import Style
import Task



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


msgNewDialog : Bool -> Date.Date -> ( Maybe Model, Cmd Msg.Msg )
msgNewDialog isExpense date =
    ( Just
        { id = Nothing
        , isExpense = isExpense
        , date = date
        , amount = ""
        , amountError = ""
        , description = ""
        }
    , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-amount")
    )


msgEditDialog : Int -> Common.Model -> ( Maybe Model, Cmd Msg.Msg )
msgEditDialog id common =
    case Ledger.getTransaction id common.ledger of
        Nothing ->
            ( Nothing, Debug.log "*** Unable to get transaction" Cmd.none )

        Just t ->
            ( Just
                { id = Just t.id
                , isExpense = Money.isExpense t.amount
                , date = t.date
                , amount = Money.toInput t.amount
                , amountError = Money.validate (Money.toInput t.amount)
                , description = t.description
                }
            , Cmd.none
            )


msgAmount : String -> Maybe Model -> ( Maybe Model, Cmd Msg.Msg )
msgAmount amount model =
    case model of
        Just dialog ->
            ( Just
                { dialog
                    | amount = amount
                    , amountError = Money.validate amount
                }
            , Cmd.none
            )

        Nothing ->
            ( Nothing, Cmd.none )


msgDescription : String -> Maybe Model -> ( Maybe Model, Cmd Msg.Msg )
msgDescription string model =
    case model of
        Just dialog ->
            ( Just
                { dialog
                    | description = string
                }
            , Cmd.none
            )

        Nothing ->
            ( model, Cmd.none )


msgConfirm : Common.Model -> Maybe Model -> ( Maybe Model, Common.Model, Cmd Msg.Msg )
msgConfirm common model =
    case model of
        Just dialog ->
            case ( dialog.id, Money.fromInput dialog.isExpense dialog.amount ) of
                ( Just id, Just amount ) ->
                    let
                        newLedger =
                            Ledger.updateTransaction
                                { id = id
                                , date = dialog.date
                                , amount = amount
                                , description = dialog.description
                                }
                                common.ledger
                    in
                    ( Nothing
                    , { common | ledger = newLedger }
                    , Ports.storeLedger
                        ( Maybe.withDefault "ERROR" common.account, Ledger.encode newLedger )
                    )

                ( Nothing, Just amount ) ->
                    let
                        newLedger =
                            Ledger.addTransaction
                                { date = dialog.date
                                , amount = amount
                                , description = dialog.description
                                }
                                common.ledger
                    in
                    ( Nothing
                    , { common | ledger = newLedger }
                    , Ports.storeLedger
                        ( Maybe.withDefault "ERROR" common.account, Ledger.encode newLedger )
                    )

                ( _, _ ) ->
                    ( model, common, Cmd.none )

        _ ->
            ( model, common, Cmd.none )


msgDelete : Common.Model -> Maybe Model -> ( Maybe Model, Common.Model, Cmd Msg.Msg )
msgDelete common model =
    case model of
        Just dialog ->
            case dialog.id of
                Just id ->
                    let
                        newLedger =
                            Ledger.deleteTransaction id common.ledger
                    in
                    ( Nothing
                    , { common | ledger = newLedger }
                    , Ports.storeLedger
                        ( Maybe.withDefault "ERROR" common.account, Ledger.encode newLedger )
                    )

                Nothing ->
                    Debug.log "IMPOSSIBLE DELETE MSG" ( model, common, Cmd.none )

        Nothing ->
            Debug.log "IMPOSSIBLE DELETE MSG" ( model, common, Cmd.none )



-- VIEW


view : Model -> Element Msg.Msg
view dialog =
    column
        [ centerX
        , centerY
        , width (px 800)
        , height shrink
        , Border.rounded 7
        , paddingXY 0 0
        , spacing 0
        , scrollbarY
        , Background.color Style.bgWhite
        , Border.shadow { offset = ( 0, 0 ), size = 4, blur = 16, color = rgba 0 0 0 0.5 }
        ]
        [ titleRow dialog
        , amountRow dialog
        , descriptionRow dialog
        , el [ height fill, Background.color Style.bgWhite ] none
        , buttonsRow dialog
        ]


titleRow dialog =
    let
        ( bg, label ) =
            case ( dialog.id, dialog.isExpense ) of
                ( Nothing, False ) ->
                    ( Style.bgIncome, "Nouvelle entrée d'argent" )

                ( Nothing, True ) ->
                    ( Style.bgExpense, "Nouvelle dépense" )

                ( Just _, False ) ->
                    ( Style.bgIncome, "Entrée d'argent" )

                ( Just _, True ) ->
                    ( Style.bgExpense, "Dépense" )
    in
    row
        [ alignLeft
        , width fill
        , paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
        , spacing 12
        , Background.color bg

        {-
           , Border.widthEach { top = 0, bottom = 3, left = 0, right = 0 }
           , Border.color Style.bgDark
        -}
        ]
        [ el
            [ width fill, Font.center, Style.bigFont, Font.bold, Font.color Style.bgWhite ]
            (text label)
        ]


amountRow dialog =
    row
        [ alignLeft
        , width fill
        , paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
        , spacing 12
        , Background.color Style.bgWhite
        ]
        [ Input.text
            [ Style.bigFont
            , paddingXY 8 12
            , width (shrink |> minimum 220)
            , alignLeft
            , Border.width 1
            , Border.color Style.bgDark
            , htmlAttribute <| HtmlAttr.id "dialog-amount"

            {-
               , onRight
                   (paragraph
                       [ Style.smallFont
                       , width fill
                       , height fill
                       , paddingEach { top = 8, bottom = 8, left = 64, right = 0 }
                       , Font.center
                       , Font.color (rgb 0 0 0)
                       ]
                       [ text dialog.amountError ]
                   )
            -}
            ]
            { label =
                Input.labelAbove
                    [ Input.focusedOnLoad
                    , width shrink
                    , alignLeft
                    , height fill
                    , Font.color Style.fgTitle -- (Style.fgTransaction dialog.isExpense)
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

        {-
           , el
               [ width fill ]
               none
        -}
        ]


descriptionRow dialog =
    row
        [ width fill
        , paddingEach { top = 24, bottom = 24, right = 48, left = 48 }
        , spacing 12
        , Background.color Style.bgWhite
        ]
        [ Input.multiline
            [ Style.bigFont
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
                    , Font.color Style.fgTitle -- (Style.fgTransaction dialog.isExpense)
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
        , paddingEach { top = 48, bottom = 24, left = 48, right = 48 }
        , Background.color Style.bgWhite
        ]
        [ Input.button
            (alignRight :: Style.button shrink Style.fgTitle Style.bgWhite Style.bgDark)
            { label = text "Annuler", onPress = Just Msg.Close }
        , case dialog.id of
            Just _ ->
                Input.button
                    (Style.button shrink Style.fgTitle Style.bgWhite Style.bgDark)
                    { label = text "Supprimer", onPress = Just Msg.DialogDelete }

            Nothing ->
                none
        , Input.button
            (Style.button shrink
                Style.fgWhite
                Style.bgTitle
                Style.bgTitle
             {-
                (Style.bgTransaction dialog.isExpense)
                (Style.bgTransaction dialog.isExpense)
             -}
            )
            { label = text "OK"
            , onPress = Just Msg.DialogConfirm
            }
        ]
