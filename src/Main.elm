module Main exposing (init, keyDecoder, main, subscriptions, update, viewLandscapePage)

import Browser
import Browser.Dom as Dom
import Browser.Events
import Browser.Navigation as Navigation
import Database
import Date
import Dialog.Settings
import Dialog.Transaction as EditTransaction
import Dict
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Keyed as Keyed
import File
import File.Select
import Html.Attributes
import Json.Decode as Decode
import Json.Encode as Encode
import Ledger
import Log
import Model exposing (Model)
import Msg exposing (Msg)
import Page.Calendar as Calendar
import Page.Diagnostics as Diagnostics
import Page.Help as Help
import Page.Loading as Loading
import Page.Reconcile as Reconcile
import Page.Settings as Settings
import Page.Statistics as Statistics
import Page.Summary as Summary
import Page.Welcome as Installation
import Ports
import Task
import Ui
import Ui.Color as Color
import Update.Installation
import Update.Settings
import Update.Transaction
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
    ( { settings = Model.simplifiedDefaultSettings
      , today = today
      , isStoragePersisted = isStoragePersisted
      , monthDisplayed = Date.getMonthYear today
      , monthPrevious = Date.getMonthYear today
      , dateSelected = today
      , ledger = Ledger.empty
      , recurring = Ledger.empty
      , accounts = Dict.empty
      , account = -1 --TODO!!!
      , categories = Dict.empty
      , page = Model.LoadingPage
      , dialog = Nothing
      , serviceVersion = "unknown"
      , context =
            Ui.classifyContext
                { width = width
                , height = height
                , fontSize = 0
                , deviceClass = Ui.AutoClass
                , animationDisabled = False
                }
      , errors = []
      , nbMonthsDisplayed = 2
      , reconcileViewport = Nothing
      }
    , Cmd.none
    )



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg.OnApplicationStart () ->
            ( model, Ports.toServiceWorker ( "request whole database", Encode.null ) )

        Msg.ChangePage page ->
            let
                oldestUnchecked =
                    Ledger.getOldestTransactionWhere model.ledger
                        (\t -> not t.checked)

                nbMonthsDisplayed =
                    case oldestUnchecked of
                        Nothing ->
                            2

                        Just t ->
                            (1 + Date.getMonthDiff model.today t.date)
                                |> Basics.max 2
            in
            if model.page == Model.ReconcilePage then
                ( model
                , Dom.getViewportOf "reconcile-viewport"
                    |> Task.attempt (Msg.SetReconcileViewport page)
                )

            else
                ( { model
                    | page = page
                    , monthPrevious = model.monthDisplayed
                    , nbMonthsDisplayed = nbMonthsDisplayed
                  }
                , if page == Model.ReconcilePage then
                    let
                        ( x, y ) =
                            case model.reconcileViewport of
                                Just viewport ->
                                    ( viewport.viewport.x, viewport.viewport.y )

                                Nothing ->
                                    ( 0, 0 )
                    in
                    Dom.setViewportOf "reconcile-viewport" x y
                        |> Task.attempt (\_ -> Msg.NoOp)

                  else
                    Cmd.none
                )

        Msg.OpenDialog focus dialog ->
            let
                noPreviousDialog =
                    model.dialog == Nothing
            in
            ( { model | dialog = Just dialog }
            , case focus of
                Msg.FocusInput ->
                    Cmd.batch
                        [ if noPreviousDialog then
                            Ports.historyPushState ()

                          else
                            Cmd.none
                        , Task.attempt (\_ -> Msg.NoOp) (Dom.focus "dialog-focus")
                        ]

                Msg.DontFocusInput ->
                    if noPreviousDialog then
                        Ports.historyPushState ()

                    else
                        Cmd.none
            )

        Msg.ConfirmDialog ->
            case model.dialog of
                Just (Model.TransactionDialog data) ->
                    Update.Transaction.confirm model data

                Just (Model.DeleteTransactionDialog data) ->
                    Update.Transaction.confirmDelete model data

                _ ->
                    Update.Settings.confirm model

        Msg.CloseDialog ->
            ( { model | dialog = Nothing }, Ports.historyGo -1 )

        Msg.RequestImportFile ->
            ( model, File.Select.file [ ".pactole,.json" ] Msg.ReadImportFile )

        Msg.ReadImportFile file ->
            ( model, Task.perform Msg.ProcessImportFile (File.toString file) )

        Msg.ProcessImportFile content ->
            case Decode.decodeString Database.decodeDB content of
                Ok db ->
                    ( { model | dialog = Just <| Model.ImportDialog db }, Cmd.none )

                Err e ->
                    Log.error ("decoding database: " ++ Decode.errorToString e) <|
                        ( { model
                            | dialog =
                                Just <|
                                    Model.UserErrorDialog
                                        "Le fichier choisi ne semble pas être une sauvegarde Pactole."
                          }
                        , Cmd.none
                        )

        Msg.OnPopState () ->
            case ( model.dialog, model.page ) of
                ( Just _, _ ) ->
                    ( { model | dialog = Nothing, monthPrevious = model.monthDisplayed }, Cmd.none )

                ( Nothing, _ ) ->
                    ( model, Cmd.none )

        Msg.SelectDate date ->
            ( { model | dateSelected = date }, Cmd.none )

        Msg.DisplayMonth monthYear ->
            ( { model | monthDisplayed = monthYear, monthPrevious = model.monthDisplayed }, Cmd.none )

        Msg.IncreaseNbMonthsDisplayed ->
            ( { model | nbMonthsDisplayed = model.nbMonthsDisplayed + 1 }, Cmd.none )

        Msg.OnLeftSwipe () ->
            if model.page == Model.CalendarPage || model.page == Model.StatisticsPage then
                ( { model | monthDisplayed = Date.incrementMonthYear model.monthDisplayed, monthPrevious = model.monthDisplayed }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Msg.OnRightSwipe () ->
            if model.page == Model.CalendarPage || model.page == Model.StatisticsPage then
                ( { model | monthDisplayed = Date.decrementMonthYear model.monthDisplayed, monthPrevious = model.monthDisplayed }
                , Cmd.none
                )

            else
                ( model, Cmd.none )

        Msg.OnUserError errmsg ->
            if model.page == Model.CalendarPage || model.page == Model.StatisticsPage then
                ( { model | dialog = Just (Model.UserErrorDialog errmsg) }, Cmd.none )

            else
                ( model, Cmd.none )

        Msg.SelectAccount accountID ->
            --TODO: check that accountID corresponds to an account
            ( { model | account = accountID }, Cmd.none )

        Msg.WindowResize size ->
            let
                heightChange =
                    toFloat (model.context.height - size.height) / toFloat model.context.height

                newContext =
                    Ui.classifyContext
                        { width = size.width
                        , height = size.height
                        , fontSize = model.settings.fontSize
                        , deviceClass = model.settings.deviceClass
                        , animationDisabled = model.settings.animationDisabled
                        }
            in
            if size.width == model.context.width && abs heightChange > 0.1 then
                -- This is probably triggered by opening the on-screen keyboard
                ( model, Cmd.none )

            else
                ( { model | context = newContext }, Cmd.none )

        Msg.SetReconcileViewport page result ->
            case result of
                Ok viewport ->
                    ( { model
                        | page = page
                        , monthPrevious = model.monthDisplayed
                        , reconcileViewport = Just viewport
                      }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        Msg.ForWelcome m ->
            Update.Installation.update m model

        Msg.ForDatabase m ->
            Database.update m model

        Msg.ForTransaction m ->
            Update.Transaction.update m model

        Msg.ForSettings m ->
            Update.Settings.update m model

        Msg.NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Ports.onApplicationStart Msg.OnApplicationStart
        , Database.fromServiceWorker
        , Ports.onPopState Msg.OnPopState
        , Ports.onLeftSwipe Msg.OnLeftSwipe
        , Ports.onRightSwipe Msg.OnRightSwipe
        , Ports.onUserError Msg.OnUserError
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
        em =
            model.context.em

        device =
            model.context.device

        activePage =
            case device.orientation of
                E.Landscape ->
                    viewLandscapePage model

                E.Portrait ->
                    viewPortraitPage model

        activeDialog =
            if device.class == E.Phone || device.class == E.Tablet then
                model.dialog
                    |> Maybe.map
                        (\dialog ->
                            E.el
                                [ E.width E.fill
                                , E.height E.fill
                                , Ui.fontFamily model.settings.font
                                , Ui.defaultFontSize model.context
                                , Background.color Color.white
                                , Font.color Color.neutral20
                                , E.scrollbarY
                                ]
                            <|
                                viewDialog model dialog
                        )

            else
                model.dialog
                    |> Maybe.map
                        (\dialog ->
                            E.el
                                [ E.width <| E.minimum (32 * em) <| E.maximum (40 * em) <| E.shrink
                                , E.height <| E.minimum (5 * em) <| E.shrink
                                , E.centerX
                                , E.centerY
                                , Border.rounded (em // 4)
                                , E.htmlAttribute <| Html.Attributes.class "desktop-dialog-shadow"
                                , Ui.fontFamily model.settings.font
                                , Ui.defaultFontSize model.context
                                , Background.color Color.white
                                , Font.color Color.neutral20
                                , E.scrollbarY
                                ]
                            <|
                                viewDialog model dialog
                        )
    in
    document model
        { page = activePage
        , maybeDialog = activeDialog
        }



-- PAGES


viewLandscapePage : Model -> E.Element Msg
viewLandscapePage model =
    case model.page of
        Model.LoadingPage ->
            Loading.view model

        Model.WelcomePage data ->
            Installation.view model data

        Model.HelpPage ->
            pageWithSidePanel model
                { panel = logoPanel model
                , page =
                    E.column [ E.width E.fill, E.height E.fill ]
                        [ Ui.landscapePageTitle model.context Help.title
                        , Help.view model
                        ]
                }

        Model.SettingsPage ->
            pageWithSidePanel model
                { panel = logoPanel model
                , page =
                    E.column [ E.width E.fill, E.height E.fill ]
                        [ Ui.landscapePageTitle model.context Settings.title
                        , Settings.view model
                        ]
                }

        Model.StatisticsPage ->
            pageWithSidePanel model
                { panel = panelWithTwoParts { top = Summary.viewDesktop model, bottom = E.none }
                , page = Statistics.viewContent model
                }

        Model.ReconcilePage ->
            pageWithSidePanel model
                { panel = panelWithTwoParts { top = Summary.viewDesktop model, bottom = E.none }
                , page = Reconcile.viewContent model
                }

        Model.CalendarPage ->
            pageWithSidePanel model
                { panel =
                    panelWithTwoParts
                        { top = Summary.viewDesktop model
                        , bottom = Calendar.viewSelectedDate model
                        }
                , page = Calendar.viewContent model
                }

        Model.DiagnosticsPage ->
            pageWithSidePanel model
                { panel = logoPanel model
                , page =
                    E.column [ E.width E.fill, E.height E.fill ]
                        [ Ui.landscapePageTitle model.context Diagnostics.title
                        , Diagnostics.view model
                        ]
                }


viewPortraitPage : Model -> E.Element Msg
viewPortraitPage model =
    case model.page of
        Model.LoadingPage ->
            E.column [ E.width E.fill, E.height E.fill ]
                [ Loading.view model ]

        Model.WelcomePage data ->
            E.column [ E.width E.fill, E.height E.fill ]
                [ Installation.view model data ]

        Model.HelpPage ->
            pageWithTopNavBar model
                (Ui.portraitPageTitle model.context Help.title)
                []
                [ Help.view model ]

        Model.SettingsPage ->
            pageWithTopNavBar model
                (Ui.portraitPageTitle model.context Settings.title)
                []
                [ Settings.view model ]

        Model.StatisticsPage ->
            pageWithTopNavBar model
                (navigationBar model)
                [ Summary.viewMobile model ]
                [ Statistics.viewContent model
                ]

        Model.ReconcilePage ->
            pageWithTopNavBar model
                (navigationBar model)
                [ Summary.viewMobile model ]
                [ Reconcile.viewContent model
                ]

        Model.CalendarPage ->
            pageWithTopNavBar model
                (navigationBar model)
                [ Summary.viewMobile model ]
                [ E.el [ E.width E.fill, E.height <| E.fillPortion 1 ] <|
                    Calendar.viewContent model
                , E.el [ E.width E.fill, E.height <| E.fillPortion 1 ] <|
                    Calendar.viewSelectedDate model
                ]

        Model.DiagnosticsPage ->
            pageWithTopNavBar model
                (Ui.portraitPageTitle model.context Diagnostics.title)
                []
                [ Diagnostics.view model ]


viewDialog : Model -> Model.Dialog -> E.Element Msg
viewDialog model dialog =
    case dialog of
        Model.TransactionDialog data ->
            EditTransaction.view model data

        Model.DeleteTransactionDialog data ->
            EditTransaction.viewDeleteTransaction model data

        Model.AccountDialog data ->
            Dialog.Settings.viewAccountDialog model data

        Model.DeleteAccountDialog data ->
            Dialog.Settings.viewDeleteAccountDialog model data

        Model.CategoryDialog data ->
            Dialog.Settings.viewCategoryDialog model data

        Model.DeleteCategoryDialog data ->
            Dialog.Settings.viewDeleteCategoryDialog model data

        Model.RecurringDialog data ->
            Dialog.Settings.viewRecurringDialog model data

        Model.ImportDialog data ->
            Dialog.Settings.viewImportDialog model data

        Model.ExportDialog data ->
            Dialog.Settings.viewExportDialog model data

        Model.FontDialog data ->
            Dialog.Settings.viewFontDialog model data

        Model.UserErrorDialog data ->
            Dialog.Settings.viewUserErrorDialog model data



-- VIEW PARTS


document : Model -> { page : E.Element Msg, maybeDialog : Maybe (E.Element Msg) } -> Browser.Document Msg
document model { page, maybeDialog } =
    { title = "Pactole"
    , body =
        [ E.layoutWith
            { options =
                E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                    :: (case model.context.device.class of
                            E.Phone ->
                                [ E.noHover ]

                            E.Tablet ->
                                [ E.noHover ]

                            _ ->
                                []
                       )
            }
            []
            (E.column
                [ E.width E.fill
                , E.height E.fill
                , Ui.fontFamily model.settings.font
                , Ui.defaultFontSize model.context
                , Font.color Color.neutral20
                , Background.color Color.white
                , case maybeDialog of
                    Just dialog ->
                        E.inFront
                            (E.el
                                [ E.width E.fill
                                , E.height E.fill
                                , E.htmlAttribute <| Html.Attributes.style "z-index" "3"
                                , E.behindContent
                                    (Input.button
                                        [ E.width E.fill
                                        , E.height E.fill
                                        , Background.color (E.rgba 0 0 0 0.6)
                                        ]
                                        { label = E.none
                                        , onPress = Just Msg.CloseDialog
                                        }
                                    )
                                ]
                                dialog
                            )

                    Nothing ->
                        E.inFront E.none
                ]
                [ case ( model.page, model.isStoragePersisted ) of
                    ( Model.LoadingPage, _ ) ->
                        E.none

                    ( Model.WelcomePage _, _ ) ->
                        E.none

                    ( _, False ) ->
                        warningBanner "Attention: le stockage des données n'a pas été autorisé! Veuillez mettre cette page dans vos favoris."

                    ( _, True ) ->
                        E.none
                , page
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
        [ E.paragraph
            [ Font.color Color.white
            , E.centerX
            , E.padding 3
            , Font.center
            ]
            [ E.text txt ]
        ]


pageWithSidePanel : Model -> { panel : E.Element Msg, page : E.Element Msg } -> E.Element Msg
pageWithSidePanel model { panel, page } =
    E.row
        [ E.width <| E.fill
        , E.height E.fill
        , E.spacing 3
        , E.clip
        ]
        [ E.column
            [ E.width <| E.minimum (15 * model.context.em) <| E.fillPortion 1
            , E.height E.fill
            , E.htmlAttribute <| Html.Attributes.class "panel-shadow"
            , E.htmlAttribute <| Html.Attributes.style "z-index" "2"
            ]
            [ navigationBar model
            , panel
            ]
        , Keyed.el
            [ E.width (E.fillPortion 3)
            , E.height E.fill
            ]
            ( Model.pageKey model.page, page )
        ]


panelWithTwoParts : { top : E.Element msg, bottom : E.Element msg } -> E.Element msg
panelWithTwoParts { top, bottom } =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.clipY
        ]
        [ E.el
            [ E.width E.fill, E.height (E.fillPortion 1) ]
            top
        , E.el
            [ E.width E.fill, E.height (E.fillPortion 3) ]
            bottom
        ]


pageWithTopNavBar : Model -> E.Element Msg -> List (E.Element Msg) -> List (E.Element Msg) -> E.Element Msg
pageWithTopNavBar model navbar topElements elements =
    Keyed.el [ E.width E.fill, E.height E.fill ]
        ( Model.pageKey model.page
        , E.column
            [ E.width E.fill
            , E.height E.fill
            , E.clipX
            , E.scrollbarY
            ]
            [ E.column
                [ E.width E.fill
                , E.htmlAttribute <| Html.Attributes.class "panel-shadow"
                , E.htmlAttribute <| Html.Attributes.style "z-index" "2"
                ]
                (navbar :: topElements)
            , E.column
                [ E.width E.fill
                , E.height E.fill
                , E.spacing <| model.context.em // 4
                , E.padding 0
                ]
                elements
            ]
        )


navigationBar : Model -> E.Element Msg
navigationBar model =
    let
        em =
            model.context.em

        width =
            case model.context.device.orientation of
                E.Landscape ->
                    model.context.width // 3

                E.Portrait ->
                    model.context.width

        compact =
            model.settings.summaryEnabled
                && model.settings.reconciliationEnabled
                && (width < 22 * em)

        navigationButton { targetPage, label, isActive } =
            Input.button
                [ E.padding <| model.context.em // 2
                , Border.color Color.transparent
                , Background.color
                    (if isActive model.page then
                        Color.primary40

                     else
                        Color.primary85
                    )
                , Font.color
                    (if isActive model.page then
                        Color.white

                     else
                        Color.primary40
                    )
                , E.mouseDown
                    [ Background.color
                        (if isActive model.page then
                            Color.primary30

                         else
                            Color.primary70
                        )
                    ]
                , E.mouseOver
                    [ Background.color
                        (if isActive model.page then
                            Color.primary40

                         else
                            Color.primary80
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
    Keyed.row
        [ E.width E.fill
        , Background.color Color.primary85
        , Ui.fontFamily model.settings.font
        ]
        [ ( "home button"
          , navigationButton
                { targetPage = Model.CalendarPage
                , label = E.text "Pactole"
                , isActive = \p -> p == Model.CalendarPage
                }
          )
        , ( "statistics button"
          , if model.settings.summaryEnabled then
                navigationButton
                    { targetPage = Model.StatisticsPage
                    , label =
                        if compact then
                            E.el [ Ui.iconFont, Ui.bigFont model.context ] (E.text "\u{F200}")
                            -- F200, E0E3

                        else
                            E.text "Bilan"
                    , isActive = \p -> p == Model.StatisticsPage
                    }

            else
                E.none
          )
        , ( "reconcile button"
          , if model.settings.reconciliationEnabled then
                navigationButton
                    { targetPage = Model.ReconcilePage
                    , label =
                        if compact then
                            E.el [ Ui.iconFont, Ui.bigFont model.context ] (E.text "\u{F0AE}")
                            -- F0AE

                        else
                            E.text "Pointer"
                    , isActive = \p -> p == Model.ReconcilePage
                    }

            else
                E.none
          )
        , ( "navbar filler"
          , E.el
                [ E.width E.fill
                , E.height E.fill
                ]
                E.none
          )
        , ( "diagnostics button"
          , case model.errors of
                [] ->
                    E.none

                _ ->
                    navigationButton
                        { targetPage = Model.DiagnosticsPage
                        , label = E.el [ Font.color Color.warning60, Ui.iconFont, Ui.bigFont model.context ] (E.text "\u{F071}")
                        , isActive = \p -> p == Model.DiagnosticsPage
                        }
          )
        , ( "help button"
          , navigationButton
                { targetPage = Model.HelpPage
                , label =
                    E.el [ Ui.iconFont, Ui.bigFont model.context, E.centerX, E.paddingXY 0 0 ] (E.text "\u{F059}")
                , isActive = \p -> p == Model.HelpPage || p == Model.SettingsPage
                }
          )
        ]


logoPanel : Model -> E.Element Msg
logoPanel _ =
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
            E.none
        ]
