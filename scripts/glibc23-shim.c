#define _GNU_SOURCE
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

int __isoc23_sscanf(const char *s, const char *f, ...) {
    va_list a; va_start(a, f); int r = vsscanf(s, f, a); va_end(a); return r;
}
int __isoc23_vsscanf(const char *s, const char *f, va_list a) { return vsscanf(s, f, a); }
int __isoc23_fscanf(FILE *s, const char *f, ...) {
    va_list a; va_start(a, f); int r = vfscanf(s, f, a); va_end(a); return r;
}
int __isoc23_scanf(const char *f, ...) {
    va_list a; va_start(a, f); int r = vscanf(f, a); va_end(a); return r;
}
long __isoc23_strtol(const char *n, char **e, int b) { return strtol(n, e, b); }
long long __isoc23_strtoll(const char *n, char **e, int b) { return strtoll(n, e, b); }
unsigned long __isoc23_strtoul(const char *n, char **e, int b) { return strtoul(n, e, b); }
unsigned long long __isoc23_strtoull(const char *n, char **e, int b) { return strtoull(n, e, b); }
