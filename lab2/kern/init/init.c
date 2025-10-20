#include <console.h> // 控制台/终端输出相关接口（cprintf/cputs等）
#include <defs.h>    // 通用内核宏与类型定义（如uintptr_t等）
#include <pmm.h>     // 物理内存管理接口（pmm_init等）
#include <stdio.h>   // 基础格式化输出支持
#include <string.h>  // 内存操作函数（memset等）
#include <dtb.h>     // 设备树解析（dtb_init）用于探测硬件/内存资源

int kern_init(void) __attribute__((noreturn)); // 内核主入口（不返回）
void grade_backtrace(void);
void print_kerninfo(void);

/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * print_kerninfo - 打印内核的关键信息，包括入口地址、文本/数据段边界、
 * BSS结束地址以及内核映像占用的内存大小。
 * */
void print_kerninfo(void) {
    extern char etext[], edata[], end[]; // 链接器导出：文本段末、数据段末、BSS段末
    cprintf("Special kernel symbols:\n");
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init); // 内核入口虚拟地址
    cprintf("  etext  0x%016lx (virtual)\n", etext);                 // 文本段结束虚拟地址
    cprintf("  edata  0x%016lx (virtual)\n", edata);                 // 数据段结束虚拟地址
    cprintf("  end    0x%016lx (virtual)\n", end);                   // BSS段结束虚拟地址
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024); // 内核镜像占用大小（入口到end）
}

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata); // 清零BSS段，保证未初始化全局/静态变量为0
    dtb_init();                    // 解析设备树，探测可用物理内存及硬件拓扑
    cons_init();                   // 初始化控制台子系统，后续可用cprintf/cputs输出
    const char *message = "(THU.CST) os is loading ...\0"; // 启动提示信息
    //cprintf("%s\n\n", message);
    cputs(message);               // 简单字符串输出（不带格式化）

    print_kerninfo();             // 打印内核入口/段边界等信息，便于调试与核验

    // grade_backtrace();
    pmm_init();                   // 物理内存管理初始化：分页大小、页框状态、空闲链表等

    /* do nothing */
    while (1)
        ; // 保持内核驻留，不返回（等待后续中断/调度机制接入）
}

