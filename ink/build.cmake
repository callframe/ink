add_executable(ink)
target_sources(ink PRIVATE "${INK_SRC_DIR}/ink_main.cc")

target_compile_features(ink PRIVATE cxx_std_20)
target_compile_options(ink PRIVATE "${INK_COPTS}")

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(ink PRIVATE wayland_client)
endif()

if(NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    if(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        set(ink_rpath "@loader_path")
    else()
        set(ink_rpath "$ORIGIN")
    endif()

    target_link_options(ink PRIVATE "-Wl,-rpath,${ink_rpath}")
endif()

install(TARGETS ink RUNTIME DESTINATION ".")
