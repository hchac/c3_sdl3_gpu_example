
## Description

This is a sample project to test the SDL3 GPU bindings from C3's vendor libraries (https://github.com/c3lang/vendor). It's using the SDL3 callbacks approach instead of the usual `SDL init -> loop -> poll events` because I was curious if it worked in C3 (it does).

Strictly following the video tutorial here:
    * https://www.youtube.com/playlist?list=PLI3kBEQ3yd-CbQfRchF70BPLF9G1HEzhy

## Assets used
* https://arexxuru.itch.io/pixel-floor-texture-pack-ground-tile

## Requirements

* SDL3
* SDL3_image
* glslc (to compile GLSL/HLSL shaders to SPIR-V)

## Setup
1. Make sure you've installed the requirements listed above

2. Download the following bindings:
    * https://github.com/c3lang/vendor/tree/main/libraries/sdl3.c3l
    * https://github.com/c3lang/vendor/tree/main/libraries/sdl3_image.c3l

    Then drop them into the `lib` folder.

## Run
`./run.sh`
