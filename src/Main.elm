port module Main exposing (Model, Msg(..), dropDecoder, hijack, hijackOn, init, main, subscriptions, update, view)

import Array exposing (..)
import Browser
import File exposing (File)
import File.Select as Select
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as D
import Process as Process
import Task



-- MAIN


main =
    Browser.document
        { init = init
        , update = update
        , view =
            \m ->
                { title = "Elm 0.19 starter"
                , body = [ view m ]
                }
        , subscriptions = subscriptions
        }



-- MODEL


type ExportStateModel
    = Idle
    | CreatingImages Float
    | CreatingZip
    | Done


type alias Image =
    { src : String
    , saturation : Float
    , contrast : Float
    , brightness : Float
    , name : String
    }


type alias UploadFilesModel =
    { hoveringImageDroppable : Bool
    }


type alias EditorModel =
    { images : Array Image
    , selectedImageIndex : Int
    , exportState : ExportStateModel
    }


type Model
    = UploadFiles UploadFilesModel
    | Editor EditorModel


init : () -> ( Model, Cmd Msg )
init _ =
    ( UploadFiles <|
        UploadFilesModel False
    , Cmd.none
    )



-- UPDATE


type Msg
    = NoOp
    | Pick
    | DragEnter
    | DragLeave
    | GotFiles File (List File)
    | GotPreviews (List Image)
    | UserSelectedImage Int
    | UserSetBrightness Float
    | UserSetContrast Float
    | UserSetSaturation Float
    | UserClicksNext
    | UserClicksPrevious
    | UserClickedDone
    | UserInputName String
    | ReceivedZip Int
    | GotImageProgress Float
    | FinishedExporting


updateImage : EditorModel -> (Image -> Image) -> EditorModel
updateImage editorModel updateFunction =
    let
        image =
            Array.get editorModel.selectedImageIndex editorModel.images
    in
    case image of
        Just selectedImage ->
            { editorModel
                | images =
                    Array.set
                        editorModel.selectedImageIndex
                        (updateFunction selectedImage)
                        editorModel.images
            }

        Nothing ->
            editorModel


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Pick, UploadFiles _ ) ->
            ( model, Select.files [ "image/*" ] GotFiles )

        ( DragEnter, UploadFiles _ ) ->
            ( UploadFiles <| UploadFilesModel True, Cmd.none )

        ( DragLeave, UploadFiles _ ) ->
            ( UploadFiles <| UploadFilesModel False, Cmd.none )

        ( GotFiles file files, UploadFiles _ ) ->
            ( UploadFiles <| UploadFilesModel False
            , Task.perform GotPreviews <|
                Task.sequence <|
                    List.map mapFileToTask (file :: files)
            )

        ( GotPreviews images, UploadFiles _ ) ->
            ( Editor <| EditorModel (Array.fromList images) 0 Idle, Cmd.none )

        ( UserSelectedImage index, Editor editorModel ) ->
            ( Editor { editorModel | selectedImageIndex = index }, Cmd.none )

        ( UserClickedDone, Editor editorModel ) ->
            ( Editor { editorModel | exportState = CreatingImages 0 }
            , generateImages (Array.toList editorModel.images)
            )

        ( UserInputName v, Editor editorModel ) ->
            ( Editor
                (updateImage editorModel (\image -> { image | name = v }))
            , Cmd.none
            )

        ( UserSetBrightness v, Editor editorModel ) ->
            ( Editor
                (updateImage editorModel (\image -> { image | brightness = v }))
            , Cmd.none
            )

        ( UserSetContrast v, Editor editorModel ) ->
            ( Editor
                (updateImage editorModel (\image -> { image | contrast = v }))
            , Cmd.none
            )

        ( UserSetSaturation v, Editor editorModel ) ->
            ( Editor
                (updateImage editorModel (\image -> { image | saturation = v }))
            , Cmd.none
            )

        ( GotImageProgress v, Editor editorModel ) ->
            ( Editor
                { editorModel
                    | exportState =
                        if v == 100 then
                            CreatingZip

                        else
                            CreatingImages v
                }
            , Cmd.none
            )

        ( ReceivedZip v, Editor editorModel ) ->
            ( Editor { editorModel | exportState = Done }, Process.sleep 1000 |> Task.perform (always FinishedExporting) )

        ( FinishedExporting, Editor editorModel ) ->
            ( Editor { editorModel | exportState = Idle }, Cmd.none )

        ( UserClicksNext, Editor editorModel ) ->
            ( Editor { editorModel | selectedImageIndex = editorModel.selectedImageIndex + 1 }, Cmd.none )

        ( UserClicksPrevious, Editor editorModel ) ->
            ( Editor { editorModel | selectedImageIndex = editorModel.selectedImageIndex - 1 }, Cmd.none )

        ( _, _ ) ->
            ( model, Cmd.none )


mapFileToTask : File -> Task.Task x Image
mapFileToTask file =
    Task.map createImage (File.toUrl file)


createImage : String -> Image
createImage preview =
    { src = preview
    , contrast = 100
    , saturation = 100
    , brightness = 100
    , name = ""
    }



-- SUBSCRIPTIONS


port generateImages : List Image -> Cmd msg


port receiveZip : (Int -> a) -> Sub a


port imageProgress : (Float -> a) -> Sub a


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveZip (\v -> ReceivedZip v)
        , imageProgress (\v -> GotImageProgress v)
        ]



-- VIEW


viewExportState : EditorModel -> Html Msg
viewExportState model =
    case model.exportState of
        Idle ->
            button [ class "done", onClick UserClickedDone ] [ text "Export" ]

        CreatingImages percentage ->
            text (String.concat [ String.fromFloat percentage, "%" ])

        CreatingZip ->
            text "Zipping.."

        Done ->
            text "Done!"


viewTopBar : Model -> Html Msg
viewTopBar model =
    div
        [ class "top-bar"
        ]
        [ text "fixNup photos"
        , div
            [ class "controls"
            ]
            [ case model of
                Editor editorModel ->
                    viewExportState editorModel

                _ ->
                    div [] []
            ]
        ]


view : Model -> Html Msg
view model =
    div
        [ class "main"
        ]
        [ viewTopBar model
        , viewState model
        ]


viewState : Model -> Html Msg
viewState model =
    case model of
        UploadFiles uploadFilesModel ->
            viewUploadFiles uploadFilesModel

        Editor editorModel ->
            viewEditor editorModel


viewEditor : EditorModel -> Html Msg
viewEditor model =
    div
        []
        [ viewImagePreviews model.selectedImageIndex model.images
        , div [ class "editor-body" ]
            [ viewPreviousImage model
            , viewImageEditor (Array.get model.selectedImageIndex model.images)
            , viewNextImage model
            ]
        ]


viewPreviousImage : EditorModel -> Html Msg
viewPreviousImage model =
    div [ class "nav" ]
        [ if model.selectedImageIndex == 0 then
            div [] []

          else
            button [ onClick UserClicksPrevious ] [ text "Previous" ]
        ]


viewNextImage : EditorModel -> Html Msg
viewNextImage model =
    div [ class "nav" ]
        [ if model.selectedImageIndex + 1 == Array.length model.images then
            div [] []

          else
            button [ onClick UserClicksNext ] [ text "Next" ]
        ]


imageFilterValue : Image -> String
imageFilterValue image =
    "saturate("
        ++ String.fromFloat image.saturation
        ++ "%) "
        ++ "contrast("
        ++ String.fromFloat image.contrast
        ++ "%) "
        ++ "brightness("
        ++ String.fromFloat image.brightness
        ++ "%)"


viewImagePreviews : Int -> Array Image -> Html Msg
viewImagePreviews selectedImageIndex images =
    div
        [ class "image-previews"
        ]
        (Array.toList
            (Array.indexedMap (viewImagePreview selectedImageIndex) images)
        )


viewImagePreview : Int -> Int -> Image -> Html Msg
viewImagePreview selectedImageIndex index image =
    img
        [ src image.src
        , style "filter" (imageFilterValue image)
        , onClick (UserSelectedImage index)
        , class
            (if index == selectedImageIndex then
                "selected"

             else
                ""
            )
        ]
        []


viewImageEditor : Maybe Image -> Html Msg
viewImageEditor image =
    case image of
        Nothing ->
            div [] [ text "no image selected" ]

        Just selectedImage ->
            viewImage selectedImage


viewImage : Image -> Html Msg
viewImage image =
    div
        [ class "image-editor"
        ]
        [ img
            [ src image.src
            , style "filter" (imageFilterValue image)
            ]
            []
        , div [ class "controls" ]
            [ input
                [ class "name"
                , placeholder "Name"
                , onInput UserInputName
                , value image.name
                ]
                []
            , div [ class "slider-container" ]
                [ label [] [ text "Contrast" ]
                , slider 50 150 image.contrast UserSetContrast
                ]
            , div [ class "slider-container" ]
                [ label [] [ text "Saturation" ]
                , slider 50 150 image.saturation UserSetSaturation
                ]
            , div [ class "slider-container" ]
                [ label [] [ text "Brightness" ]
                , slider 50 150 image.brightness UserSetBrightness
                ]
            ]
        ]


slider : Float -> Float -> Float -> (Float -> Msg) -> Html Msg
slider min max value fn =
    input
        [ type_ "range"
        , Html.Attributes.min (String.fromFloat min)
        , Html.Attributes.max (String.fromFloat max)
        , Html.Attributes.value (String.fromFloat value)
        , onInput (inputStringToFloat fn)
        , onDoubleClick (fn 100)
        ]
        []


inputStringToFloat : (Float -> Msg) -> String -> Msg
inputStringToFloat fn value =
    case String.toFloat value of
        Just float ->
            fn float

        Nothing ->
            NoOp


viewUploadFiles : UploadFilesModel -> Html Msg
viewUploadFiles model =
    div
        [ style "border"
            (if model.hoveringImageDroppable then
                "6px dashed purple"

             else
                "6px dashed #ccc"
            )
        , style "border-radius" "20px"
        , style "width" "480px"
        , style "margin" "100px auto"
        , style "padding" "40px"
        , style "display" "flex"
        , style "flex-direction" "column"
        , style "justify-content" "center"
        , style "align-items" "center"
        , hijackOn "dragenter" (D.succeed DragEnter)
        , hijackOn "dragover" (D.succeed DragEnter)
        , hijackOn "dragleave" (D.succeed DragLeave)
        , hijackOn "drop" dropDecoder
        ]
        [ button [ onClick Pick ] [ text "Upload Images" ]
        , div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "height" "60px"
            , style "padding" "20px"
            ]
            []
        ]


dropDecoder : D.Decoder Msg
dropDecoder =
    D.at [ "dataTransfer", "files" ] (D.oneOrMore GotFiles File.decoder)


hijackOn : String -> D.Decoder msg -> Attribute msg
hijackOn event decoder =
    preventDefaultOn event (D.map hijack decoder)


hijack : msg -> ( msg, Bool )
hijack msg =
    ( msg, True )
