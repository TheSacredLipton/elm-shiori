module Css exposing (Model, main, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class)


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }


type alias Model =
    { property : Int
    , property2 : String
    }


init : Model
init =
    Model 0 "modelInitialValue2"


type Msg
    = Msg1
    | Msg2


update : Msg -> Model -> Model
update msg model =
    case msg of
        Msg1 ->
            model

        Msg2 ->
            model


{-|

    <shiori> view (Model 0 "modelInitialValue2")

-}
view : Model -> Html Msg
view _ =
    div [ class "hello" ]
        [ text "hello" ]
