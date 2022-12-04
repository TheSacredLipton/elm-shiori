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
                P.run functionCommentsParser mock1
                    |> Expect.equal (Ok [ ( "square", { codes = [ "square colors.red", "square colors.green" ], imports = [ "import tomtomtom" ] } ), ( "mori", { codes = [ "mori colors.red", "mori colors.green" ], imports = [ "import tomtomtomtoms" ] } ) ])

        -- |> Expect.equal (Err [])
        -- , test "elmParserTest2" <|
        --     \() ->
        --         P.run (elmParser "Main") mock2
        --             |> Expect.equal (Ok ( "Main", [ ( "square", [ "import Element exposing (..) ", "import Element exposing (..) ", "square colors.red", "square colors.green" ] ), ( "mori", [ "mori colors.red", "mori colors.green" ] ) ] ))
        -- |> Expect.equal (Err [])
        , test "elmParserTest3" <|
            \() ->
                P.run functionCommentsParser mock3
                    |> Expect.equal (Ok [])

        -- |> Expect.equal (Err [])
        -- , test "elmParserTest4" <|
        --     \() ->
        --         P.run (elmParser "Main") mock4
        --             -- |> Expect.equal (Ok ( "Main", [] ))
        --             |> Expect.equal (Err [])
        ]


importPasertTest =
    test "importPasertTest" <|
        \() ->
            -- P.run getImport "{-| j import Exposing (.. -} \n test: Tom"
            P.run functionCommentsParser mock4
                -- |> Expect.equal (Ok ( "test2", { codes = [ "test2 colors.green", "test2 colors.green" ], imports = [ "import Element exposing (..)", "import Element exposing (..)" ] } ))
                |> Expect.equal (Ok [ ( "test", { codes = [ "test2 colors.green", "test2 colors.green" ], imports = [ "import Element exposing (..)", "import Element exposing (..)" ] } ), ( "test2", { codes = [ "test2 colors.green" ], imports = [ "import ss" ] } ) ])


mock1 : String
mock1 =
    """
{-|
    import tomtomtom
    
    square

    :: square colors.red

    :: square colors.green


-}

square

{-|
    import tomtomtomtoms

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
    import Element exposing (..) 
    import Element exposing (..) 
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


mock4 : String
mock4 =
    """{-|
    
    import Element exposing (..)

    import Element exposing (..)

    :: test2 colors.green
    
    :: test2 colors.green



-}
test


{-|

    import ss

    :: test2 colors.green


-}

test2
"""
