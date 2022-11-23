module Image exposing (..)

import Element exposing (..)


{-|

    ## img

    :: img

-}
img : Element msg
img =
    image [] { src = "/assets/shiori.png", description = "shiori.png" }
