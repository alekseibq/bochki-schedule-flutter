cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "desktop_multi_window")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "desktop_multi_window_plugin")

add_library(${PLUGIN_NAME} SHARED
  "desktop_multi_window_plugin.cpp"
  "multi_window_manager.cc"
  "flutter_window.cc"
  "window_channel_plugin.cc"
  "win32_window.cpp"
  )
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin flutter_wrapper_app)
target_link_libraries(${PLUGIN_NAME} PRIVATE "dwmapi.lib")

include(CTest)
if(BUILD_TESTING)
  add_executable(desktop_multi_window_managed_window_removals_test
    "test/managed_window_removals_test.cc"
  )
  target_compile_features(desktop_multi_window_managed_window_removals_test
    PRIVATE cxx_std_17)
  target_include_directories(desktop_multi_window_managed_window_removals_test
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
  add_test(
    NAME desktop_multi_window_managed_window_removals_test
    COMMAND desktop_multi_window_managed_window_removals_test
  )
endif()

# List of absolute paths to libraries that should be bundled with the plugin
set(desktop_multi_window_bundled_libraries
  ""
  PARENT_SCOPE
)
