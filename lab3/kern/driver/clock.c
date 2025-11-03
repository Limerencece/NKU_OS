#include <clock.h>
#include <defs.h>
#include <sbi.h>
#include <stdio.h>
#include <riscv.h>

volatile size_t ticks;

static inline uint64_t get_cycles(void) {
#if __riscv_xlen == 64
    uint64_t n;
    __asm__ __volatile__("rdtime %0" : "=r"(n));
    return n;
#else
    uint32_t lo, hi, tmp;
    __asm__ __volatile__(
        "1:\n"
        "rdtimeh %0\n"
        "rdtime %1\n"
        "rdtimeh %2\n"
        "bne %0, %2, 1b"
        : "=&r"(hi), "=&r"(lo), "=&r"(tmp));
    return ((uint64_t)hi << 32) | lo;
#endif
}

// Hardcode timebase
static uint64_t timebase = 100000;

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // enable timer interrupt in sie

    /*
    含义： sie 是 S-mode 中断使能寄存器，用于控制哪些中断源可以在 Supervisor 模式下被接收。
    组成结构：
    - 每一位对应一种特定的中断源
    - 位为 1 表示该中断源被使能，位为 0 表示被屏蔽
    - 主要位域包括：
        - SSIP (bit 1): S-mode 软件中断使能
        - STIP (bit 5): S-mode 定时器中断使能
        - SEIP (bit 9): S-mode 外部中断使能
    */
    /*
    "分级使能"机制：既要在 sie 中使能特定中断源，又要在 sstatus 中开启全局中断。
        1. sie : 细粒度控制，决定"哪些类型的中断可以被接收"
        2. sstatus.SIE : 粗粒度控制，决定"是否接收任何中断"
    */
    set_csr(sie, MIP_STIP);  // SSTATUS_SIE
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    // timebase = sbi_timebase() / 500;
    clock_set_next_event();

    // initialize time counter 'ticks' to zero
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

// clock_set_next_event() ，它会读取当前时间 rdtime ，再通过 sbi_set_timer(get_cycles() + timebase) 请求固件设置“下一次触发时间点”。可以理解为“设了个闹钟”。
// 注意，时钟中断就是在这触发的！！！！！！！！！！！！
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
/*
我们在 clock_init() 里已经预约了一个未来时间点；当时间到达，硬件把 sip.STIP 置为挂起。
含义： sip 是 RISC-V 的 S-mode 中断挂起寄存器（Supervisor Interrupt Pending），用于指示哪些中断当前处于"挂起"状态，即已经发生但尚未被处理的中断。
组成结构：
    - bit 1 (SSIP) : S-mode 软件中断挂起位
    - bit 5 (STIP) : S-mode 定时器中断挂起位
    - bit 9 (SEIP) : S-mode 外部中断挂起位
工作机制：
    - 我们通过 sbi_set_timer() 告诉硬件"在某个时间点触发中断"
    - 时间到达时，硬件自动设置 sip.STIP = 1
    - CPU 检查到 sip.STIP = 1 且 sie.STIP = 1 且 sstatus.SIE = 1 时，触发中断陷入
*/