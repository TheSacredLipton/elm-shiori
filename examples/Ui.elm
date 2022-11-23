module Ui exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Input as Input


type Msg
    = ReplaceMe


colors =
    { red = rgb255 255 0 0
    , green = rgb255 0 255 0
    , blue = rgb255 0 0 255
    }


{-|

    :: square colors.red

    :: square colors.green

    :: square colors.blue

-}
square : Color -> Element msg
square color =
    el
        [ width <| px 100
        , height <| px 100
        , Background.color color
        ]
        none


{-|

    :: square2 colors.red

    :: square2 colors.green

    :: square2 colors.blue

-}
square2 : Color -> Element msg
square2 color =
    el
        [ width <| px 100
        , height <| px 100
        , Background.color color
        ]
        none
