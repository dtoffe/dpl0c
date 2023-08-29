#include <unistd.h>

/** 
 * call runtime like this: call void @write(i32 %fd, i8* %buf, i32 %count)
 */
int write(int fd, char *buf, int count) {
  // Check if the file descriptor is valid.
  if (fd < 0) {
    return -1;
  }

  // Write the specified number of bytes to the file descriptor.
  int bytes_written = write(fd, buf, count);

  // Check if the write was successful.
  if (bytes_written < 0) {
    return -1;
  }

  // Return the number of bytes written.
  return bytes_written;
}

/** 
 * call runtime like this: call i32 @read(i32 %fd, i8* %buf, i32 %count)
 */
int read(int fd, char *buf, int count) {
  // Check if the file descriptor is valid.
  if (fd < 0) {
    return -1;
  }

  // Read the specified number of bytes from the file descriptor.
  int bytes_read = read(fd, buf, count);

  // Check if the read was successful.
  if (bytes_read < 0) {
    return -1;
  }

  // Return the number of bytes read.
  return bytes_read;
}
