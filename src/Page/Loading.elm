module Page.Loading exposing (view)

import Element as E
import Model exposing (Model)
import Msg exposing (Msg)


view :
    Model
    ->
        { summary : E.Element Msg
        , detail : E.Element Msg
        , main : E.Element Msg
        }
view _ =
    { summary = E.none
    , detail = E.none
    , main = E.none
    }
