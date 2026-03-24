#!/usr/bin/env bash

mkdir -p build && \
glslc src/shape.frag -o build/shape.spv.frag && \
glslc src/shape.vert -o build/shape.spv.vert && \
c3c build && \
./build/loop_example
