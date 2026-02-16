# NorthstarLauncher

add_executable(NorthstarLauncher "main.cpp" "resources.rc")

target_compile_definitions(NorthstarLauncher PRIVATE UNICODE _UNICODE)

target_link_libraries(
    NorthstarLauncher
    PRIVATE shlwapi
            kernel32
            user32
            gdi32
            winspool
            comdlg32
            advapi32
            shell32
            ole32
            oleaut32
            uuid
            odbc32
            odbccp32
            ws2_32
    )

if (MSVC)
    set_target_properties(
        NorthstarLauncher PROPERTIES
        LINK_FLAGS "/MANIFEST:NO /DEBUG /STACK:8000000"
    )
endif()
