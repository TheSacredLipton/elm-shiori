module Gen.Main exposing (annotation_, call_, caseOf_, make_, moduleName_, try, try2, values_)

{-| 
@docs values_, call_, caseOf_, make_, annotation_, try, try2, moduleName_
-}


import Elm
import Elm.Annotation as Type
import Elm.Case


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "Main" ]


{-| try2: Int -> Element Msg -}
try2 : Int -> Elm.Expression
try2 try2Arg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Main" ]
            , name = "try2"
            , annotation =
                Just
                    (Type.function
                        [ Type.int ]
                        (Type.namedWith
                            []
                            "Element"
                            [ Type.namedWith [] "Msg" [] ]
                        )
                    )
            }
        )
        [ Elm.int try2Arg ]


{-| {-| UITEST:BUTTON

    import Dict

    : layout [] <| try 1

    : layout [] <| try 2

    : layout [] <| try 3

-}

try: Int -> Element msg
-}
try : Int -> Elm.Expression
try tryArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "Main" ]
            , name = "try"
            , annotation =
                Just
                    (Type.function
                        [ Type.int ]
                        (Type.namedWith [] "Element" [ Type.var "msg" ])
                    )
            }
        )
        [ Elm.int tryArg ]


annotation_ : { msg : Type.Annotation }
annotation_ =
    { msg = Type.namedWith [ "Main" ] "Msg" [] }


make_ : { replaceMe : Elm.Expression }
make_ =
    { replaceMe =
        Elm.value
            { importFrom = [ "Main" ]
            , name = "ReplaceMe"
            , annotation = Just (Type.namedWith [] "Msg" [])
            }
    }


caseOf_ :
    { msg :
        Elm.Expression
        -> { msgTags_0_0 | replaceMe : Elm.Expression }
        -> Elm.Expression
    }
caseOf_ =
    { msg =
        \msgExpression msgTags ->
            Elm.Case.custom
                msgExpression
                (Type.namedWith [ "Main" ] "Msg" [])
                [ Elm.Case.branch0 "ReplaceMe" msgTags.replaceMe ]
    }


call_ :
    { try2 : Elm.Expression -> Elm.Expression
    , try : Elm.Expression -> Elm.Expression
    }
call_ =
    { try2 =
        \try2Arg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Main" ]
                    , name = "try2"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.int ]
                                (Type.namedWith
                                    []
                                    "Element"
                                    [ Type.namedWith [] "Msg" [] ]
                                )
                            )
                    }
                )
                [ try2Arg ]
    , try =
        \tryArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "Main" ]
                    , name = "try"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.int ]
                                (Type.namedWith [] "Element" [ Type.var "msg" ])
                            )
                    }
                )
                [ tryArg ]
    }


values_ : { try2 : Elm.Expression, try : Elm.Expression }
values_ =
    { try2 =
        Elm.value
            { importFrom = [ "Main" ]
            , name = "try2"
            , annotation =
                Just
                    (Type.function
                        [ Type.int ]
                        (Type.namedWith
                            []
                            "Element"
                            [ Type.namedWith [] "Msg" [] ]
                        )
                    )
            }
    , try =
        Elm.value
            { importFrom = [ "Main" ]
            , name = "try"
            , annotation =
                Just
                    (Type.function
                        [ Type.int ]
                        (Type.namedWith [] "Element" [ Type.var "msg" ])
                    )
            }
    }


