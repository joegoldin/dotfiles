#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <unistd.h>

static int unity_editor;

__attribute__((constructor)) static void identify_process(void)
{
    char executable[4096];
    ssize_t length = readlink("/proc/self/exe", executable, sizeof(executable) - 1);
    if (length < 0 || length >= (ssize_t)sizeof(executable) - 1)
        return;
    executable[length] = '\0';
    const char *name = strrchr(executable, '/');
    unity_editor = name && strcmp(name + 1, "Unity") == 0;
}

void *dlopen(const char *filename, int flags)
{
    void *(*original)(const char *, int) = dlsym(RTLD_NEXT, "dlopen");
    // Unity 6000.6 loads ABI 2 at startup, but its COLLADA importer prefers ABI 16.
    // Keep the importer on ABI 2 to avoid mixing incompatible XML parser state.
    if (unity_editor && filename && strcmp(filename, "libxml2.so.16") == 0)
        filename = "libxml2.so.2";
    // The optimized tail call preserves the caller used by glibc for RUNPATH lookup.
    return original(filename, flags);
}
