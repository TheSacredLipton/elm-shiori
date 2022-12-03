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

    :: column [] <| .body <| view init

    :: column [] <| .body <| view { world = "world" }

    :: column [] <| .body <| view { world = "world2" }

-}
view : Model -> { title : String, body : List (Element Msg) }
view model =
    { title = "home"
    , body = [ text <| "hello " ++ model.world ]
    }
