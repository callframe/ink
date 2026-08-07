cmake_minimum_required(VERSION 3.20)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
project(ink
    DESCRIPTION "A minimalistic and modern Editor"
    VERSION 0.1.0
)

set(INK_COPTS
    $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic>
    $<$<CXX_COMPILER_ID:MSVC>:/W4>

    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:GNU,Clang>>:-g>
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:MSVC>>:/Fs>
)

set(INK_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(INK_SRC_DIR "${INK_DIR}/ink")

include("${INK_SRC_DIR}/build.cmake")
