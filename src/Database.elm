module Database exposing
    ( createAccount
    , createCategory
    , createRecurringTransaction
    , createTransaction
    , decodeDB
    , deleteAccount
    , deleteCategory
    , deleteRecurringTransaction
    , deleteTransaction
    , exportDatabase
    , exportFileName
    , firstAccount
    , importDatabase
    , msgFromService
    , proceedWithInstallation
    , processRecurringTransactions
    , receive
    , renameAccount
    , renameCategory
    , replaceRecurringTransaction
    , replaceTransaction
    , requestWholeDatabase
    , storeSettings
    , update
    , upgradeSettingsToV2
    )

import Date exposing (Date)
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger exposing (Ledger)
import Log
import Model exposing (Model)
import Money exposing (Money)
import Msg exposing (Msg)
import Ports



-- UPDATE


update : Msg.DatabaseMsg -> Model -> ( Model, Cmd Msg )
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


proceedWithInstallation : Model -> { firstAccount : String, initialBalance : Money, date : Date } -> Cmd msg
proceedWithInstallation model data =
    Ports.send
        ( "broadcast import database"
        , Encode.object
            [ ( "serviceVersion", Encode.string model.serviceVersion )
            , ( "accounts"
              , Encode.list Encode.object
                    [ [ ( "id", Encode.int 1 ), ( "name", Encode.string data.firstAccount ) ]
                    ]
              )
            , ( "ledger"
              , Encode.list Ledger.encodeTransaction
                    [ { id = 1
                      , account = 1
                      , date = data.date
                      , amount = data.initialBalance
                      , description = "Solde initial"
                      , category = 0
                      , checked = False
                      }
                    ]
              )
            , ( "recurring", Encode.list Encode.object [] )
            , ( "categories"
              , Encode.list Encode.object
                    [ [ ( "id", Encode.int 1 )
                      , ( "name", Encode.string "Maison" )
                      , ( "icon", Encode.string "\u{F015}" )
                      ]
                    , [ ( "id", Encode.int 2 )
                      , ( "name", Encode.string "Santé" )
                      , ( "icon", Encode.string "\u{F0F1}" )
                      ]
                    , [ ( "id", Encode.int 3 )
                      , ( "name", Encode.string "Nourriture" )
                      , ( "icon", Encode.string "\u{F2E7}" )
                      ]
                    , [ ( "id", Encode.int 4 )
                      , ( "name", Encode.string "Vêtements" )
                      , ( "icon", Encode.string "\u{F553}" )
                      ]
                    , [ ( "id", Encode.int 5 )
                      , ( "name", Encode.string "Transports" )
                      , ( "icon", Encode.string "\u{F5E4}" )
                      ]
                    , [ ( "id", Encode.int 6 )
                      , ( "name", Encode.string "Loisirs" )
                      , ( "icon", Encode.string "\u{F5CA}" )
                      ]
                    , [ ( "id", Encode.int 7 )
                      , ( "name", Encode.string "Banque" )
                      , ( "icon", Encode.string "\u{F19C}" )
                      ]
                    ]
              )
            , ( "settings"
              , Model.encodeSettings
                    { categoriesEnabled = False
                    , reconciliationEnabled = False
                    , summaryEnabled = False
                    , balanceWarning = 100
                    , settingsLocked = model.settings.settingsLocked
                    }
              )
            ]
        )


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


exportFileName : Model -> String
exportFileName model =
    let
        today =
            model.today

        year =
            Date.getYear today |> String.fromInt |> String.padLeft 4 '0'

        month =
            Date.getMonth today |> Date.getMonthNumber |> String.fromInt |> String.padLeft 2 '0'

        day =
            Date.getDay today |> String.fromInt |> String.padLeft 2 '0'
    in
    "Pactole-" ++ year ++ "-" ++ month ++ "-" ++ day ++ ".json"


exportDatabase : Model -> Cmd msg
exportDatabase model =
    Ports.send
        ( "export database"
        , Encode.object
            [ ( "filename", Encode.string <| exportFileName model )
            , ( "settings", Model.encodeSettings model.settings )
            , ( "recurring", Ledger.encode model.recurring )
            , ( "accounts", Model.encodeAccounts model.accounts )
            , ( "categories", Model.encodeCategories model.categories )
            , ( "ledger", Ledger.encode model.ledger )
            , ( "serviceVersion", Encode.string model.serviceVersion )
            ]
        )


importDatabase : Cmd msg
importDatabase =
    Ports.send
        ( "select import"
        , Encode.object []
        )



-- FROM THE SERVICE WORKER


receive : Sub Msg
receive =
    Ports.receive (Msg.ForDatabase << Msg.DbFromService)


msgFromService : ( String, Decode.Value ) -> Model -> ( Model, Cmd Msg )
msgFromService ( title, content ) model =
    let
        defaultInstallationData =
            { firstAccount = "Mon compte"
            , initialBalance = ( "", Nothing )
            }
    in
    case title of
        "start application" ->
            ( model, Ports.send ( "request whole database", Encode.null ) )

        "persistent storage granted" ->
            case Decode.decodeValue (Decode.at [ "granted" ] Decode.bool) content of
                Ok granted ->
                    if granted then
                        ( { model
                            | isStoragePersisted = True
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | error = Just "le stockage persistant n'a pas été autorisé!"
                            , isStoragePersisted = False
                          }
                        , Cmd.none
                        )

                Err e ->
                    Log.error ("decoding database: " ++ Decode.errorToString e) ( model, Cmd.none )

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
                        , serviceVersion = db.serviceVersion
                        , page =
                            if List.isEmpty db.accounts then
                                Model.InstallationPage defaultInstallationData

                            else
                                Model.MainPage
                      }
                    , if not (List.isEmpty db.accounts) then
                        Ports.send ( "request storage persistence", Encode.null )

                      else
                        Cmd.none
                    )
                        |> upgradeSettingsToV2 content
                        |> processRecurringTransactions

                Err e ->
                    Log.error ("decoding database: " ++ Decode.errorToString e) ( model, Cmd.none )

        "update settings" ->
            case Decode.decodeValue Model.decodeSettings content of
                Ok settings ->
                    ( { model | settings = settings }, Cmd.none )

                Err e ->
                    Log.error ("decoding settings: " ++ Decode.errorToString e) ( model, Cmd.none )

        "update accounts" ->
            case Decode.decodeValue (Decode.list Model.decodeAccount) content of
                Ok (head :: tail) ->
                    let
                        accounts =
                            head :: tail

                        accountID =
                            Tuple.first head
                    in
                    ( { model | accounts = Dict.fromList accounts, account = accountID }
                    , Cmd.none
                    )

                Ok [] ->
                    ( { model
                        | accounts = Dict.empty
                        , account = -1
                        , page = Model.InstallationPage defaultInstallationData
                      }
                    , Cmd.none
                    )

                Err e ->
                    Log.error ("decoding accounts: " ++ Decode.errorToString e) ( model, Cmd.none )

        "update categories" ->
            case Decode.decodeValue (Decode.list Model.decodeCategory) content of
                Ok categories ->
                    ( { model | categories = Dict.fromList categories }, Cmd.none )

                Err e ->
                    Log.error ("decoding categories: " ++ Decode.errorToString e) ( model, Cmd.none )

        "update ledger" ->
            case Decode.decodeValue Ledger.decode content of
                Ok ledger ->
                    ( { model | ledger = ledger }
                    , Cmd.none
                    )

                Err e ->
                    Log.error (Decode.errorToString e) ( model, Cmd.none )

        "update recurring transactions" ->
            case Decode.decodeValue Ledger.decode content of
                Ok recurring ->
                    ( { model | recurring = recurring }, Cmd.none )

                Err e ->
                    Log.error (Decode.errorToString e) ( model, Cmd.none )

        "javascript error" ->
            case Decode.decodeValue Decode.string content of
                Ok msg ->
                    ( { model | error = Just msg }, Cmd.none )

                _ ->
                    ( { model | error = Just "undecodable javascript error" }, Cmd.none )

        _ ->
            Log.error ("unkown message from service: \"" ++ title ++ "\"") ( model, Cmd.none )



-- UTILITIES


upgradeSettingsToV2 : Decode.Value -> ( Model, Cmd msg ) -> ( Model, Cmd msg )
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
            Log.error ("decoding database: " ++ Decode.errorToString e)
                ( model
                , previousCmds
                )


decodeDB : Decode.Decoder { settings : Model.Settings, accounts : List ( Int, String ), categories : List ( Int, { name : String, icon : String } ), ledger : Ledger, recurring : Ledger, serviceVersion : String }
decodeDB =
    Decode.map6
        (\s a c l r srd ->
            { settings = s
            , accounts = a
            , categories = c
            , ledger = l
            , recurring = r
            , serviceVersion = srd
            }
        )
        (Decode.field "settings" Model.decodeSettings)
        (Decode.field "accounts" (Decode.list Model.decodeAccount))
        (Decode.field "categories" (Decode.list Model.decodeCategory))
        (Decode.field "ledger" Ledger.decode)
        (Decode.field "recurring" Ledger.decode)
        (Decode.field "serviceVersion" Decode.string)


firstAccount : List ( Int, String ) -> Int
firstAccount accounts =
    case accounts of
        head :: _ ->
            Tuple.first head

        _ ->
            -1


processRecurringTransactions : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
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
