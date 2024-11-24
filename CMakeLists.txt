cmake_minimum_required(VERSION 3.15)
if (NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE ${CMAKE_SOURCE_DIR}/toolchain-clang.cmake)
endif()
project(squiroll)

set (CMAKE_CXX_STANDARD 20)
set (REPLACEMENT_FILES_DIR "replacement_files")
set (NEW_FILES_DIR "new_files")

# Generate PDB files
add_compile_options(-gcodeview-command-line -gcolumn-info -gcodeview -gcodeview-ghash -g)
add_link_options(/DEBUG)
add_link_options("$<$<NOT:$<CONFIG:Debug>>:SHELL:/OPT:REF /OPT:ICF /PDBALTPATH:%_PDB%>")
add_compile_options("$<$<NOT:$<CONFIG:Debug>>:SHELL:-Xclang -O3>")

add_compile_options(
	-Wno-cpp
	-Wno-narrowing
	-Wno-nonportable-include-path
	-Wno-pragma-pack
	-Wno-c++11-narrowing
	-Wno-c++17-extensions
	-Wno-c++2b-extensions
	-Wno-unused-function
	-Wno-unused-const-variable
	-Wno-unused-variable
	-Wno-unused-but-set-variable
	-Wno-unused-label
	-Wno-missing-braces
	-Wno-logical-op-parentheses
	-Wno-bitwise-op-parentheses
	-Wno-shift-op-parentheses
	-Wno-pointer-to-int-cast
	-Wno-int-to-pointer-cast
	-Wno-format-security
	-Wno-gnu-alignof-expression
	-Wno-missing-declarations
	-Wno-initializer-overrides
	-Wno-microsoft-goto
	-Wno-microsoft-template
	-Wno-microsoft-extra-qualification
	-Wno-deprecated-this-capture
	-Wno-inline-namespace-reopened-noninline
	/clang:-mstack-probe-size=1024
	/GS-
	/Gs-
	/EHsc
	/Zc:threadSafeInit-
)
add_compile_definitions(_CRT_SECURE_NO_WARNINGS _CRT_NONSTDC_NO_DEPRECATE _CRT_DECLARE_NONSTDC_NAMES _WINSOCK_DEPRECATED_NO_WARNINGS DOSWIN32=1 NOMINMAX _WINSOCKAPI_)

add_executable(
	th155r
	th155r/main.cpp
)
target_include_directories(th155r PRIVATE th155r/shared)
set_property(TARGET th155r PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
install(TARGETS th155r DESTINATION .)
install(FILES $<TARGET_PDB_FILE:th155r> DESTINATION .)

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" AND (CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "X86" OR CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "AMD64"))
	add_executable(make_embed tools/make_embed.cpp)
	add_executable(condense_nut tools/condense_nut.cpp)
	set(MAKE_EMBED make_embed)
	set(CONDENSE_NUT condense_nut)
else()
	include(ExternalProject)
	set(MAKE_EMBED_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/tools_prefix)
	ExternalProject_Add(nut_tools_ BUILD_ALWAYS true SOURCE_DIR ${CMAKE_SOURCE_DIR}/tools/
		BUILD_BYPRODUCTS
			${MAKE_EMBED_PREFIX}/bin/make_embed${CMAKE_HOST_EXECUTABLE_SUFFIX}
			${MAKE_EMBED_PREFIX}/bin/condense_nut${CMAKE_HOST_EXECUTABLE_SUFFIX}
		CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${MAKE_EMBED_PREFIX}/)
	add_executable(make_embed IMPORTED)
	set_property(TARGET make_embed PROPERTY IMPORTED_LOCATION ${MAKE_EMBED_PREFIX}/bin/make_embed${CMAKE_HOST_EXECUTABLE_SUFFIX})
	add_dependencies(make_embed nut_tools_)
	add_executable(condense_nut IMPORTED)
	set_property(TARGET condense_nut PROPERTY IMPORTED_LOCATION ${MAKE_EMBED_PREFIX}/bin/condense_nut${CMAKE_HOST_EXECUTABLE_SUFFIX})
	add_dependencies(condense_nut nut_tools_)
endif()

set(EMBEDDED_H ${CMAKE_CURRENT_BINARY_DIR}/embedded_h)
set(COMPRESSED_NUTS ${CMAKE_CURRENT_BINARY_DIR}/compressed_nuts)
function(target_embed_dir target dir)
	make_directory(${COMPRESSED_NUTS}/${dir})
	make_directory(${EMBEDDED_H}/${dir})
	file(GLOB FILES CONFIGURE_DEPENDS ${dir}/*)
	file(REAL_PATH ${dir}/../ dir)
	foreach(file_full_path ${FILES})
		file(RELATIVE_PATH file_path ${dir} ${file_full_path})
		add_custom_command(
			OUTPUT ${COMPRESSED_NUTS}/${file_path}
			COMMAND $<TARGET_FILE:condense_nut> ${file_full_path} ${COMPRESSED_NUTS}/${file_path}
			DEPENDS condense_nut
			MAIN_DEPENDENCY ${file_path}
		)
		add_custom_command(
			OUTPUT ${EMBEDDED_H}/${file_path}.h
			COMMAND $<TARGET_FILE:make_embed> compressed_nuts/${file_path} ${EMBEDDED_H}/${file_path}.h
			DEPENDS make_embed ${COMPRESSED_NUTS}/${file_path}
		)
		target_sources(${target} PRIVATE ${EMBEDDED_H}/${file_path}.h)
		# message(${file_full_path} ${file_path})
	endforeach()
endfunction()
file(GLOB NETCODE_CPPS CONFIGURE_DEPENDS th155r/Netcode/*.cpp)
add_library(
	Netcode
	SHARED
	${NETCODE_CPPS}
)
target_embed_dir(Netcode ${REPLACEMENT_FILES_DIR})
target_embed_dir(Netcode ${NEW_FILES_DIR})
target_include_directories(Netcode PRIVATE ${EMBEDDED_H})
target_link_libraries(
	Netcode
	user32
	ws2_32
	dbghelp
)
target_include_directories(Netcode PRIVATE th155r/shared th155r/Netcode/include)
target_link_options(Netcode PRIVATE "-exclude-all-symbols" "-kill-at" "/DEF:${CMAKE_SOURCE_DIR}/Netcode.def")
target_sources(Netcode PRIVATE "Netcode.def")
# Avoid using different ABI on STL on debug builds
set_property(TARGET Netcode PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
install(TARGETS Netcode DESTINATION .)
install(FILES $<TARGET_PDB_FILE:Netcode> DESTINATION .)
