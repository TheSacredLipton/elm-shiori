module ElmCss exposing (Model, main, view, styledButton, infoCard)

import Browser
import Css exposing (..)
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (css, href, src)


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = \model -> Html.Styled.toUnstyled (view model)
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

    <shiori name="Indigo Button"> ElmCss.styledButton "Click me" </shiori>
    <shiori name="Pink Button"> ElmCss.styledButton "Submit" </shiori>
    <shiori name="Gray Button"> ElmCss.styledButton "Cancel" </shiori>

-}
styledButton : String -> Html.Styled.Html msg
styledButton label =
    button
        [ css
            [ padding2 (px 12) (px 24)
            , backgroundColor (rgb 99 102 241)
            , hover [ backgroundColor (rgb 79 70 229) ]
            , color (rgb 255 255 255)
            , border (px 0)
            , borderRadius (px 8)
            , fontSize (px 14)
            , fontWeight bold
            , cursor pointer
            , boxShadow4 (px 0) (px 4) (px 6) (rgba 99 102 241 0.2)
            ]
        ]
        [ text label ]


{-|

    <shiori name="Info Card A"> ElmCss.infoCard </shiori>
    <shiori name="Info Card B"> ElmCss.infoCard </shiori>

-}
infoCard : Html.Styled.Html msg
infoCard =
    div
        [ css
            [ displayFlex
            , flexDirection column
            , property "gap" "8px"
            , padding (px 20)
            , backgroundColor (rgb 255 255 255)
            , borderRadius (px 16)
            , border3 (px 1) solid (rgb 243 244 246)
            , boxShadow4 (px 0) (px 10) (px 15) (rgba 0 0 0 0.03)
            , maxWidth (px 300)
            , fontFamily sansSerif
            ]
        ]
        [ h4
            [ css
                [ margin (px 0)
                , fontSize (px 16)
                , fontWeight bold
                , color (rgb 31 41 55)
                ]
            ]
            [ text "elm-css Isolation" ]
        , p
            [ css
                [ margin (px 0)
                , fontSize (px 13)
                , color (rgb 107 114 128)
                , lineHeight (num 1.5)
                ]
            ]
            [ text "This card component styles are compiled using elm-css and fully isolated within the iframe viewer." ]
        ]


view : Model -> Html.Styled.Html Msg
view _ =
    div [] [ text "hello" ]
