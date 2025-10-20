#ifndef __LIBS_DEFS_H__
#define __LIBS_DEFS_H__

#ifndef NULL
#define NULL ((void *)0)
#endif

#define __always_inline inline __attribute__((always_inline))
#define __noinline __attribute__((noinline))
#define __noreturn __attribute__((noreturn))

/* Represents true-or-false values */
typedef int bool;  // 布尔类型定义

/* Explicitly-sized versions of integer types */
typedef char int8_t;           // 8位有符号整数
typedef unsigned char uint8_t; // 8位无符号整数
typedef short int16_t;         // 16位有符号整数
typedef unsigned short uint16_t; // 16位无符号整数
typedef int int32_t;           // 32位有符号整数
typedef unsigned int uint32_t; // 32位无符号整数
typedef long long int64_t;     // 64位有符号整数
typedef unsigned long long uint64_t; // 64位无符号整数

/* Add fast types */
typedef signed char int_fast8_t;      // 快速8位有符号整数
typedef short int_fast16_t;          // 快速16位有符号整数
typedef long int_fast32_t;           // 快速32位有符号整数
typedef long long int_fast64_t;      // 快速64位有符号整数

typedef unsigned char uint_fast8_t;  // 快速8位无符号整数
typedef unsigned short uint_fast16_t; // 快速16位无符号整数
typedef unsigned long uint_fast32_t;  // 快速32位无符号整数
typedef unsigned long long uint_fast64_t; // 快速64位无符号整数

/* *
 * Pointers and addresses are 64 bits long.
 * We use pointer types to represent addresses,
 * uintptr_t to represent the numerical values of addresses.
 * */
typedef int64_t intptr_t;     // 有符号指针类型（64位）
typedef uint64_t uintptr_t;   // 无符号指针类型（64位）

/* size_t is used for memory object sizes */
typedef uintptr_t size_t;     // 大小类型，用于表示内存对象大小

/* used for page numbers */
typedef size_t ppn_t;         // 页号类型

/* *
 * Rounding operations (efficient when n is a power of 2)
 * Round down to the nearest multiple of n
 * */
#define ROUNDDOWN(a, n) ({                                          \
            size_t __a = (size_t)(a);                               \
            (typeof(a))(__a - __a % (n));                           \
        })  // 向下舍入到n的最近倍数

/* Round up to the nearest multiple of n */
#define ROUNDUP(a, n) ({                                            \
            size_t __n = (size_t)(n);                               \
            (typeof(a))(ROUNDDOWN((size_t)(a) + __n - 1, __n));     \
        })  // 向上舍入到n的最近倍数

/* Return the offset of 'member' relative to the beginning of a struct type */
#define offsetof(type, member)                                      \
    ((size_t)(&((type *)0)->member))  // 计算结构体成员偏移量

/* *
 * to_struct - get the struct from a ptr
 * @ptr:    a struct pointer of member
 * @type:   the type of the struct this is embedded in
 * @member: the name of the member within the struct
 * */
#define to_struct(ptr, type, member)                               \
    ((type *)((char *)(ptr) - offsetof(type, member)))  // 通过成员指针获取包含结构体指针

#endif /* !__LIBS_DEFS_H__ */

