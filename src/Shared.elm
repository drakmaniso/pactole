module Shared exposing
    ( Category
    , Mode(..)
    , Model
    , Msg(..)
    , Page(..)
    , Settings
    , accountName
    , category
    , init
    , msgAttemptSettings
    , msgAttemptTimeout
    , msgChangePage
    , msgCreateAccount
    , msgCreateCategory
    , msgFromService
    , msgSelectAccount
    , msgSelectDate
    , msgSetSettings
    , msgShowAdvanced
    , msgShowFocus
    , msgToday
    )

import Array as Array
import Browser
import Browser.Dom as Dom
import Date
import Dict
import Json.Decode as Decode
import Ledger
import Money
import Ports
import Process
import Task
import Time
import Tuple
import Url



-- MODEL


type alias Model =
    { settings : Settings
    , today : Date.Date
    , date : Date.Date
    , ledger : Ledger.Ledger
    , accounts : Dict.Dict Int String
    , account : Maybe Int
    , categories : Dict.Dict Int Category
    , showAdvanced : Bool
    , advancedCounter : Int
    , showFocus : Bool
    , page : Page
    }


type alias Category =
    { name : String
    , icon : String
    }


type alias Settings =
    { categoriesEnabled : Bool
    , defaultMode : Mode
    , reconciliationEnabled : Bool
    , summaryEnabled : Bool
    , balanceWarning : Int
    }


type Mode
    = InCalendar
    | InTabular


type Page
    = MainPage
    | StatsPage
    | ReconcilePage
    | SettingsPage


decodeAccount =
    Decode.map2 Tuple.pair
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)


decodeCategory =
    Decode.map3 (\id name icon -> ( id, { name = name, icon = icon } ))
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "icon" Decode.string)


decodeSettings =
    Decode.map5
        (\cat mod rec summ balwarn ->
            { categoriesEnabled = cat
            , defaultMode = mod
            , reconciliationEnabled = rec
            , summaryEnabled = summ
            , balanceWarning = balwarn
            }
        )
        (Decode.oneOf [ Decode.field "categoriesEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "defaultMode" decodeMode, Decode.succeed InCalendar ])
        (Decode.oneOf [ Decode.field "reconciliationEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "summaryEnabled" Decode.bool, Decode.succeed False ])
        (Decode.oneOf [ Decode.field "balanceWarning" Decode.int, Decode.succeed 100 ])


decodeMode =
    Decode.map
        (\str ->
            case str of
                "calendar" ->
                    InCalendar

                _ ->
                    InTabular
        )
        Decode.string


accountName accountID model =
    Maybe.withDefault
        ("COMPTE_" ++ String.fromInt accountID)
        (Dict.get accountID model.accounts)


category categoryID model =
    Maybe.withDefault
        { name = "CATEGORIE_" ++ String.fromInt categoryID, icon = "" }
        (Dict.get categoryID model.categories)



-- INIT


init : Decode.Value -> ( Model, Cmd Msg )
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
    ( { settings =
            { categoriesEnabled = False
            , defaultMode = InCalendar
            , reconciliationEnabled = False
            , summaryEnabled = False
            , balanceWarning = 100
            }
      , today = today
      , date = today
      , ledger = Ledger.empty
      , accounts = Dict.empty
      , account = Nothing
      , categories = Dict.empty
      , showAdvanced = False
      , advancedCounter = 0
      , showFocus = False
      , page = MainPage
      }
    , cmd
    )



-- MSG


type Msg
    = Today Date.Date
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | FromService ( String, Decode.Value )
    | ChangePage Page
    | AttemptSettings
    | AttemptTimeout
    | Close
    | SelectDate Date.Date
    | SelectAccount Int
    | KeyDown String
    | KeyUp String
    | NewDialog Bool Date.Date -- NewDialog isExpense date
    | EditDialog Int
    | DialogAmount String
    | DialogDescription String
    | DialogCategory Int
    | DialogDelete
    | DialogConfirm
    | CreateAccount String
    | OpenRenameAccount Int
    | OpenDeleteAccount Int
    | CreateCategory String String
    | OpenRenameCategory Int
    | OpenDeleteCategory Int
    | SettingsChangeName String
    | SettingsChangeIcon String
    | SetSettings Settings
    | SettingsConfirm
    | CheckTransaction Ledger.Transaction Bool
    | NoOp



-- UPDATE MESSAGES


msgToday : Date.Date -> Model -> ( Model, Cmd Msg )
msgToday d model =
    ( { model | today = d, date = d }, Cmd.none )


msgSelectDate : Date.Date -> Model -> ( Model, Cmd Msg )
msgSelectDate date model =
    ( { model | date = date }, Cmd.none )


msgSelectAccount : Int -> Model -> ( Model, Cmd Msg )
msgSelectAccount accountID model =
    ( { model | account = Just accountID }, Ports.getLedger accountID )


msgCreateAccount : String -> Model -> ( Model, Cmd Msg )
msgCreateAccount name model =
    ( model, Ports.createAccount name )


msgCreateCategory : String -> String -> Model -> ( Model, Cmd Msg )
msgCreateCategory name icon model =
    ( model, Ports.createCategory name icon )


msgShowAdvanced : Bool -> Model -> ( Model, Cmd Msg )
msgShowAdvanced show model =
    ( { model | showAdvanced = show }, Cmd.none )


msgShowFocus : Bool -> Model -> ( Model, Cmd Msg )
msgShowFocus show model =
    ( { model | showFocus = show }, Cmd.none )


msgChangePage : Page -> Model -> ( Model, Cmd Msg )
msgChangePage page model =
    ( { model | page = page }
    , Task.attempt (\_ -> NoOp) (Dom.blur "unfocus-on-page-change")
    )


msgAttemptSettings : Model -> ( Model, Cmd Msg )
msgAttemptSettings model =
    ( { model
        | advancedCounter =
            if model.advancedCounter > 3 then
                3

            else
                model.advancedCounter + 1
        , showAdvanced = model.advancedCounter >= 3
      }
    , Task.perform
        (\_ -> AttemptTimeout)
        (Process.sleep 3000.0
            |> Task.andThen (\_ -> Task.succeed ())
        )
    )


msgAttemptTimeout model =
    ( { model
        | advancedCounter =
            if model.advancedCounter <= 0 then
                0

            else
                model.advancedCounter - 1
        , showAdvanced = model.advancedCounter <= 0
      }
    , Cmd.none
    )


msgSetSettings : Settings -> Model -> ( Model, Cmd Msg )
msgSetSettings settings model =
    let
        modeString =
            case settings.defaultMode of
                InCalendar ->
                    "calendar"

                InTabular ->
                    "tabular"

        settingsString =
            { categoriesEnabled = settings.categoriesEnabled
            , modeString = modeString
            , reconciliationEnabled = settings.reconciliationEnabled
            , summaryEnabled = settings.summaryEnabled
            , balanceWarning = settings.balanceWarning
            }
    in
    ( model
      --{ model | settings = settings }
    , Ports.setSettings settingsString
    )



-- SERVICE WORKER MESSAGES


msgFromService : ( String, Decode.Value ) -> Model -> ( Model, Cmd Msg )
msgFromService ( title, content ) model =
    case title of
        "start application" ->
            ( model
            , Cmd.batch
                [ Ports.getAccountList
                , Ports.getCategoryList
                , Ports.getSettings
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

        "set settings" ->
            case Decode.decodeValue decodeSettings content of
                Ok settings ->
                    ( { model | settings = settings }, Cmd.none )

                Err e ->
                    --TODO: error
                    ( model, Ports.error ("while decoding settings: " ++ Decode.errorToString e) )

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

        "settings updated" ->
            case Decode.decodeValue decodeSettings content of
                Ok settings ->
                    ( { model | settings = settings }
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
