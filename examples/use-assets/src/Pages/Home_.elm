module Pages.Home_ exposing (..)

import Html exposing (..)


{-|

    <shiori> home

-}
home : Html msg
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

    import Html exposing (div)

    <shiori> div [] <| .body <| view init

    <shiori> div [] <| .body <| view { world = "world" }

    <shiori> div [] <| .body <| view { world = "world2" }

-}
view : Model -> { title : String, body : List (Html Msg) }
view model =
    { title = "home"
    , body = [ text <| "hello " ++ model.world ]
    }
