module ShioriExtractorTest exposing (all)

import Review.Test
import ShioriExtractor exposing (rule)
import Test exposing (Test, describe, test)


all : Test
all =
    describe "ShioriExtractor"
        [ test "should report error when function documentation contains <shiori> tag" <|
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
                    |> Review.Test.expectErrors
                        [ Review.Test.error
                            { message = "SHIORI_EXTRACT:square:{-|\n    <shiori> square colors.red\n-}"
                            , details = [ "Contains shiori tag" ]
                            , under = "{-|\n    <shiori> square colors.red\n-}"
                            }
                        ]
        , test "should not report error when documentation does not contain <shiori> tag" <|
            \() ->
                """module A exposing (..)

{-|
    some documentation
-}
square = 1
"""
                    |> Review.Test.run rule
                    |> Review.Test.expectNoErrors
        ]
