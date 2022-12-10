module Shiori_View exposing (..)

import Html


map : List (Html.Html msg) -> List (Html.Html ())
map =
    List.map <| Html.map (always ())
