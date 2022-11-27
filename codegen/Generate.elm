module Generate exposing (Code(..), elmFileName, elmParser, genRouteParserHelper, headUpper, joinDot, main, urlName, variantName)

{-| -}

import Elm
import Elm.Annotation as Type
import Elm.Case
import Elm.Op exposing (pipe)
import Gen.CodeGen.Generate as Generate
import Json.Decode as D
import Json.Encode as E
import List.Extra as List
import Parser as P exposing ((|.), (|=), Parser)
import Set


{-| FIXME: Dictじゃない
-}
type alias Dict a b =
    List ( a, b )


type alias ElmCode =
    Dict
        FileName
        (Dict
            FunctionName
            (List Code)
        )


type alias ElmCodeRecord =
    { fileName : FileName, index : Int, functionName : FunctionName, code : String, imports : List String }


filterByCode : List Code -> List String
filterByCode code =
    List.filterMap
        (\c ->
            case c of
                Code s ->
                    Just s

                _ ->
                    Nothing
        )
        code


getImports : List Code -> List String
getImports codes =
    List.filterMap
        (\code ->
            case code of
                Import str ->
                    Just str

                _ ->
                    Nothing
        )
        codes



-- case code of
--     Code code_ ->
--         { code = code_, import_ = "" }
--     Import i ->
--         { code = "", import_ = import_ }


fromElmCode : ElmCode -> List ElmCodeRecord
fromElmCode elmCode =
    elmCode
        |> List.map
            (\( fileName, list_functionname_codes ) ->
                List.map
                    (\( functionName, codes ) ->
                        let
                            imports =
                                getImports codes
                        in
                        List.indexedMap
                            (\index code ->
                                { fileName = fileName, index = index, functionName = functionName, code = code, imports = imports }
                            )
                        <|
                            filterByCode codes
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
                        |> List.map (\( fileName, v ) -> P.run (elmParser fileName) v |> Result.withDefault ( "", [] ))
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



-- type alias Code =
--     String


type Code
    = Code String
    | Import String


{-| TODO: リファクタしましょう
-}
elmParser : FileName -> Parser ( FileName, Dict FunctionName (List Code) )
elmParser fileName =
    let
        commentContents s =
            P.succeed identity
                |= P.oneOf
                    [ P.succeed (\a -> P.Done <| ( a, List.reverse s ))
                        |. P.keyword "-}"
                        |. P.backtrackable P.spaces
                        |= getKeyword
                    , P.succeed (\d -> P.Loop <| (Import <| "import " ++ d) :: s)
                        |. P.spaces
                        |. P.chompUntil "import"
                        |. P.keyword "import"
                        |. P.spaces
                        |= P.getChompedString (P.chompWhile (\c -> c /= '\n'))
                        |. P.spaces
                    , P.succeed (\d -> P.Loop <| Code d :: s)
                        |. P.spaces
                        |. P.chompUntil "::"
                        |. P.keyword "::"
                        |. P.spaces
                        |= P.getChompedString (P.chompWhile (\c -> c /= '\n'))
                        |. P.spaces

                    -- 何もなかった時
                    -- TODO: MaybeのNothingにしたい
                    , P.succeed (P.Done <| ( "", [] ))
                        |. P.chompUntil "-}"
                        |. P.keyword "-}"
                        |. P.backtrackable P.spaces
                    ]

        comments s =
            P.succeed identity
                |= P.oneOf
                    [ P.succeed (\d -> P.Loop <| d :: s)
                        |. P.chompUntil "{-|"
                        |= P.loop [] commentContents
                    , P.succeed (P.Done s)
                    ]
    in
    P.succeed (\a -> ( fileName, a ))
        |. P.spaces
        |= (P.map (\a -> List.filter (\( k, _ ) -> (not << String.isEmpty) k) a) <| P.loop [] comments)
        |. P.spaces


getKeyword : Parser String
getKeyword =
    P.variable { start = Char.isLower, inner = Char.isAlphaNum, reserved = Set.fromList [] }


toScore : String -> String
toScore =
    String.replace "." "_"



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
                        , Elm.val code |> Elm.declaration "view"
                        ]
            )


route : ElmCode -> Elm.File
route elmCode =
    Elm.file [ "Shiori", "Route" ] <|
        List.append
            (List.map (\{ index, fileName, functionName } -> import_ False <| joinDot [ "Shiori", elmFileName (toScore fileName) functionName index ]) <| fromElmCode elmCode)
            [ import_ True "Url.Parser"
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
                Elm.withType (Type.list <| Type.named [ "Shiori_View" ] "View") <|
                    Elm.Case.custom (url |> pipe (Elm.val "toRoute")) (Type.var "Route") <|
                        Elm.Case.branch0 "NotFound" (Elm.list [])
                            :: List.map genViewHelper elmCode
            )


genViewHelper : ( FileName, Dict FunctionName (List Code) ) -> Elm.Case.Branch
genViewHelper ( fileName, v ) =
    Elm.Case.branch1 (toScore fileName) ( "str", Type.string ) <|
        always (helper2 fileName v)


{-| TODO: RENAME
-}
helper2 : FileName -> Dict String (List Code) -> Elm.Expression
helper2 fileName vv =
    Elm.Case.string (Elm.val "str")
        { cases =
            List.map
                (\( functionName, codes_ ) ->
                    let
                        codes =
                            filterByCode codes_
                    in
                    ( functionName, pipe (Elm.val "Shiori_View.map") <| Elm.list <| List.indexedMap (\i _ -> Elm.val <| joinDot [ "Shiori", elmFileName (toScore fileName) functionName i, "view" ]) codes )
                )
                vv
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


genLinksHelper : FileName -> Dict FunctionName (List Code) -> Elm.Expression
genLinksHelper fileName dictFunctionNameCode =
    let
        helper ( functionName, l ) =
            List.indexedMap (\index _ -> Elm.string <| urlName fileName functionName index) l
                |> Elm.list
                |> Elm.tuple (Elm.string functionName)
    in
    List.map helper dictFunctionNameCode
        |> Elm.list
