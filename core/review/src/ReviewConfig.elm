module ReviewConfig exposing (config)

import Review.Rule exposing (Rule)
import ShioriExtractor

config : List Rule
config =
    [ ShioriExtractor.rule
    ]
