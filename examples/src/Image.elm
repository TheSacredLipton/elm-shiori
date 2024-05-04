module Image exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


{-|

    <shiori> image

-}
image : Html msg
image =
    img [ src "/shiori.png" ] []
