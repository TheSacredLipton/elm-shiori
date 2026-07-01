module ShioriExtractor exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Review.Rule as Rule exposing (Error, Rule)
import Json.Encode as Encode

rule : Rule
rule =
    Rule.newModuleRuleSchema "ShioriExtractor" []
        |> Rule.withImportVisitor importVisitor
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

importVisitor : Node Import -> List String -> ( List (Error {}), List String )
importVisitor node context =
    let
        imp = Node.value node
        moduleName = String.join "." (Node.value imp.moduleName)
        isSystem =
            moduleName == "Html"
                || String.startsWith "Html." moduleName
                || moduleName == "Url"
                || String.startsWith "Url." moduleName
    in
    if isSystem then
        ( [], context )
    else
        let
            aliasStr =
                case imp.moduleAlias of
                    Just aliasNode ->
                        " as " ++ String.join "." (Node.value aliasNode)
                    Nothing ->
                        ""
            exposingStr =
                case imp.exposingList of
                    Just exposingNode ->
                        " exposing " ++ exposingToString (Node.value exposingNode)
                    Nothing ->
                        ""
            importLine =
                "import " ++ moduleName ++ aliasStr ++ exposingStr
        in
        ( [], importLine :: context )

exposingToString : Exposing -> String
exposingToString exp =
    case exp of
        All _ ->
            "(..)"
        Explicit list ->
            let
                items = List.map (Node.value >> topLevelExposeToString) list
            in
            "(" ++ String.join ", " items ++ ")"

topLevelExposeToString : TopLevelExpose -> String
topLevelExposeToString val =
    case val of
        InfixExpose name ->
            "(" ++ name ++ ")"
        TypeExpose typeExpose ->
            case typeExpose.open of
                Just _ ->
                    typeExpose.name ++ "(..)"
                Nothing ->
                    typeExpose.name
        FunctionExpose name ->
            name
        TypeOrAliasExpose name ->
            name

declarationVisitor : Node Declaration -> List String -> ( List (Error {}), List String )
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
                            mergedImports = extracted.imports ++ context
                            extractedWithMerged = { extracted | imports = mergedImports }
                            jsonStr = encodeResult funcName extractedWithMerged
                        in
                        ( [ Rule.error
                                { message = "SHIORI_EXTRACT:" ++ jsonStr
                                , details = [ "Contains shiori tag" ]
                                }
                                range
                          ]
                        , context
                        )
                    else
                        ( [], context )

                Nothing ->
                    ( [], context )

        _ ->
            ( [], context )
