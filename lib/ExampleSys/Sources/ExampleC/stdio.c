// Hardware-specific putchar - in real embedded system this writes to UART
int putchar(int c) {
  // Stub implementation for embedded system
  // In real hardware, you'd write to UART registers
  (void)c; // Suppress unused parameter warning
  return c;
}

// Simple printf implementation for embedded systems
// Only supports basic string printing, no format specifiers
int printf(const char* format, ...) {
  if (!format) return 0;

  int count = 0;
  while (*format) {
    putchar(*format);
    format++;
    count++;
  }

  return count;
}
