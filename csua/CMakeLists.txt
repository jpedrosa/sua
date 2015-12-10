cmake_minimum_required(VERSION 3.4)
project(csua)
add_library(csua src/csua.c)
set_target_properties(csua PROPERTIES LINKER_LANGUAGE "C")

install(TARGETS csua DESTINATION lib)
install(FILES src/csua.h DESTINATION include)
