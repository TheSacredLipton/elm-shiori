module GenerateTest exposing (..)

import Element.Region exposing (description)
import Expect
import Generate exposing (..)
import Parser as P
import Test exposing (..)


elmParserTest : Test
elmParserTest =
    describe "elmParser Test"
        [ test "elmParserTest1" <|
            \() ->
                P.run (elmParser "Main") mock1
                    |> Expect.equal (Ok ( "Main", [ ( "mori", [ Code "mori colors.red", Code "mori colors.green" ] ), ( "square", [ Code "square colors.red", Code "square colors.green" ] ) ] ))

        -- |> Expect.equal (Err [])
        , test "elmParserTest2" <|
            \() ->
                P.run (elmParser "Main") mock2
                    |> Expect.equal (Ok ( "Main", [ ( "mori", [ Code "mori colors.red", Code "mori colors.green" ] ), ( "square", [ Import "import Element exposing (..) ", Import "import Element exposing (..) ", Code "square colors.red", Code "square colors.green" ] ) ] ))

        -- |> Expect.equal (Err [])
        , test "elmParserTest3" <|
            \() ->
                P.run (elmParser "Main") mock3
                    |> Expect.equal (Ok ( "Main", [] ))

        -- |> Expect.equal (Err [])
        ]


mock1 : String
mock1 =
    """
{-|
    square

    :: square colors.red

    :: square colors.green


-}

square

{-|


    :: mori colors.red

    :: mori colors.green


-}

mori
"""


mock2 : String
mock2 =
    """
{-|
    a
    !import Element exposing (..) 
    !import Element exposing (..) 
    b

    :: square colors.red

    :: square colors.green


-}

square
a = 1

{-|


    :: mori colors.red

    :: mori colors.green


-}

mori
"""


mock3 : String
mock3 =
    """
module Empty exposing (..)

{-| 
-}

empty: Element msg
empty =
    []
"""
