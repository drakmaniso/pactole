module Update.Installation exposing (update)

import Database
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)


update : Msg.InstallMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.page of
        Model.InstallationPage installation ->
            case msg of
                Msg.ProceedWithInstall ->
                    case Money.fromInput False (Tuple.first installation.initialBalance) of
                        Ok initialBalance ->
                            ( { model | page = Model.CalendarPage }
                            , Database.proceedWithInstallation model
                                { firstAccount = installation.firstAccount
                                , initialBalance = initialBalance
                                , date = model.today
                                }
                            )

                        Err error ->
                            ( { model
                                | page =
                                    Model.InstallationPage
                                        { installation
                                            | initialBalance = ( Tuple.first installation.initialBalance, Just error )
                                        }
                              }
                            , Cmd.none
                            )

                Msg.ChangeInstallName newName ->
                    ( { model | page = Model.InstallationPage { installation | firstAccount = newName } }
                    , Cmd.none
                    )

                Msg.ChangeInstallBalance newBalance ->
                    ( { model | page = Model.InstallationPage { installation | initialBalance = ( newBalance, Nothing ) } }
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )
                |> Log.error "what?"
