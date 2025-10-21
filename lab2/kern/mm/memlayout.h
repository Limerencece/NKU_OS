#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

/* All physical memory mapped at this address */
#define KERNBASE            0xFFFFFFFFC0200000 // = 0x80200000(物理内存里内核的起始位置, KERN_BEGIN_PADDR) + 0xFFFFFFFF40000000(偏移量, PHYSICAL_MEMORY_OFFSET)
//把原有内存映射到虚拟内存空间的最后一页
#define KMEMSIZE            0x7E00000          // the maximum amount of physical memory
// 0x7E00000 = 0x8000000 - 0x200000
// QEMU 缺省的RAM为 0x80000000到0x88000000, 128MiB, 0x80000000到0x80200000被OpenSBI占用
#define KERNTOP             (KERNBASE + KMEMSIZE) // 0x88000000对应的虚拟地址

#define PHYSICAL_MEMORY_END         0x88000000
#define PHYSICAL_MEMORY_OFFSET      0xFFFFFFFF40000000
#define KERNEL_BEGIN_PADDR          0x80200000
#define KERNEL_BEGIN_VADDR          0xFFFFFFFFC0200000


#define KSTACKPAGE          2                           // # of pages in kernel stack
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)       // sizeof kernel stack

#ifndef __ASSEMBLER__

#include <defs.h>
#include <list.h>

typedef uintptr_t pte_t;
typedef uintptr_t pde_t;

/* *
 * struct Page - Page descriptor structures. Each Page describes one
 * physical page. In kern/mm/pmm.h, you can find lots of useful functions
 * that convert Page to other data types, such as physical address.
 * */
struct Page {
    int ref;                        // page frame's reference counter
    // 引用计数。记录该物理页当前被多少处持有或映射；为0时可回收。
    uint64_t flags;                 // array of flags that describe the status of the page frame
    // 状态位图。每一位表示一种状态（如保留、是否为空闲块头页等）。
    unsigned int property;          // the num of free block, used in first fit pm manager
    // 当该页是空闲块的“头页”时，记录该连续空闲块的页数，用于首次适配/伙伴分配。
    list_entry_t page_link;         // free list link
    // 把页（或空闲块头页）挂接到空闲页双向链表的指针，用于管理遍历空闲页。
};

/* Flags describing the status of a page frame */
// flags 位图中各位的语义说明：
// PG_reserved（位索引 0）：=1 表示该页为内核保留页，不参与 alloc/free；=0 表示可参与分配。
// PG_property（位索引 1）：=1 表示该页是连续空闲块的“头页”，可用于分配；=0 表示不是头页或该块已被分配。
#define PG_reserved                 0       // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0 
#define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.

#define SetPageReserved(page)       ((page)->flags |= (1UL << PG_reserved))
// 将保留位（PG_reserved）置为1，标记该页为内核保留。
#define ClearPageReserved(page)     ((page)->flags &= ~(1UL << PG_reserved))
// 清除保留位，标记该页不再保留，可参与分配。
#define PageReserved(page)          (((page)->flags >> PG_reserved) & 1)
// 读取保留位当前值（0/1），判断该页是否为保留页。
#define SetPageProperty(page)       ((page)->flags |= (1UL << PG_property))
// 将“头页”标志位（PG_property）置为1，标记该页为空闲块头页。
#define ClearPageProperty(page)     ((page)->flags &= ~(1UL << PG_property))
// 清除“头页”标志位，表示该页不再是空闲块头页或该块已分配。
#define PageProperty(page)          (((page)->flags >> PG_property) & 1)
// 读取“头页”标志位当前值（0/1），判断该页是否为空闲块头页。

// convert list entry to page
#define le2page(le, member)                 \
    to_struct((le), struct Page, member)

/* free_area_t - maintains a doubly linked list to record free (unused) pages */
typedef struct {
    list_entry_t free_list;         // the list header
    unsigned int nr_free;           // number of free pages in this free list
} free_area_t;

#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */
