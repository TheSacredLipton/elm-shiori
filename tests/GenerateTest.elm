module GenerateTest exposing (..)

import Expect
import Generate exposing (..)
import Parser as P
import Test exposing (..)
import Elm.ToString


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


docTests : Test
docTests =
    describe "doc tests migrated from Generate.elm"
        [ test "getKeyword" <|
            \() ->
                P.run getKeyword "import Html exposing"
                    |> Expect.equal (Ok "import")
        , test "import_" <|
            \() ->
                Elm.ToString.declaration (import_ True "Url.Parser")
                    |> Expect.equal { body = "import Url.Parser exposing (..)\n\n\n", docs = "", imports = "", signature = "" }
        , test "genTypeRoute" <|
            \() ->
                Elm.ToString.declaration (genTypeRoute [("", [])])
                    |> Expect.equal { body = "type Route\n    = NotFound\n    |  String\n\n\n", docs = "", imports = "import\nimport", signature = "" }
        , test "genView" <|
            \() ->
                Elm.ToString.declaration (genView [("", [])])
                    |> Expect.equal { body = "view : Url.Url -> List (Html.Html ())\nview url =\n    case url |> toRoute of\n        NotFound ->\n            []\n    \n         str ->\n            case str of\n                _ ->\n                    []\n\n\n", docs = "", imports = "import Html\nimport Url", signature = "view : Url.Url -> List (Html.Html ())" }
        , test "helper2" <|
            \() ->
                Elm.ToString.expression (helper2 "" [("", { codes = [], imports = [] })])
                    |> Expect.equal { body = "case str of\n    \"\" ->\n        [] |> Shiori_View.map\n\n    _ ->\n        []", imports = "import\nimport", signature = "Infinite type inference loop!  Whoops.  This is an issue with elm-codegen.  If you can report this to the elm-codegen repo, that would be appreciated!" }
        , test "genRouteParser" <|
            \() ->
                Elm.ToString.declaration (genRouteParser [("", [])])
                    |> Expect.equal { body = "routeParser : Parser (Route -> b) b\nrouteParser =\n    [ map  <| s \"\" </> string ] |> oneOf\n\n\n", docs = "", imports = "import\nimport", signature = "routeParser : Parser (Route -> b) b" }
        , test "url_oneOf" <|
            \() ->
                Elm.ToString.expression url_oneOf
                    |> Expect.equal { body = "oneOf", imports = "import\nimport", signature = "List (Parser a b) -> Parser (Route -> b) b" }
        , test "genRouteParserHelper" <|
            \() ->
                genRouteParserHelper "Page.Home"
                    |> Expect.equal "map Page_Home <| s \"Page.Home\" </> string"
        , test "genToRoute" <|
            \() ->
                Elm.ToString.declaration genToRoute
                    |> Expect.equal { body = "toRoute : Url.Url -> Route\ntoRoute url =\n    url |> parse routeParser  |> Maybe.withDefault NotFound\n\n\n", docs = "", imports = "import Url", signature = "toRoute : Url.Url -> Route" }
        ]
