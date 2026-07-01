module ShioriExtractor exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Module exposing (Module)
import Elm.Syntax.Expression exposing (Expression(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Elm.Syntax.Import exposing (Import)
import Elm.Syntax.Exposing exposing (Exposing(..), TopLevelExpose(..))
import Elm.Syntax.Range exposing (Range)
import Review.Rule as Rule exposing (Error, Rule)
import Review.Fix as Fix
import Json.Encode as Encode
import String
import List
import Maybe

type alias ExtractedCode =
    { name : String
    , code : String
    }

type alias Extracted =
    { codes : List ExtractedCode
    , imports : List String
    }

type alias ModuleContext =
    { moduleName : String
    , codes : List (String, Extracted) -- (FuncName, Extracted)
    , imports : List String
    , isRouteModule : Bool
    , moduleKey : Rule.ModuleKey
    , lastLine : Int
    }

type alias ProjectContext =
    { routeModuleKey : Maybe Rule.ModuleKey
    , routeModuleLastLine : Int
    , modules : List ModuleContext
    }

rule : Rule
rule =
    Rule.newProjectRuleSchema "ShioriExtractor" initialProjectContext
        |> Rule.withModuleVisitor
            (\schema ->
                schema
                    |> Rule.withModuleDefinitionVisitor moduleDefinitionVisitor
                    |> Rule.withImportVisitor importVisitor
                    |> Rule.withDeclarationEnterVisitor declarationVisitor
            )
        |> Rule.withModuleContext
            { fromProjectToModule = fromProjectToModule
            , fromModuleToProject = fromModuleToProject
            , foldProjectContexts = foldProjectContexts
            }
        |> Rule.withFinalProjectEvaluation finalEvaluation
        |> Rule.fromProjectRuleSchema

initialProjectContext : ProjectContext
initialProjectContext =
    { routeModuleKey = Nothing
    , routeModuleLastLine = 1
    , modules = []
    }

fromProjectToModule : Rule.ModuleKey -> Node ModuleName -> ProjectContext -> ModuleContext
fromProjectToModule moduleKey moduleNode _ =
    let
        moduleName = Node.value moduleNode
    in
    { moduleName = String.join "." moduleName
    , codes = []
    , imports = []
    , isRouteModule = moduleName == [ "Shiori", "Route" ]
    , moduleKey = moduleKey
    , lastLine = 1
    }

fromModuleToProject : Rule.ModuleKey -> Node ModuleName -> ModuleContext -> ProjectContext
fromModuleToProject moduleKey _ moduleContext =
    if moduleContext.isRouteModule then
        { routeModuleKey = Just moduleKey
        , routeModuleLastLine = moduleContext.lastLine
        , modules = [ moduleContext ]
        }
    else
        { routeModuleKey = Nothing
        , routeModuleLastLine = 1
        , modules = [ moduleContext ]
        }

foldProjectContexts : ProjectContext -> ProjectContext -> ProjectContext
foldProjectContexts a b =
    let
        routeKey =
            case a.routeModuleKey of
                Just key -> Just key
                Nothing -> b.routeModuleKey
        routeLastLine =
            if a.routeModuleLastLine > b.routeModuleLastLine then
                a.routeModuleLastLine
            else
                b.routeModuleLastLine
    in
    { routeModuleKey = routeKey
    , routeModuleLastLine = routeLastLine
    , modules = a.modules ++ b.modules
    }

moduleDefinitionVisitor : Node Module -> ModuleContext -> ( List (Error {}), ModuleContext )
moduleDefinitionVisitor node context =
    ( [], updateLastLine (Node.range node) context )

importVisitor : Node Import -> ModuleContext -> ( List (Error {}), ModuleContext )
importVisitor node context =
    let
        imp = Node.value node
        moduleName = String.join "." (Node.value imp.moduleName)
        isSystem =
            moduleName == "Html"
                || String.startsWith "Html." moduleName
                || moduleName == "Url"
                || String.startsWith "Url." moduleName
        updatedContext = updateLastLine (Node.range node) context
    in
    if isSystem then
        ( [], updatedContext )
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
        ( [], { updatedContext | imports = importLine :: updatedContext.imports } )

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

declarationVisitor : Node Declaration -> ModuleContext -> ( List (Error {}), ModuleContext )
declarationVisitor node context =
    let
        updatedContext = updateLastLine (Node.range node) context
    in
    case Node.value node of
        FunctionDeclaration func ->
            let
                declaration = Node.value func.declaration
                funcName = Node.value declaration.name
                maybeDoc = func.documentation
            in
            if updatedContext.isRouteModule && funcName == "links" then
                let
                    isEmptyList =
                        case Node.value declaration.expression of
                            ListExpr [] ->
                                True
                            _ ->
                                False
                in
                if isEmptyList then
                    ( [], updatedContext )
                else
                    ( [], { updatedContext | codes = [ ("dummy", { codes = [], imports = [] }) ] } )
            else
                case maybeDoc of
                    Just (Node range commentStr) ->
                        if String.contains "<shiori" commentStr then
                            let
                                extracted = extract commentStr
                            in
                            if List.isEmpty extracted.codes then
                                ( [], updatedContext )
                            else
                                let
                                    mergedImports = extracted.imports ++ updatedContext.imports
                                    extractedWithMerged = { extracted | imports = mergedImports }
                                    jsonStr = encodeResult funcName extractedWithMerged
                                in
                                ( [ Rule.error
                                        { message = "SHIORI_EXTRACT:" ++ jsonStr
                                        , details = [ "Contains shiori tag" ]
                                        }
                                        range
                                  ]
                                , { updatedContext | codes = (funcName, extracted) :: updatedContext.codes }
                                )
                        else
                            ( [], updatedContext )

                    Nothing ->
                        ( [], updatedContext )

        _ ->
            ( [], updatedContext )

updateLastLine : Range -> ModuleContext -> ModuleContext
updateLastLine range context =
    let
        endRow = range.end.row
    in
    if endRow > context.lastLine then
        { context | lastLine = endRow }
    else
        context

encodeResult : String -> Extracted -> String
encodeResult funcName extracted =
    Encode.object
        [ ( "funcName", Encode.string funcName )
        , ( "codes", Encode.list encodeCode extracted.codes )
        , ( "imports", Encode.list Encode.string extracted.imports )
        ]
        |> Encode.encode 0

encodeCode : ExtractedCode -> Encode.Value
encodeCode c =
    Encode.object
        [ ( "name", Encode.string c.name )
        , ( "code", Encode.string c.code )
        ]

-- Parsing Logic
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
    { currentBlock : Maybe ( String, List String )
    , codes : List ExtractedCode
    , imports : List String
    }

parseLines : List String -> ParseState -> Extracted
parseLines lines state =
    case lines of
        [] ->
            let
                finalCodes =
                    case state.currentBlock of
                        Just ( name, block ) ->
                            case block of
                                [] -> state.codes
                                first :: _ -> { name = name, code = String.trim first } :: state.codes
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
                    Just ( name, block ) ->
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
                                    , codes = if String.isEmpty fullBlock then state.codes else { name = name, code = fullBlock } :: state.codes
                                }
                        else
                            parseLines rest { state | currentBlock = Just ( name, line :: block ) }

                    Nothing ->
                        if String.contains "<shiori" line then
                            let
                                after =
                                    case String.split "<shiori" line of
                                        _ :: restPart -> String.join "<shiori" restPart
                                        [] -> ""

                                idx =
                                    case String.indexes ">" after of
                                        firstIdx :: _ -> firstIdx
                                        [] -> 0

                                afterStart =
                                    String.dropLeft (idx + 1) after

                                tagContent =
                                    String.left idx after

                                name =
                                    if String.contains "name=\"" tagContent then
                                        case String.split "name=\"" tagContent of
                                            _ :: namePart :: _ ->
                                                case String.split "\"" namePart of
                                                    actualName :: _ -> actualName
                                                    [] -> ""
                                            _ -> ""
                                    else
                                        ""
                            in
                            if String.contains "</shiori>" afterStart then
                                let
                                    code =
                                        case String.split "</shiori>" afterStart of
                                            before :: _ -> String.trim before
                                            [] -> ""
                                    newCodes =
                                        if String.isEmpty code then state.codes else { name = name, code = code } :: state.codes
                                in
                                parseLines rest { state | codes = newCodes }
                            else
                                let
                                    hasClose =
                                        List.any (String.contains "</shiori>") rest
                                in
                                if hasClose then
                                    parseLines rest { state | currentBlock = Just ( name, [afterStart] ) }
                                else
                                    parseLines rest state
                        else
                            parseLines rest state

-- Route.elm Generation Logic
finalEvaluation : ProjectContext -> List (Error { useErrorForModule : () })
finalEvaluation projectContext =
    case projectContext.routeModuleKey of
        Just routeKey ->
            let
                -- 他のモジュールにプレビュー（シャオリタグ）が存在するかどうか
                hasShioriTags =
                    projectContext.modules
                        |> List.filter (\m -> not m.isRouteModule)
                        |> List.any (\m -> not (List.isEmpty m.codes))

                -- Shiori.Route モジュールがまだプレースホルダー状態かどうか
                routeModuleContext =
                    projectContext.modules
                        |> List.filter (\m -> m.isRouteModule)
                        |> List.head

                routeIsPlaceholder =
                    case routeModuleContext of
                        Just r ->
                            List.isEmpty r.codes

                        Nothing ->
                            True
            in
            if hasShioriTags && routeIsPlaceholder then
                let
                    -- 自動生成の対象は Shiori.Route 以外の、プレビュー関数があるモジュール
                    validModules =
                        projectContext.modules
                            |> List.filter (\m -> not m.isRouteModule && not (List.isEmpty m.codes))
                            |> List.sortBy .moduleName
                    
                    generatedCode = generateRouteSource validModules
                    
                    targetRange =
                        { start = { row = 1, column = 1 }
                        , end = { row = projectContext.routeModuleLastLine + 5, column = 100 }
                        }
                in
                [ Rule.errorForModuleWithFix routeKey
                    { message = "Route module needs to be updated with shiori previews"
                    , details = [ "Auto-generated Route.elm with updated previews" ]
                    }
                    { start = { row = 1, column = 1 }, end = { row = 1, column = 2 } }
                    [ Fix.replaceRangeBy targetRange generatedCode ]
                ]
            else
                []

        Nothing ->
            []

generateRouteSource : List ModuleContext -> String
generateRouteSource modules =
    let
        moduleNames = List.map .moduleName modules

        importsSection =
            moduleNames
                |> List.map (\m -> "import " ++ m)
                |> String.join "\n"

        -- カスタムインポートの集約と重複排除
        customImports =
            modules
                |> List.foldl (\m acc -> m.imports ++ acc) []
                -- さらに各モジュールの関数ごとのインポートも集約
                |> (\list -> List.foldl (\(_, ext) acc -> ext.imports ++ acc) list (List.concatMap .codes modules))
                |> uniqueList
                |> List.sort
                |> String.join "\n"

        -- Route 型定義
        routeVariants =
            "NotFound" :: List.map (\m -> m.moduleName |> String.replace "." "_" |> (\variant -> variant ++ " String (Maybe Int)")) modules
        
        routeTypeSection =
            "type Route\n    = " ++ String.join "\n    | " routeVariants

        -- routeParser
        parserItemsForModule m =
            let
                variant = String.replace "." "_" m.moduleName
            in
            [ "Url.Parser.map (\\f idx -> " ++ variant ++ " f (Just idx)) (s \"" ++ m.moduleName ++ "\" </> string </> Url.Parser.int)"
            , "Url.Parser.map (\\f -> " ++ variant ++ " f Nothing) (s \"" ++ m.moduleName ++ "\" </> string)"
            ]

        parserSection =
            "routeParser : Parser (Route -> b) b\nrouteParser =\n    oneOf\n        [ "
                ++ (List.concatMap parserItemsForModule modules |> String.join "\n        , ")
                ++ "\n        ]"

        -- view
        viewBranches =
            "        NotFound ->\n            []" :: List.map viewBranchForModule modules
        
        viewSection =
            "view : Url.Url -> List (Html.Html ())\nview url =\n    case url |> toRoute of\n"
                ++ String.join "\n\n" viewBranches

        -- links
        linksSection =
            "links : List ( String, List ( String, List ( String, String ) ) )\nlinks =\n    [ "
                ++ (List.map linksItemForModule modules |> String.join "\n    , ")
                ++ "\n    ]"
    in
    String.join "\n\n"
        [ "module Shiori.Route exposing (Route(..), links, routeParser, toRoute, view)"
        , "import Html exposing (Html)"
        , "import Url"
        , "import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, string)"
        , "import Shiori_View"
        , importsSection
        , customImports
        , routeTypeSection
        , parserSection
        , "toRoute : Url.Url -> Route\ntoRoute url =\n    url\n        |> parse routeParser\n        |> Maybe.withDefault NotFound"
        , viewSection
        , linksSection
        ] ++ "\n"

viewBranchForModule : ModuleContext -> String
viewBranchForModule m =
    let
        variant = String.replace "." "_" m.moduleName
        funcBranches = List.map (viewBranchForFunc m.moduleName) m.codes
    in
    "        " ++ variant ++ " str maybeIdx ->\n            case str of\n"
        ++ String.join "\n" funcBranches
        ++ "\n                _ ->\n                    []"

viewBranchForFunc : String -> (String, Extracted) -> String
viewBranchForFunc moduleName (funcName, ext) =
    let
        letBindings =
            ext.codes
                |> List.indexedMap (\i c ->
                    let
                        resolvedCode = resolveSymbols moduleName funcName c.code
                        indented = indentCode 28 resolvedCode
                    in
                    "                        preview_" ++ String.fromInt i ++ " =\n" ++ indented
                )
                |> String.join "\n\n"

        cardCodes =
            ext.codes
                |> List.indexedMap (\i c ->
                    let
                        displayName = if String.isEmpty c.name then "Preview " ++ String.fromInt i else c.name
                    in
                    "Shiori_View.card \"" ++ displayName ++ "\" preview_" ++ String.fromInt i
                )

        cardsJoined =
            String.join "\n                            , " cardCodes

        soloBranches =
            ext.codes
                |> List.indexedMap (\i _ ->
                    "                                " ++ String.fromInt i ++ " ->\n                                    [ Shiori_View.solo preview_" ++ String.fromInt i ++ " ] |> Shiori_View.map"
                )
                |> String.join "\n\n"
    in
    "                \"" ++ funcName ++ "\" ->\n                    let\n"
        ++ letBindings
        ++ "\n                    in\n                    case maybeIdx of\n                        Just idx ->\n                            case idx of\n"
        ++ soloBranches
        ++ "\n\n                                _ ->\n                                    []\n                        Nothing ->\n                            [ "
        ++ cardsJoined
        ++ "\n                            ] |> Shiori_View.map"

linksItemForModule : ModuleContext -> String
linksItemForModule m =
    let
        funcItems = List.map (linksItemForFunc m.moduleName) m.codes
    in
    "( \"" ++ m.moduleName ++ "\", [ " ++ String.join "\n      , " funcItems ++ " ] )"

linksItemForFunc : String -> (String, Extracted) -> String
linksItemForFunc moduleName (funcName, ext) =
    let
        subItems =
            ext.codes
                |> List.indexedMap (\i c ->
                    let
                        displayName = if String.isEmpty c.name then "Preview " ++ String.fromInt i else c.name
                        path = "/" ++ moduleName ++ "/" ++ funcName ++ "/" ++ String.fromInt i
                    in
                    "( \"" ++ displayName ++ "\", \"" ++ path ++ "\" )"
                )
    in
    "( \"" ++ funcName ++ "\", [ " ++ String.join ", " subItems ++ " ] )"

-- Helper: Symbols resolution (replacing funcName with Module.funcName)
resolveSymbols : String -> String -> String -> String
resolveSymbols moduleName funcName target =
    let
        isWordChar char =
            Char.isAlphaNum char || char == '_'
        
        elmBuiltins =
            [ "Bool", "True", "False", "Int", "Float", "Char", "String", "List", "Maybe"
            , "Just", "Nothing", "Result", "Ok", "Err", "Order", "LT", "EQ", "GT", "Never"
            , "Program", "Cmd", "Sub"
            ]

        isBuiltin w =
            List.member w elmBuiltins

        isCapitalized w =
            case String.toList w of
                c :: _ ->
                    Char.isUpper c
                [] ->
                    False

        replaceWord w =
            if w == funcName then
                moduleName ++ "." ++ funcName
            else if isCapitalized w && not (isBuiltin w) then
                moduleName ++ "." ++ w
            else
                w

        splitAndReplace list currentAcc resultAcc =
            case list of
                [] ->
                    resultAcc ++ replaceWord currentAcc

                c :: rest ->
                    if isWordChar c then
                        splitAndReplace rest (currentAcc ++ String.fromChar c) resultAcc
                    else
                        splitAndReplace rest "" (resultAcc ++ replaceWord currentAcc ++ String.fromChar c)
    in
    splitAndReplace (String.toList target) "" ""

-- Helper: Indentation helper
indentCode : Int -> String -> String
indentCode spaces code =
    let
        lines = String.split "\n" code
        trimmedLines = List.filter (\l -> String.trim l /= "") lines
        
        getIndentLen line =
            let
                chars = String.toList line
                countSpaces list acc =
                    case list of
                        ' ' :: rest -> countSpaces rest (acc + 1)
                        '\t' :: rest -> countSpaces rest (acc + 4)
                        _ -> acc
            in
            countSpaces chars 0

        minIndent =
            trimmedLines
                |> List.map getIndentLen
                |> List.minimum
                |> Maybe.withDefault 0

        pad = String.repeat spaces " "
        
        processLine line =
            if String.trim line == "" then
                ""
            else
                pad ++ String.dropLeft minIndent line
    in
    lines
        |> List.map processLine
        |> String.join "\n"

-- Helper: Unique list elements
uniqueList : List a -> List a
uniqueList list =
    let
        addUnique item acc =
            if List.member item acc then
                acc
            else
                item :: acc
    in
    List.foldl addUnique [] list |> List.reverse
