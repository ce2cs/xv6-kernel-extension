#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int g(int x) {
  return x+3;
}

int f(int x) {
  return g(x);
}

void main(void) {
  int x = 0;
  x = g(x);
  printf("%d\n", x);
  x = f(g(x));
  printf("%d\n", x);
  exit(0);
}
