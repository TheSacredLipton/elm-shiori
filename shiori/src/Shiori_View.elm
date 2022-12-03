module Shiori_View exposing (..)

import Element exposing (Element, layout)
import Origami.Html exposing (Html, fromHtml)


map : List (Element msg) -> List (Html ())
map =
    List.map (layout [] >> fromHtml >> Origami.Html.map (always ()))



{-
   origami : List (Html msg) -> List View
   origami =
       List.map (Origami.Html.map (always ()))


   elmui : List (Element msg) -> List View
   elmui =
       List.map (layout [] >> fromHtml >> Origami.Html.map (always ()))


   html : List (Html.Html msg) -> List View
   html =
       List.map (fromHtml >> Origami.Html.map (always ()))


   elmcss : List (Html.Html msg) -> List View
   elmcss =
       List.map (fromHtml >> Origami.Html.map (always ()))
-}
