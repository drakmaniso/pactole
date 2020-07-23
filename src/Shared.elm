module Shared exposing
    ( Mode(..)
    , Model
    ,  accountName
       --, msgUpdateAccountList

    , init
    , msgCreateAccount
    , msgFromService
    , msgSelectAccount
    , msgSelectDate
    , msgShowAdvanced
    , msgToCalendar
    , msgToTabular
    , msgToday
    )

import Array as Array
import Date
import Dict
import Json.Decode as Decode
import Ledger
import Money
import Msg
import Ports
import Time
import Tuple



-- MODEL


type alias Model =
    { mode : Mode
    , today : Date.Date
    , date : Date.Date
    , ledger : Ledger.Ledger
    , accounts : Dict.Dict Int String
    , account : Maybe Int
    , categories : Dict.Dict Int Category
    , showAdvanced : Bool
    }


type alias Category =
    { name : String
    , icon : String
    }


accountName id model =
    case Dict.get id model.accounts of
        Just name ->
            name

        Nothing ->
            "ERROR"


decodeAccount =
    Decode.map2 Tuple.pair
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)


decodeCategory =
    Decode.map3 (\id name icon -> ( id, { name = name, icon = icon } ))
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "icon" Decode.string)


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
      , accounts = Dict.empty
      , account = Nothing
      , categories = Dict.empty
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


msgSelectAccount : Int -> Model -> ( Model, Cmd Msg.Msg )
msgSelectAccount accountID model =
    ( { model | account = Just accountID }, Ports.getLedger accountID )


msgCreateAccount : String -> Model -> ( Model, Cmd Msg.Msg )
msgCreateAccount account model =
    ( model, Ports.createAccount account )


msgShowAdvanced : Bool -> Model -> ( Model, Cmd Msg.Msg )
msgShowAdvanced show model =
    ( { model | showAdvanced = show }, Cmd.none )



-- SERVICE WORKER MESSAGES


msgFromService : ( String, Decode.Value ) -> Model -> ( Model, Cmd Msg.Msg )
msgFromService ( title, content ) model =
    case title of
        "service worker ready" ->
            ( model
            , Cmd.batch
                [ Ports.getAccountList
                , Ports.getCategoryList
                ]
            )

        "set account list" ->
            case Decode.decodeValue (Decode.list decodeAccount) content of
                Ok (head :: tail) ->
                    let
                        accounts =
                            head :: tail

                        accountID =
                            --TODO: use current account if set
                            Tuple.first head
                    in
                    ( { model | accounts = Dict.fromList accounts, account = Just accountID }
                    , Ports.getLedger accountID
                    )

                Err e ->
                    --TODO: error
                    ( model, Ports.error ("while decoding account list: " ++ Decode.errorToString e) )

                _ ->
                    --TODO: error
                    ( model, Ports.error "received account list is empty" )

        "set category list" ->
            case Decode.decodeValue (Decode.list decodeCategory) content of
                Ok categories ->
                    ( { model | categories = Dict.fromList categories }, Cmd.none )

                Err e ->
                    --TODO: error
                    ( model, Ports.error ("while decoding category list: " ++ Decode.errorToString e) )

        "ledger updated" ->
            case ( model.account, Decode.decodeValue Decode.int content ) of
                ( Just currentID, Ok updatedID ) ->
                    if updatedID == currentID then
                        ( model, Ports.getLedger updatedID )

                    else
                        ( model, Cmd.none )

                ( Nothing, _ ) ->
                    ( model, Cmd.none )

                ( _, Err e ) ->
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
