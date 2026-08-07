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
    $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:MSVC>>:/FS>
)

set(INK_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${INK_DIR}/cmake")

include(InkHelpers)

set(INK_SRC_DIR "${INK_DIR}/ink")
set(INK_THIRD_PARTY_DIR "${INK_DIR}/third_party")

set(CMAKE_SKIP_BUILD_RPATH TRUE)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/archives")

include("${INK_SRC_DIR}/build.cmake")
include("${INK_THIRD_PARTY_DIR}/build.cmake")