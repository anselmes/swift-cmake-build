#include <stdio.h>

void external_example(void);

void example(void)
{
  printf("Hello from C!");
  external_example();
}
