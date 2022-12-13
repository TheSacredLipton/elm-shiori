module Generate exposing (..)

{-| -}

import Elm
import Elm.Annotation as Type
import Elm.Case
import Elm.Op exposing (pipe)
import Gen.CodeGen.Generate as Generate
import Json.Decode as D
import List.Extra as List
import Parser as P exposing ((|.), (|=), Parser)
import Set


type alias Flags =
    List ( String, String )


type alias ElmCode =
    List
        ( FileName
        , List
            ( FunctionName
            , Code
            )
        )


type alias FileName =
    String


type alias FunctionName =
    String


type alias Code =
    { codes : List String, imports : List String }


type alias ElmCodeRecord =
    { fileName : FileName, index : Int, functionName : FunctionName, code : String, imports : List String }


fromElmCode : ElmCode -> List ElmCodeRecord
fromElmCode elmCode =
    elmCode
        |> List.map
            (\( fileName, list_functionname_codes ) ->
                list_functionname_codes
                    |> List.map
                        (\( functionName, { codes, imports } ) ->
                            codes
                                |> List.indexedMap
                                    (\index code ->
                                        { fileName = fileName, index = index, functionName = functionName, code = code, imports = imports }
                                    )
                        )
            )
        |> List.concat
        |> List.concat



----------
-- MAIN
----------


main : Program D.Value () ()
main =
    Generate.fromJson decoder <|
        \flags ->
            let
                elmCode : ElmCode
                elmCode =
                    flags
                        |> List.map (\( fileName, v ) -> ( fileName, P.run functionCommentsParser v |> Result.withDefault [] ))
            in
            route elmCode :: files elmCode



-------------
-- DECODER
-------------


decoder : D.Decoder Flags
decoder =
    D.keyValuePairs D.string |> D.map List.reverse



------------
-- PARSER
------------


functionCommentsParser : Parser (List ( FunctionName, { codes : List String, imports : List String } ))
functionCommentsParser =
    let
        helper s =
            P.succeed identity
                |= P.oneOf
                    [ P.succeed (\d -> P.Loop <| d :: s)
                        |= functionCommentParser
                    , P.succeed (P.Done <| List.reverse s)
                    ]
    in
    P.loop [] helper
        |> P.map (List.filterMap identity)


functionCommentParser : Parser (Maybe ( FunctionName, { codes : List String, imports : List String } ))
functionCommentParser =
    P.succeed identity
        |= getCommentWithKeyword
        |> getFunctionName
        |> getImportsAndCodes


getCommentWithKeyword : Parser String
getCommentWithKeyword =
    P.succeed ()
        |. P.chompUntil "{-|"
        |. P.multiComment "{-|" "-}" P.Nestable
        |. P.spaces
        |. getKeyword
        |> P.getChompedString


getFunctionName : Parser String -> Parser { body : String, functionName : String }
getFunctionName =
    let
        getFunctionName_ =
            P.succeed identity
                |. P.chompUntil "-}"
                |. P.keyword "-}"
                |. P.spaces
                |= getKeyword
    in
    P.andThen
        (\source ->
            run_ "getFunctionNameError" getFunctionName_ source
                |> P.map (\a -> { body = source, functionName = a })
        )


getImportsAndCodes : Parser { a | body : String, functionName : b } -> Parser (Maybe ( b, { codes : List String, imports : List String } ))
getImportsAndCodes =
    P.andThen
        (\{ body, functionName } ->
            let
                trim =
                    String.split "\n" body
                        |> List.map (\a -> String.trim a)

                imports =
                    List.filter (\a -> String.startsWith "import" a) trim

                codes =
                    List.filter (\a -> String.startsWith "::" a) trim
                        |> List.map (\a -> String.dropLeft 2 a |> String.trim)
            in
            if List.isEmpty codes then
                P.succeed Nothing

            else
                P.succeed <| Just ( functionName, { codes = codes, imports = imports } )
        )


{-|

    import Parser as P

    P.run getKeyword "import Html exposing"
    --> Ok "import"

-}
getKeyword : Parser String
getKeyword =
    P.variable { start = Char.isLower, inner = Char.isAlphaNum, reserved = Set.fromList [] }


run_ : String -> Parser a -> String -> Parser a
run_ err parser source =
    case P.run parser source of
        Ok r ->
            P.succeed r

        Err _ ->
            P.problem err



-----------
-- Files
-----------


files : ElmCode -> List Elm.File
files elmCode =
    fromElmCode elmCode
        |> List.map
            (\{ fileName, functionName, index, code, imports } ->
                Elm.file [ "Shiori", elmFileName (toScore fileName) functionName index ] <|
                    List.append
                        (List.map Elm.unsafe <| imports)
                        [ import_ True fileName
                        , Elm.val code |> Elm.declaration "view__"
                        ]
            )


route : ElmCode -> Elm.File
route elmCode =
    Elm.file [ "Shiori", "Route" ] <|
        List.append
            (List.map (\{ index, fileName, functionName } -> import_ False <| joinDot [ "Shiori", elmFileName (toScore fileName) functionName index ]) <| fromElmCode elmCode)
            [ import_ True "Url.Parser"
            , import_ False "Shiori_View"
            , genTypeRoute elmCode
            , genView elmCode
            , genRouteParser elmCode
            , genToRoute
            , genLinks elmCode
            ]


{-|

    import Elm.ToString exposing (declaration)

    declaration <| import_ True "Url.Parser"
    -->  { body = "import Url.Parser exposing (..)\n\n\n", docs = "", imports = "", signature = "" }

-}
import_ : Bool -> String -> Elm.Declaration
import_ isExposingAll name =
    Elm.unsafe <|
        String.join " "
            [ "import"
            , name
            , if isExposingAll then
                "exposing (..)"

              else
                ""
            ]


{-|

        import Elm.ToString exposing (declaration)

        declaration <| genTypeRoute [("", [])]
        --> { body = "type Route\n    = NotFound\n    |  String\n\n\n", docs = "", imports = "import\nimport", signature = "" }

-}
genTypeRoute : ElmCode -> Elm.Declaration
genTypeRoute elmCode =
    Elm.customType "Route" <|
        List.append [ Elm.variant "NotFound" ] <|
            List.map (\( fileName, _ ) -> Elm.variantWith (toScore fileName) [ Type.string ]) <|
                elmCode


{-|

        import Elm.ToString exposing (declaration)

        declaration <| genView [("", [])]
        --> { body = "view : Url.Url -> List (Html.Html ())\nview url =\n    case url |> toRoute of\n        NotFound ->\n            []\n\n         str ->\n            case str of\n                _ ->\n                    []\n\n\n", docs = "", imports = "import Html\nimport Url", signature = "view : Url.Url -> List (Html.Html ())" }

-}
genView : ElmCode -> Elm.Declaration
genView elmCode =
    Elm.declaration "view" <|
        Elm.fn ( "url", Just <| Type.named [ "Url" ] "Url" )
            (\url ->
                Elm.withType (Type.list <| Type.namedWith [ "Html" ] "Html" [ Type.unit ]) <|
                    Elm.Case.custom (url |> pipe (Elm.val "toRoute")) (Type.var "Route") <|
                        Elm.Case.branch0 "NotFound" (Elm.list [])
                            :: List.map genViewHelper elmCode
            )


genViewHelper : ( FileName, List ( FunctionName, { codes : List String, imports : List String } ) ) -> Elm.Case.Branch
genViewHelper ( fileName, v ) =
    Elm.Case.branch1 (toScore fileName) ( "str", Type.string ) <|
        always (helper2 fileName v)


{-| TODO: RENAME
FIXME: テスト失敗してそうな雰囲気

        import Elm.ToString exposing (expression)

        expression <| helper2 "" [("", { codes = [], imports = [] })]
        --> { body = "case str of\n    \"\" ->\n        [] |> Shiori_View.map\n\n    _ ->\n        []", imports = "import\nimport", signature = "Infinite type inference loop!  Whoops.  This is an issue with elm-codegen.  If you can report this to the elm-codegen repo, that would be appreciated!" }

-}
helper2 : FileName -> List ( FunctionName, { codes : List String, imports : List String } ) -> Elm.Expression
helper2 fileName vv =
    Elm.Case.string (Elm.val "str")
        { cases =
            vv
                |> List.map
                    (\( functionName, codes ) ->
                        ( functionName
                        , pipe (Elm.val "Shiori_View.map") <|
                            Elm.list <|
                                List.indexedMap
                                    (\i _ ->
                                        Elm.val <|
                                            joinDot [ "Shiori", elmFileName (toScore fileName) functionName i, "view__" ]
                                    )
                                    codes.codes
                        )
                    )
        , otherwise = Elm.list []
        }


{-|

    import Elm.ToString exposing (declaration)

    declaration <| genRouteParser [("", [])]
    --> { body = "routeParser : Parser (Route -> b) b\nrouteParser =\n    [ map  <| s \"\" </> string ] |> oneOf\n\n\n", docs = "", imports = "import\nimport", signature = "routeParser : Parser (Route -> b) b" }

-}
genRouteParser : ElmCode -> Elm.Declaration
genRouteParser elmCode =
    elmCode
        |> List.map (\( fileName, _ ) -> Elm.val <| genRouteParserHelper fileName)
        |> Elm.list
        |> pipe url_oneOf
        |> Elm.declaration "routeParser"


{-|

    import Elm.ToString exposing (expression)

    expression <| url_oneOf
    --> { body = "oneOf", imports = "import\nimport", signature = "List (Parser a b) -> Parser (Route -> b) b" }

-}
url_oneOf : Elm.Expression
url_oneOf =
    let
        parser_a_b =
            Type.namedWith []
                "Parser"
                [ Type.var "a"
                , Type.var "b"
                ]

        parser_route_b =
            Type.namedWith []
                "Parser"
                [ Type.function [ Type.named [] "Route" ] <| Type.var "b"
                , Type.var "b"
                ]
    in
    Elm.value
        { importFrom = []
        , name = "oneOf"
        , annotation =
            Just
                (Type.function [ Type.list <| parser_a_b ] parser_route_b)
        }


{-| FIXME:

    genRouteParserHelper "Page.Home" --> "map Page_Home <| s \"Page.Home\" </> string"

-}
genRouteParserHelper : String -> String
genRouteParserHelper fileName =
    "map " ++ toScore fileName ++ " <| s \"" ++ fileName ++ "\" </> string"


{-|

        import Elm.ToString exposing (declaration)

        declaration <| genToRoute
        -->  { body = "toRoute : Url.Url -> Route\ntoRoute url =\n    url |> parse routeParser  |> Maybe.withDefault NotFound\n\n\n", docs = "", imports = "import Url", signature = "toRoute : Url.Url -> Route" }

-}
genToRoute : Elm.Declaration
genToRoute =
    Elm.declaration "toRoute" <|
        Elm.fn ( "url", Just <| Type.named [ "Url" ] "Url" )
            (\url ->
                url
                    |> pipe (Elm.val "parse routeParser ")
                    |> pipe (Elm.val "Maybe.withDefault NotFound")
                    |> Elm.withType (Type.named [] "Route")
            )


{-|

        import Elm.ToString exposing (declaration)

        declaration <| genLinks [("", [])]
        -->  { body = "links : List ( String, List a )\nlinks =\n    [ ( \"\", [] ) ]\n\n\n", docs = "", imports = "import\nimport", signature = "links : List ( String, List a )" }

-}
genLinks : ElmCode -> Elm.Declaration
genLinks elmCode =
    elmCode
        |> List.map (\( fileName, v ) -> Elm.tuple (Elm.string fileName) (genLinksHelper fileName v))
        |> Elm.list
        |> Elm.declaration "links"


{-|

        import Elm.ToString exposing (expression)

        expression <| genLinksHelper "foo" [ ( "bar", { codes = [ "baz" ], imports = [] } ) ]
        -->   { body = "[ ( \"bar\", [ \"foo_bar_0\" ] ) ]", imports = "import\nimport", signature = "List ( String, List String )" }

-}
genLinksHelper : FileName -> List ( FunctionName, { codes : List String, imports : List String } ) -> Elm.Expression
genLinksHelper fileName dictFunctionNameCode =
    let
        helper ( functionName, l ) =
            List.indexedMap (\index _ -> Elm.string <| urlName fileName functionName index) l
                |> Elm.list
                |> Elm.tuple (Elm.string functionName)
    in
    dictFunctionNameCode
        |> List.map (\( functionName, code ) -> ( functionName, code.codes ))
        |> List.map helper
        |> Elm.list



------------------
-- Utility
------------------


{-|

    variantName "Main" 100 --> "Main_100"

    variantName "main" 100 --> "Main_100"

-}
variantName : String -> Int -> String
variantName fileName index =
    joinScore [ headUpper fileName, String.fromInt index ]


{-|

    headUpper "tom" --> "Tom"

    headUpper "t" --> "T"

-}
headUpper : String -> String
headUpper s =
    String.toUpper (String.left 1 s) ++ String.dropLeft 1 s


{-|

    elmFileName "Main" "button" 100 --> "Main_button_100"

-}
elmFileName : String -> String -> Int -> String
elmFileName fileName functionName index =
    joinScore [ fileName, functionName, String.fromInt index ]


{-|

    urlName "Main" "button" 1 --> "main_button_1"

-}
urlName : String -> String -> Int -> String
urlName fileName functionName index =
    joinScore [ String.toLower fileName, functionName, String.fromInt index ]


{-|

    toScore "Main.A" --> "Main_A"

-}
toScore : String -> String
toScore =
    String.replace "." "_"


{-| TODO: 先頭を大文字にする処理を追加すると安全かもしれない

    joinDot [] --> ""

    joinDot [ "Main", "Button" ] --> "Main.Button"

-}
joinDot : List String -> String
joinDot =
    String.join "."


{-|

    joinScore [] --> ""

    joinScore [ "Main", "Button" ] --> "Main_Button"

-}
joinScore : List String -> String
joinScore =
    String.join "_"
