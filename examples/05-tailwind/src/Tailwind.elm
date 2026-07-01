module Tailwind exposing (Model, main, view, profileCard, articleCard, pricingSection, widthTest)

import Browser
import Html exposing (..)
import Html.Attributes exposing (class, src)


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
    div [ class "p-8 text-center bg-slate-50 rounded-2xl border border-slate-100" ]
        [ h1 [ class "text-2xl font-bold text-slate-800 mb-2" ] [ text "Tailwind CSS Components Catalog" ]
        , p [ class "text-sm text-slate-500" ] [ text "Select one of the components from the sidebar navigation to preview them." ]
        ]


{-|

    <shiori> profileCard

-}
profileCard : Html msg
profileCard =
    div [ class "flex items-center justify-center p-6 bg-slate-50" ]
        [ div [ class "w-full max-w-xs bg-white rounded-2xl shadow-md overflow-hidden border border-slate-100 transition-all duration-300 hover:shadow-lg hover:-translate-y-1" ]
            [ div [ class "h-24 bg-gradient-to-r from-sky-400 to-blue-500" ] []
            , div [ class "px-6 pb-6 text-center" ]
                [ div [ class "relative -mt-12 mb-3 inline-block" ]
                    [ img [ class "w-24 h-24 rounded-full border-4 border-white object-cover shadow-sm", src "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80" ] []
                    , span [ class "absolute bottom-1 right-1 block h-4 w-4 rounded-full bg-emerald-400 border-2 border-white" ] []
                    ]
                , h3 [ class "text-lg font-bold text-slate-800" ] [ text "Sarah Jenkins" ]
                , p [ class "text-xs text-slate-400 font-medium mb-4" ] [ text "Lead Frontend Engineer" ]
                , div [ class "flex flex-wrap justify-center gap-1.5 mb-6" ]
                    [ span [ class "px-2 py-0.5 text-[10px] font-semibold bg-sky-50 text-sky-600 rounded-full" ] [ text "Elm" ]
                    , span [ class "px-2 py-0.5 text-[10px] font-semibold bg-blue-50 text-blue-600 rounded-full" ] [ text "Tailwind" ]
                    , span [ class "px-2 py-0.5 text-[10px] font-semibold bg-violet-50 text-violet-600 rounded-full" ] [ text "TypeScript" ]
                    ]
                , button [ class "w-full py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold rounded-lg shadow transition-all duration-150 active:scale-95" ]
                    [ text "Follow" ]
                ]
            ]
        ]


{-|

    <shiori> articleCard

-}
articleCard : Html msg
articleCard =
    div [ class "flex items-center justify-center p-6 bg-slate-50" ]
        [ div [ class "w-full max-w-sm bg-white rounded-2xl shadow-sm overflow-hidden border border-slate-100 transition-all duration-300 hover:shadow-md" ]
            [ div [ class "relative h-48 overflow-hidden" ]
                [ img [ class "w-full h-full object-cover transition-transform duration-500 hover:scale-105", src "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&auto=format&fit=crop&q=80" ] []
                , span [ class "absolute top-4 left-4 px-2.5 py-1 text-[11px] font-bold bg-white/90 backdrop-blur-sm text-slate-900 rounded-full uppercase tracking-wider" ] [ text "Travel" ]
                ]
            , div [ class "p-5" ]
                [ p [ class "text-xs text-slate-400 mb-2 font-medium" ] [ text "July 1, 2026 • 5 min read" ]
                , h4 [ class "text-lg font-bold text-slate-800 mb-2 hover:text-sky-500 cursor-pointer transition-colors duration-150" ]
                    [ text "Designing the Ultimate Sandbox Environment for Elm" ]
                , p [ class "text-sm text-slate-500 line-clamp-2 mb-4 font-normal leading-relaxed text-left" ]
                    [ text "Explore how to isolate styles using modern iframe techniques in web application design, ensuring your components are visually pure." ]
                , div [ class "flex items-center gap-3 pt-3 border-t border-slate-100" ]
                    [ img [ class "w-8 h-8 rounded-full object-cover", src "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop&q=80" ] []
                    , div [ class "text-left" ]
                        [ p [ class "text-xs font-semibold text-slate-800" ] [ text "Alex Rivera" ]
                        , p [ class "text-[10px] text-slate-400" ] [ text "Designer & Writer" ]
                        ]
                    ]
                ]
            ]
        ]


{-|

    <shiori> pricingSection

-}
pricingSection : Html msg
pricingSection =
    div [ class "py-8 px-4 bg-slate-50 text-center rounded-2xl border border-slate-100" ]
        [ h2 [ class "text-2xl font-bold text-slate-800 mb-2" ] [ text "Simple, Transparent Pricing" ]
        , p [ class "text-sm text-slate-500 mb-8 max-w-md mx-auto" ] [ text "Choose the plan that fits your workflow. Start building immediately." ]
        , div [ class "flex flex-col md:flex-row justify-center items-center gap-6 max-w-4xl mx-auto" ]
            [ div [ class "flex-1 w-full max-w-sm p-6 bg-white rounded-2xl border border-slate-100 shadow-sm" ]
                [ h3 [ class "text-sm font-bold text-slate-400 uppercase tracking-wider mb-2" ] [ text "Basic" ]
                , div [ class "flex items-baseline justify-center gap-1 mb-4" ]
                    [ span [ class "text-3xl font-extrabold text-slate-800" ] [ text "$0" ]
                    , span [ class "text-xs text-slate-400" ] [ text "/mo" ]
                    ]
                , p [ class "text-xs text-slate-500 mb-6" ] [ text "Perfect for individual developers experimenting with Elm." ]
                , button [ class "w-full py-2 bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-bold rounded-lg mb-6 transition-colors duration-150" ]
                    [ text "Get Started" ]
                , ul [ class "text-left text-xs text-slate-600 space-y-2.5 border-t border-slate-100 pt-6" ]
                    [ li [ class "flex items-center gap-2" ]
                        [ span [ class "text-emerald-500 font-bold" ] [ text "✓" ]
                        , text "Up to 5 active components"
                        ]
                    , li [ class "flex items-center gap-2" ]
                        [ span [ class "text-emerald-500 font-bold" ] [ text "✓" ]
                        , text "Basic catalog hosting"
                        ]
                    ]
                ]
            , div [ class "flex-1 w-full max-w-sm p-6 bg-white rounded-2xl border-2 border-sky-500 shadow-md relative overflow-hidden" ]
                [ div [ class "absolute top-0 right-0 bg-sky-500 text-white text-[9px] font-bold px-3 py-1 rounded-bl-lg uppercase tracking-wider" ] [ text "Popular" ]
                , h3 [ class "text-sm font-bold text-slate-400 uppercase tracking-wider mb-2" ] [ text "Pro" ]
                , div [ class "flex items-baseline justify-center gap-1 mb-4" ]
                    [ span [ class "text-4xl font-extrabold text-slate-800" ] [ text "$19" ]
                    , span [ class "text-xs text-slate-400" ] [ text "/mo" ]
                    ]
                , p [ class "text-xs text-slate-500 mb-6" ] [ text "For professional developers needing advanced isolation." ]
                , button [ class "w-full py-2 bg-sky-500 hover:bg-sky-600 text-white text-xs font-bold rounded-lg mb-6 shadow-sm shadow-sky-500/20 transition-colors duration-150" ]
                    [ text "Upgrade to Pro" ]
                , ul [ class "text-left text-xs text-slate-600 space-y-2.5 border-t border-slate-100 pt-6" ]
                    [ li [ class "flex items-center gap-2" ]
                        [ span [ class "text-emerald-500 font-bold" ] [ text "✓" ]
                        , text "Unlimited active components"
                        ]
                    , li [ class "flex items-center gap-2" ]
                        [ span [ class "text-emerald-500 font-bold" ] [ text "✓" ]
                        , text "Automatic iframe isolation"
                        ]
                    ]
                ]
            ]
        ]


{-|

    <shiori> widthTest

-}
widthTest : Html msg
widthTest =
    div [ class "bg-sky-400 w-[2000px] h-10" ] []
