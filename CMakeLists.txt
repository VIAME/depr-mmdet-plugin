###    (V) (°,,,°) (V)     <><     (V) (°,,,°) (V)    <><     (V) (°,,,°) (V)
# Top-level CMakeLists.txt build file for this VIAME external plugin
##  ) (V)    <><     (V) (°,,,°) (V)     <><     (V) (°,,,°) (V)    <>< 

# This example serves how to write an external VIAME plugin which links
# against a pre-installed or pre-built version of VIAME. In particular,
# one which also includes python libraries which need to be built as
# a part of the plugin.

cmake_minimum_required( VERSION 3.13.0 )
set( CMAKE_CXX_STANDARD 17 )

project( VIAME-External-Plugin )
set( PLUGIN_NAME "VIAME-External-Plugin" )

# Make sure we know where the VIAME installation rests
set( VIAME_INSTALL_DIR "" CACHE PATH "Location of VIAME installation" )

if( VIAME_INSTALL_DIR )
  if( NOT EXISTS "${VIAME_INSTALL_DIR}" )
    message( FATAL_ERROR "VIAME directory does not exist, set "
      "VIAME_INSTALL_DIR to point to a valid VIAME installation" )
  endif()
  if( NOT EXISTS "${VIAME_INSTALL_DIR}/setup_viame.sh" AND
      NOT EXISTS "${VIAME_INSTALL_DIR}/setup_viame.bat" )
    message( FATAL_ERROR "VIAME install directory must contain a "
      "setup_viame.sh or setup_viame.bat file" )
  endif()
else()
  message( FATAL_ERROR "VIAME directory not set, please set "
    "VIAME_INSTALL_DIR to point to a valid VIAME installation" )
endif()

set( PLUGIN_INSTALL_DIR "${VIAME_INSTALL_DIR}" CACHE PATH "Install location" )

if( NOT PLUGIN_INSTALL_DIR )
  message( FATAL_ERROR "Plugin install dir must be set" )
endif()

# Find python and set up required python paths
find_package( Python COMPONENTS Interpreter Development REQUIRED )

set( VIAME_PYTHON_STRING "python${Python_VERSION_MAJOR}.${Python_VERSION_MINOR}"
  CACHE INTERNAL "Version ID used in python install paths" )

set( VIAME_PYBASE ${VIAME_INSTALL_DIR}/lib/${VIAME_PYTHON_STRING} )
set( VIAME_PYTHON_INSTALL ${VIAME_PYBASE} CACHE INTERNAL "Python install path" )
set( VIAME_PYTHON_USERBASE "${VIAME_INSTALL_DIR}" )

set( PLUGIN_PYBASE ${PLUGIN_INSTALL_DIR}/lib/${VIAME_PYTHON_STRING} )
set( PLUGIN_PYTHON_INSTALL ${PLUGIN_PYBASE} CACHE INTERNAL "Python install path" )
set( PLUGIN_PYTHON_USERBASE "${PLUGIN_INSTALL_DIR}" )

if( WIN32 )
  string( REPLACE "/" "\\" VIAME_PYTHON_USERBASE "${VIAME_PYTHON_USERBASE}" )
  string( REPLACE "/" "\\" PLUGIN_PYTHON_USERBASE "${PLUGIN_PYTHON_USERBASE}" )

  set( PLUGIN_PYTHON_PATH
    ${PLUGIN_PYBASE};${PLUGIN_PYBASE}/site-packages;${PLUGIN_PYBASE}/dist-packages;
    ${VIAME_PYBASE};${VIAME_PYBASE}/site-packages;${VIAME_PYBASE}/dist-packages
    CACHE INTERNAL "Pythonpath for all files installed as a part of VIAME" )
else()
  set( PLUGIN_PYTHON_PATH
    ${PLUGIN_PYBASE}:${PLUGIN_PYBASE}/site-packages:${PLUGIN_PYBASE}/dist-packages:
    ${VIAME_PYBASE}:${VIAME_PYBASE}/site-packages:${VIAME_PYBASE}/dist-packages
    CACHE INTERNAL "Pythonpath for all files installed as a part of VIAME")
endif()

# Find CUDA and CUDNN and set up required CUDA paths
find_package( CUDA QUIET REQUIRED )

if( CUDA_VERSION_MAJOR GREATER_EQUAL 10 AND NOT CUDA_cublas_device_LIBRARY )
  set( CUDA_cublas_device_LIBRARY CACHE INTERNAL "${CUDA_cublas_LIBRARY}" )
endif()

if( NOT CUDA_VERSION_PATCH )
  if( CUDA_NVCC_EXECUTABLE AND
      CUDA_NVCC_EXECUTABLE STREQUAL CMAKE_CUDA_COMPILER AND
      CMAKE_CUDA_COMPILER_VERSION MATCHES [=[([0-9]+)\.([0-9]+)\.([0-9]+)]=] )
    set( CUDA_VERSION_PATCH "${CMAKE_MATCH_3}" )
  elseif( CUDA_NVCC_EXECUTABLE )
    execute_process( COMMAND ${CUDA_NVCC_EXECUTABLE} "--version" OUTPUT_VARIABLE NOUT )
    if( NOUT MATCHES [=[ V([0-9]+)\.([0-9]+)\.([0-9]+)]=] )
      set( CUDA_VERSION_PATCH "${CMAKE_MATCH_3}" )
    endif()
  endif()
endif()

if( CUDA_VERSION VERSION_EQUAL "10.1" AND CUDA_VERSION_PATCH EQUAL "168" )
  message( FATAL_ERROR "CUDA 10.1.168 has bugs, upgrade to 10.1.264 or above" )
endif()

set( DEF_CUDA_ARCHS "3.5 5.0 5.2 6.0 6.1" )
if( CUDA_VERSION VERSION_GREATER "8.5" )
  set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 7.0" )
  if( CUDA_VERSION VERSION_LESS "10.1" )
    set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 7.0+PTX" )
  endif()
endif()
if( CUDA_VERSION VERSION_GREATER "9.5" )
  set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 7.5" )
  if( CUDA_VERSION VERSION_LESS "11.0" )
    set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 7.5+PTX" )
  endif()
endif()
if( CUDA_VERSION VERSION_GREATER "10.5" )
  set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 8.0" )
  if( CUDA_VERSION VERSION_LESS "11.1" )
    set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 8.0+PTX" )
  endif()
endif()
if( CUDA_VERSION VERSION_GREATER "11.0" )
  set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 8.6" )
  if( CUDA_VERSION VERSION_LESS "12.1" )
    set( DEF_CUDA_ARCHS "${DEF_CUDA_ARCHS} 8.6+PTX" )
  endif()
endif()

set( CUDA_ARCHITECTURES "${DEF_CUDA_ARCHS}" CACHE STRING "CUDA Architectures" )
mark_as_advanced( CUDA_ARCHITECTURES )

if( WIN32 )
  set( VIAME_EXECUTABLES_PATH
    ${VIAME_INSTALL_DIR}/bin;${CUDA_TOOLKIT_ROOT_DIR}/bin;$ENV{PATH}
    CACHE INTERNAL "All compiled and system-related runnable executables" )
else()
  set( VIAME_EXECUTABLES_PATH
    ${VIAME_INSTALL_DIR}/bin:${CUDA_TOOLKIT_ROOT_DIR}/bin:$ENV{PATH}
    CACHE INTERNAL "All compiled and system-related runnable executables" )
endif()

set( CUDNN_ROOT_DIR "" CACHE PATH "CUDNN root folder, leave as blank to auto-detect." )

find_library( CUDNN_LIBRARY REQUIRED
  NAMES cudnn libcudnn.so libcudnn.so.8 libcudnn.so.7 libcudnn.so.6
  HINTS ${CUDNN_ROOT_DIR}
        ${CUDNN_ROOT_DIR}/lib
        ${CUDNN_ROOT_DIR}/lib/x64
        ${CUDA_TOOLKIT_ROOT_DIR}
        ${CUDA_TOOLKIT_ROOT_DIR}/lib
        ${CUDA_TOOLKIT_ROOT_DIR}/lib/x64
        ${CUDA_TOOLKIT_ROOT_DIR}/lib64
        ${CUDA_TOOLKIT_ROOT_DIR}/targets/aarch64-linux
  PATH_SUFFIXES lib lib64 )

get_filename_component( CUDNN_LIBRARY "${CUDNN_LIBRARY}" REALPATH )

if( NOT CUDNN_LIBRARY )
  message( FATAL_ERROR "Unable to locate CUDNN library" )
endif()

# Different subprojects use each variable
set( CUDNN_LIBRARIES "${CUDNN_LIBRARY}" CACHE INTERNAL "" FORCE )

# Check version of CUDNN
get_filename_component( CUDNN_ROOT_DIR_TMP "${CUDNN_LIBRARY}" DIRECTORY )
get_filename_component( CUDNN_ROOT_DIR_TMP "${CUDNN_ROOT_DIR_TMP}" DIRECTORY )

set( CUDNN_ROOT_DIR "${CUDNN_ROOT_DIR_TMP}" CACHE INTERNAL "CUDNN root folder" FORCE )
set( CUDNN_INCLUDE_FILE "${CUDNN_ROOT_DIR}/include/cudnn.h" CACHE INTERNAL "" FORCE )

if( CUDNN_ROOT_DIR STREQUAL "/" )
  set( CUDNN_INCLUDE_FILE "/include/cudnn.h" CACHE INTERNAL "" FORCE )
endif()

if( NOT EXISTS ${CUDNN_INCLUDE_FILE} )
  get_filename_component( CUDNN_ROOT_DIR_TMP "${CUDNN_ROOT_DIR_TMP}" DIRECTORY )

  set( CUDNN_ROOT_DIR "${CUDNN_ROOT_DIR_TMP}" CACHE INTERNAL "CUDNN root folder" FORCE )
  set( CUDNN_INCLUDE_FILE "${CUDNN_ROOT_DIR}/include/cudnn.h" CACHE INTERNAL "" FORCE )
endif()

if( NOT EXISTS ${CUDNN_INCLUDE_FILE} )
  message( ERROR "Unable to locate cudnn.h include header" )
endif()

if( CUDNN_ROOT_DIR STREQUAL "/" )
  set( CUDNN_INCLUDE_DIR "/include" CACHE INTERNAL "CUDNN include" FORCE )
else()
  set( CUDNN_INCLUDE_DIR "${CUDNN_ROOT_DIR}/include" CACHE INTERNAL "" FORCE )
endif()

if( EXISTS "${CUDNN_ROOT_DIR}/include/cudnn_version.h" )
  set( CUDNN_VERSION_FILE "${CUDNN_ROOT_DIR}/include/cudnn_version.h" )
else()
  set( CUDNN_VERSION_FILE "${CUDNN_INCLUDE_FILE}" )
endif()

if( EXISTS "${CUDNN_VERSION_FILE}" )
  file( READ "${CUDNN_VERSION_FILE}" TMP_CUDNN_VERSION_FILE_CONTENTS )

  string( REGEX MATCH "define CUDNN_MAJOR * +([0-9]+)"
          CUDNN_VERSION_MAJOR "${TMP_CUDNN_VERSION_FILE_CONTENTS}" )
  string( REGEX REPLACE "define CUDNN_MAJOR * +([0-9]+)" "\\1"
          CUDNN_VERSION_MAJOR "${CUDNN_VERSION_MAJOR}" )
endif()

###
# Python Sub-Project Builds
##
set( PYTHON_LIBS_TO_BUILD mmcv mmdet )

set( VIAME_PROJECT_LIST ${VIAME_PROJECT_LIST} ${PYTHON_LIBS_TO_BUILD} )
set( PYTHON_ENV_VARS )

list( APPEND PYTHON_ENV_VARS "CUDNN_LIBRARY=${CUDNN_LIBRARIES}" )
if( WIN32 )
  string( REPLACE ";" "----" PYTHON_ENV_VARS "${PYTHON_ENV_VARS}" )
endif()
if( CUDNN_ROOT_DIR )
  list( APPEND PYTHON_ENV_VARS "CUDNN_INCLUDE_DIR=${CUDNN_ROOT_DIR}/include" )
endif()

list( APPEND PYTHON_ENV_VARS "USE_CUDA=1" )
list( APPEND PYTHON_ENV_VARS "FORCE_CUDA=1" )
list( APPEND PYTHON_ENV_VARS "CUDA_VISIBLE_DEVICES=0" )
list( APPEND PYTHON_ENV_VARS "CUDA_HOME=${CUDA_TOOLKIT_ROOT_DIR}" )
list( APPEND PYTHON_ENV_VARS "MMCV_WITH_OPS=1" )

if( WIN32 )
  set( EXTRA_INCLUDE_DIRS "${VIAME_INSTALL_DIR}/include;$ENV{INCLUDE}" )
  set( EXTRA_LIBRARY_DIRS "${VIAME_INSTALL_DIR}/lib;$ENV{LIB}" )

  string( REPLACE ";" "----" VIAME_PYTHON_PATH "${VIAME_PYTHON_PATH}" )
  string( REPLACE ";" "----" EXTRA_INCLUDE_DIRS "${EXTRA_INCLUDE_DIRS}" )
  string( REPLACE ";" "----" EXTRA_LIBRARY_DIRS "${EXTRA_LIBRARY_DIRS}" )

  list( APPEND PYTHON_ENV_VARS "INCLUDE=${EXTRA_INCLUDE_DIRS}" )
  list( APPEND PYTHON_ENV_VARS "LIB=${EXTRA_LIBRARY_DIRS}" )
  list( APPEND PYTHON_ENV_VARS "PYTHONHOME=${VIAME_PYTHON_USERBASE}" )
  list( APPEND PYTHON_ENV_VARS "PYTHONIOENCODING=UTF-8" )
else()
  list( APPEND PYTHON_ENV_VARS "CPPFLAGS=-I${VIAME_INSTALL_DIR}/include" )
  list( APPEND PYTHON_ENV_VARS "LDFLAGS=-L${VIAME_INSTALL_DIR}/lib" )
  list( APPEND PYTHON_ENV_VARS "LD_LIBRARY_PATH=${VIAME_INSTALL_DIR}/lib:$ENV{LD_LIBRARY_PATH}" )
  list( APPEND PYTHON_ENV_VARS "CC=${CMAKE_C_COMPILER}" )
  list( APPEND PYTHON_ENV_VARS "CXX=${CMAKE_CXX_COMPILER}" )
  list( APPEND PYTHON_ENV_VARS "PATH=${VIAME_EXECUTABLES_PATH}" )
endif()

list( APPEND PYTHON_ENV_VARS "PYTHONPATH=${PLUGIN_PYTHON_PATH}" )
list( APPEND PYTHON_ENV_VARS "PYTHONUSERBASE=${PLUGIN_PYTHON_USERBASE}" )

foreach( LIB ${PYTHON_LIBS_TO_BUILD} )

  set( LIBRARY_LOCATION ${VIAME_PACKAGES_DIR}/packages/${LIB} )
  set( LIBRARY_LOCATION_URL file://${LIBRARY_LOCATION} )

  set( LIBRARY_PIP_CACHE_DIR ${CMAKE_BUILD_PREFIX}/src/python-build/${LIB}-cache )
  set( LIBRARY_PIP_BUILD_DIR ${CMAKE_BUILD_PREFIX}/src/python-build/${LIB}-build )
  set( LIBRARY_PIP_TMP_DIR   ${CMAKE_BUILD_PREFIX}/src/python-build/${LIB}-tmp )

  CreateDirectory( ${LIBRARY_PIP_CACHE_DIR} )
  CreateDirectory( ${LIBRARY_PIP_BUILD_DIR} )
  CreateDirectory( ${LIBRARY_PIP_TMP_DIR} )

  set( LIBRARY_PIP_BUILD_DIR_CMD -b ${LIBRARY_PIP_BUILD_DIR} )
  set( LIBRARY_PIP_CACHE_DIR_CMD --cache-dir ${LIBRARY_PIP_CACHE_DIR} )

  if( VIAME_SYMLINK_PYTHON )
    set( LIBRARY_PIP_BUILD_CMD
      ${Python_EXECUTABLE} setup.py build )
    set( LIBRARY_PIP_INSTALL_CMD
      ${Python_EXECUTABLE} -m pip install --user -e . )
  else()
    if( "${LIB}" STREQUAL "mmcv" OR "${LIB}" STREQUAL "torchvision" )
      set( LIBRARY_PIP_BUILD_CMD
        ${Python_EXECUTABLE} setup.py
          bdist_wheel -d ${LIBRARY_PIP_BUILD_DIR} )
    else()
      set( LIBRARY_PIP_BUILD_CMD
        ${Python_EXECUTABLE} setup.py build_ext
          --include-dirs="${VIAME_INSTALL_DIR}/include"
          --library-dirs="${VIAME_INSTALL_DIR}/lib"
          --inplace bdist_wheel -d ${LIBRARY_PIP_BUILD_DIR} )
    endif()
    set( LIBRARY_PIP_INSTALL_CMD
      ${CMAKE_COMMAND}
        -DPYTHON_EXECUTABLE=${Python_EXECUTABLE}
        -DPython_EXECUTABLE=${Python_EXECUTABLE}
        -DWHEEL_DIR=${LIBRARY_PIP_BUILD_DIR}
        -P ${VIAME_CMAKE_DIR}/install_python_wheel.cmake )
  endif()

  set( LIBRARY_PYTHON_BUILD
    ${CMAKE_COMMAND} -E env "${PYTHON_ENV_VARS}"
    "TMPDIR=${LIBRARY_PIP_TMP_DIR}"
    ${LIBRARY_PIP_BUILD_CMD} )
  set( LIBRARY_PYTHON_INSTALL
    ${CMAKE_COMMAND} -E env "${PYTHON_ENV_VARS}"
    "TMPDIR=${LIBRARY_PIP_TMP_DIR}"
    ${LIBRARY_PIP_INSTALL_CMD} )

  set( LIBRARY_PATCH_COMMAND "" )

  if( "${LIB}" STREQUAL "bioharn" )
    set( PROJECT_DEPS netharn )
  elseif( "${LIB}" STREQUAL "netharn" )
    set( PROJECT_DEPS mmdetection )
  elseif( "${LIB}" STREQUAL "mmdetection" )
    set( PROJECT_DEPS fletch mmcv )
    if( VIAME_ENABLE_PYTHON-VIS-INTERNAL )
      set( PROJECT_DEPS ${PROJECT_DEPS} torchvision )
    endif()
  else()
    set( PROJECT_DEPS fletch python-deps pytorch )
  endif()

  ExternalProject_Add( ${LIB}
    DEPENDS ${PROJECT_DEPS}
    PREFIX ${VIAME_BUILD_PREFIX}
    SOURCE_DIR ${LIBRARY_LOCATION}
    BUILD_IN_SOURCE 1
    PATCH_COMMAND ${LIBRARY_PATCH_COMMAND}
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ${LIBRARY_PYTHON_BUILD}
    INSTALL_COMMAND ${LIBRARY_PYTHON_INSTALL}
    LIST_SEPARATOR "----"
    )

  if( VIAME_FORCEBUILD )
    ExternalProject_Add_Step( ${LIB} forcebuild
      COMMAND ${CMAKE_COMMAND}
        -E remove ${VIAME_BUILD_PREFIX}/src/{LIB}-stamp
      COMMENT "Removing build stamp file for build update (forcebuild)."
      DEPENDEES configure
      DEPENDERS build
      ALWAYS 1
      )
  endif()
endforeach()

# Set default paths
#set( CMAKE_INSTALL_PREFIX "${VIAME_INSTALL_DIR}" CACHE PATH "Default install dir" FORCE )
#
#set( PLUGIN_FILES
#  )
#
#if( EXISTS "${VIAME_INSTALL_DIR}/lib/python3.6/site-packages" )
#  set( PYTHON_PATH "lib/python3.6/site-packages" )
#else()
#  set( PYTHON_PATH "lib/python3.6/dist-packages" )
#endif()
#
#foreach( PLUGIN_FILE ${PLUGIN_FILES} )
#  install( FILES "${PLUGIN_FILE}"
#    DESTINATION "${VIAME_DIR}/${PYTHON_PATH}/${PLUGIN_PATH}"
#    )
#endforeach()
