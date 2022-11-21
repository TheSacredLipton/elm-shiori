module Ui exposing (..)

import Element exposing (..)
import Element.Input as Input


type Msg
    = ReplaceMe


{-|

    :: layout [] <| try 1

    :: layout [] <| try 2

    :: layout [] <| try 3

-}
try : Int -> Element msg
try i =
    text <| String.fromInt i



{-|

    :: layout [] <| try2 1

    :: layout [] <| try2 2

    :: layout [] <| try2 3

-}
try2 : Int -> Element Msg
try2 i =
    Input.button [] { label = text "ok", onPress = Just ReplaceMe }
