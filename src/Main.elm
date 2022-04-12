module Main exposing (init, keyDecoder, main, subscriptions, update, viewDesktopPage)

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
import Html
import Html.Attributes
import Json.Decode as Decode
import Ledger
import Model exposing (Model)
import Msg exposing (Msg)
import Page.Calendar as Calendar
import Page.Diagnostics as Diagnostics
import Page.Help as Help
import Page.Installation as Installation
import Page.Loading as Loading
import Page.Reconcile as Reconcile
import Page.Settings as Settings
import Page.Statistics as Statistics
import Page.Summary as Summary
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
      , serviceVersion = "unknown"
      , context = Ui.classifyContext { width = width, height = height, fontSize = 0 }
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

        Msg.CloseDialog ->
            ( { model | dialog = Nothing }, Ports.closeDialog () )

        Msg.SelectDate date ->
            ( { model | date = date }, Cmd.none )

        Msg.SelectAccount accountID ->
            --TODO: check that accountID corresponds to an account
            ( { model | account = accountID }, Cmd.none )

        Msg.WindowResize size ->
            let
                heightChange =
                    toFloat (model.context.height - size.height) / toFloat model.context.height

                newContext =
                    Ui.classifyContext { width = size.width, height = size.height, fontSize = model.settings.fontSize }
            in
            if size.width == model.context.width && heightChange > 0.1 then
                -- This is probably triggered by opening the on-screen keyboard
                ( model, Cmd.none )

            else
                ( { model | context = newContext }, Cmd.none )

        Msg.ForInstallation m ->
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
    case model.context.device.orientation of
        E.Landscape ->
            viewDesktop model

        E.Portrait ->
            viewMobile model



-- DESKTOP VIEW


viewDesktop : Model -> Browser.Document Msg
viewDesktop model =
    let
        activePage =
            viewDesktopPage model

        activeDialog =
            model.dialog |> Maybe.map (viewDialog model)
    in
    { title = "Pactole"
    , body =
        [ pageHtml model activePage
        , dialogHtml model activeDialog
        ]
    }


viewDesktopPage : Model -> E.Element Msg
viewDesktopPage model =
    case model.page of
        Model.LoadingPage ->
            Loading.view model

        Model.InstallationPage data ->
            Installation.view model data

        Model.HelpPage ->
            pageWithSidePanel model
                { panel = logoPanel model
                , page = Help.view model
                }

        Model.SettingsPage ->
            pageWithSidePanel model
                { panel = logoPanel model
                , page = Settings.view model
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
                { panel = panelWithTwoParts { top = Summary.viewDesktop model, bottom = Calendar.dayView model }
                , page = Calendar.viewMonth model
                }

        Model.DiagnosticsPage ->
            pageWithSidePanel model
                { panel = logoPanel model
                , page = Diagnostics.view model
                }


viewDialog : Model -> Model.Dialog -> E.Element Msg
viewDialog model dialog =
    case dialog of
        Model.TransactionDialog _ ->
            EditTransaction.view model

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

        Model.ImportDialog ->
            Dialog.Settings.viewImportDialog model

        Model.ExportDialog ->
            Dialog.Settings.viewExportDialog model

        Model.FontDialog data ->
            Dialog.Settings.viewFontDialog model data

        Model.UserErrorDialog data ->
            Dialog.Settings.viewUserErrorDialog model data



-- MOBILE VIEW


viewMobile : Model -> Browser.Document Msg
viewMobile model =
    case model.dialog of
        Nothing ->
            { title = "Pactole"
            , body = [ pageHtml model <| viewMobilePage model, mobileDialogHtml model Nothing ]
            }

        Just dialog ->
            { title = "Pactole"
            , body =
                [ pageHtml model <| E.none
                , mobileDialogHtml model <|
                    Just <|
                        E.column [ E.width E.fill, E.height E.fill ]
                            [ mobileDialogNavigationBar model
                            , viewDialog model dialog
                            ]
                ]
            }


viewMobilePage : Model -> E.Element Msg
viewMobilePage model =
    case model.page of
        Model.LoadingPage ->
            E.column [ E.width E.fill, E.height E.fill ]
                [ Loading.view model ]

        Model.InstallationPage data ->
            E.column [ E.width E.fill, E.height E.fill ]
                [ Installation.view model data ]

        Model.HelpPage ->
            pageWithTopNavBar model [] [ Help.view model ]

        Model.SettingsPage ->
            pageWithTopNavBar model [] [ Settings.view model ]

        Model.StatisticsPage ->
            pageWithTopNavBar model
                [ Summary.viewMobile model ]
                [ Statistics.viewContent model
                ]

        Model.ReconcilePage ->
            pageWithTopNavBar model
                [ Summary.viewMobile model ]
                [ Reconcile.viewContent model
                ]

        Model.CalendarPage ->
            pageWithTopNavBar model
                [ Summary.viewMobile model ]
                (if False then
                    [ E.el [ E.width E.fill, E.height <| E.fillPortion 1 ] <|
                        Calendar.viewWeek model
                    , E.el [ E.width E.fill, E.height <| E.fillPortion 2 ] <|
                        Calendar.dayView model
                    ]

                 else
                    [ E.el [ E.width E.fill, E.height <| E.fillPortion 1 ] <|
                        Calendar.viewMonth model
                    , E.el [ E.width E.fill, E.height <| E.fillPortion 1 ] <|
                        Calendar.dayView model
                    ]
                )

        Model.DiagnosticsPage ->
            pageWithTopNavBar model [] [ Diagnostics.view model ]



-- VIEW PARTS


pageHtml : Model -> E.Element Msg -> Html.Html Msg
pageHtml model element =
    E.layoutWith
        { options =
            [ E.focusStyle
                { borderColor = Nothing
                , backgroundColor = Nothing
                , shadow = Nothing
                }
            ]
        }
        []
        (E.column
            [ E.width E.fill
            , E.height E.fill
            , Ui.fontFamily model.settings.font
            , Ui.defaultFontSize model.context
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
            , element
            ]
        )


dialogHtml : Model -> Maybe (E.Element Msg) -> Html.Html Msg
dialogHtml model maybeElement =
    let
        em =
            model.context.em
    in
    Html.node "dialog"
        [ Html.Attributes.id "dialog"
        , Html.Attributes.class "dialog"
        ]
        [ E.layoutWith
            { options =
                [ E.noStaticStyleSheet
                , E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            []
            (E.el
                [ E.width <| E.minimum (32 * em) <| E.maximum (40 * em) <| E.shrink
                , E.height <| E.minimum (5 * em) <| E.shrink
                , Ui.fontFamily model.settings.font
                , Ui.defaultFontSize model.context
                , Background.color Color.white
                , Font.color Color.neutral30
                , E.paddingXY (2 * em) em
                , E.scrollbarY
                ]
             <|
                case maybeElement of
                    Just e ->
                        e

                    Nothing ->
                        E.none
            )
        ]


mobileDialogHtml : Model -> Maybe (E.Element Msg) -> Html.Html Msg
mobileDialogHtml model maybeElement =
    Html.node "dialog"
        [ Html.Attributes.id "dialog"
        , Html.Attributes.class "mobile-dialog"
        ]
        [ E.layoutWith
            { options =
                [ E.noStaticStyleSheet
                , E.focusStyle
                    { borderColor = Nothing
                    , backgroundColor = Nothing
                    , shadow = Nothing
                    }
                ]
            }
            []
            (E.el
                [ E.width <| E.fill
                , E.height <| E.fill
                , Ui.fontFamily model.settings.font
                , Ui.defaultFontSize model.context
                , Background.color Color.white
                , Font.color Color.neutral30
                , E.clip
                ]
             <|
                case maybeElement of
                    Just e ->
                        e

                    Nothing ->
                        E.none
            )
        ]


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
            , E.htmlAttribute <| Html.Attributes.class "panel-shadow"
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
            [ E.width E.fill, E.height (E.fillPortion 2) ]
            bottom
        ]


pageWithTopNavBar : Model -> List (E.Element Msg) -> List (E.Element Msg) -> E.Element Msg
pageWithTopNavBar model topElements elements =
    E.column
        [ E.width E.fill
        , E.height E.fill
        , E.spacing <| model.context.em // 2
        ]
        (E.column
            [ E.width E.fill
            , E.htmlAttribute <| Html.Attributes.class "panel-shadow"
            ]
            (navigationBar model :: topElements)
            :: elements
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

        optional flag s =
            if flag then
                s

            else
                0

        compact =
            width
                < (6
                    + optional model.settings.summaryEnabled 6
                    + optional model.settings.reconciliationEnabled 6
                    + optional (not model.settings.settingsLocked) 2
                  )
                * em

        extraCompact =
            width < 14 * em

        navigationButton { targetPage, label } =
            Input.button
                [ E.padding <| model.context.em // 4
                , Ui.transition
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
    Keyed.row
        [ E.width E.fill
        , Background.color Color.primary85
        , Ui.fontFamily model.settings.font
        ]
        [ ( "home button"
          , navigationButton
                { targetPage = Model.CalendarPage
                , label =
                    if extraCompact then
                        -- E.image [ E.width <| E.px <| model.context.bigEm ]
                        --     { src = "images/icon-512x512.png"
                        --     , description = "Pactole Logo"
                        --     }
                        E.el [ Ui.iconFont, Ui.bigFont model.context ] (E.text "\u{F133}")
                        -- F4D3, F153, F133

                    else
                        E.text "Pactole"
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
                        }
          )
        , ( "settings button"
          , if model.settings.settingsLocked then
                E.none

            else
                navigationButton
                    { targetPage = Model.SettingsPage
                    , label =
                        E.el [ Ui.iconFont, Ui.bigFont model.context, E.centerX, E.paddingXY 0 0 ] (E.text "\u{F013}")
                    }
          )
        , ( "help button"
          , navigationButton
                { targetPage = Model.HelpPage
                , label =
                    E.el [ Ui.iconFont, Ui.bigFont model.context, E.centerX, E.paddingXY 0 0 ] (E.text "\u{F059}")
                }
          )
        ]


mobileDialogNavigationBar : Model -> E.Element Msg
mobileDialogNavigationBar model =
    E.row
        [ E.width E.fill
        , Background.color Color.primary85
        , Ui.fontFamily model.settings.font
        ]
        [ Input.button
            [ E.paddingXY 6 6
            , Border.color Color.transparent
            , Background.color Color.primary85
            , Font.color Color.primary40
            , E.mouseDown [ Background.color Color.primary80 ]
            , E.mouseOver [ Background.color Color.primary90 ]
            , E.height E.fill
            , Border.width 4
            , Ui.focusVisibleOnly
            ]
            { onPress = Just Msg.CloseDialog
            , label = E.row [] [ E.el [ Ui.bigFont model.context ] Ui.backIcon, E.text "  Retour" ]
            }
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
