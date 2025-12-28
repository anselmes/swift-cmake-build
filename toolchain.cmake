set(CMAKE_SYSTEM_NAME Generic)

set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

set(BUILD_TYPE $ENV{BUILD_TYPE})
if(NOT BUILD_TYPE)
  set(BUILD_TYPE "debug")
endif()

set(TARGET $ENV{TARGET})
if(NOT TARGET)
  set(TARGET "native")
endif()

set(TOOLCHAINS $ENV{TOOLCHAINS})
if(NOT TOOLCHAINS)
  set(TOOLCHAINS "swift")
endif()

set(VERBOSE $ENV{VERBOSE})
if(NOT VERBOSE)
  set(VERBOSE OFF)
endif()

# Function to build Swift apps (looks for toolset.json in current directory)
function(swift_build_app)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/toolset.json")
    # toolset.json exists
    add_custom_target(
      ${PROJECT_NAME} ALL
      COMMAND swift build $<$<BOOL:${VERBOSE}>:-v> 
        --package-path ${CMAKE_CURRENT_SOURCE_DIR} 
        --configuration ${BUILD_TYPE} 
        --toolset toolset.json 
        --triple ${TARGET}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Building ${PROJECT_NAME} app with swiftc (with toolset)"
    )
  else()
    # No toolset.json
    add_custom_target(
      ${PROJECT_NAME} ALL
      COMMAND swift build $<$<BOOL:${VERBOSE}>:-v> 
        --package-path ${CMAKE_CURRENT_SOURCE_DIR} 
        --configuration ${BUILD_TYPE} 
        --triple ${TARGET}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Building ${PROJECT_NAME} app with swiftc"
    )
  endif()
endfunction()

# Function to build Swift libraries (looks for toolset.json in parent lib directory)
function(swift_build_library)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../toolset.json")
    # toolset.json exists in parent
    add_custom_target(
      ${PROJECT_NAME} ALL
      COMMAND swift build $<$<BOOL:${VERBOSE}>:-v> 
        --package-path ${CMAKE_CURRENT_SOURCE_DIR} 
        --configuration ${BUILD_TYPE} 
        --toolset ../toolset.json 
        --triple ${TARGET}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Building ${PROJECT_NAME} library with swiftc (with toolset)"
    )
  else()
    # No toolset.json in parent
    add_custom_target(
      ${PROJECT_NAME} ALL
      COMMAND swift build $<$<BOOL:${VERBOSE}>:-v> 
        --package-path ${CMAKE_CURRENT_SOURCE_DIR} 
        --configuration ${BUILD_TYPE} 
        --triple ${TARGET}
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      COMMENT "Building ${PROJECT_NAME} library with swiftc"
    )
  endif()
endfunction()

# Function to strip symbols from Swift build
function(swift_build_strip)
  add_custom_command(
    TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND llvm-strip "${CMAKE_CURRENT_SOURCE_DIR}/.build/${BUILD_TYPE}/lib${PROJECT_NAME}.a"
    COMMENT "Stripping symbols from ${PROJECT_NAME} static library for release build"
  )
endfunction()
