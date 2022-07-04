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
    , fromServiceWorker
    , msgFromService
    , proceedWithInstallation
    , processRecurringTransactions
    , renameAccount
    , renameCategory
    , replaceRecurringTransaction
    , replaceTransaction
    , requestWholeDatabase
    , storeSettings
    , update
    )

import Date exposing (Date)
import Dict
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Log
import Model exposing (Model)
import Money exposing (Money)
import Msg exposing (Msg)
import Ports
import Ui



-- UPDATE


update : Msg.DatabaseMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.FromServiceWorker ( title, json ) ->
            msgFromService ( title, json ) model

        Msg.StoreSettings settings ->
            ( model, storeSettings settings )

        Msg.CheckTransaction transaction checked ->
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
    Ports.toServiceWorker ( "request whole database", Encode.null )


storeSettings : Model.Settings -> Cmd msg
storeSettings settings =
    Ports.toServiceWorker ( "store settings", Model.encodeSettings settings )


createAccount : String -> Cmd msg
createAccount name =
    Ports.toServiceWorker ( "create account", Encode.string name )


proceedWithInstallation : Model -> { wantSimplified : Bool } -> Cmd msg
proceedWithInstallation model data =
    let
        settings =
            if data.wantSimplified then
                Model.simplifiedDefaultSettings

            else
                Model.completeDefaultSettings
    in
    Ports.toServiceWorker
        ( "install database"
        , Model.encodeDatabase
            { serviceVersion = model.serviceVersion
            , accounts = [ ( 1, "(sans nom)" ) ]
            , categories =
                [ ( 1
                  , { name = "Maison"
                    , icon = "\u{F015}"
                    }
                  )
                , ( 2
                  , { name = "Santé"
                    , icon = "\u{F0F1}"
                    }
                  )
                , ( 3
                  , { name = "Nourriture"
                    , icon = "\u{F2E7}"
                    }
                  )
                , ( 4
                  , { name = "Vêtements"
                    , icon = "\u{F553}"
                    }
                  )
                , ( 5
                  , { name = "Transports"
                    , icon = "\u{F5E4}"
                    }
                  )
                , ( 6
                  , { name = "Loisirs"
                    , icon = "\u{F5CA}"
                    }
                  )
                , ( 7
                  , { name = "Banque"
                    , icon = "\u{F19C}"
                    }
                  )
                ]
            , ledger = Ledger.empty
            , recurring = Ledger.empty
            , settings = settings
            }
        )


renameAccount : Int -> String -> Cmd msg
renameAccount account newName =
    Ports.toServiceWorker
        ( "rename account"
        , Encode.object
            [ ( "id", Encode.int account )
            , ( "name", Encode.string newName )
            ]
        )


deleteAccount : Int -> Cmd msg
deleteAccount account =
    Ports.toServiceWorker
        ( "delete account"
        , Encode.int account
        )


createCategory : String -> String -> Cmd msg
createCategory name icon =
    Ports.toServiceWorker
        ( "create category"
        , Encode.object
            [ ( "name", Encode.string name )
            , ( "icon", Encode.string icon )
            ]
        )


renameCategory : Int -> String -> String -> Cmd msg
renameCategory id name icon =
    Ports.toServiceWorker
        ( "rename category"
        , Encode.object
            [ ( "id", Encode.int id )
            , ( "name", Encode.string name )
            , ( "icon", Encode.string icon )
            ]
        )


deleteCategory : Int -> Cmd msg
deleteCategory id =
    Ports.toServiceWorker
        ( "delete category"
        , Encode.int id
        )


createTransaction : Ledger.NewTransaction -> Cmd msg
createTransaction transaction =
    Ports.toServiceWorker
        ( "create transaction"
        , Ledger.encodeNewTransaction transaction
        )


replaceTransaction : Ledger.Transaction -> Cmd msg
replaceTransaction transaction =
    Ports.toServiceWorker
        ( "replace transaction"
        , Ledger.encodeTransaction transaction
        )


deleteTransaction : Int -> Cmd msg
deleteTransaction id =
    Ports.toServiceWorker
        ( "delete transaction"
        , Encode.object
            [ ( "id", Encode.int id )
            ]
        )


createRecurringTransaction : Ledger.NewTransaction -> Cmd msg
createRecurringTransaction transaction =
    Ports.toServiceWorker
        ( "create recurring transaction"
        , Ledger.encodeNewTransaction transaction
        )


replaceRecurringTransaction : Ledger.Transaction -> Cmd msg
replaceRecurringTransaction transaction =
    Ports.toServiceWorker
        ( "replace recurring transaction"
        , Ledger.encodeTransaction transaction
        )


deleteRecurringTransaction : Int -> Cmd msg
deleteRecurringTransaction id =
    Ports.toServiceWorker
        ( "delete recurring transaction"
        , Encode.object
            [ ( "id", Encode.int id )
            ]
        )



-- FROM THE SERVICE WORKER


fromServiceWorker : Sub Msg
fromServiceWorker =
    Ports.fromServiceWorker (Msg.ForDatabase << Msg.FromServiceWorker)


msgFromService : ( String, Decode.Value ) -> Model -> ( Model, Cmd Msg )
msgFromService ( title, content ) model =
    let
        defaultInstallationData =
            { wantSimplified = False
            }
    in
    case title of
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
                            | errors = model.errors ++ [ "Warning: persistent storage not granted!" ]
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
                        , account = Model.firstAccount db.accounts
                        , categories = Dict.fromList db.categories
                        , ledger = db.ledger
                        , recurring = db.recurring
                        , serviceVersion = db.serviceVersion
                        , page =
                            if List.isEmpty db.accounts then
                                Model.WelcomePage defaultInstallationData

                            else
                                Model.CalendarPage
                        , context =
                            Ui.classifyContext
                                { width = model.context.width
                                , height = model.context.height
                                , fontSize = db.settings.fontSize
                                , deviceClass = db.settings.deviceClass
                                , animationDisabled = db.settings.animationDisabled
                                }
                      }
                    , if not (List.isEmpty db.accounts) then
                        Ports.requestStoragePersistence ()

                      else
                        Cmd.none
                    )
                        |> processRecurringTransactions

                Err e ->
                    Log.error ("decoding database: " ++ Decode.errorToString e) ( model, Cmd.none )

        "update settings" ->
            case Decode.decodeValue Model.decodeSettings content of
                Ok settings ->
                    let
                        device =
                            model.context
                    in
                    ( { model
                        | settings = settings
                        , context =
                            Ui.classifyContext
                                { width = device.width
                                , height = device.height
                                , fontSize = settings.fontSize
                                , deviceClass = settings.deviceClass
                                , animationDisabled = settings.animationDisabled
                                }
                      }
                    , Cmd.none
                    )

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
                        , page = Model.WelcomePage defaultInstallationData
                      }
                    , Cmd.none
                    )

                Err e ->
                    Log.error ("decoding accounts: " ++ Decode.errorToString e) ( model, Cmd.none )

        "update categories" ->
            case Decode.decodeValue Model.decodeCategories content of
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
                    ( { model | errors = model.errors ++ [ "ERROR: " ++ msg ] }, Cmd.none )

                _ ->
                    ( { model | errors = model.errors ++ [ "ERROR: undecodable javascript" ] }, Cmd.none )

        _ ->
            Log.error ("unkown message from service: \"" ++ title ++ "\"") ( model, Cmd.none )



-- UTILITIES


decodeDB : Decode.Decoder Model.Database
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
        (Decode.field "categories" Model.decodeCategories)
        (Decode.field "ledger" Ledger.decode)
        (Decode.field "recurring" Ledger.decode)
        (Decode.field "serviceVersion" Decode.string)


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
