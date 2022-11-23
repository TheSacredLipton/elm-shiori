module GenerateTest exposing (..)

import Dict
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Generate exposing (..)
import Parser as P
import Test exposing (..)


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



-- suite2 : Test
-- suite2 =
--     test "elmParser2" <|
--         \() ->
--             P.run elmParser2 mock2
--                 |> Expect.equal (Ok [ ( "mori", [ "mori colors.green", "mori colors.red" ] ), ( "square", [ "square colors.green", "square colors.red" ] ) ])


suite3 : Test
suite3 =
    test "elmParser3" <|
        \() ->
            P.run (elmParser "Main") mock2
                |> Expect.equal (Ok ( "Main", Dict.fromList [ ( "mori", [ "mori colors.green", "mori colors.red" ] ), ( "square", [ "square colors.green", "square colors.red" ] ) ] ))



-- |> Expect.equal (Ok [ ( "mori", [ "mori colors.green", "mori colors.red" ] ), ( "square", [ "square colors.green", "square colors.red" ] ) ])
-- |> Expect.equal (Err [])


mock2 =
    """
{-|
    fefwaf

    :: square colors.red

    :: square colors.green


-}

square
jfoiejwof

{-|


    :: mori colors.red

    :: mori colors.green


-}

mori
"""


mock3 =
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

{-|


    :: mori colors.red

    :: mori colors.green


-}

mori : Color -> Element msg
mori color =
    el
        [ width <| px 100
        , height <| px 100
        , Background.color color
        ]
        none

"""
