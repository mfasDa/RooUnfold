################################################################################
# Project: RooUnfold
################################################################################
project(RooUnfold)

cmake_minimum_required(VERSION 2.8)
enable_language (Fortran)

# The project version number.
set(VERSION_MAJOR   1   CACHE STRING "Project major version number.")
set(VERSION_MINOR   12   CACHE STRING "Project minor version number.")
mark_as_advanced(VERSION_MAJOR VERSION_MINOR)

find_package( ROOT COMPONENTS Tree Unfold Matrix Hist RIO MathCore Physics RooFitCore RooFit Graf Postscript Gpad)

file(GLOB RooUnfoldLinkDef src/*_LinkDef.h)
set(RooUnfoldDagostini ${CMAKE_CURRENT_SOURCE_DIR}/src/bayes.for)
file(GLOB RooUnfoldSources src/*.cxx)
file(GLOB RooUnfoldHeaders src/*.h)
list(REMOVE_ITEM RooUnfoldHeaders ${RooUnfoldLinkDef})
file(GLOB RooUnfoldExecSources examples/*.cxx)

if(EXISTS ${RooUnfoldDagostini})
  set(EXTRA_FLAGS "-DHAVE_DAGOSTINI")
else()
  message("disabling d'Agostini implementation")
  file(GLOB RooUnfoldDagostini src/RooUnfoldDagostini.*)
  list(REMOVE_ITEM RooUnfoldHeaders ${RooUnfoldDagostini})
  list(REMOVE_ITEM RooUnfoldSources ${RooUnfoldDagostini})
  set(RooUnfoldDagostini "")  
endif()

SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${EXTRA_FLAGS}")

get_filename_component (Fortran_COMPILER_NAME ${CMAKE_Fortran_COMPILER} NAME)
if (Fortran_COMPILER_NAME MATCHES "gfortran")
  set (CMAKE_Fortran_FLAGS "-funroll-all-loops -fno-f2c -O3 -std=f95 -fimplicit-none")
elseif (Fortran_COMPILER_NAME MATCHES "g77")
  set (CMAKE_Fortran_FLAGS "-funroll-all-loops -fno-f2c -O3 -std=f95 -fimplicit-none -m32")
endif()

  # generate the dictionary source code
  include(${ROOT_USE_FILE})
  set(EXTRA_FLAGS "-I${CMAKE_CURRENT_SOURCE_DIR}/src")
  ROOT_GENERATE_DICTIONARY(G__RooUnfold ${RooUnfoldHeaders} LINKDEF ${RooUnfoldLinkDef} OPTIONS ${EXTRA_FLAGS})

  # register the shared object to include both sources and dictionaries
  add_library( RooUnfold SHARED ${RooUnfoldSources} ${RooUnfoldDagostini} G__RooUnfold.cxx)
 
  # link everything together at the end
  target_link_libraries( RooUnfold ${ROOT_LIBRARIES} )
  
  # Add all targets to the build-tree export set
  export(TARGETS RooUnfold FILE "${PROJECT_BINARY_DIR}/RooUnfoldTargets.cmake")
  
  # Export the package for use from the build-tree
  # (this registers the build-tree with a global CMake-registry)
  export(PACKAGE RooUnfold)
  
  set(CONF_INCLUDE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}" "${PROJECT_BINARY_DIR}")
  set(CONF_LIBRARY_DIRS "${PROJECT_BINARY_DIR}")
  set(CONF_LIBRARIES    RooUnfold)
  include(CMakePackageConfigHelpers)
  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/RooUnfold/RooUnfoldConfigVersion.cmake"
    VERSION ${VERSION_MAJOR}.${VERSION_MINOR}
    COMPATIBILITY AnyNewerVersion
  )

  configure_file(RooUnfoldConfig.cmake.in
    "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/RooUnfoldConfig.cmake" @ONLY)

  install(TARGETS RooUnfold
          ARCHIVE DESTINATION lib
          LIBRARY DESTINATION lib)

  install(FILES
    ${RooUnfoldHeaders} DESTINATION include
  )

  install(FILES
    "${PROJECT_BINARY_DIR}/libRooUnfold.rootmap"
    "${PROJECT_BINARY_DIR}/libRooUnfold_rdict.pcm"
    DESTINATION lib)
  
  # Install the RooUnfoldConfig.cmake and RooUnfoldConfigVersion.cmake
  set(ConfigPackageLocation lib/cmake/RooUnfold)
  install(
  FILES
  "${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/RooUnfoldConfig.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/RooUnfold/RooUnfoldConfigVersion.cmake"
  DESTINATION
    ${ConfigPackageLocation}
  COMPONENT
    Devel
  )

  include(CTest)
  enable_testing()

  foreach(ExecSource ${RooUnfoldExecSources})
    get_filename_component(ExecName ${ExecSource} NAME_WE)    
    add_executable( ${ExecName} ${ExecSource} )
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src)
    target_link_libraries ( ${ExecName} RooUnfold ${ROOT_LIBRARIES} )
  endforeach()

file(GLOB Tests "${CMAKE_CURRENT_SOURCE_DIR}/test/*.sh")

foreach(TestScript ${Tests})
  get_filename_component(TestName ${TestScript} NAME)
  add_test(
    NAME ${TestName}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMAND bash ${TestScript}
    )
endforeach()

# first we can indicate the documentation build as an option and set it to ON by default
option(BUILD_DOC "Build documentation" ON)

# check if Doxygen is installed
if(BUILD_DOC)
  find_package(Doxygen)
  if (DOXYGEN_FOUND)
      # set input and output files
      set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/Doxyfile.cmake)
      set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)

      # request to configure the file
      configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
      message("Doxygen build started")

      # note the option ALL which allows to build the docs together with the application
      add_custom_target( doxygen ALL
          COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
          WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
          COMMENT "Generating API documentation with Doxygen"
          VERBATIM )
  else (DOXYGEN_FOUND)
    message("Doxygen need to be installed to generate the doxygen documentation")
  endif (DOXYGEN_FOUND)
endif(BUILD_DOC)