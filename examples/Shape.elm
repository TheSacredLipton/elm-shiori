module Shape exposing (..)

import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
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

    :: circle colors.red

    :: circle colors.green

    :: circle colors.blue

-}
circle : Color -> Element msg
circle color =
    el
        [ width <| px 100
        , height <| px 100
        , Background.color color
        , Border.rounded 50
        ]
        none


{-|

    :: heightTest colors.red

-}
heightTest : Color -> Element msg
heightTest color =
    el
        [ width <| px 100
        , height <| px 1000
        , Background.color color
        ]
        none
