module Shiori_View exposing (..)

import Html exposing (Html)


map : List (Html.Html msg) -> List (Html ())
map =
    List.map <| Html.map (always ())
