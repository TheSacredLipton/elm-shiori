module Generate exposing (elmFileName, elmParser, genRouteParserHelper, headUpper, joinDot, main, urlName, variantName)

{-| -}

import Dict exposing (Dict)
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


type alias ElmCode =
    Dict
        FileName
        (Dict
            FunctionName
            (List Code)
        )


type alias ElmCodeRecord =
    { fileName : FileName, index : Int, functionName : FunctionName, code : Code }


fromElmCode : ElmCode -> List ElmCodeRecord
fromElmCode elmCode =
    elmCode
        |> Dict.map
            (\fileName v ->
                Dict.map
                    (\functionName codes ->
                        List.indexedMap
                            (\index code ->
                                { fileName = fileName, index = index, functionName = functionName, code = code }
                            )
                            codes
                    )
                    v
                    |> Dict.values
            )
        |> Dict.values
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
                    flags.targets
                        |> List.map (\( fileName, v ) -> P.run (elmParser fileName) v |> Result.withDefault ( "", Dict.empty ))
                        |> Dict.fromList
            in
            route elmCode :: files elmCode


type alias Flags =
    { targets : List ( String, String )
    }



-------------
-- DECODER
-------------


decoder : D.Decoder Flags
decoder =
    D.map Flags
        (D.field "targets" (D.keyValuePairs D.string))



------------
-- PARSER
------------


type alias FileName =
    String


type alias FunctionName =
    String


type alias Code =
    String


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
                        |= getVal
                    , P.succeed (\d -> P.Loop <| d :: s)
                        |. P.spaces
                        |. P.chompUntil "::"
                        |. P.keyword "::"
                        |. P.spaces
                        |= P.getChompedString (P.chompWhile (\c -> c /= '\n'))
                        |. P.spaces
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
        |= (P.map Dict.fromList <| P.loop [] comments)
        |. P.spaces


getVal : Parser String
getVal =
    P.variable { start = Char.isLower, inner = Char.isAlphaNum, reserved = Set.fromList [] }



-----------
-- File
-----------


files : ElmCode -> List Elm.File
files elmCode =
    fromElmCode elmCode
        |> List.map
            (\{ fileName, functionName, index, code } ->
                Elm.file [ "Shiori", elmFileName fileName functionName index ]
                    [ import_ True fileName
                    , Elm.val code |> Elm.declaration "view"
                    ]
            )


{-| TODO: elmCodeはletで事前に一度で渡した方が良い
-}
route : ElmCode -> Elm.File
route elmCode =
    Elm.file [ "Shiori", "Route" ] <|
        List.append
            (List.map (\{ index, fileName, functionName } -> import_ False <| joinDot [ "Shiori", elmFileName fileName functionName index ]) <| fromElmCode elmCode)
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
        |> Dict.map (\fileName _ -> Elm.variantWith fileName [ Type.string ])
        |> Dict.values
        |> List.append [ Elm.variant "NotFound" ]
        |> Elm.customType "Route"


genView : ElmCode -> Elm.Declaration
genView elmCode =
    Elm.declaration "view" <|
        Elm.fn ( "url", Just <| Type.named [ "Url" ] "Url" )
            (\url ->
                Elm.Case.branch0 "NotFound" (Elm.list [])
                    :: toListMap genViewHelper elmCode
                    |> Elm.Case.custom (url |> pipe (Elm.val "toRoute")) (Type.var "Route")
                    |> pipe (Elm.val "View.map")
                    |> Elm.withType (Type.list <| Type.named [ "View" ] "View")
            )


genViewHelper : FileName -> Dict FunctionName (List Code) -> Elm.Case.Branch
genViewHelper fileName v =
    always (helper2 fileName v)
        |> Elm.Case.branch1 fileName ( "str", Type.string )


{-| TODO: RENAME
-}
helper2 : FileName -> Dict String (List Code) -> Elm.Expression
helper2 fileName vv =
    Elm.Case.string (Elm.val "str")
        { cases =
            toListMap
                (\functionName codes ->
                    ( functionName, Elm.list <| List.indexedMap (\i _ -> Elm.val <| joinDot [ "Shiori", elmFileName fileName functionName i, "view" ]) codes )
                )
                vv
        , otherwise = Elm.list []
        }


genRouteParser : ElmCode -> Elm.Declaration
genRouteParser elmCode =
    fromElmCode elmCode
        |> List.map (Elm.val << genRouteParserHelper)
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
genRouteParserHelper : ElmCodeRecord -> String
genRouteParserHelper { fileName } =
    "map " ++ fileName ++ " <| s \"" ++ fileName ++ "\" </> string"


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



-- map Button <| s "Button" </> string


genLinks : ElmCode -> Elm.Declaration
genLinks elmCode =
    elmCode
        |> toListMap (\fileName v -> Elm.tuple (Elm.string fileName) (genLinksHelper fileName v))
        |> Elm.list
        |> Elm.declaration "links"


genLinksHelper : FileName -> Dict FunctionName (List Code) -> Elm.Expression
genLinksHelper fileName dictFunctionNameCode =
    let
        helper functionName l =
            List.indexedMap (\index _ -> Elm.string <| urlName fileName functionName index) l
                |> Elm.list
                |> Elm.tuple (Elm.string functionName)
    in
    toListMap helper dictFunctionNameCode
        |> Elm.list


toListMap : (k -> v -> a) -> Dict k v -> List a
toListMap fn d =
    Dict.map fn d
        |> Dict.values
