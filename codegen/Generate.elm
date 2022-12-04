module Generate exposing (elmFileName, functionCommentParser, functionCommentsParser, genRouteParserHelper, headUpper, joinDot, main, urlName, variantName)

{-| -}

import Elm
import Elm.Annotation as Type
import Elm.Case
import Elm.Op exposing (pipe)
import Gen.CodeGen.Generate as Generate
import Json.Decode as D
import Json.Encode as E
import List.Extra as List
import Parser as P exposing ((|.), (|=), Parser, chompIf)
import Set


type alias ElmCode =
    List
        ( FileName
        , List
            ( FunctionName
            , Code
            )
        )


type alias Code =
    { codes : List String, imports : List String }


type alias ElmCodeRecord =
    { fileName : FileName, index : Int, functionName : FunctionName, code : String, imports : List String }


fromElmCode : ElmCode -> List ElmCodeRecord
fromElmCode elmCode =
    elmCode
        |> List.map
            (\( fileName, list_functionname_codes ) ->
                List.map
                    (\( functionName, { codes, imports } ) ->
                        -- let
                        --     imports =
                        --         getImports codes
                        -- in
                        List.indexedMap
                            (\index code ->
                                { fileName = fileName, index = index, functionName = functionName, code = code, imports = imports }
                            )
                        <|
                            codes
                    )
                    list_functionname_codes
            )
        |> List.concat
        |> List.concat



----------
-- MAIN
----------


main : Program E.Value () ()
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


type alias Flags =
    List ( String, String )



-------------
-- DECODER
-------------


{-| FIXME: ここでreverseするの間違ってると思う
-}
decoder : D.Decoder Flags
decoder =
    D.keyValuePairs D.string |> D.map List.reverse



------------
-- PARSER
------------


type alias FileName =
    String


type alias FunctionName =
    String


getKeyword : Parser String
getKeyword =
    P.variable { start = Char.isLower, inner = Char.isAlphaNum, reserved = Set.fromList [] }


toScore : String -> String
toScore =
    String.replace "." "_"


functionCommentParser : Parser (Maybe ( FunctionName, { codes : List String, imports : List String } ))
functionCommentParser =
    P.succeed identity
        |= (P.succeed ()
                |. P.chompUntil "{-|"
                |. P.multiComment "{-|" "-}" P.Nestable
                |. P.spaces
                |. getKeyword
                |> P.getChompedString
           )
        |> P.andThen
            (\source ->
                let
                    getFunctionName =
                        P.succeed identity
                            |. P.chompUntil "-}"
                            |. P.keyword "-}"
                            |. P.spaces
                            |= getKeyword
                in
                wrapRun "err" getFunctionName source
                    |> P.map (\a -> { body = source, functionName = a })
            )
        |> P.andThen
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


wrapRun : String -> Parser a -> String -> Parser a
wrapRun err parser arg =
    case P.run parser arg of
        Ok r ->
            P.succeed r

        Err _ ->
            P.problem err



-----------
-- File
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


{-| TODO: 先頭を大文字にする処理を追加すると安全かもしれない

    joinDot [] --> ""

    joinDot [ "Main", "Button" ] --> "Main.Button"

-}
joinDot : List String -> String
joinDot =
    String.join "."


joinScore : List String -> String
joinScore =
    String.join "_"


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


import_ : Bool -> String -> Elm.Declaration
import_ isExposingAll name =
    Elm.unsafe <|
        "import "
            ++ name
            ++ (if isExposingAll then
                    " exposing (..)"

                else
                    ""
               )


genTypeRoute : ElmCode -> Elm.Declaration
genTypeRoute elmCode =
    elmCode
        |> List.map (\( fileName, _ ) -> Elm.variantWith (toScore fileName) [ Type.string ])
        |> List.append [ Elm.variant "NotFound" ]
        |> Elm.customType "Route"


genView : ElmCode -> Elm.Declaration
genView elmCode =
    Elm.declaration "view" <|
        Elm.fn ( "url", Just <| Type.named [ "Url" ] "Url" )
            (\url ->
                Elm.withType (Type.list <| Type.namedWith [ "Origami.Html" ] "Html" [ Type.unit ]) <|
                    Elm.Case.custom (url |> pipe (Elm.val "toRoute")) (Type.var "Route") <|
                        Elm.Case.branch0 "NotFound" (Elm.list [])
                            :: List.map genViewHelper elmCode
            )


genViewHelper : ( FileName, List ( FunctionName, { codes : List String, imports : List String } ) ) -> Elm.Case.Branch
genViewHelper ( fileName, v ) =
    Elm.Case.branch1 (toScore fileName) ( "str", Type.string ) <|
        always (helper2 fileName v)


{-| TODO: RENAME
-}
helper2 : FileName -> List ( FunctionName, { codes : List String, imports : List String } ) -> Elm.Expression
helper2 fileName vv =
    Elm.Case.string (Elm.val "str")
        { cases =
            vv
                |> List.map (\( functionName, code ) -> ( functionName, code.codes ))
                |> List.map
                    (\( functionName, codes_ ) ->
                        let
                            codes =
                                codes_
                        in
                        ( functionName, pipe (Elm.val "Shiori_View.map") <| Elm.list <| List.indexedMap (\i _ -> Elm.val <| joinDot [ "Shiori", elmFileName (toScore fileName) functionName i, "view__" ]) codes )
                    )
        , otherwise = Elm.list []
        }


genRouteParser : ElmCode -> Elm.Declaration
genRouteParser elmCode =
    elmCode
        |> List.map (\( fileName, _ ) -> Elm.val <| genRouteParserHelper fileName)
        |> Elm.list
        |> pipe url_oneOf
        |> Elm.declaration "routeParser"


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
-}
genRouteParserHelper : String -> String
genRouteParserHelper fileName =
    "map " ++ toScore fileName ++ " <| s \"" ++ fileName ++ "\" </> string"


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


genLinks : ElmCode -> Elm.Declaration
genLinks elmCode =
    elmCode
        |> List.map (\( fileName, v ) -> Elm.tuple (Elm.string fileName) (genLinksHelper fileName v))
        |> Elm.list
        |> Elm.declaration "links"


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
