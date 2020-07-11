module Common exposing
    ( Mode(..)
    , Model
    , init
    , msgCreateAccount
    , msgReceive
    , msgSelectAccount
    , msgSelectDate
    , msgShowAdvanced
    , msgToCalendar
    , msgToTabular
    , msgToday
    , msgUpdateAccountList
    )

import Array as Array
import Date
import Json.Decode as Decode
import Ledger
import Money
import Msg
import Ports
import Time



-- MODEL


type alias Model =
    { mode : Mode
    , today : Date.Date
    , date : Date.Date
    , ledger : Ledger.Ledger
    , accounts : List String
    , account : Maybe String
    , showAdvanced : Bool
    }


type Mode
    = InCalendar
    | InTabular


init : Decode.Value -> ( Model, Cmd Msg.Msg )
init flags =
    let
        day =
            case Decode.decodeValue (Decode.at [ "today", "day" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    0

        month =
            case Decode.decodeValue (Decode.at [ "today", "month" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    0

        year =
            case Decode.decodeValue (Decode.at [ "today", "year" ] Decode.int) flags of
                Ok v ->
                    v

                Err e ->
                    0

        ( today, cmd ) =
            case Date.fromParts { day = day, month = month, year = year } of
                Just d ->
                    ( d, Cmd.none )

                Nothing ->
                    ( Date.default, Ports.error "init flags: invalid date for today" )
    in
    ( { mode = InCalendar
      , today = today
      , date = today
      , ledger = Ledger.empty
      , accounts = []
      , account = Nothing
      , showAdvanced = False
      }
    , cmd
    )



-- UPDATE MESSAGES


msgToday : Date.Date -> Model -> ( Model, Cmd Msg.Msg )
msgToday d model =
    ( { model | today = d, date = d }, Cmd.none )


msgToCalendar : Model -> ( Model, Cmd Msg.Msg )
msgToCalendar model =
    ( { model | mode = InCalendar }
    , Cmd.none
    )


msgToTabular : Model -> ( Model, Cmd Msg.Msg )
msgToTabular model =
    ( { model | mode = InTabular }
    , Cmd.none
    )


msgSelectDate : Date.Date -> Model -> ( Model, Cmd Msg.Msg )
msgSelectDate date model =
    ( { model | date = date }, Cmd.none )


msgSelectAccount : String -> Model -> ( Model, Cmd Msg.Msg )
msgSelectAccount account model =
    ( { model | account = Just account }, Ports.getLedger account )


msgCreateAccount : String -> Model -> ( Model, Cmd Msg.Msg )
msgCreateAccount account model =
    ( model, Ports.createAccount account )


msgUpdateAccountList : Decode.Value -> Model -> ( Model, Cmd Msg.Msg )
msgUpdateAccountList json model =
    let
        ( accounts, account, cmd ) =
            case Decode.decodeValue (Decode.list Decode.string) json of
                Ok a ->
                    ( a, List.head a, Cmd.none )

                Err e ->
                    ( [], Nothing, Ports.error ("Msg.SetAccounts: " ++ Decode.errorToString e) )
    in
    ( { model | accounts = accounts, account = account, ledger = Ledger.empty }, cmd )


msgShowAdvanced : Bool -> Model -> ( Model, Cmd Msg.Msg )
msgShowAdvanced show model =
    ( { model | showAdvanced = show }, Cmd.none )



-- SERVICE WORKER MESSAGES


msgReceive : ( String, Decode.Value ) -> Model -> ( Model, Cmd Msg.Msg )
msgReceive ( title, content ) model =
    case title of
        "service worker ready" ->
            ( model, Ports.getAccountList )

        "set account list" ->
            case Decode.decodeValue (Decode.list (Decode.field "name" Decode.string)) content of
                Ok (account :: others) ->
                    ( { model | accounts = account :: others, account = Just account }
                    , Ports.getLedger account
                    )

                Err e ->
                    --TODO: error
                    ( model, Ports.error ("while decoding account list: " ++ Decode.errorToString e) )

                _ ->
                    --TODO: error
                    ( model, Ports.error "received account list is empty" )

        "ledger updated" ->
            case Decode.decodeValue Decode.string content of
                Ok account ->
                    ( model, Ports.getLedger account )

                Err e ->
                    ( model, Ports.error (Decode.errorToString e) )

        "set ledger" ->
            case Decode.decodeValue Ledger.decode content of
                Ok ledger ->
                    ( { model | ledger = ledger }
                    , Cmd.none
                    )

                Err e ->
                    ( model, Ports.error (Decode.errorToString e) )

        {-
           "add transaction" ->
               case Decode.decodeValue (Decode.field "account" Decode.string) content of
                   Ok account ->
                       if Just account == model.account then
                           let
                               transaction =
                                   content
                                       |> Decode.decodeValue
                                           (Decode.map3
                                               (\date amount desc ->
                                                   { date = Date.fromInt date
                                                   , amount = amount
                                                   , description = desc
                                                   }
                                               )
                                               (Decode.field "date" Decode.int)
                                               (Decode.field "amount" Money.decoder)
                                               (Decode.field "description" Decode.string)
                                           )
                           in
                           case transaction of
                               Ok tr ->
                                   ( { model | ledger = Ledger.addTransaction tr model.ledger }
                                   , Cmd.none
                                   )

                               Err e ->
                                   ( model, Ports.error (Decode.errorToString e) )

                       else
                           ( model, Cmd.none )

                   Err e ->
                       ( model, Ports.error (Decode.errorToString e) )
        -}
        _ ->
            --TODO: error
            ( model, Ports.error ("in message from service: unknown title \"" ++ title ++ "\"") )
