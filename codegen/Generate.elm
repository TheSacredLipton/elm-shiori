module Generate exposing (elm, main, mock)

{-| -}

import Dict
import Elm
import Elm.Annotation as Type
import Elm.Op exposing (pipe)
import Gen.CodeGen.Generate as Generate
import Gen.UiTest
import Json.Decode as D
import Json.Encode as E
import Parser as P exposing ((|.), (|=), Parser, Step)


main : Program E.Value () ()
main =
    Generate.fromJson decoder <|
        \flags ->
            List.map
                (\( k, v ) -> List.indexedMap (\i a -> file i k flags.imports a) (P.run elm v |> Result.withDefault []))
                flags.tests
                |> List.concat


{-|

    import Parser as P

    P.run elm mock --> Ok []

-}
elm : Parser (List String)
elm =
    P.map List.concat <|
        P.succeed (\a -> a)
            |. P.spaces
            |= P.loop [] commentsParser
            |. P.spaces


commentsParser : List (List String) -> Parser (Step (List (List String)) (List (List String)))
commentsParser revStmts =
    P.oneOf
        [ P.succeed (\stmt -> P.Loop (stmt :: revStmts))
            |. P.spaces
            |. P.chompUntil "{-|"
            |. P.keyword "{-|"
            |= P.loop [] codeParser
            |. P.keyword "-}"
            |. P.spaces
        , P.succeed ()
            |> P.map (\_ -> P.Done (List.reverse revStmts))
        ]


codeParser : List String -> Parser (Step (List String) (List String))
codeParser revStmts =
    P.oneOf
        [ P.succeed (\stmt -> P.Loop (stmt :: revStmts))
            |. P.spaces
            |. P.chompUntil "::"
            |. P.keyword "::"
            |. P.spaces
            |= P.getChompedString (P.chompWhile (\c -> c /= '\n'))
            |. P.spaces
        , P.succeed ()
            |> P.map (\_ -> P.Done (List.reverse revStmts))
        ]


mock =
    """
{-| 

    :: layout [] <| try 1

    :: layout [] <| try 2

    :: layout [] <| try 3

-} 

type alias 

{-| 

    :: layout [] <| try 1

    :: layout [] <| try 2

    :: layout [] <| try 3

-} 
 
"""


type alias Flags =
    { imports : List String
    , tests : List ( String, String )
    }


decoder : D.Decoder Flags
decoder =
    D.map2 Flags
        (D.field "imports" (D.list D.string))
        (D.field "tests" (D.keyValuePairs D.string))


file : Int -> String -> List String -> String -> Elm.File
file index filename imports body =
    Elm.file [ "UiTests", filename ++ String.fromInt index ] <|
        List.concat
            [ [ import_ filename ]
            , List.map import_ imports
            , [ Gen.UiTest.view (Elm.val <| "<| " ++ body)
                    |> Elm.withType Gen.UiTest.annotation_.uI
                    |> Elm.declaration "main"
              ]
            ]


import_ : String -> Elm.Declaration
import_ name =
    Elm.unsafe <| "import " ++ name ++ " exposing (..)"
