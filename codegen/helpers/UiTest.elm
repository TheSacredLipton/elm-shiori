module UiTest exposing (UI, view)

{-| -}

import Browser
import Html


{-| -}
type alias UI =
    Program () () ()


{-| -}
view : Html.Html msg -> UI
view html =
    Browser.sandbox
        { init = ()
        , update = \_ _ -> ()
        , view =
            \_ ->
                Html.map (always ()) html
        }
