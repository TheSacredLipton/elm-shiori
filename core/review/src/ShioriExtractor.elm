module ShioriExtractor exposing (rule)

import Elm.Syntax.Declaration exposing (Declaration(..))
import Elm.Syntax.Node as Node exposing (Node(..))
import Elm.Syntax.ModuleName exposing (ModuleName)
import Review.Rule as Rule exposing (Error, Rule)

rule : Rule
rule =
    Rule.newModuleRuleSchema "ShioriExtractor" ()
        |> Rule.withDeclarationEnterVisitor declarationVisitor
        |> Rule.fromModuleRuleSchema

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
                        ( [ Rule.error
                                { message = "SHIORI_EXTRACT:" ++ funcName ++ ":" ++ commentStr
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
