#include "csua.h"

// Swift has a limitation when mapping to C functions that have variadic
// parameters. This function sets the fixed parameters to provide the hints
// that Swift needs.
extern int csua_open(const char *path, int oflag, mode_t mode) {
  return open(path, oflag, mode);
}
