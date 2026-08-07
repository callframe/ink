add_executable(ink)
target_sources(ink PRIVATE "${INK_SRC_DIR}/ink_main.cc")

target_compile_features(ink PRIVATE cxx_std_20)
target_compile_options(ink PRIVATE "${INK_COPTS}")
