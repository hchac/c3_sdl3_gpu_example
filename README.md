
## Description

This is a sample project to test the SDL3 GPU bindings from C3's vendor libraries (https://github.com/c3lang/vendor).

`callback_example`:

* Uses SDL3's new callback approach, where there is no `main` function and instead rely on SDL3 calling predefined functions
* Strictly following the video tutorials here: https://www.youtube.com/playlist?list=PLI3kBEQ3yd-CbQfRchF70BPLF9G1HEzhy

`loop_example`:

* The more traditional main() for loop approach for SDL
* Follows the tutorial at https://learnopengl.com but using SDL3 GPU instead

## Assets used
* https://arexxuru.itch.io/pixel-floor-texture-pack-ground-tile (in `callback_example`)
* https://learnopengl.com (in `loop_example`)

## Requirements

* glslc (to compile GLSL/HLSL shaders to SPIR-V)

## Setup for both `callback_example` and `loop_example`
1. Make sure you've installed the requirements listed above

2. Download the following bindings:
    * https://github.com/c3lang/vendor/releases/download/latest/sdl3.c3l
    * https://github.com/c3lang/vendor/releases/download/latest/sdl3_image.c3l

    Unpack the downloads, then drop the unpacked folders into the `lib` folder inside `callback_example` and `loop_example`. Make sure the folder copied into `lib` ends in `.c3l`, so: `lib/sdl3.c3l` and `lib/sdl3_image.c3l`.

3. `./run.sh` to compile & run inside `callback_example` or `loop_example`
