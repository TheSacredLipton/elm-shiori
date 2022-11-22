module GenerateTest exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Generate exposing (..)
import Parser as P
import Test exposing (..)


suite : Test
suite =
    describe "e"
        [ test "Example1" <|
            \() ->
                P.run elmParser mock
                    |> Expect.equal (Ok [ "square colors.red", "square colors.green", "square colors.blue" ])
        ]


mock =
    """
--
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

aaa

{-| 選択中は変化するボタン
-}
square : Color -> Element msg
square color =
    el
        [ width <| px 100
        , height <| px 100
        , Background.color color
        ]
        none

"""
