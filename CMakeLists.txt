cmake_minimum_required(VERSION 3.31)
project(Python-for-ooRexx CXX)

# Configuration.
set(oorexx_library $ENV{REXX_HOME}/api)
set(python_version 3.12.7)

# Variables.
set(target python)

# Target.
add_library(${target} SHARED src/python.cpp)

# ooRexx library.
target_include_directories(${target} PRIVATE ${oorexx_library})

# Python library.
find_package(Python3 ${python_version} EXACT REQUIRED COMPONENTS Development.Embed)
target_link_libraries(${target} PRIVATE Python3::Python)

# Create distribution.
add_custom_command(
    TARGET ${target}
    POST_BUILD

    COMMAND ${CMAKE_COMMAND}
    ARGS -E copy $<TARGET_FILE:${target}> ${CMAKE_SOURCE_DIR}/dist/$<TARGET_FILE_NAME:${target}>

    COMMAND ${CMAKE_COMMAND}
    ARGS -E copy ${CMAKE_SOURCE_DIR}/src/python.cls ${CMAKE_SOURCE_DIR}/src/python.py ${CMAKE_SOURCE_DIR}/dist
)
