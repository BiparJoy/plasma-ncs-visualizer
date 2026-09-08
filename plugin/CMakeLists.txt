cmake_minimum_required(VERSION 3.20)
project(aurora-ncs-plugin LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Quick OpenGL)

qt_standard_project_setup(REQUIRES 6.6)

qt_add_qml_module(aurorancs
    URI com.tausif.aurorancs
    VERSION 1.0
    PLUGIN_TARGET aurorancs
    SOURCES
        ncsvisualizer.h
        ncsvisualizer.cpp
)

target_link_libraries(aurorancs PRIVATE Qt6::Core Qt6::Gui Qt6::Quick Qt6::OpenGL)

# Install into Qt's own QML import path so plasmashell can find the module
# without any environment variables.
if(NOT DEFINED QT_QML_DIR)
    execute_process(
        COMMAND ${CMAKE_COMMAND} -E env qtpaths6 --query QT_INSTALL_QML
        OUTPUT_VARIABLE QT_QML_DIR
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
endif()
message(STATUS "QML module install dir: ${QT_QML_DIR}/com/tausif/aurorancs")

install(TARGETS aurorancs
    LIBRARY DESTINATION "${QT_QML_DIR}/com/tausif/aurorancs"
    RUNTIME DESTINATION "${QT_QML_DIR}/com/tausif/aurorancs"
)
install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/qmldir"
    "${CMAKE_CURRENT_BINARY_DIR}/aurorancs.qmltypes"
    DESTINATION "${QT_QML_DIR}/com/tausif/aurorancs"
)
