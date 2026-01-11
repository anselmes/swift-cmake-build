# toolchain.cmake
#
# SwiftPM builds driven by CMake, with Embedded Swift mode.
#
# MARK: Overview
#
# Controls (env or -D on the cmake command line):
#   BUILD_TYPE=debug|release          (default: debug)
#   VERBOSE=0|1                       (default: 0)
#   TARGET=<swift triple>             (default: unset; host build)
#   EMBEDDED=0|1                      (default: 0)
#
# Embedded SDK wiring (only used when EMBEDDED=1):
#   EMBEDDED_SYSROOT=/path/to/sysroot
#   EMBEDDED_LIBDIR=/path/to/libdir
#   EMBEDDED_LINK_LIBS="c;m;gcc"      (semicolon-separated list)
#   EMBEDDED_NO_HOST_STDLIB=1
#   EMBEDDED_NO_STARTFILES=1
#
# Optional:
#   SWIFT_RELEASE_ASSERTS=1           (keep asserts in release)

set(CMAKE_SYSTEM_NAME Generic)

set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

# MARK: Helpers

function(_norm_bool in_val out_var)
  set(v "${in_val}")
  string(TOLOWER "${v}" v)

  set(res 0)
  if(v STREQUAL "1" OR v STREQUAL "on" OR v STREQUAL "true" OR v STREQUAL "yes" OR v STREQUAL "y")
    set(res 1)
  endif()

  set(${out_var} "${res}" PARENT_SCOPE)
endfunction()

# MARK: Env & Config

# BUILD_TYPE (debug|release)
set(BUILD_TYPE "$ENV{BUILD_TYPE}")
if(NOT BUILD_TYPE)
  set(BUILD_TYPE "debug")
endif()
string(TOLOWER "${BUILD_TYPE}" BUILD_TYPE)

# TARGET (SwiftPM --triple)
set(TARGET "$ENV{TARGET}")
# If a user sets TARGET=native explicitly, treat it as "host" too.
if("${TARGET}" STREQUAL "native")
  set(TARGET "")
endif()

# VERBOSE (SwiftPM -v + compiler verbosity)
set(VERBOSE_RAW "$ENV{VERBOSE}")
if(NOT VERBOSE_RAW)
  set(VERBOSE_RAW "0")
endif()
_norm_bool("${VERBOSE_RAW}" VERBOSE)

# EMBEDDED (export EMBEDDED=1 for embedded builds)
set(EMBEDDED_RAW "$ENV{EMBEDDED}")
if(NOT EMBEDDED_RAW)
  set(EMBEDDED_RAW "0")
endif()
_norm_bool("${EMBEDDED_RAW}" EMBEDDED)

# Embedded SDK wiring (Optional: newlib | zephyr-sdk | etc...)
set(EMBEDDED_SYSROOT "$ENV{EMBEDDED_SYSROOT}")
set(EMBEDDED_LIBDIR  "$ENV{EMBEDDED_LIBDIR}")
set(EMBEDDED_LINK_LIBS "$ENV{EMBEDDED_LINK_LIBS}")   # e.g. "c;m;gcc" (semicolon separated)

# Controls to block host libs/start files (Optional: enabled if full link env)
set(EMBEDDED_NO_HOST_STDLIB "$ENV{EMBEDDED_NO_HOST_STDLIB}")
set(EMBEDDED_NO_STARTFILES  "$ENV{EMBEDDED_NO_STARTFILES}")

# Keep asserts in Release for "checked" release (Optional)
set(SWIFT_RELEASE_ASSERTS "$ENV{SWIFT_RELEASE_ASSERTS}")

message(STATUS "BUILD_TYPE=${BUILD_TYPE}")
if(TARGET)
  message(STATUS "TARGET=${TARGET} (passing --triple)")
else()
  message(STATUS "TARGET=<host> (no --triple)")
endif()
message(STATUS "VERBOSE=${VERBOSE}")
message(STATUS "EMBEDDED_RAW='${EMBEDDED_RAW}' -> EMBEDDED=${EMBEDDED}")

# MARK: SPM Argument Builders

function(_swift_common_swiftpm_args out_var)
  set(args)

  if(VERBOSE)
    # SwiftPM verbosity + show underlying compiler invocations
    list(APPEND args -v)
    list(APPEND args -Xswiftc -v)
    list(APPEND args -Xcc -v)
  endif()

  # SwiftPM configuration
  if(BUILD_TYPE STREQUAL "release")
    list(APPEND args --configuration release)
  else()
    list(APPEND args --configuration debug)
  endif()

  # Target triple
  if(TARGET)
    list(APPEND args --triple ${TARGET})
  endif()

  # Build-type-dependent Swift flags
  if(BUILD_TYPE STREQUAL "release")
    # Embedded release:     optimize for size
    # Non-embedded release: optimize for speed
    if(EMBEDDED)
      list(APPEND args -Xswiftc -Osize)
    else()
      list(APPEND args -Xswiftc -O)
    endif()

    if(SWIFT_RELEASE_ASSERTS)
      list(APPEND args -Xswiftc -assert-config -Xswiftc Debug)
    endif()
  else()
    list(APPEND args -Xswiftc -Onone)
    list(APPEND args -Xswiftc -g)
    list(APPEND args -Xswiftc -assert-config -Xswiftc Debug)
  endif()

  # Release dead-stripping
  if(BUILD_TYPE STREQUAL "release")
    if(TARGET MATCHES "apple" OR (NOT TARGET AND CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin"))
      list(APPEND args -Xswiftc -Xlinker -Xswiftc -dead_strip)
    else()
      list(APPEND args -Xswiftc -Xlinker -Xswiftc --gc-sections)
    endif()
  endif()

  # Embedded SDK wiring (Optional)
  if(EMBEDDED)
    if(EMBEDDED_SYSROOT)
      list(APPEND args -Xswiftc --sysroot -Xswiftc ${EMBEDDED_SYSROOT})
    endif()

    if(EMBEDDED_LIBDIR)
      list(APPEND args -Xswiftc -Xlinker -Xswiftc -L${EMBEDDED_LIBDIR})
    endif()

    # Prevent accidental host linkage (Optional: if complete embedded link environment)
    if(EMBEDDED_NO_HOST_STDLIB)
      _norm_bool("${EMBEDDED_NO_HOST_STDLIB}" _nhs)
      if(_nhs)
        list(APPEND args -Xswiftc -Xlinker -Xswiftc -nostdlib)
        list(APPEND args -Xswiftc -Xlinker -Xswiftc -nodefaultlibs)

        if(EMBEDDED_NO_STARTFILES)
          _norm_bool("${EMBEDDED_NO_STARTFILES}" _nsf)
          if(_nsf)
            list(APPEND args -Xswiftc -Xlinker -Xswiftc -nostartfiles)
          endif()
        endif()
      endif()
    endif()

    # Add explicit libs if requested (typically newlib/picolibc/gcc runtime, etc...)
    if(EMBEDDED_LINK_LIBS)
      foreach(lib IN LISTS EMBEDDED_LINK_LIBS)
        list(APPEND args -Xswiftc -Xlinker -Xswiftc -l${lib})
      endforeach()
    endif()
  endif()

  set(${out_var} "${args}" PARENT_SCOPE)
endfunction()

# MARK: Toolset Selection

function(_swift_select_toolset out_var kind)
  # kind: "app" uses toolset files in current directory
  #       "lib" uses toolset files in parent directory (../)
  if(kind STREQUAL "app")
    set(normal   "${CMAKE_CURRENT_SOURCE_DIR}/toolset.json")
    set(embedded "${CMAKE_CURRENT_SOURCE_DIR}/toolset.embedded.json")
  else()
    set(normal   "${CMAKE_CURRENT_SOURCE_DIR}/../toolset.json")
    set(embedded "${CMAKE_CURRENT_SOURCE_DIR}/../toolset.embedded.json")
  endif()

  if(EMBEDDED EQUAL 1 AND EXISTS "${embedded}")
    set(${out_var} "${embedded}" PARENT_SCOPE)
    message(STATUS "Toolset(${kind}): using embedded toolset: ${embedded}")
  elseif(EXISTS "${normal}")
    set(${out_var} "${normal}" PARENT_SCOPE)
    message(STATUS "Toolset(${kind}): using normal toolset: ${normal}")
  else()
    set(${out_var} "" PARENT_SCOPE)
    message(WARNING "Toolset(${kind}): no toolset found (expected ${normal} or ${embedded})")
  endif()
endfunction()

# MARK: Public API

function(swift_build_app)
  _swift_select_toolset(TOOLSET_PATH "app")
  _swift_common_swiftpm_args(COMMON_ARGS)

  set(cmd swift build)
  list(APPEND cmd ${COMMON_ARGS})
  list(APPEND cmd --package-path ${CMAKE_CURRENT_SOURCE_DIR})
  if(TOOLSET_PATH)
    list(APPEND cmd --toolset ${TOOLSET_PATH})
  endif()

  add_custom_target(
    ${PROJECT_NAME} ALL
    COMMAND ${cmd}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building ${PROJECT_NAME} app with SwiftPM"
    VERBATIM
  )
endfunction()

function(swift_build_library)
  _swift_select_toolset(TOOLSET_PATH "lib")
  _swift_common_swiftpm_args(COMMON_ARGS)

  set(cmd swift build)
  list(APPEND cmd ${COMMON_ARGS})
  list(APPEND cmd --package-path ${CMAKE_CURRENT_SOURCE_DIR})
  if(TOOLSET_PATH)
    list(APPEND cmd --toolset ${TOOLSET_PATH})
  endif()

  add_custom_target(
    ${PROJECT_NAME} ALL
    COMMAND ${cmd}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    COMMENT "Building ${PROJECT_NAME} library with SwiftPM"
    VERBATIM
  )
endfunction()

function(swift_build_strip)
  if(BUILD_TYPE STREQUAL "release")
    add_custom_command(
      TARGET ${PROJECT_NAME} POST_BUILD
      COMMAND llvm-strip "${CMAKE_CURRENT_SOURCE_DIR}/.build/release/lib${PROJECT_NAME}.a"
      COMMENT "Stripping symbols from ${PROJECT_NAME} static library (release)"
      VERBATIM
    )
  endif()
endfunction()
