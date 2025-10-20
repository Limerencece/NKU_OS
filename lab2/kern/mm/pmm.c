#include <default_pmm.h>
#include <best_fit_pmm.h>
#include <buddy_system_pmm.h>  // 新增
#include <slub_pmm.h>          // 新增
#include <defs.h>
#include <error.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <riscv.h>
#include <dtb.h>

// virtual address of physical page array
struct Page *pages;  // 物理页数组的虚拟地址
// amount of physical memory (in pages)
size_t npage = 0;    // 物理内存页数
// the kernel image is mapped at VA=KERNBASE and PA=info.base
uint64_t va_pa_offset;  // 虚拟地址到物理地址的偏移量
// memory starts at 0x80000000 in RISC-V
// DRAM_BASE defined in riscv.h as 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE;  // DRAM基地址对应的页号

// virtual address of boot-time page directory
uintptr_t *satp_virtual = NULL;  // 启动时页目录的虚拟地址
// physical address of boot-time page directory
uintptr_t satp_physical;         // 启动时页目录的物理地址

// physical memory management
const struct pmm_manager *pmm_manager;  // 物理内存管理器


static void check_alloc_page(void);  // 分配页检查函数声明

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    //pmm_manager = &default_pmm_manager;  // 使用默认内存管理器
    //pmm_manager = &buddy_system_pmm_manager;  // 使用伙伴系统内存管理器
    pmm_manager = &slub_pmm_manager;  // 使用SLUB内存管理器
    //pmm_manager = &best_fit_pmm_manager;      // 也可以使用最佳适应算法
    cprintf("memory management: %s\n", pmm_manager->name);  // 打印内存管理器名称
    pmm_manager->init();  // 初始化内存管理器
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);  // 初始化内存映射，构建空闲页结构
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);  // 分配n个连续页
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);  // 释放n个连续页
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();  // 获取当前空闲页数量
}

static void page_init(void) {
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;  // 设置虚拟地址到物理地址的偏移

    uint64_t mem_begin = get_memory_base();  // 获取内存起始地址
    uint64_t mem_size  = get_memory_size();   // 获取内存大小
    if (mem_size == 0) {
        panic("DTB memory info not available");  // 内存信息不可用
    }
    uint64_t mem_end   = mem_begin + mem_size;  // 计算内存结束地址

    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
            mem_end - 1);  // 打印物理内存映射信息

    uint64_t maxpa = mem_end;  // 最大物理地址

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;  // 限制最大地址不超过内核顶部
    }

    extern char end[];  // 内核结束地址（来自链接器脚本）

    npage = maxpa / PGSIZE;  // 计算总页数
    //kernel在end[]结束, pages是剩下的页的开始
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);  // 页结构数组起始地址（页对齐）

    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i);  // 标记所有页为保留状态
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));  // 空闲内存起始地址

    mem_begin = ROUNDUP(freemem, PGSIZE);  // 空闲内存起始地址（页对齐）
    mem_end = ROUNDDOWN(mem_end, PGSIZE);   // 内存结束地址（页对齐）
    if (freemem < mem_end) {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);  // 初始化空闲内存映射
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
    // First we should init a physical memory manager(pmm) based on the framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();  // 初始化物理内存管理器

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();  // 页面初始化

    // use pmm->check to verify the correctness of the alloc/free function in a pmm
    check_alloc_page();  // 检查分配页功能

    extern char boot_page_table_sv39[];  // 启动页表
    satp_virtual = (pte_t*)boot_page_table_sv39;  // 设置页表虚拟地址
    satp_physical = PADDR(satp_virtual);          // 计算页表物理地址
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);  // 打印页表地址
}

static void check_alloc_page(void) {
    pmm_manager->check();  // 调用内存管理器的检查函数
    cprintf("check_alloc_page() succeeded!\n");  // 检查成功
}
