# ink_error_unless(<condition>... MESSAGE <text>...)
#
# A function, not a macro: CMake resolves variable reads through the caller's
# scope, so the condition still sees the caller's locals, while macro argument
# substitution would mangle backslashes in regexes (see CMP0219).
# Message parts are concatenated, so long messages can be split across lines.
# The prefix must not collide with anything a caller might name in its
# condition -- callers commonly parse into `arg`, which this would shadow.
function(ink_error_unless)
    cmake_parse_arguments(PARSE_ARGV 0 _ink_cond "" "" "MESSAGE")
    if(NOT (${_ink_cond_UNPARSED_ARGUMENTS}))
        message(FATAL_ERROR ${_ink_cond_MESSAGE})
    endif()
endfunction()

# ink_set_if_defined(<variable-name> <value>)
#
# No-op when the name is empty, so callers can forward optional OUT_* arguments.
# Must be a macro: it sets a variable in the scope of its caller's caller, and
# there is no GRANDPARENT_SCOPE.
macro(ink_set_if_defined NAME VALUE)
    if(NOT "${NAME}" STREQUAL "")
        set("${NAME}" "${VALUE}" PARENT_SCOPE)
    endif()
endmacro()

# ink_semver(
#     VERSION <string> | FILE <path> ANCHOR <regex>
#     [OUT_VERSION <var>] [OUT_FULL <var>] [OUT_MAJOR <var>]
#     [OUT_MINOR <var>] [OUT_PATCH <var>] [OUT_PRERELEASE <var>]
# )
#
# Extracts a version from a literal string, or from the first line of FILE
# matching ANCHOR. ANCHOR only locates the line, so no call site repeats a
# version regex.
#
# Handles 1.2.3, 1.2 (patch normalises to 0), 1.2.3-rc.1, 1.2.3.rc.1 and
# 1.2.3+build5. OUT_VERSION is always MAJOR.MINOR.PATCH, OUT_FULL is verbatim.
function(ink_semver)
    set(one_value_args
        VERSION FILE ANCHOR
        OUT_VERSION OUT_FULL OUT_MAJOR OUT_MINOR OUT_PATCH OUT_PRERELEASE)
    cmake_parse_arguments(PARSE_ARGV 0 arg "" "${one_value_args}" "")

    ink_error_unless(NOT arg_UNPARSED_ARGUMENTS
        MESSAGE "ink_semver: unknown arguments: ${arg_UNPARSED_ARGUMENTS}")
    ink_error_unless(NOT arg_KEYWORDS_MISSING_VALUES
        MESSAGE "ink_semver: keywords without a value: ${arg_KEYWORDS_MISSING_VALUES}")
    ink_error_unless(NOT (DEFINED arg_VERSION AND DEFINED arg_FILE)
        MESSAGE "ink_semver: VERSION and FILE are mutually exclusive")
    ink_error_unless(DEFINED arg_VERSION OR DEFINED arg_FILE
        MESSAGE "ink_semver: one of VERSION or FILE is required")

    if(DEFINED arg_FILE)
        ink_error_unless(DEFINED arg_ANCHOR MESSAGE "ink_semver: FILE requires ANCHOR")
        ink_error_unless(EXISTS "${arg_FILE}" MESSAGE "ink_semver: no such file: ${arg_FILE}")

        file(STRINGS "${arg_FILE}" lines REGEX "${arg_ANCHOR}")
        ink_error_unless(lines
            MESSAGE "ink_semver: ANCHOR '${arg_ANCHOR}' matched no line in ${arg_FILE}")
        list(GET lines 0 subject)
    else()
        ink_error_unless(NOT DEFINED arg_ANCHOR
            MESSAGE "ink_semver: ANCHOR is only meaningful with FILE")
        set(subject "${arg_VERSION}")
    endif()

    # Inline rather than via ink_error_unless: CMAKE_MATCH_* would be set in the
    # helper's scope and lost before we could read the capture groups.
    if(NOT subject MATCHES "([0-9]+)\\.([0-9]+)(\\.([0-9]+))?([-.+][0-9A-Za-z.+-]+)?")
        message(FATAL_ERROR "ink_semver: no version found in '${subject}'")
    endif()

    # Snapshot before any further regex clobbers CMAKE_MATCH_*.
    set(full "${CMAKE_MATCH_0}")
    set(major "${CMAKE_MATCH_1}")
    set(minor "${CMAKE_MATCH_2}")
    set(patch "${CMAKE_MATCH_4}")
    set(prerelease "${CMAKE_MATCH_5}")

    if(patch STREQUAL "")
        set(patch "0")
    endif()
    string(REGEX REPLACE "^[-.+]" "" prerelease "${prerelease}")

    ink_set_if_defined("${arg_OUT_VERSION}" "${major}.${minor}.${patch}")
    ink_set_if_defined("${arg_OUT_FULL}" "${full}")
    ink_set_if_defined("${arg_OUT_MAJOR}" "${major}")
    ink_set_if_defined("${arg_OUT_MINOR}" "${minor}")
    ink_set_if_defined("${arg_OUT_PATCH}" "${patch}")
    ink_set_if_defined("${arg_OUT_PRERELEASE}" "${prerelease}")
endfunction()

# ink_patch(SOURCE_DIR <dir> PATCHES <file>...)
#
# Patches a vendored source tree at configure time. Re-running cmake on an
# already patched tree is a no-op, so this is safe to call unconditionally.
function(ink_patch)
    cmake_parse_arguments(PARSE_ARGV 0 arg "" "SOURCE_DIR" "PATCHES")

    ink_error_unless(NOT arg_UNPARSED_ARGUMENTS
        MESSAGE "ink_patch: unknown arguments: ${arg_UNPARSED_ARGUMENTS}")
    ink_error_unless(NOT arg_KEYWORDS_MISSING_VALUES
        MESSAGE "ink_patch: keywords without a value: ${arg_KEYWORDS_MISSING_VALUES}")
    ink_error_unless(arg_SOURCE_DIR MESSAGE "ink_patch: SOURCE_DIR is required")
    ink_error_unless(arg_PATCHES MESSAGE "ink_patch: PATCHES is required")
    ink_error_unless(IS_DIRECTORY "${arg_SOURCE_DIR}"
        MESSAGE "ink_patch: no such directory: ${arg_SOURCE_DIR}\n"
                "Initialise submodules with: git submodule update --init --recursive")

    find_program(INK_GIT_EXECUTABLE NAMES git REQUIRED)

    foreach(patch IN LISTS arg_PATCHES)
        ink_error_unless(EXISTS "${patch}" MESSAGE "ink_patch: no such patch: ${patch}")

        set_property(DIRECTORY "${CMAKE_SOURCE_DIR}"
            APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${patch}")

        # A clean reverse-check means the patch is already in the worktree.
        execute_process(
            COMMAND "${INK_GIT_EXECUTABLE}" apply --reverse --check "${patch}"
            WORKING_DIRECTORY "${arg_SOURCE_DIR}"
            RESULT_VARIABLE applied
            OUTPUT_QUIET
            ERROR_QUIET
        )
        if(applied EQUAL 0)
            continue()
        endif()

        execute_process(
            COMMAND "${INK_GIT_EXECUTABLE}" apply "${patch}"
            WORKING_DIRECTORY "${arg_SOURCE_DIR}"
            RESULT_VARIABLE result
            ERROR_VARIABLE stderr
        )
        ink_error_unless(result EQUAL 0
            MESSAGE "ink_patch: failed to apply ${patch} in ${arg_SOURCE_DIR}\n${stderr}\n"
                    "If the submodule was updated, the patch needs refreshing. Reset with:\n"
                    "  git -C ${arg_SOURCE_DIR} checkout -- .")

        message(STATUS "Applied patch: ${patch}")
    endforeach()
endfunction()
