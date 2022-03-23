module Main exposing (init, keyDecoder, main, subscriptions, update, view)

import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Navigation
import Database
import Date
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Json.Decode as Decode
import Ledger
import Log
import Model
import Msg
import Page.Calendar as Calendar
import Page.Dialog as Dialog
import Page.Help as Help
import Page.Reconcile as Reconcile
import Page.Settings as Settings
import Page.Statistics as Statistics
import Task
import Ui
import Ui.Color as Color
import Url



-- MAIN


main : Program Decode.Value Model.Model Msg.Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        , onUrlChange = \_ -> Msg.NoOp
        , onUrlRequest = \_ -> Msg.NoOp
        }



-- INIT


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model.Model, Cmd Msg.Msg )
init flags _ _ =
    let
        day =
            case Decode.decodeValue (Decode.at [ "today", "day" ] Decode.int) flags of
                Ok v ->
                    v

                Err _ ->
                    --TODO
                    0

        month =
            case Decode.decodeValue (Decode.at [ "today", "month" ] Decode.int) flags of
                Ok v ->
                    v

                Err _ ->
                    --TODO
                    0

        year =
            case Decode.decodeValue (Decode.at [ "today", "year" ] Decode.int) flags of
                Ok v ->
                    v

                Err _ ->
                    --TODO
                    0

        ( today, cmd ) =
            case Date.fromParts { day = day, month = month, year = year } of
                Just d ->
                    ( d, Cmd.none )

                Nothing ->
                    ( Date.default, Log.error "init flags: invalid date for today" )

        width =
            Decode.decodeValue (Decode.at [ "width" ] Decode.int) flags |> Result.withDefault 800

        height =
            Decode.decodeValue (Decode.at [ "height" ] Decode.int) flags |> Result.withDefault 600

        hasStorageAPI =
            Decode.decodeValue (Decode.at [ "hasStorageAPI" ] Decode.bool) flags |> Result.withDefault False

        isStoragePersisted =
            Decode.decodeValue (Decode.at [ "isStoragePersisted" ] Decode.bool) flags |> Result.withDefault False
    in
    ( { settings =
            { categoriesEnabled = False
            , reconciliationEnabled = False
            , summaryEnabled = False
            , balanceWarning = 100
            , settingsLocked = True
            }
      , today = today
      , hasStorageAPI = hasStorageAPI
      , isPersistentStorageGranted = False
      , isStoragePersisted = isStoragePersisted
      , date = today
      , ledger = Ledger.empty
      , recurring = Ledger.empty
      , accounts = Dict.empty
      , account = -1 --TODO!!!
      , categories = Dict.empty
      , showFocus = False
      , page = Model.MainPage
      , dialog = Nothing
      , settingsDialog = Nothing
      , serviceVersion = "unknown"
      , device = Ui.device width height
      }
    , cmd
    )



-- UPDATE


update : Msg.Msg -> Model.Model -> ( Model.Model, Cmd Msg.Msg )
update msg model =
    case msg of
        Msg.ChangePage page ->
            ( { model | page = page }
            , Task.attempt (\_ -> Msg.NoOp) (Dom.blur "unfocus-on-page-change")
            )

        Msg.Close ->
            --TODO: delegate to Dialog?
            ( { model | dialog = Nothing, settingsDialog = Nothing }, Cmd.none )

        Msg.SelectDate date ->
            ( { model | date = date }, Cmd.none )

        Msg.SelectAccount accountID ->
            ( { model | account = accountID }, Cmd.none )

        Msg.KeyDown string ->
            if string == "Tab" then
                ( { model | showFocus = True }, Cmd.none )

            else
                ( model, Cmd.none )

        Msg.WindowResize size ->
            ( { model
                | device = Ui.device size.width size.height
              }
            , Cmd.none
            )

        Msg.ForDatabase m ->
            Database.update m model

        Msg.ForDialog m ->
            Dialog.update m model

        Msg.ForSettingsDialog m ->
            Settings.update m model

        Msg.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model.Model -> Sub Msg.Msg
subscriptions _ =
    Sub.batch
        [ Database.receive
        , Browser.Events.onKeyDown (keyDecoder Msg.KeyDown)
        , Browser.Events.onResize (\width height -> Msg.WindowResize { width = width, height = height })
        ]


keyDecoder : (String -> Msg.Msg) -> Decode.Decoder Msg.Msg
keyDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.map msg



-- VIEW


view : Model.Model -> Browser.Document Msg.Msg
view model =
    let
        activeDialog =
            case model.dialog of
                Just _ ->
                    Just (Dialog.view model)

                Nothing ->
                    model.settingsDialog |> Maybe.map (\_ -> Settings.viewDialog model)

        activePageParts =
            case model.page of
                Model.HelpPage ->
                    Help.view model

                Model.SettingsPage ->
                    Settings.view model

                Model.StatsPage ->
                    Statistics.view model

                Model.ReconcilePage ->
                    Reconcile.view model

                Model.MainPage ->
                    Calendar.view model

        activePage =
            pageWithSidePanel model
                { panel =
                    E.column
                        [ E.width E.fill
                        , E.height E.fill
                        , E.clipX
                        , E.clipY
                        ]
                        [ E.el
                            [ E.width E.fill, E.height (E.fillPortion 1) ]
                            activePageParts.summary
                        , Ui.ruler
                        , E.el
                            [ E.width E.fill, E.height (E.fillPortion 2) ]
                            activePageParts.detail
                        ]
                , page = activePageParts.main
                }
    in
    { title = "Pactole"
    , body =
        [ E.layoutWith
            { options =
                [ E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow =
                        if model.showFocus then
                            Just
                                { color = Color.focusColor
                                , offset = ( 0, 0 )
                                , blur = 0
                                , size = 4
                                }

                        else
                            Nothing
                    }
                ]
            }
            (case activeDialog of
                Just d ->
                    [ E.inFront
                        (E.el
                            [ E.width E.fill
                            , E.height E.fill
                            , Ui.fontFamily
                            , Font.color Color.neutral30
                            , E.padding 16
                            , E.scrollbarY
                            , E.behindContent
                                (Input.button
                                    [ E.width E.fill
                                    , E.height E.fill
                                    , Background.color (E.rgba 0 0 0 0.6)
                                    ]
                                    { label = E.none
                                    , onPress = Just Msg.Close
                                    }
                                )
                            ]
                            d
                        )
                    ]

                Nothing ->
                    [ E.inFront
                        (E.column []
                            []
                        )
                    ]
            )
            (E.column [ E.width E.fill, E.height E.fill, Background.color Color.warning60 ]
                [ if not model.isStoragePersisted then
                    E.row [ E.width E.fill ]
                        [ E.el
                            [ Font.color Color.white, Ui.normalFont, E.centerX, E.padding 3 ]
                            (E.text "Il y a un problème avec le stockage des données de l'application!")
                        ]

                  else
                    E.none
                , activePage
                ]
            )
        ]
    }


pageWithSidePanel : Model.Model -> { panel : E.Element Msg.Msg, page : E.Element Msg.Msg } -> E.Element Msg.Msg
pageWithSidePanel model { panel, page } =
    E.row
        [ E.width E.fill
        , E.height E.fill
        , E.clipX
        , E.clipY
        , Background.color Color.white
        , Ui.fontFamily
        , Ui.normalFont
        , Font.color Color.neutral30
        ]
        [ E.column
            [ E.width (E.fillPortion 1 |> E.minimum 450)
            , E.height E.fill
            , E.clipY
            , E.paddingXY 6 6
            ]
            [ navigationBar model
            , E.el
                [ E.width E.fill
                , E.height E.fill
                , E.clipY
                , E.paddingXY 6 6
                , E.alignTop
                ]
                panel
            ]
        , E.el
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            , E.clipY
            , E.paddingEach { top = 6, left = 0, bottom = 3, right = 6 }
            ]
            page
        ]


navigationBar model =
    let
        navigationButton { targetPage, label } =
            Input.button
                [ E.paddingXY 12 6
                , Background.color
                    (if model.page == targetPage then
                        Color.primary40

                     else
                        Color.primary95
                    )
                , Font.color
                    (if model.page == targetPage then
                        Color.white

                     else
                        Color.primary40
                    )
                , E.height E.fill
                , Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 32, bottomRight = 32 }
                ]
                { onPress = Just (Msg.ChangePage targetPage)
                , label = label
                }
    in
    E.row
        [ E.width E.fill
        , Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 32, bottomRight = 32 }
        , Background.color Color.primary95
        , Ui.smallerShadow
        ]
        [ navigationButton
            { targetPage = Model.MainPage
            , label = E.text "Pactole"
            }
        , if model.settings.summaryEnabled then
            navigationButton
                { targetPage = Model.StatsPage
                , label = E.text "Bilan"
                }

          else
            E.none
        , if model.settings.reconciliationEnabled then
            navigationButton
                { targetPage = Model.ReconcilePage
                , label = E.text "Pointer"
                }

          else
            E.none
        , E.el
            [ E.width E.fill
            , E.height E.fill
            ]
            E.none
        , if model.settings.settingsLocked then
            E.none

          else
            navigationButton
                { targetPage = Model.SettingsPage
                , label =
                    E.el [ Ui.iconFont, Ui.bigFont, E.centerX, E.paddingXY 0 0 ] (E.text "\u{F013}")
                }
        , navigationButton
            { targetPage = Model.HelpPage
            , label =
                E.el [ Ui.iconFont, Ui.bigFont, E.centerX, E.paddingXY 0 0 ] (E.text "\u{F059}")
            }
        ]
