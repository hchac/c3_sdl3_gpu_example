#!/usr/bin/env bash

glslc src/shader.glsl.frag -o build/shader.spv.frag && \
glslc src/shader.glsl.vert -o build/shader.spv.vert && \
c3c build --no-entry && \
./build/c3_sdl3_gpu_example
