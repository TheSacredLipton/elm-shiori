module Image exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


{-|

    :: image

-}
image : Html msg
image =
    img [ src "/assets/shiori.png" ] []
