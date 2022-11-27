module Pages.Home_ exposing (..)

import Element exposing (..)


{-|

    :: home

-}
home : Element msg
home =
    text "home"


type Msg
    = ReplaceMe


type alias Model =
    { world : String }


init : Model
init =
    { world = "init" }


{-|

    import Element exposing (..)

    :: column [] <| .body <| view2 init

    :: column [] <| .body <| view2 { world = "world" }

    :: column [] <| .body <| view2 { world = "world2" }

-}
view2 : Model -> { title : String, body : List (Element Msg) }
view2 model =
    { title = "home"
    , body = [ text <| "hello " ++ model.world ]
    }
