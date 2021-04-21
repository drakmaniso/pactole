module Database exposing (..)

import Date
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Log
import Model
import Msg
import Ports



-- UPDATE


update : Msg.DatabaseMsg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.DbFromService ( title, json ) ->
            msgFromService ( title, json ) model

        Msg.DbCreateAccount name ->
            ( model, createAccount name )

        Msg.DbCreateCategory name icon ->
            ( model, createCategory name icon )

        Msg.DbStoreSettings settings ->
            ( model, storeSettings settings )

        Msg.DbCheckTransaction transaction checked ->
            ( model
            , replaceTransaction
                { id = transaction.id
                , account = transaction.account
                , date = transaction.date
                , amount = transaction.amount
                , description = transaction.description
                , category = transaction.category
                , checked = checked
                }
            )



-- TO THE SERVICE WORKER


requestAccounts : Cmd msg
requestAccounts =
    Ports.send ( "request accounts", Encode.object [] )


createAccount : String -> Cmd msg
createAccount name =
    Ports.send ( "create account", Encode.string name )


renameAccount : Int -> String -> Cmd msg
renameAccount account newName =
    Ports.send
        ( "rename account"
        , Encode.object
            [ ( "id", Encode.int account )
            , ( "name", Encode.string newName )
            ]
        )


deleteAccount : Int -> Cmd msg
deleteAccount account =
    Ports.send
        ( "delete account"
        , Encode.int account
        )


requestCategories : Cmd msg
requestCategories =
    Ports.send ( "request categories", Encode.object [] )


createCategory : String -> String -> Cmd msg
createCategory name icon =
    Ports.send
        ( "create category"
        , Encode.object
            [ ( "name", Encode.string name )
            , ( "icon", Encode.string icon )
            ]
        )


renameCategory : Int -> String -> String -> Cmd msg
renameCategory id name icon =
    Ports.send
        ( "rename category"
        , Encode.object
            [ ( "id", Encode.int id )
            , ( "name", Encode.string name )
            , ( "icon", Encode.string icon )
            ]
        )


deleteCategory : Int -> Cmd msg
deleteCategory id =
    Ports.send
        ( "delete category"
        , Encode.int id
        )


requestLedger : () -> Cmd msg
requestLedger () =
    Ports.send ( "request ledger", Encode.null )


createTransaction : Ledger.NewTransaction -> Cmd msg
createTransaction transaction =
    Ports.send
        ( "create transaction"
        , Ledger.encodeNewTransaction transaction
        )


replaceTransaction : Ledger.Transaction -> Cmd msg
replaceTransaction transaction =
    Ports.send
        ( "replace transaction"
        , Ledger.encodeTransaction transaction
        )


deleteTransaction : Int -> Cmd msg
deleteTransaction id =
    Ports.send
        ( "delete transaction"
        , Encode.object
            [ ( "id", Encode.int id )
            ]
        )


requestSettings : Cmd msg
requestSettings =
    Ports.send ( "request settings", Encode.object [] )


storeSettings : Model.Settings -> Cmd msg
storeSettings settings =
    Ports.send ( "store settings", Model.encodeSettings settings )



-- FROM THE SERVICE WORKER


receive : Sub Msg.Msg
receive =
    Ports.receive (Msg.ForDatabase << Msg.DbFromService)


msgFromService : ( String, Decode.Value ) -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgFromService ( title, content ) model =
    case title of
        "start application" ->
            ( model
            , Cmd.batch
                [ requestAccounts
                , requestCategories
                , requestSettings
                ]
            )

        "update accounts" ->
            case Decode.decodeValue (Decode.list Model.decodeAccount) content of
                Ok (head :: tail) ->
                    let
                        accounts =
                            head :: tail

                        accountID =
                            --TODO: use current account if set
                            Tuple.first head
                    in
                    ( { model | accounts = Dict.fromList accounts, account = accountID }
                    , requestLedger ()
                    )

                Err e ->
                    --TODO: error
                    ( model, Log.error ("while decoding account list: " ++ Decode.errorToString e) )

                _ ->
                    --TODO: error
                    ( model, Log.error "received account list is empty" )

        "update categories" ->
            case Decode.decodeValue (Decode.list Model.decodeCategory) content of
                Ok categories ->
                    ( { model | categories = Dict.fromList categories }, Cmd.none )

                Err e ->
                    --TODO: error
                    ( model, Log.error ("while decoding category list: " ++ Decode.errorToString e) )

        "update settings" ->
            case Decode.decodeValue Model.decodeSettings content of
                Ok settings ->
                    processRecurringTransactions { model | settings = settings }

                Err e ->
                    --TODO: error
                    ( model, Log.error ("while decoding settings: " ++ Decode.errorToString e) )

        "update ledger" ->
            case Decode.decodeValue Ledger.decode content of
                Ok ledger ->
                    ( { model | ledger = ledger }
                    , Cmd.none
                    )

                Err e ->
                    ( model, Log.error (Decode.errorToString e) )

        _ ->
            --TODO: error
            ( model, Log.error ("in message from service: unknown title \"" ++ title ++ "\"") )


processRecurringTransactions : Model.Model -> ( Model.Model, Cmd Msg.Msg )
processRecurringTransactions model =
    let
        settings =
            model.settings

        recurring =
            settings.recurringTransactions
                |> List.map
                    (\t ->
                        let
                            d =
                                if Date.compare t.date model.today /= GT then
                                    Date.findNextDayOfMonth (Date.getDay t.date) model.today

                                else
                                    t.date
                        in
                        { t | date = d }
                    )

        newSettings =
            { settings
                | recurringTransactions = recurring
            }

        createTransacs t =
            if Date.compare t.date model.today == GT then
                []

            else
                createTransaction t
                    :: createTransacs { t | date = Date.incrementMonth t.date }

        cmds =
            model.settings.recurringTransactions
                |> List.filter
                    (\t -> Date.compare t.date model.today /= GT)
                |> List.concatMap
                    (\t -> createTransacs t)
    in
    ( { model | settings = newSettings }
    , if List.length cmds > 0 then
        Cmd.batch
            (cmds ++ [ storeSettings newSettings ])

      else
        Cmd.none
    )
