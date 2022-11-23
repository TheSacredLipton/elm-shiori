module View exposing (..)

import Element exposing (..)


type alias View =
    Element ()


map : List (Element msg) -> List View
map =
    List.map (Element.map (always ()))
