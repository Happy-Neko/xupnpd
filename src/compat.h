#ifndef __COMPAT_H
#define __COMPAT_H

#ifdef __FreeBSD__
#define O_LARGEFILE     0
#define lseek64         lseek
typedef off_t           off64_t;
#endif

#endif
