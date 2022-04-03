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
import Html.Attributes
import Json.Decode as Decode
import Ledger
import Model exposing (Model)
import Msg exposing (Msg)
import Page.Calendar as Calendar
import Page.Diagnostics as Diagnostics
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

        isStoragePersisted =
            Decode.decodeValue (Decode.at [ "isStoragePersisted" ] Decode.bool) flags |> Result.withDefault False
    in
    ( { settings = Model.defaultSettings
      , today = today
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
      , device = Ui.classifyDevice width height
      , errors = []
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

        Msg.SelectDate date ->
            ( { model | date = date }, Cmd.none )

        Msg.SelectAccount accountID ->
            --TODO: check that accountID corresponds to an account
            ( { model | account = accountID }, Cmd.none )

        Msg.WindowResize size ->
            ( { model
                | device = Ui.classifyDevice size.width size.height
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

                Model.DiagnosticsPage ->
                    Diagnostics.viewContent model

        activePagePanel =
            case model.page of
                Model.LoadingPage ->
                    E.none

                Model.InstallationPage _ ->
                    E.none

                Model.HelpPage ->
                    logoPanel model

                Model.SettingsPage ->
                    logoPanel model

                Model.StatsPage ->
                    Statistics.viewPanel model

                Model.ReconcilePage ->
                    Reconcile.viewPanel model

                Model.MainPage ->
                    Calendar.viewPanel model

                Model.DiagnosticsPage ->
                    logoPanel model
    in
    case model.page of
        Model.LoadingPage ->
            document model activeDialog activePageContent

        Model.InstallationPage _ ->
            document model activeDialog activePageContent

        _ ->
            document model activeDialog <|
                pageWithSidePanel model
                    { panel = activePagePanel
                    , page = activePageContent
                    }


document : Model -> Maybe (E.Element Msg) -> E.Element Msg -> Browser.Document Msg
document model activeDialog activePage =
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
                            , Ui.fontFamily model.settings.font
                            , Ui.defaultFontSize model.device
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
                , Ui.fontFamily model.settings.font
                , Ui.defaultFontSize model.device
                , Font.color Color.neutral30
                , Background.color Color.white
                ]
                [ case ( model.page, model.isStoragePersisted ) of
                    ( Model.LoadingPage, _ ) ->
                        E.none

                    ( Model.InstallationPage _, _ ) ->
                        E.none

                    ( _, False ) ->
                        warningBanner "Attention: le stockage n'est pas persistant!"

                    ( _, True ) ->
                        E.none
                , activePage
                ]
            )
        ]
    }


warningBanner : String -> E.Element Msg
warningBanner txt =
    E.row
        [ E.width E.fill
        , E.padding 6
        , Background.color Color.warning60
        , E.htmlAttribute <| Html.Attributes.style "z-index" "3"
        , Ui.defaultShadow
        ]
        [ E.el [ E.width E.fill ] E.none
        , E.el
            [ Font.color Color.white
            , E.centerX
            , E.padding 3
            ]
            (E.text txt)
        , E.el [ E.width E.fill ] E.none
        ]


pageWithSidePanel : Model -> { panel : E.Element Msg, page : E.Element Msg } -> E.Element Msg
pageWithSidePanel model { panel, page } =
    E.row
        [ E.width E.fill
        , E.height E.fill
        , E.spacing 3
        ]
        [ E.column
            [ E.width (E.fillPortion 1)
            , E.height E.fill
            , E.htmlAttribute <|
                Html.Attributes.style "box-shadow"
                    """
                            0px 0px 32px 64px rgba(0, 0, 0, 0.02),
                            0px 0px 16px 32px rgba(0, 0, 0, 0.02),
                            0px 0px 8px 16px rgba(0, 0, 0, 0.02),
                            0px 0px 4px 8px rgba(0, 0, 0, 0.04),
                            0px 0px 2px 4px rgba(0, 0, 0, 0.08),
                            0px 0px 1px 2px rgba(0, 0, 0, 0.08)
                            """
            , E.htmlAttribute <| Html.Attributes.style "z-index" "2"
            ]
            [ navigationBar model
            , panel
            ]
        , E.el
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            , E.clipY
            ]
            page
        ]


navigationBar : Model -> E.Element Msg
navigationBar model =
    let
        navigationButton { targetPage, label } =
            Input.button
                [ E.paddingXY 6 6
                , Border.color Color.transparent
                , Background.color
                    (if model.page == targetPage then
                        Color.primary40

                     else
                        Color.primary85
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
                            Color.primary40

                         else
                            Color.primary90
                        )
                    ]
                , E.height E.fill
                , Border.width 4
                , Ui.focusVisibleOnly
                ]
                { onPress = Just (Msg.ChangePage targetPage)
                , label = label
                }
    in
    E.el
        [ E.width E.fill
        , Ui.fontFamily model.settings.font
        ]
        (E.row
            [ E.width E.fill
            , Background.color Color.primary85
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
            , case model.errors of
                [] ->
                    E.none

                _ ->
                    navigationButton
                        { targetPage = Model.DiagnosticsPage
                        , label = E.el [ Font.color Color.warning60, Ui.iconFont ] (E.text "\u{F071}")
                        }
            , if model.settings.settingsLocked then
                E.none

              else
                navigationButton
                    { targetPage = Model.SettingsPage
                    , label =
                        E.el [ Ui.iconFont, Ui.bigFont model.device, E.centerX, E.paddingXY 0 0 ] (E.text "\u{F013}")
                    }
            , navigationButton
                { targetPage = Model.HelpPage
                , label =
                    E.el [ Ui.iconFont, Ui.bigFont model.device, E.centerX, E.paddingXY 0 0 ] (E.text "\u{F059}")
                }
            ]
        )


logoPanel : Model -> E.Element Msg
logoPanel model =
    E.column [ E.width E.fill, E.height E.fill ]
        [ E.el [ E.width E.fill, E.height <| E.fillPortion 1 ]
            (E.row [ E.width E.fill, E.centerY ]
                [ E.el [ E.width E.fill, E.height E.fill ] E.none
                , E.image [ E.width (E.fillPortion 2) ]
                    { src = "images/icon-512x512.png"
                    , description = "Pactole Logo"
                    }
                , E.el [ E.width E.fill, E.height E.fill ] E.none
                ]
            )
        , E.el [ E.width E.fill, E.height <| E.fillPortion 2 ]
            (Input.button
                [ E.centerX
                , E.alignBottom
                , Ui.smallerFont model.device
                , Font.color Color.neutral70
                , E.padding 12
                , E.mouseOver [ Font.color Color.neutral50 ]
                , E.mouseDown [ Font.color Color.neutral20 ]
                ]
                { label = E.text ("version " ++ model.serviceVersion)
                , onPress = Just (Msg.ChangePage Model.DiagnosticsPage)
                }
            )
        ]
