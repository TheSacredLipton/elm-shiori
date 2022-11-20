module Gen.UiTest exposing (annotation_, call_, moduleName_, values_, view)

{-| 
@docs values_, call_, annotation_, view, moduleName_
-}


import Elm
import Elm.Annotation as Type


{-| The name of this module. -}
moduleName_ : List String
moduleName_ =
    [ "UiTest" ]


{-| {-| -}

view: Html.Html msg -> UI
-}
view : Elm.Expression -> Elm.Expression
view viewArg =
    Elm.apply
        (Elm.value
            { importFrom = [ "UiTest" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Html" ] "Html" [ Type.var "msg" ] ]
                        (Type.namedWith [] "UI" [])
                    )
            }
        )
        [ viewArg ]


annotation_ : { uI : Type.Annotation }
annotation_ =
    { uI =
        Type.alias
            moduleName_
            "UI"
            []
            (Type.namedWith [] "Program" [ Type.unit, Type.unit, Type.unit ])
    }


call_ : { view : Elm.Expression -> Elm.Expression }
call_ =
    { view =
        \viewArg ->
            Elm.apply
                (Elm.value
                    { importFrom = [ "UiTest" ]
                    , name = "view"
                    , annotation =
                        Just
                            (Type.function
                                [ Type.namedWith
                                    [ "Html" ]
                                    "Html"
                                    [ Type.var "msg" ]
                                ]
                                (Type.namedWith [] "UI" [])
                            )
                    }
                )
                [ viewArg ]
    }


values_ : { view : Elm.Expression }
values_ =
    { view =
        Elm.value
            { importFrom = [ "UiTest" ]
            , name = "view"
            , annotation =
                Just
                    (Type.function
                        [ Type.namedWith [ "Html" ] "Html" [ Type.var "msg" ] ]
                        (Type.namedWith [] "UI" [])
                    )
            }
    }


