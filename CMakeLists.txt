cmake_minimum_required(VERSION 3.15)
project(squiroll)

set (CMAKE_CXX_STANDARD 20)
set (REPLACEMENT_FILES_DIR "replacement_files")
set (NEW_FILES_DIR "new_files")

# Generate PDB files
add_compile_options(-gcodeview-command-line -gcolumn-info -gcodeview -gcodeview-ghash -g)
add_link_options(/DEBUG)
if (NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
	add_link_options(/OPT:REF /OPT:ICF /PDBALTPATH:%_PDB%)
endif()
add_compile_options(-Wno-cpp -Wno-narrowing -Wno-nonportable-include-path -Wno-pragma-pack /EHsc)
add_compile_definitions(_CRT_SECURE_NO_WARNINGS _WINSOCK_DEPRECATED_NO_WARNINGS NOMINMAX _WINSOCKAPI_)

add_executable(
	th155r
	th155r/main.cpp
)
target_include_directories(th155r PRIVATE th155r/shared)
set_property(TARGET th155r PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
install(TARGETS th155r DESTINATION .)
install(FILES $<TARGET_PDB_FILE:th155r> DESTINATION .)

include(ExternalProject)
ExternalProject_Add(make_embed SOURCE_DIR ${CMAKE_SOURCE_DIR}/tools/ CMAKE_ARGS -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/tools_prefix/)

set(EMBEDDED_H ${CMAKE_CURRENT_BINARY_DIR}/embedded_h)
function(target_embed_dir target dir)
	make_directory(${EMBEDDED_H}/${dir})
	file(GLOB FILES CONFIGURE_DEPENDS ${dir}/*)
	file(REAL_PATH ${dir}/../ dir)
	foreach(file_full_path ${FILES})
		file(RELATIVE_PATH file_path ${dir} ${file_full_path})
		add_custom_command(
			OUTPUT ${EMBEDDED_H}/${file_path}.h
			COMMAND ${CMAKE_CURRENT_BINARY_DIR}/tools_prefix/bin/make_embed ${file_full_path} ${EMBEDDED_H}/${file_path}.h
			DEPENDS make_embed
			MAIN_DEPENDENCY ${file_path}
		)
		target_sources(${target} PRIVATE ${EMBEDDED_H}/${file_path}.h)
		# message(${file_full_path} ${file_path})
	endforeach()
endfunction()
file(GLOB NETCODE_CPPS CONFIGURE_DEPENDS th155r/Netcode/*.cpp)
add_library(
	Netcode
	MODULE
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