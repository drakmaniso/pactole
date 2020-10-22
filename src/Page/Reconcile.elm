module Page.Reconcile exposing (view)

import Dict
import Element as E
import Element.Font as Font
import Ledger
import Money
import Page.Summary as Summary
import Shared
import Ui



-- VIEW


view : Shared.Model -> E.Element Shared.Msg
view shared =
    Ui.pageWithSidePanel []
        { panel =
            [ E.el
                [ E.width E.fill, E.height (E.fillPortion 1) ]
                (Summary.view shared)
            , E.el
                [ E.width E.fill, E.height (E.fillPortion 2) ]
                E.none
            ]
        , page =
            [ Ui.dateNavigationBar shared
            , E.el [ E.height E.fill ] E.none
            , E.el [ E.height E.fill ] E.none
            ]
        }
