if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    return()
endif()


# --- Paths and options -------------------------------------------------------

set(INK_WAYLAND_DIR "${INK_THIRD_PARTY_DIR}/wayland")
set(INK_WAYLAND_SOURCE "${INK_WAYLAND_DIR}/source")
set(INK_WAYLAND_GEN "${CMAKE_CURRENT_BINARY_DIR}/wayland-gen")

set(INK_WAYLAND_ICONDIR "/usr/share/icons" CACHE STRING
    "Directory wayland-cursor searches for cursor themes")


# --- Vendored source ---------------------------------------------------------

ink_patch(
    SOURCE_DIR "${INK_WAYLAND_SOURCE}"
    PATCHES    "${INK_WAYLAND_DIR}/config-h-includes.patch"
)

ink_semver(
    FILE        "${INK_WAYLAND_SOURCE}/meson.build"
    ANCHOR      "^[ \t]*version:"
    OUT_VERSION INK_WAYLAND_VERSION
    OUT_MAJOR   INK_WAYLAND_VERSION_MAJOR
    OUT_MINOR   INK_WAYLAND_VERSION_MINOR
    OUT_PATCH   INK_WAYLAND_VERSION_MICRO
)

ink_error_unless(INK_WAYLAND_VERSION_MAJOR EQUAL 1
    MESSAGE "wayland ${INK_WAYLAND_VERSION}: major version is no longer 1, "
            "the SONAME of libwayland-client and libwayland-cursor needs bumping")

set(INK_WAYLAND_SOVERSION 0)


# --- Dependencies and generated headers --------------------------------------

pkg_check_modules(EXPAT REQUIRED IMPORTED_TARGET expat)
pkg_check_modules(LIBFFI REQUIRED IMPORTED_TARGET libffi)

set(WAYLAND_VERSION "${INK_WAYLAND_VERSION}")
set(WAYLAND_VERSION_MAJOR "${INK_WAYLAND_VERSION_MAJOR}")
set(WAYLAND_VERSION_MINOR "${INK_WAYLAND_VERSION_MINOR}")
set(WAYLAND_VERSION_MICRO "${INK_WAYLAND_VERSION_MICRO}")

configure_file(
    "${INK_WAYLAND_SOURCE}/src/wayland-version.h.in"
    "${INK_WAYLAND_GEN}/wayland-version.h"
    @ONLY
)


# --- Helpers -----------------------------------------------------------------

# ink_wayland_protocol(
#     XML <path> OUTPUT_DIR <dir>
#     [CLIENT_HEADER <file>] [CLIENT_CORE_HEADER <file>]
#     [PRIVATE_CODE <file>] [PUBLIC_CODE <file>]
#     OUT_SOURCES <variable-name>
# )
#
# Runs wayland-scanner over XML. Every output is named explicitly by the caller
# and collected into the variable named by OUT_SOURCES; nothing else is set.
# Use PRIVATE_CODE unless the linking library exports the protocol symbols.
function(ink_wayland_protocol)
    set(one_value_args
        XML OUTPUT_DIR OUT_SOURCES
        CLIENT_HEADER CLIENT_CORE_HEADER PRIVATE_CODE PUBLIC_CODE)
    cmake_parse_arguments(PARSE_ARGV 0 arg "" "${one_value_args}" "")

    ink_error_unless(NOT arg_UNPARSED_ARGUMENTS
        MESSAGE "ink_wayland_protocol: unknown arguments: ${arg_UNPARSED_ARGUMENTS}")
    ink_error_unless(NOT arg_KEYWORDS_MISSING_VALUES
        MESSAGE "ink_wayland_protocol: keywords without a value: ${arg_KEYWORDS_MISSING_VALUES}")
    ink_error_unless(arg_XML MESSAGE "ink_wayland_protocol: XML is required")
    ink_error_unless(arg_OUTPUT_DIR MESSAGE "ink_wayland_protocol: OUTPUT_DIR is required")
    ink_error_unless(arg_OUT_SOURCES MESSAGE "ink_wayland_protocol: OUT_SOURCES is required")
    ink_error_unless(EXISTS "${arg_XML}"
        MESSAGE "ink_wayland_protocol: no such protocol file: ${arg_XML}")
    ink_error_unless(
        arg_CLIENT_HEADER OR arg_CLIENT_CORE_HEADER OR arg_PRIVATE_CODE OR arg_PUBLIC_CODE
        MESSAGE "ink_wayland_protocol: at least one output is required")

    file(MAKE_DIRECTORY "${arg_OUTPUT_DIR}")
    set(generated "")

    # keyword;scanner mode;extra flag
    foreach(spec
        "CLIENT_HEADER;client-header;"
        "CLIENT_CORE_HEADER;client-header;-c"
        "PRIVATE_CODE;private-code;"
        "PUBLIC_CODE;public-code;")

        list(GET spec 0 keyword)
        list(GET spec 1 mode)
        list(GET spec 2 flag)

        if(NOT arg_${keyword})
            continue()
        endif()

        set(output "${arg_OUTPUT_DIR}/${arg_${keyword}}")

        add_custom_command(
            OUTPUT "${output}"
            COMMAND "$<TARGET_FILE:wayland_scanner>" -s ${flag} ${mode}
                    "${arg_XML}" "${output}"
            DEPENDS wayland_scanner "${arg_XML}"
            COMMENT "Generating ${arg_${keyword}}"
            VERBATIM
        )

        list(APPEND generated "${output}")
    endforeach()

    set_source_files_properties(${generated} PROPERTIES GENERATED TRUE)
    set("${arg_OUT_SOURCES}" "${generated}" PARENT_SCOPE)
endfunction()


function(ink_wayland_target_defaults target)
    set_target_properties(${target} PROPERTIES
        C_STANDARD 99
        C_EXTENSIONS OFF
        C_VISIBILITY_PRESET hidden
    )

    target_compile_definitions(${target} PRIVATE _POSIX_C_SOURCE=200809L)

    target_compile_options(${target} PRIVATE
        -Wall -Wextra
        -Wno-unused-parameter -Wstrict-prototypes -Wmissing-prototypes
    )

    target_include_directories(${target} PRIVATE
        "${INK_WAYLAND_DIR}"
        "${INK_WAYLAND_GEN}"
        "${INK_WAYLAND_SOURCE}/src"
    )
endfunction()


# --- Static libraries --------------------------------------------------------
#
# PIC because both get rolled into the shared libraries below.

add_library(wayland_util STATIC "${INK_WAYLAND_SOURCE}/src/wayland-util.c")
ink_wayland_target_defaults(wayland_util)
set_target_properties(wayland_util PROPERTIES POSITION_INDEPENDENT_CODE ON)

add_library(wayland_private STATIC
    "${INK_WAYLAND_SOURCE}/src/connection.c"
    "${INK_WAYLAND_SOURCE}/src/wayland-os.c"
)

ink_wayland_target_defaults(wayland_private)
set_target_properties(wayland_private PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(wayland_private PUBLIC PkgConfig::LIBFFI m)


# --- Scanner and protocol code -----------------------------------------------

add_executable(wayland_scanner "${INK_WAYLAND_SOURCE}/src/scanner.c")
ink_wayland_target_defaults(wayland_scanner)
target_link_libraries(wayland_scanner PRIVATE wayland_util PkgConfig::EXPAT)

set_target_properties(wayland_scanner PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tools"
)

ink_wayland_protocol(
    XML                "${INK_WAYLAND_SOURCE}/protocol/wayland.xml"
    OUTPUT_DIR         "${INK_WAYLAND_GEN}"
    CLIENT_HEADER      wayland-client-protocol.h
    CLIENT_CORE_HEADER wayland-client-protocol-core.h
    PUBLIC_CODE        wayland-protocol.c
    OUT_SOURCES        INK_WAYLAND_CORE_PROTOCOL_SOURCES
)

# --- Shared libraries --------------------------------------------------------

add_library(wayland_client SHARED
    "${INK_WAYLAND_SOURCE}/src/wayland-client.c"
    ${INK_WAYLAND_CORE_PROTOCOL_SOURCES}
)

ink_wayland_target_defaults(wayland_client)

set_target_properties(wayland_client PROPERTIES
    OUTPUT_NAME wayland-client
    SOVERSION "${INK_WAYLAND_SOVERSION}"
)

target_link_libraries(wayland_client
    PRIVATE wayland_util wayland_private
    PUBLIC Threads::Threads m
)

target_include_directories(wayland_client PUBLIC
    "${INK_WAYLAND_GEN}"
    "${INK_WAYLAND_SOURCE}/src"
)


add_library(wayland_cursor SHARED
    "${INK_WAYLAND_SOURCE}/cursor/wayland-cursor.c"
    "${INK_WAYLAND_SOURCE}/cursor/xcursor.c"
    "${INK_WAYLAND_SOURCE}/cursor/os-compatibility.c"
)

ink_wayland_target_defaults(wayland_cursor)

set_target_properties(wayland_cursor PROPERTIES
    OUTPUT_NAME wayland-cursor
    SOVERSION "${INK_WAYLAND_SOVERSION}"
)

# Without this xcursor.c falls back to a hardcoded X11R6 path.
target_compile_definitions(wayland_cursor PRIVATE "ICONDIR=\"${INK_WAYLAND_ICONDIR}\"")
target_link_libraries(wayland_cursor PUBLIC wayland_client)
target_include_directories(wayland_cursor PUBLIC "${INK_WAYLAND_SOURCE}/cursor")

install(TARGETS wayland_client wayland_cursor LIBRARY DESTINATION "." NAMELINK_SKIP)
