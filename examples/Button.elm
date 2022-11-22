module Button exposing (..)

import Element exposing (..)
import Element.Input as Input


type Msg
    = Sample


{-|

    :: button

-}
button : Element Msg
button =
    Input.button [] { onPress = Just Sample, label = text "button" }
