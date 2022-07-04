module Update.Installation exposing (update)

import Database
import Log
import Model exposing (Model)
import Money
import Msg exposing (Msg)


update : Msg.WelcomeMsg -> Model -> ( Model, Cmd Msg )
update msg model =
    case model.page of
        Model.WelcomePage installation ->
            case msg of
                Msg.ProceedWithInstall ->
                    ( { model | page = Model.CalendarPage }
                    , Database.proceedWithInstallation model
                        { wantSimplified = installation.wantSimplified
                        }
                    )

                Msg.SetWantSimplified wantSimplified ->
                    ( { model | page = Model.WelcomePage { installation | wantSimplified = wantSimplified } }
                    , Cmd.none
                    )

        _ ->
            ( model, Cmd.none )
                |> Log.error "what?"
