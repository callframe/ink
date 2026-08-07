#include "wayland-client.h"
#include <cstdio>

int main() {
  struct wl_display *display = ::wl_display_connect(NULL);
  if (!display) {
    std::fprintf(stderr, "Failed to connect to Wayland display\n");
    return 1;
  }

  ::wl_display_disconnect(display);
}