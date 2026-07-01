module Css exposing (Model, main, view, premiumCard, switchToggle)

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

    <shiori name="Initial State"> view (Model 0 "modelInitialValue2") </shiori>
    <shiori name="Incremented State"> view (Model 5 "modelInitialValue2") </shiori>

-}
view : Model -> Html Msg
view model =
    div [ class "hello" ]
        [ text ("hello " ++ String.fromInt model.property) ]


{-|

    <shiori name="Premium Layout A"> premiumCard </shiori>
    <shiori name="Premium Layout B"> premiumCard </shiori>

-}
premiumCard : Html msg
premiumCard =
    div [ class "css-card" ]
        [ div [ class "css-card-banner" ] []
        , div [ class "css-card-content" ]
            [ h3 [ class "css-card-title" ] [ text "Creative Project" ]
            , p [ class "css-card-text" ]
                [ text "This component has its styles completely isolated inside an iframe using vanilla CSS files managed via shiori.json configuration." ]
            , button [ class "css-card-btn" ] [ text "Explore" ]
            ]
        ]


{-|

    <shiori name="Switch Toggle"> switchToggle </shiori>

-}
switchToggle : Html msg
switchToggle =
    div [ class "css-switch" ]
        [ div [ class "css-switch-track" ]
            [ div [ class "css-switch-thumb" ] []
            ]
        , span [ class "css-switch-label" ] [ text "Feature enabled" ]
        ]
