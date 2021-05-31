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


requestWholeDatabase : Cmd msg
requestWholeDatabase =
    Ports.send ( "request whole database", Encode.null )


storeSettings : Model.Settings -> Cmd msg
storeSettings settings =
    Ports.send ( "store settings", Model.encodeSettings settings )


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


createRecurringTransaction : Ledger.NewTransaction -> Cmd msg
createRecurringTransaction transaction =
    Ports.send
        ( "create recurring transaction"
        , Ledger.encodeNewTransaction transaction
        )


replaceRecurringTransaction : Ledger.Transaction -> Cmd msg
replaceRecurringTransaction transaction =
    Ports.send
        ( "replace recurring transaction"
        , Ledger.encodeTransaction transaction
        )


deleteRecurringTransaction : Int -> Cmd msg
deleteRecurringTransaction id =
    Ports.send
        ( "delete recurring transaction"
        , Encode.object
            [ ( "id", Encode.int id )
            ]
        )



-- FROM THE SERVICE WORKER


receive : Sub Msg.Msg
receive =
    Ports.receive (Msg.ForDatabase << Msg.DbFromService)


msgFromService : ( String, Decode.Value ) -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
msgFromService ( title, content ) model =
    case title of
        "start application" ->
            ( model, Ports.send ( "request whole database", Encode.null ) )

        "update whole database" ->
            case Decode.decodeValue decodeDB content of
                Ok db ->
                    ( { model
                        | settings = db.settings
                        , accounts = Dict.fromList db.accounts
                        , account = firstAccount db.accounts
                        , categories = Dict.fromList db.categories
                        , ledger = db.ledger
                        , recurring = db.recurring
                      }
                    , Cmd.none
                    )
                        |> upgradeSettingsToV2 content
                        |> processRecurringTransactions

                Err e ->
                    --TODO: error
                    ( model, Log.error ("while decoding whole database: " ++ Decode.errorToString e) )

        "update settings" ->
            case Decode.decodeValue Model.decodeSettings content of
                Ok settings ->
                    ( { model | settings = settings }, Cmd.none )

                Err e ->
                    --TODO: error
                    ( model, Log.error ("while decoding settings: " ++ Decode.errorToString e) )

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
                    , Cmd.none
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

        "update ledger" ->
            case Decode.decodeValue Ledger.decode content of
                Ok ledger ->
                    ( { model | ledger = ledger }
                    , Cmd.none
                    )

                Err e ->
                    ( model, Log.error (Decode.errorToString e) )

        "update recurring transactions" ->
            case Decode.decodeValue Ledger.decode content of
                Ok recurring ->
                    ( { model | recurring = recurring }, Cmd.none )

                Err e ->
                    ( model, Log.error (Decode.errorToString e) )

        _ ->
            --TODO: error
            ( model, Log.error ("in message from service: unknown title \"" ++ title ++ "\"") )



-- UTILITIES


upgradeSettingsToV2 : Decode.Value -> ( { a | settings : Model.Settings }, Cmd msg ) -> ( { a | settings : Model.Settings }, Cmd msg )
upgradeSettingsToV2 json ( model, previousCmds ) =
    let
        decoder =
            Decode.field "settings"
                (Decode.oneOf
                    [ Decode.field "recurringTransactions" (Decode.list Ledger.decodeNewTransaction)
                    , Decode.succeed []
                    ]
                )
    in
    case Decode.decodeValue decoder json of
        Ok [] ->
            ( model, previousCmds )

        Ok recurring ->
            let
                cmds =
                    recurring
                        |> List.map
                            (\t ->
                                createRecurringTransaction t
                            )
            in
            ( model, Cmd.batch (previousCmds :: storeSettings model.settings :: cmds) )

        Err e ->
            --TODO: error
            ( model
            , Cmd.batch
                [ previousCmds
                , Log.error ("while decoding whole database: " ++ Decode.errorToString e)
                ]
            )


decodeDB : Decode.Decoder { settings : Model.Settings, accounts : List ( Int, String ), categories : List ( Int, { name : String, icon : String } ), ledger : Ledger.Ledger, recurring : Ledger.Ledger }
decodeDB =
    Decode.map5
        (\s a c l r ->
            { settings = s
            , accounts = a
            , categories = c
            , ledger = l
            , recurring = r
            }
        )
        (Decode.field "settings" Model.decodeSettings)
        (Decode.field "accounts" (Decode.list Model.decodeAccount))
        (Decode.field "categories" (Decode.list Model.decodeCategory))
        (Decode.field "ledger" Ledger.decode)
        (Decode.field "recurring" Ledger.decode)


firstAccount : List ( Int, String ) -> Int
firstAccount accounts =
    case accounts of
        head :: _ ->
            Tuple.first head

        _ ->
            -1


processRecurringTransactions : ( Model.Model, Cmd Msg.Msg ) -> ( Model.Model, Cmd Msg.Msg )
processRecurringTransactions ( model, previousCmds ) =
    let
        activated =
            Ledger.getActivatedRecurringTransactions model.recurring model.today

        cmds =
            activated
                |> List.foldl
                    (\t cs ->
                        cs
                            ++ createAllDueTransactions (Ledger.newTransactionFromRecurring t)
                            ++ [ replaceRecurringTransaction
                                    { t | date = Date.findNextDayOfMonth (Date.getDay t.date) model.today }
                               ]
                    )
                    [ previousCmds ]

        createAllDueTransactions t =
            if Date.compare t.date model.today == GT then
                []

            else
                createTransaction t
                    :: createAllDueTransactions { t | date = Date.incrementMonth t.date }
    in
    ( model, Cmd.batch cmds )
