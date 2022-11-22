module Generate exposing (elmParser, main)

{-| -}

import Elm
import Elm.Annotation as Type
import Elm.Case
import Elm.Op exposing (pipe)
import Gen.CodeGen.Generate as Generate
import Json.Decode as D
import Json.Encode as E
import List.Extra as List
import Parser as P exposing ((|.), (|=), Parser, Step)


main : Program E.Value () ()
main =
    Generate.fromJson decoder <|
        \flags ->
            let
                aa =
                    flags.targets
                        |> List.map (\( name, v ) -> List.indexedMap (\index body -> ( index, name, body )) (P.run elmParser v |> Result.withDefault []))
                        |> List.concat
            in
            List.map (\( index, name, body ) -> file index name flags.imports body) aa
                |> List.append [ route (List.map (\( i, n, _ ) -> ( i, n )) aa) ]


type alias Flags =
    { imports : List String
    , targets : List ( String, String )
    }


decoder : D.Decoder Flags
decoder =
    D.map2 Flags
        (D.field "imports" (D.list D.string))
        (D.field "targets" (D.keyValuePairs D.string))



------------
-- PARSER
------------


elmParser : Parser (List String)
elmParser =
    P.map List.concat <|
        P.succeed (\a -> a)
            |. P.spaces
            |. P.chompUntil "{-|"
            |= P.sequence
                { start = "{-|"
                , separator = "\n"
                , end = "-}"
                , spaces = P.spaces
                , item = P.loop [] codeParser
                , trailing = P.Optional
                }
            |. P.spaces


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



-----------
-- File
-----------


file : Int -> String -> List String -> String -> Elm.File
file index filename imports body =
    Elm.file [ "Shiori", filename ++ String.fromInt index ] <|
        List.append
            (List.map import_ imports)
            [ import_ filename
            , (Elm.val <| body) |> Elm.declaration "view"
            ]


route : List ( Int, String ) -> Elm.File
route ls =
    Elm.file [ "Shiori", "Route" ] <|
        List.append
            (List.map (\( i, n ) -> import2_ <| "Shiori." ++ n ++ String.fromInt i) ls)
            [ import_ "Url.Parser"
            , typeRoute ls
            , Elm.Case.custom (Elm.val "toRoute url")
                (Type.var "Route")
                (Elm.Case.branch0 "NotFound" (Elm.val "notfound") :: List.map (\( i, n ) -> Elm.Case.branch0 (n ++ "_" ++ String.fromInt i) (Elm.val <| "Shiori." ++ n ++ String.fromInt i ++ ".view")) ls)
                |> Elm.declaration "view url notfound"
            , Elm.list (List.map (\( i, n ) -> Elm.val <| ("map " ++ n ++ "_" ++ String.fromInt i ++ "<| s \"" ++ String.toLower n ++ String.fromInt i ++ "\"")) ls)
                |> pipe (Elm.val "oneOf")
                |> Elm.declaration "routeParser"
            , Elm.val "Maybe.withDefault NotFound (parse routeParser url)"
                |> Elm.declaration "toRoute url"
            , Elm.list (List.map (\( i, n ) -> Elm.string <| String.toLower n ++ String.fromInt i) ls)
                |> Elm.declaration "links"
            ]


import_ : String -> Elm.Declaration
import_ name =
    Elm.unsafe <| "import " ++ name ++ " exposing (..)"


import2_ : String -> Elm.Declaration
import2_ name =
    Elm.unsafe <| "import " ++ name


typeRoute : List ( Int, String ) -> Elm.Declaration
typeRoute ls =
    List.map (\( i, n ) -> Elm.variant (n ++ "_" ++ String.fromInt i)) ls
        |> List.append [ Elm.variant "NotFound" ]
        |> Elm.customType "Route"
