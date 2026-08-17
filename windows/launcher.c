/*
 * MyBSD Tomoyo Explorer - Windows Launcher
 * Copyright (c) 1999-2002 Ariff Abdullah (skywizard), MyBSD Project
 * Maintainer: 9M2PJU <9m2pju@gmail.com>
 */

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void GetExecutableDir(char *outPath, size_t maxLen) {
    GetModuleFileNameA(NULL, outPath, (DWORD)maxLen);
    char *lastSlash = strrchr(outPath, '\\');
    if (lastSlash) {
        *lastSlash = '\0';
    }
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
    char baseDir[MAX_PATH];
    char rubyExe[MAX_PATH];
    char scriptPath[MAX_PATH];
    char cmdBuffer[MAX_PATH * 4];
    char targetDir[MAX_PATH];

    GetExecutableDir(baseDir, sizeof(baseDir));

    // Target directory (default: user profile or current dir)
    targetDir[0] = '\0';
    if (lpCmdLine && lpCmdLine[0] != '\0') {
        // Strip quotes if present
        if (lpCmdLine[0] == '"') {
            strncpy(targetDir, lpCmdLine + 1, sizeof(targetDir) - 1);
            targetDir[sizeof(targetDir) - 1] = '\0';
            char *quote = strrchr(targetDir, '"');
            if (quote) *quote = '\0';
        } else {
            strncpy(targetDir, lpCmdLine, sizeof(targetDir) - 1);
            targetDir[sizeof(targetDir) - 1] = '\0';
        }
    } else {
        GetEnvironmentVariableA("USERPROFILE", targetDir, sizeof(targetDir));
        if (targetDir[0] == '\0') {
            strncpy(targetDir, "C:\\", sizeof(targetDir) - 1);
            targetDir[sizeof(targetDir) - 1] = '\0';
        }
    }

    // Set EXPLORER_BASE
    char explorerBase[MAX_PATH];
    snprintf(explorerBase, sizeof(explorerBase), "%s\\share\\bsd-explorer", baseDir);
    SetEnvironmentVariableA("EXPLORER_BASE", explorerBase);

    // Look for ruby executable:
    // 1. AppDir\bin\rubyw.exe
    // 2. AppDir\bin\ruby.exe
    // 3. AppDir\rubyw.exe
    snprintf(rubyExe, sizeof(rubyExe), "%s\\bin\\rubyw.exe", baseDir);
    if (GetFileAttributesA(rubyExe) == INVALID_FILE_ATTRIBUTES) {
        snprintf(rubyExe, sizeof(rubyExe), "%s\\bin\\ruby.exe", baseDir);
    }
    if (GetFileAttributesA(rubyExe) == INVALID_FILE_ATTRIBUTES) {
        snprintf(rubyExe, sizeof(rubyExe), "%s\\rubyw.exe", baseDir);
    }

    // Script path: share\bsd-explorer\explorer_alone
    snprintf(scriptPath, sizeof(scriptPath), "%s\\share\\bsd-explorer\\explorer_alone", baseDir);
    if (GetFileAttributesA(scriptPath) == INVALID_FILE_ATTRIBUTES) {
        snprintf(scriptPath, sizeof(scriptPath), "%s\\ruby-BSD-Explorer\\explorer_alone", baseDir);
    }

    // If bundled runtime exists, launch it directly
    if (GetFileAttributesA(rubyExe) != INVALID_FILE_ATTRIBUTES &&
        GetFileAttributesA(scriptPath) != INVALID_FILE_ATTRIBUTES) {
        
        snprintf(cmdBuffer, sizeof(cmdBuffer), "\"%s\" \"%s\" \"%s\"", rubyExe, scriptPath, targetDir);

        STARTUPINFOA si;
        PROCESS_INFORMATION pi;
        ZeroMemory(&si, sizeof(si));
        si.cb = sizeof(si);
        ZeroMemory(&pi, sizeof(pi));

        if (CreateProcessA(NULL, cmdBuffer, NULL, NULL, FALSE, 0, NULL, baseDir, &si, &pi)) {
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            return 0;
        }
    }

    // Fallback: If running standalone in WSL/container or asking to open guide
    char msg[1024];
    snprintf(msg, sizeof(msg),
        "MyBSD Tomoyo Explorer\n\n"
        "Original Author: Ariff Abdullah (skywizard@MyBSD.org.my)\n"
        "Maintainer: 9M2PJU\n\n"
        "Running on Windows:\n"
        "To launch Tomoyo Explorer on Windows with graphical X11/Wayland display:\n\n"
        "1. Open PowerShell or Command Prompt\n"
        "2. Run with WSL2:\n"
        "   wsl curl -fsSL https://raw.githubusercontent.com/9M2PJU/MyBSD-Tomoyo-Explorer/master/install.sh | bash\n\n"
        "Would you like to open the GitHub project page for downloads and instructions?");

    int result = MessageBoxA(NULL, msg, "MyBSD Tomoyo Explorer", MB_YESNO | MB_ICONINFORMATION);
    if (result == IDYES) {
        ShellExecuteA(NULL, "open", "https://github.com/9M2PJU/MyBSD-Tomoyo-Explorer", NULL, NULL, SW_SHOWNORMAL);
    }

    return 0;
}
