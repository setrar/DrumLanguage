port module Drum exposing (main)

{- This is a starter app which presents a text label, text field, and a button.
   What you enter in the text field is echoed in the label.  When you press the
   button, the text in the label is reverse.
   This version uses `mdgriffith/elm-ui` for the view functions.
-}

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import Html exposing (Html)
import Http
import Json.Encode as E
import Phoneme
    exposing
        ( PhonemeClass(..)
        , Pitch(..)
        , PitchClass(..)
        , multiplyRests
        , phonemeClassOfString
        , pitchOfPhonemeClass1
        , stringOfPhonemeClass
        , stringOfPitch
        )


main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { input : String
    , output : String
    , numberOfRestsString : String
    }


type Msg
    = NoOp
    | InputText String
    | InputNumberOfRests String
    | Play
    | Stop


type alias Flags =
    {}


port sendNotes : List String -> Cmd msg


port sendCommand : String -> Cmd msg


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { input = initialText
      , output = ""
      , numberOfRestsString = "1"
      }
    , Cmd.none
    )


initialText =
    String.replace "\n"
        " "
        """Write something here, e.g.,
Twas brillig, and the slithey toves
did gyre and gimble in the wabe.
All mimsy were the borogroves,
And the mome wraths outgrabe.
"""


subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        InputText str ->
            ( { model | input = str }, Cmd.none )

        InputNumberOfRests str ->
            ( { model | numberOfRestsString = str }, Cmd.none )

        Play ->
            let
                k =
                    String.toInt model.numberOfRestsString |> Maybe.withDefault 1

                pitchOfPhonemeClass =
                    pitchOfPhonemeClass2

                noteList =
                    (model.input ++ "        ")
                        |> String.toLower
                        |> String.split ""
                        |> List.map (phonemeClassOfString >> pitchOfPhonemeClass)
                        |> multiplyRests k
                        |> List.map stringOfPitch
            in
            ( { model
                | output = noteList |> List.take 30 |> String.join " "
              }
            , sendNotes noteList
            )

        Stop ->
            ( model, sendCommand "stop" )



--
-- VIEW
--


view : Model -> Html Msg
view model =
    Element.layout [] (mainColumn model)


mainColumn : Model -> Element Msg
mainColumn model =
    column mainColumnStyle
        [ column [ centerX, spacing 20 ]
            [ title "Drum Language App"
            , inputText model
            , outputDisplay model
            , appButtons model
            ]
        ]


title : String -> Element msg
title str =
    row [ centerX, Font.bold, Font.size 24 ] [ text str ]


outputDisplay : Model -> Element msg
outputDisplay model =
    row [ centerX, Font.size 11 ]
        [ text model.output ]


inputText : Model -> Element Msg
inputText model =
    Input.multiline [ width (px 600), height (px 200) ]
        { onChange = InputText
        , text = model.input
        , placeholder = Nothing
        , label = Input.labelLeft [] <| el [] (text "")
        , spellcheck = False
        }


inputNumberOfRests : Model -> Element Msg
inputNumberOfRests model =
    Input.text [ width (px 60) ]
        { onChange = InputNumberOfRests
        , text = model.numberOfRestsString
        , placeholder = Nothing
        , label = Input.labelLeft [] <| el [ moveDown 13, paddingXY 4 0 ] (text "Rests")
        }


appButtons : Model -> Element Msg
appButtons model =
    row [ centerX, spacing 20 ]
        [ Input.button buttonStyle
            { onPress = Just Play
            , label = el [ centerX, centerY ] (text "Play")
            }
        , Input.button buttonStyle
            { onPress = Just Stop
            , label = el [ centerX, centerY ] (text "Stop")
            }
        , inputNumberOfRests model
        ]



--
-- STYLE
--


mainColumnStyle =
    [ centerX
    , centerY
    , Background.color (rgb255 240 240 240)
    , width (px 700)
    , paddingXY 20 20
    ]


buttonStyle =
    [ Background.color (rgb255 40 40 40)
    , Font.color (rgb255 255 255 255)
    , paddingXY 15 8
    ]


pitchOfPhonemeClass3 : PhonemeClass -> Pitch
pitchOfPhonemeClass3 pc =
    case pc of
        Vowel ->
            Pitch C 3

        Nasal ->
            Pitch E 3

        VoicedFricative ->
            Pitch F 3

        Fricative ->
            Pitch G 3

        VoicedPlosive ->
            Pitch Bb 3

        Plosive ->
            Pitch C 4

        Approximant ->
            Pitch D 4

        Silence ->
            Rest

        Punctuation ->
            Pitch C 2

        _ ->
            Pitch G 4


pitchOfPhonemeClass2 : PhonemeClass -> Pitch
pitchOfPhonemeClass2 pc =
    case pc of
        Vowel ->
            Pitch G 2

        Approximant ->
            Pitch C 3

        Nasal ->
            Pitch E 3

        VoicedFricative ->
            Pitch F 3

        Fricative ->
            Pitch G 3

        VoicedPlosive ->
            Pitch Bb 3

        Plosive ->
            Pitch D 4

        Silence ->
            Rest

        Punctuation ->
            Pitch C 2

        _ ->
            Pitch G 1
