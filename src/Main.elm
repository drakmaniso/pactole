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
import Model exposing (Model)
import Msg exposing (Msg)
import Page.Calendar as Calendar
import Page.Dialog as Dialog
import Page.Help as Help
import Page.Installation as Installation
import Page.Loading as Loading
import Page.Reconcile as Reconcile
import Page.Settings as Settings
import Page.Statistics as Statistics
import Task
import Ui
import Ui.Color as Color
import Url



-- MAIN


main : Program Decode.Value Model Msg
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


init : Decode.Value -> Url.Url -> Navigation.Key -> ( Model, Cmd Msg )
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

        today =
            case Date.fromParts { day = day, month = month, year = year } of
                Just d ->
                    d

                Nothing ->
                    --TODO:
                    -- ( Date.default, Log.error "init flags: invalid date for today" )
                    Date.default

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
            , settingsLocked = False
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
      , page = Model.LoadingPage
      , dialog = Nothing
      , settingsDialog = Nothing
      , serviceVersion = "unknown"
      , device = Ui.device width height
      , error = Nothing
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.ChangePage page ->
            ( { model | page = page }
            , Task.attempt (\_ -> Msg.NoOp) (Dom.blur "unfocus-on-page-change")
            )

        Msg.Close ->
            ( { model | dialog = Nothing, settingsDialog = Nothing }, Cmd.none )

        Msg.CloseErrorBanner ->
            ( { model | error = Nothing }, Cmd.none )

        Msg.SelectDate date ->
            ( { model | date = date }, Cmd.none )

        Msg.SelectAccount accountID ->
            --TODO: check that accountID corresponds to an account
            ( { model | account = accountID }, Cmd.none )

        Msg.WindowResize size ->
            ( { model
                | device = Ui.device size.width size.height
              }
            , Cmd.none
            )

        Msg.ForInstallation m ->
            Installation.update m model

        Msg.ForDatabase m ->
            Database.update m model

        Msg.ForDialog m ->
            Dialog.update m model

        Msg.ForSettingsDialog m ->
            Settings.update m model

        Msg.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Database.receive
        , Browser.Events.onResize (\width height -> Msg.WindowResize { width = width, height = height })
        ]


keyDecoder : (String -> Msg) -> Decode.Decoder Msg
keyDecoder msg =
    Decode.field "key" Decode.string
        |> Decode.map msg



-- VIEW


view : Model -> Browser.Document Msg
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
                Model.LoadingPage ->
                    Loading.view model

                Model.InstallationPage installation ->
                    Installation.view model installation

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
    document model activePage activeDialog


document : Model -> E.Element Msg -> Maybe (E.Element Msg) -> Browser.Document Msg
document model activePage activeDialog =
    { title = "Pactole"
    , body =
        [ E.layoutWith
            { options =
                [ E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
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
                            , E.padding 0
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
            (E.column [ E.width E.fill, E.height E.fill ]
                [ if not (Dict.isEmpty model.accounts) && not model.isStoragePersisted then
                    errorBanner "Attention: le stockage n'est pas persistant!" Nothing

                  else
                    E.none
                , case model.error of
                    Just error ->
                        errorBanner ("Erreur: " ++ error) (Just Msg.CloseErrorBanner)

                    _ ->
                        E.none
                , activePage
                ]
            )
        ]
    }


errorBanner : String -> Maybe Msg -> E.Element Msg
errorBanner error maybeCloseMsg =
    E.row [ E.width E.fill, E.padding 6, Background.color Color.warning60 ]
        [ E.el [ E.width (E.px 32) ] E.none
        , E.el [ E.width E.fill ] E.none
        , Ui.errorIcon
        , E.el
            [ Font.color Color.white
            , Ui.normalFont
            , E.centerX
            , E.padding 3
            ]
            (E.text error)
        , Ui.errorIcon
        , E.el [ E.width E.fill ] E.none
        , case maybeCloseMsg of
            Just closeMsg ->
                Input.button
                    [ Background.color Color.transparent
                    , Ui.normalFont
                    , Font.color Color.white
                    , Font.center
                    , E.padding 3
                    , E.width (E.px 32)
                    , E.height (E.px 32)
                    , Border.rounded 32
                    , E.mouseDown [ Background.color Color.warning50 ]
                    , E.mouseOver [ Background.color Color.warning70 ]
                    ]
                    { onPress = Just closeMsg
                    , label = Ui.closeIcon
                    }

            Nothing ->
                E.el [ E.width (E.px 32) ] E.none
        ]


pageWithSidePanel : Model -> { panel : E.Element Msg, page : E.Element Msg } -> E.Element Msg
pageWithSidePanel model { panel, page } =
    let
        minLeftSize =
            case ( model.settings.summaryEnabled, model.settings.reconciliationEnabled ) of
                ( True, True ) ->
                    450

                ( True, False ) ->
                    360

                ( False, True ) ->
                    360

                ( False, False ) ->
                    320
    in
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
            [ E.width (E.fillPortion 1 |> E.minimum minLeftSize)
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


navigationBar : Model -> E.Element Msg
navigationBar model =
    let
        navigationButton { targetPage, label } =
            Input.button
                [ E.paddingXY 6 2
                , Border.color Color.transparent
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
                , Border.width 4
                , Ui.focusVisibleOnly
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
        (case model.page of
            Model.LoadingPage ->
                [ E.el [ E.paddingXY 12 6, Font.color Color.primary40, E.centerX ] (E.text "Chargement...") ]

            Model.InstallationPage _ ->
                [ E.el [ E.paddingXY 12 6, Font.bold, Font.color Color.primary40, E.centerX ] (E.text "Pactole") ]

            _ ->
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
        )
