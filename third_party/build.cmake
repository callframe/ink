if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    find_package(PkgConfig REQUIRED)
    find_package(Threads REQUIRED)
endif()

include("${INK_THIRD_PARTY_DIR}/wayland/build.cmake")
