module Shiori exposing (main)

import Browser
import Browser.Dom exposing (setViewport)
import Browser.Navigation as Nav
import Html exposing (Html, a, div, map, text)
import Html.Attributes exposing (href, style)
import Html.Events exposing (onClick)
import Shiori.Route as Route
import Task
import Url
import Url.Builder as Builder


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , isActive : Bool
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { key = key
      , url = url
      , isActive = False
      }
    , Cmd.none
    )


type Msg
    = UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url
    | ToggleMenu
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url, isActive = False }
            , Cmd.none
            )

        ToggleMenu ->
            ( { model | isActive = not model.isActive }, Task.perform (\_ -> NoOp) (setViewport 0 0) )

        NoOp ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "elm-shiori"
    , body =
        [ div
            [ style "display" "flex"
            , style "flex-direction" "column"
            , style "height" "100vh"
            , style "align-items" "center"
            ]
            [ header
            , header_
            , smNav model.isActive
            , div
                [ style "max-width" "900px"
                , style "width" "100%"
                , style "display" "flex"
                , style "gap" "24px"
                ]
                [ sideNav 250
                , sideNav_ 250
                , body model.url
                ]
            ]
        ]
    }


header : Html Msg
header =
    div
        [ style "height" "48px"
        , style "width" "100%"
        , style "background-color" "#FB923C"
        , style "box-shadow" "0 2px 2px 0 rgba(0, 0, 0, 0.2)"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "left" "0"
        , style "position" "fixed"
        , style "top" "0"
        , style "z-index" "10"
        ]
        [ div
            [ style "max-width" "900px"
            , style "width" "100%"
            , style "height" "100%"
            , style "padding" "0px 20px"
            , style "box-sizing" "border-box"
            , style "color" "#FFFFFF"
            , style "display" "flex"
            , style "justify-content" "space-between"
            , style "align-items" "center"
            ]
            [ div
                []
                [ a
                    [ href "/"
                    , style "color" "#FFFFFF"
                    , style "display" "block"
                    , style "text-decoration" "none"
                    , style "box-sizing" "border-box"
                    ]
                    [ text "elm-shiori" ]
                ]
            , menuButton
            ]
        ]


menuButton : Html Msg
menuButton =
    div
        [ onClick ToggleMenu
        , style "padding" "10px 0px"
        , style "box-sizing" "border-box"
        , style "display" "block"
        , style "display" "flex"
        , style "fill" "currentColor"
        ]
        []


header_ : Html msg
header_ =
    div
        [ style "height" "48px"
        , style "flex-shrink" "0"
        ]
        []


sideNav : Int -> Html msg
sideNav width =
    div
        [ style "width" <| String.fromInt width ++ "px"
        , style "height" "calc(100% - 48px)"
        , style "padding" "30px 20px"
        , style "box-sizing" "border-box"
        , style "flex-direction" "column"
        , style "gap" "24px"
        , style "border-left" "1px solid #E0E0E0"
        , style "position" "fixed"
        , style "display" "none"
        , style "overflow-y" "scroll"
        , style "display" "flex"
        ]
    <|
        List.map sideNavLinkGroup Route.links


sideNav_ : Int -> Html msg
sideNav_ width =
    div
        [ style "width" <| String.fromInt width ++ "px"
        , style "flex-shrink" "0"
        , style "display" "none"
        , style "display" "flex"
        ]
        []


smNav : Bool -> Html msg
smNav isActive =
    if isActive then
        div
            [ style "display" "block"
            , style "width" "100%"
            , style "box-sizing" "border-box"
            , style "padding" "20px"
            , style "box-shadow" "0 2px 2px 0 rgba(0, 0, 0, 0.2)"
            ]
        <|
            List.map sideNavLinkGroup Route.links

    else
        text ""


type alias FileName =
    String


type alias FunctionName =
    String


sideNavLinkGroup : ( FileName, List ( FunctionName, List String ) ) -> Html msg
sideNavLinkGroup ( fileName, v ) =
    div [ style "gap" "8px", style "width" "100%" ]
        [ div [ style "font-size" "20" ] [ text fileName ]
        , div [ style "width" "100%", style "font-size" "16px" ] <| List.map (\( functionName, _ ) -> sideNavLink functionName <| Builder.absolute [ fileName, functionName ] []) <| v
        ]


sideNavLink : FunctionName -> String -> Html msg
sideNavLink name url =
    a
        [ style "width" "100%"
        , style "padding" "8px 10px"
        , style "color" "#969696"
        , style "display" "block"
        , style "text-decoration" "none"
        , style "box-sizing" "border-box"
        , href url
        ]
        [ text name ]


body : Url.Url -> Html Msg
body url =
    div
        [ style "width" "100%"
        , style "padding" "30px 10px"
        , style "box-sizing" "border-box"
        ]
        [ div
            [ style "gap" "20px"
            , style "display" "flex"
            , style "flex-direction" "column"
            ]
          <|
            List.map (map (always NoOp)) (Route.view url)
        ]
