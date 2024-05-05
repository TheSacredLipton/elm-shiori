module Shiori_View exposing (..)

import Html exposing (Html)
import Element exposing (Element, layout)


map : List (Element msg) -> List (Html ())
map =
    List.map (layout [] >> Html.map (always ()))