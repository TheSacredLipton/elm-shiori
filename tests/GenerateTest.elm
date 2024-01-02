module GenerateTest exposing (..)

import Expect
import Generate exposing (..)
import Parser as P
import Test exposing (..)


{-| TODO: 名前
-}
elmParserTest : Test
elmParserTest =
    describe "elmParser Test"
        [ test "elmParserTest1" <|
            \() ->
                P.run functionCommentsParser mock1
                    |> Expect.equal (Ok [ ( "square", { codes = [ "square colors.red", "square colors.green" ], imports = [ "import tomtomtom" ] } ), ( "mori", { codes = [ "mori colors.red", "mori colors.green" ], imports = [ "import tomtomtomtoms" ] } ) ])

        -- |> Expect.equal (Err [])
        , test "elmParserTest2" <|
            \() ->
                P.run functionCommentsParser mock2
                    |> Expect.equal (Ok [ ( "square", { codes = [ "square colors.red", "square colors.green" ], imports = [ "import Element exposing (..)", "import Element exposing (..)" ] } ), ( "mori", { codes = [ "mori colors.red", "mori colors.green" ], imports = [] } ) ])

        -- |> Expect.equal (Err [])
        , test "elmParserTest3" <|
            \() ->
                P.run functionCommentsParser mock3
                    |> Expect.equal (Ok [])

        -- |> Expect.equal (Err [])
        , test "elmParserTest4" <|
            \() ->
                P.run functionCommentsParser mock4
                    |> Expect.equal (Ok [ ( "test", { codes = [ "test2 colors.green", "test2 colors.green" ], imports = [ "import Element exposing (..)", "import Element exposing (..)" ] } ), ( "test2", { codes = [ "test2 colors.green" ], imports = [ "import ss" ] } ) ])

        -- |> Expect.equal (Err [])
        ]


mock1 : String
mock1 =
    """
{-|
    import tomtomtom
    
    square

    <shiori> square colors.red

    <shiori> square colors.green


-}

square

{-|
    import tomtomtomtoms

    <shiori> mori colors.red

    <shiori> mori colors.green


-}

mori
"""


mock2 : String
mock2 =
    """
{-|
    a
    import Element exposing (..) 
    import Element exposing (..) 
    b

    <shiori> square colors.red

    <shiori> square colors.green


-}

square
a = 1

{-|


    <shiori> mori colors.red

    <shiori> mori colors.green


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


mock4 : String
mock4 =
    """{-|
    
    import Element exposing (..)

    import Element exposing (..)

    <shiori> test2 colors.green
    
    <shiori> test2 colors.green



-}
test


{-|

    import ss

    <shiori> test2 colors.green


-}

test2
"""
