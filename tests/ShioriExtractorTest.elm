module ShioriExtractorTest exposing (all)

import Review.Test
import ShioriExtractor exposing (rule)
import Test exposing (Test, describe, test)


all : Test
all =
    describe "ShioriExtractor"
        [ test "should report error when function documentation contains <shiori> tag (with closed tag)" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    <shiori> square colors.red </shiori>
-}
square : Int
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "SHIORI_EXTRACT:{\"funcName\":\"square\",\"codes\":[{\"name\":\"\",\"code\":\"square colors.red\"}],\"imports\":[]}"
                            , details = [ "Contains shiori tag" ]
                            , under = "{-|\n    <shiori> square colors.red </shiori>\n-}"
                            }
                        ]
        , test "should extract name attribute from <shiori name=\"...\">" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    <shiori name="Custom Square"> square colors.red </shiori>
-}
square : Int
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "SHIORI_EXTRACT:{\"funcName\":\"square\",\"codes\":[{\"name\":\"Custom Square\",\"code\":\"square colors.red\"}],\"imports\":[]}"
                            , details = [ "Contains shiori tag" ]
                            , under = "{-|\n    <shiori name=\"Custom Square\"> square colors.red </shiori>\n-}"
                            }
                        ]
        , test "should not report error when documentation does not contain <shiori> tag" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    some documentation
-}
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should ignore shiori tag when there is no closed tag" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    <shiori> square colors.red
-}
square : Int
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        , test "should handle same-line closed tag" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    <shiori> square colors.red </shiori>
-}
square : Int
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "SHIORI_EXTRACT:{\"funcName\":\"square\",\"codes\":[{\"name\":\"\",\"code\":\"square colors.red\"}],\"imports\":[]}"
                            , details = [ "Contains shiori tag" ]
                            , under = "{-|\n    <shiori> square colors.red </shiori>\n-}"
                            }
                        ]
        , test "should handle multi-line closed tags" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    <shiori>
    view
        { model = Clipboard.init
        , targetId = "test"
        }
    </shiori>
-}
view : Int
view = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "SHIORI_EXTRACT:{\"funcName\":\"view\",\"codes\":[{\"name\":\"\",\"code\":\"view\\n        { model = Clipboard.init\\n        , targetId = \\\"test\\\"\\n        }\"}],\"imports\":[]}"
                            , details = [ "Contains shiori tag" ]
                            , under = "{-|\n    <shiori>\n    view\n        { model = Clipboard.init\n        , targetId = \"test\"\n        }\n    </shiori>\n-}"
                            }
                        ]
        , test "should extract imports from documentation comment" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    import Color
    import Element exposing (El)

    <shiori> square Color.red </shiori>
-}
square : Int
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "SHIORI_EXTRACT:{\"funcName\":\"square\",\"codes\":[{\"name\":\"\",\"code\":\"square Color.red\"}],\"imports\":[\"import Color\",\"import Element exposing (El)\"]}"
                            , details = [ "Contains shiori tag" ]
                            , under = "{-|\n    import Color\n    import Element exposing (El)\n\n    <shiori> square Color.red </shiori>\n-}"
                            }
                        ]
        , test "should handle multiple shiori tags within the same comment block" <|
            \() ->
                """module A exposing (..)

{-| Module doc -}

{-|
    <shiori> square Color.red </shiori>
    <shiori>
    square
        Color.blue
    </shiori>
-}
square : Int
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "SHIORI_EXTRACT:{\"funcName\":\"square\",\"codes\":[{\"name\":\"\",\"code\":\"square Color.red\"},{\"name\":\"\",\"code\":\"square\\n        Color.blue\"}],\"imports\":[]}"
                            , details = [ "Contains shiori tag" ]
                            , under = "{-|\n    <shiori> square Color.red </shiori>\n    <shiori>\n    square\n        Color.blue\n    </shiori>\n-}"
                            }
                        ]
        ]
