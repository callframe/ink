/* Fixed baseline for the vendored wayland build -- nothing here is probed.
 * Requires glibc >= 2.30 (gettid); the next-newest is memfd_create @ 2.27.
 * Linux only, see third_party/wayland/build.cmake. */

#ifndef INK_WAYLAND_CONFIG_H
#define INK_WAYLAND_CONFIG_H

#define HAVE_ACCEPT4          1  /* glibc 2.10  wayland-os.c:255 */
#define HAVE_PPOLL            1  /* glibc 2.4   wayland-client.c:2062 */
#define HAVE_GETTID           1  /* glibc 2.30  connection.c:1543,1567 */
#define HAVE_MEMFD_CREATE     1  /* glibc 2.27  cursor/os-compatibility.c:39,131 */
#define HAVE_MKOSTEMP         1  /* glibc 2.7   cursor/os-compatibility.c:50,79 */
#define HAVE_POSIX_FALLOCATE  1  /* glibc 2.2.5 cursor/os-compatibility.c:190 */
#define HAVE_STRNDUP          1  /* glibc 2.2.5 scanner.c:1031 */

/* A build knob rather than a platform fact: DTD validation is off, so
 * scanner.c never pulls in wayland.dtd.h. This is why embed.py, and therefore
 * Python, is not a build dependency. */
#define HAVE_LIBXML 0

/* Deliberately undefined. Those read with #if rather than #ifdef evaluate to 0,
 * which is the behaviour we want; adding -Wundef would mean defining them.
 *   HAVE_BROKEN_MSG_CMSG_CLOEXEC           FreeBSD kernel bug, wayland-os.c:213
 *   HAVE_SYS_UCRED_H, HAVE_XUCRED_CR_PID   BSD peercred
 *   HAVE_SYS_PRCTL_H, HAVE_SYS_PROCCTL_H, HAVE_PRCTL
 *   PACKAGE, PACKAGE_VERSION */

#endif /* INK_WAYLAND_CONFIG_H */
