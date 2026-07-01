module ShioriExtractor exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Review.Rule as Rule exposing (Error, Rule)
import Json.Encode as Encode

rule : Rule
rule =
    Rule.newModuleRuleSchema "ShioriExtractor" ()
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.fromModuleRuleSchema

type alias Extracted =
    { codes : List String
    , imports : List String
    }

extract : String -> Extracted
extract commentStr =
    let
        cleanComment =
            commentStr
                |> String.replace "{-|" ""
                |> String.replace "-}" ""
                |> String.trim

        lines =
            String.split "\n" cleanComment
    in
    parseLines lines { currentBlock = Nothing, codes = [], imports = [] }

type alias ParseState =
    { currentBlock : Maybe (List String)
    , codes : List String
    , imports : List String
    }

parseLines : List String -> ParseState -> Extracted
parseLines lines state =
    case lines of
        [] ->
            let
                finalCodes =
                    case state.currentBlock of
                        Just block ->
                            case block of
                                [] -> state.codes
                                first :: _ -> (String.trim first) :: state.codes
                        Nothing ->
                            state.codes
            in
            { codes = List.reverse finalCodes, imports = List.reverse state.imports }

        line :: rest ->
            let
                trimmed = String.trim line
            in
            if String.startsWith "import " trimmed then
                parseLines rest { state | imports = trimmed :: state.imports }
            else
                case state.currentBlock of
                    Just block ->
                        if String.contains "</shiori>" line then
                            let
                                beforeClose =
                                    case String.split "</shiori>" line of
                                        before :: _ -> before
                                        [] -> ""
                                fullBlock =
                                    List.reverse (beforeClose :: block)
                                        |> String.join "\n"
                                        |> String.trim
                            in
                            parseLines rest
                                { state
                                    | currentBlock = Nothing
                                    , codes = if String.isEmpty fullBlock then state.codes else fullBlock :: state.codes
                                }
                        else
                            parseLines rest { state | currentBlock = Just (line :: block) }

                    Nothing ->
                        if String.contains "<shiori>" line then
                            let
                                afterStart =
                                    case String.split "<shiori>" line of
                                        _ :: after :: _ -> after
                                        _ :: [] -> ""
                                        [] -> ""
                            in
                            if String.contains "</shiori>" afterStart then
                                let
                                    code =
                                        case String.split "</shiori>" afterStart of
                                            before :: _ -> String.trim before
                                            [] -> ""
                                    newCodes =
                                        if String.isEmpty code then state.codes else code :: state.codes
                                in
                                parseLines rest { state | codes = newCodes }
                            else
                                let
                                    hasClose =
                                        isMultiLineStart rest
                                in
                                if hasClose then
                                    parseLines rest { state | currentBlock = Just [afterStart] }
                                else
                                    let
                                        code = String.trim afterStart
                                        newCodes =
                                            if String.isEmpty code then state.codes else code :: state.codes
                                    in
                                    parseLines rest { state | codes = newCodes }
                        else
                            parseLines rest state

isMultiLineStart : List String -> Bool
isMultiLineStart lines =
    case lines of
        [] ->
            False

        line :: rest ->
            if String.contains "</shiori>" line then
                True
            else if String.contains "<shiori>" line then
                False
            else
                isMultiLineStart rest

encodeResult : String -> Extracted -> String
encodeResult funcName extracted =
    Encode.object
        [ ( "funcName", Encode.string funcName )
        , ( "codes", Encode.list Encode.string extracted.codes )
        , ( "imports", Encode.list Encode.string extracted.imports )
        ]
        |> Encode.encode 0

declarationVisitor : Node Declaration -> () -> ( List (Error {}), () )
declarationVisitor node context =
    case Node.value node of
        FunctionDeclaration func ->
            let
                declaration = Node.value func.declaration
                funcName = Node.value declaration.name
                maybeDoc = func.documentation
            in
            case maybeDoc of
                Just (Node range commentStr) ->
                    if String.contains "<shiori>" commentStr then
                        let
                            extracted = extract commentStr
                            jsonStr = encodeResult funcName extracted
                        in
                        ( [ Rule.error
                                { message = "SHIORI_EXTRACT:" ++ jsonStr
                                , details = [ "Contains shiori tag" ]
                                }
                                range
                          ]
                        , ()
                        )
                    else
                        ( [], () )

                Nothing ->
                    ( [], () )

        _ ->
            ( [], () )
