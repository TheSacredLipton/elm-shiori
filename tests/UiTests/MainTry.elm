module UiTests.MainTry exposing (main)

import Browser
import Element exposing (..)
import Html exposing (Html)
import Main


uiview : Html () -> Program () () ()
uiview s =
    Browser.sandbox
        { init = ()
        , update = \_ _ -> ()
        , view =
            \_ ->
                s
        }



-- MSGは変換する必要あるかもな


main : Program () () ()
main =
    Main.try2 1
        |> layout []
        |> Html.map (always ())
        |> uiview
