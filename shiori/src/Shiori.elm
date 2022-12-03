module Shiori exposing (main)

import Browser
import Browser.Dom exposing (setViewport)
import Browser.Navigation as Nav
import Origami exposing (property, with, withMedia)
import Origami.Html exposing (Html, a, div, fromHtml, map, text, toHtmls)
import Origami.Html.Attributes exposing (css, href)
import Origami.Html.Events exposing (onClick)
import Origami.StyleTag as StyleTag
import Origami.Svg exposing (rect, svg)
import Origami.Svg.Attributes as SA
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
        toHtmls
            [ fromHtml <| StyleTag.styleTag_ [ StyleTag.style "body" [ StyleTag.property "margin" "0" ] ]
            , div
                [ css
                    [ property "display" "flex"
                    , property "flex-direction" "column"
                    , property "height" "100vh"
                    , property "align-items" "center"
                    ]
                ]
                [ header
                , header_
                , smNav model.isActive
                , div
                    [ css
                        [ property "max-width" "900px"
                        , property "width" "100%"
                        , property "display" "flex"
                        , property "gap" "24px"
                        ]
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
        [ css
            [ property "height" "48px"
            , property "width" "100%"
            , property "Background-color" "#FB923C"
            , property "box-shadow" "0 2px 2px 0 rgba(0, 0, 0, 0.2)"
            , property "display" "flex"
            , property "align-items" "center"
            , property "justify-content" "center"
            , property "left" "0"
            , property "position" "fixed"
            , property "top" "0"
            , property "z-index" "10"
            ]
        ]
        [ div
            [ css
                [ property "max-width" "900px"
                , property "width" "100%"
                , property "height" "100%"
                , property "padding" "0px 20px"
                , property "box-sizing" "border-box"
                , property "color" "#FFFFFF"
                , property "display" "flex"
                , property "justify-content" "space-between"
                , property "align-items" "center"
                ]
            ]
            [ div
                []
                [ a
                    [ href "/"
                    , css
                        [ property "color" "#FFFFFF"
                        , property "display" "block"
                        , property "text-decoration" "none"
                        , property "box-sizing" "border-box"
                        , with ":hover" [ property "color" "#DDDDDD" ]
                        ]
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
        , css
            [ property "padding" "10px 0px"
            , property "box-sizing" "border-box"
            , property "display" "block"
            , md [ property "display" "none" ]
            , property "fill" "currentColor"
            , with ":hover" [ property "color" "#DDDDDD" ]
            ]
        ]
        [ svg [ SA.width "24", SA.height "16", SA.viewBox "0 0 24 24" ]
            [ rect [ SA.x "0", SA.y "2", SA.width "24", SA.height "2" ] []
            , rect [ SA.x "0", SA.y "12", SA.width "24", SA.height "2" ] []
            , rect [ SA.x "0", SA.y "22", SA.width "24", SA.height "2" ] []
            ]
        ]


header_ : Html msg
header_ =
    div
        [ css
            [ property "height" "48px"
            , property "flex-shrink" "0"
            ]
        ]
        []


md : List Origami.Style -> Origami.Style
md properties =
    withMedia "(min-width: 768px)" properties


sideNav : Int -> Html msg
sideNav width =
    div
        [ css
            [ property "width" <| String.fromInt width ++ "px"
            , property "height" "calc(100% - 48px)"
            , property "padding" "30px 20px"
            , property "box-sizing" "border-box"
            , property "flex-direction" "column"
            , property "gap" "24px"
            , property "border-left" "1px solid #E0E0E0"
            , property "position" "fixed"
            , property "display" "none"
            , property "overflow-y" "scroll"
            , md [ property "display" "flex" ]
            ]
        ]
    <|
        List.map sideNavLinkGroup Route.links


sideNav_ : Int -> Html msg
sideNav_ width =
    div
        [ css
            [ property "width" <| String.fromInt width ++ "px"
            , property "flex-shrink" "0"
            , property "display" "none"
            , md [ property "display" "flex" ]
            ]
        ]
        []


smNav : Bool -> Html msg
smNav isActive =
    if isActive then
        div
            [ css
                [ property "display" "block"
                , md [ property "display" "none" ]
                , property "width" "100%"
                , property "box-sizing" "border-box"
                , property "padding" "20px"
                , property "box-shadow" "0 2px 2px 0 rgba(0, 0, 0, 0.2)"
                ]
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
    div [ css [ property "gap" "8px", property "width" "100%" ] ]
        [ div [ css [ property "font-size" "20" ] ] [ text fileName ]
        , div [ css [ property "width" "100%", property "font-size" "16px" ] ] <| List.map (\( functionName, _ ) -> sideNavLink functionName <| Builder.absolute [ fileName, functionName ] []) <| v
        ]


sideNavLink : FunctionName -> String -> Html msg
sideNavLink name url =
    a
        [ css
            [ property "width" "100%"
            , property "padding" "8px 10px"
            , property "color" "#969696"
            , property "display" "block"
            , property "text-decoration" "none"
            , property "box-sizing" "border-box"
            , with ":hover" [ property "color" "#212121" ]
            ]
        , href url
        ]
        [ text name ]


body : Url.Url -> Html Msg
body url =
    div
        [ css
            [ property "width" "100%"
            , property "padding" "30px 10px"
            , property "box-sizing" "border-box"
            ]
        ]
        [ div
            [ css
                [ property "gap" "20px"
                , property "display" "flex"
                , property "flex-direction" "column"
                ]
            ]
          <|
            List.map (map (always NoOp)) (Route.view url)
        ]
