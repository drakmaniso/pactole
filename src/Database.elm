module Database exposing (..)

import Date
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Log
import Model
import Money
import Msg
import Ports



-- UPDATE


update : Msg.DatabaseMsg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.FromService ( title, json ) ->
            msgFromService ( title, json ) model

        Msg.CreateAccount name ->
            ( model, createAccount name )

        Msg.CreateCategory name icon ->
            ( model, createCategory name icon )

        Msg.StoreSettings settings ->
            ( model, storeSettings settings )

        Msg.CheckTransaction transaction checked ->
            ( model
            , replaceTransaction
                model.account
                { id = transaction.id
                , date = transaction.date
                , amount = transaction.amount
                , description = transaction.description
                , category = transaction.category
                , checked = checked
                }
            )



-- TO THE SERVICE WORKER


requestAccounts =
    Ports.send ( "request accounts", Encode.object [] )


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


requestCategories =
    Ports.send ( "request categories", Encode.object [] )


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


requestLedger : Int -> Cmd msg
requestLedger account =
    Ports.send ( "request ledger", Encode.int account )


createTransaction : Maybe Int -> Ledger.NewTransaction -> Cmd msg
createTransaction maybeAccount transaction =
    case maybeAccount of
        Just account ->
            Ports.send
                ( "create transaction"
                , Ledger.encodeNewTransaction account transaction
                )

        Nothing ->
            Log.error "create transaction: no current account"


replaceTransaction : Maybe Int -> Ledger.Transaction -> Cmd msg
replaceTransaction maybeAccount transaction =
    case maybeAccount of
        Just account ->
            Ports.send
                ( "replace transaction"
                , Ledger.encodeTransaction account transaction
                )

        Nothing ->
            Log.error "replace transaction: no current account"


deleteTransaction : Maybe Int -> Int -> Cmd msg
deleteTransaction account id =
    case account of
        Just acc ->
            Ports.send
                ( "delete transaction"
                , Encode.object
                    [ ( "account", Encode.int acc )
                    , ( "id", Encode.int id )
                    ]
                )

        Nothing ->
            Log.error "delete transaction: no current account"


requestSettings =
    Ports.send ( "request settings", Encode.object [] )


storeSettings : Model.Settings -> Cmd msg
storeSettings settings =
    Ports.send ( "store settings", Model.encodeSettings settings )



-- FROM THE SERVICE WORKER


receive : Sub Msg.Msg
receive =
    Ports.receive (Msg.ForDatabase << Msg.FromService)


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
                    ( { model | accounts = Dict.fromList accounts, account = Just accountID }
                    , requestLedger accountID
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

        "invalidate ledger" ->
            case ( model.account, Decode.decodeValue Decode.int content ) of
                ( Just currentID, Ok updatedID ) ->
                    if updatedID == currentID then
                        ( model, requestLedger updatedID )

                    else
                        ( model, Cmd.none )

                ( Nothing, _ ) ->
                    ( model, Cmd.none )

                ( _, Err e ) ->
                    ( model, Log.error (Decode.errorToString e) )

        "update ledger" ->
            case Decode.decodeValue Ledger.decode content of
                Ok ledger ->
                    ( { model | ledger = ledger }
                    , Cmd.none
                    )

                Err e ->
                    ( model, Log.error (Decode.errorToString e) )

        {-
           "invalidate settings" ->
               case Decode.decodeValue Model.decodeSettings content of
                   Ok settings ->
                       ( { model | settings = settings }
                       , Cmd.none
                       )
            Err e ->
                ( model, Log.error (Decode.errorToString e) )
        -}
        _ ->
            --TODO: error
            ( model, Log.error ("in message from service: unknown title \"" ++ title ++ "\"") )


processRecurringTransactions model =
    let
        settings =
            model.settings

        recurring =
            settings.recurringTransactions
                |> List.map
                    (\( a, t ) ->
                        let
                            d =
                                if Date.compare t.date model.today /= GT then
                                    Date.findNextDayOfMonth (Date.getDay t.date) model.today

                                else
                                    t.date
                        in
                        ( a, { t | date = d } )
                    )

        newSettings =
            { settings
                | recurringTransactions = recurring
            }

        createTransacs a t =
            if Date.compare t.date model.today == GT then
                []

            else
                createTransaction (Just a) (Debug.log "*** RECURRING TRANSACTION PROCESSED: " t)
                    :: createTransacs a { t | date = Date.incrementMonth t.date }

        cmds =
            model.settings.recurringTransactions
                |> List.filter
                    (\( _, t ) -> Date.compare t.date model.today /= GT)
                |> List.concatMap
                    (\( a, t ) -> createTransacs a t)
    in
    ( { model | settings = newSettings }
    , if List.length cmds > 0 then
        Cmd.batch
            (cmds ++ [ storeSettings newSettings ])

      else
        Cmd.none
    )
