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
import Money
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
      , topBar = False
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

        Msg.ChangeLayout l ->
            ( { model | topBar = l }, Cmd.none )

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

        activePageContent =
            case model.page of
                Model.LoadingPage ->
                    Loading.viewContent model

                Model.InstallationPage installation ->
                    Installation.viewContent model installation

                Model.HelpPage ->
                    Help.viewContent model

                Model.SettingsPage ->
                    Settings.viewContent model

                Model.StatsPage ->
                    Statistics.viewContent model

                Model.ReconcilePage ->
                    Reconcile.viewContent model

                Model.MainPage ->
                    Calendar.viewContent model

        activePagePanel =
            case model.page of
                Model.LoadingPage ->
                    Loading.viewPanel model

                Model.InstallationPage installation ->
                    Installation.viewPanel model installation

                Model.HelpPage ->
                    Help.viewPanel model

                Model.SettingsPage ->
                    Settings.viewPanel model

                Model.StatsPage ->
                    Statistics.viewPanel model

                Model.ReconcilePage ->
                    Reconcile.viewPanel model

                Model.MainPage ->
                    Calendar.viewPanel model

        activePage =
            pageWithSidePanel model
                { panel = activePagePanel
                , page = activePageContent
                }
    in
    if model.topBar && model.page /= Model.MainPage then
        document model activePageContent activeDialog

    else
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
            (E.column
                [ E.width E.fill
                , E.height E.fill
                , Ui.fontFamily
                , Ui.normalFont
                , Font.color Color.neutral30
                ]
                [ if not (Dict.isEmpty model.accounts) && not model.isStoragePersisted then
                    errorBanner "Attention: le stockage n'est pas persistant!" Nothing

                  else
                    E.none
                , case model.error of
                    Just error ->
                        errorBanner ("Erreur: " ++ error) (Just Msg.CloseErrorBanner)

                    _ ->
                        E.none
                , if model.topBar then
                    navigationBar model

                  else
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
                    , E.alignTop
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
            [ E.width (E.fillPortion 1)
            , E.height E.fill
            , E.clipX
            , E.clipY
            ]
            [ if not model.topBar then
                navigationBar model

              else
                E.none
            , panel
            ]
        , E.el
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            , E.clipX
            , E.clipY
            ]
            page
        ]


navigationBar : Model -> E.Element Msg
navigationBar model =
    let
        roundedBorders =
            if model.topBar then
                Border.rounded 0

            else
                Border.roundEach { topLeft = 32, bottomLeft = 32, topRight = 32, bottomRight = 32 }

        navigationButton { targetPage, label } =
            Input.button
                [ E.paddingXY 6 2
                , Border.color Color.transparent
                , Background.color
                    (if model.page == targetPage then
                        Color.primary40

                     else
                        Color.primary90
                    )
                , Font.color
                    (if model.page == targetPage then
                        Color.white

                     else
                        Color.primary40
                    )
                , E.mouseDown
                    [ Background.color
                        (if model.page == targetPage then
                            Color.primary30

                         else
                            Color.primary80
                        )
                    ]
                , E.mouseOver
                    [ Background.color
                        (if model.page == targetPage then
                            Color.primary50

                         else
                            Color.primary95
                        )
                    ]
                , E.height E.fill
                , roundedBorders
                , Border.width 4
                , Ui.focusVisibleOnly
                ]
                { onPress = Just (Msg.ChangePage targetPage)
                , label = label
                }
    in
    E.el
        [ E.width E.fill
        , if model.topBar then
            E.paddingEach { left = 0, right = 0, top = 0, bottom = 6 }

          else
            E.padding 3
        , Ui.normalFont
        , Ui.fontFamily
        ]
        (E.row
            [ E.width E.fill
            , roundedBorders
            , Background.color Color.primary90
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
                    , if model.topBar then
                        viewBalance model

                      else
                        E.el
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
        )


viewBalance : Model -> E.Element msg
viewBalance model =
    let
        balance =
            Ledger.getBalance model.ledger model.account model.today

        parts =
            Money.toStrings balance

        sign =
            if parts.sign == "+" then
                ""

            else
                "-"

        color =
            if Money.isGreaterThan balance 0 then
                Color.neutral30

            else
                Color.warning60
    in
    E.paragraph
        [ Font.center, Ui.bigFont, Font.color color, Ui.notSelectable ]
        [ E.el [ Font.bold ] (E.text (Model.accountName model.account model))
        , E.text ": "
        , if Money.isGreaterThan balance model.settings.balanceWarning then
            E.none

          else
            Ui.warningIcon
        , E.el
            [ Ui.bigFont
            , Font.bold
            , E.centerX
            ]
            (E.text (sign ++ parts.units))
        , E.el
            [ Ui.normalFont
            , Font.bold
            , E.alignBottom
            , E.paddingEach { top = 0, bottom = 2, left = 0, right = 0 }
            , E.centerX
            ]
            (E.text ("," ++ parts.cents))
        , E.el
            [ Ui.normalFont
            , E.alignTop
            , E.paddingEach { top = 2, bottom = 0, left = 4, right = 0 }
            , E.centerX
            ]
            (E.text "€")
        , if Money.isGreaterThan balance model.settings.balanceWarning then
            E.none

          else
            Ui.warningIcon
        ]
