#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
/*
含义： sstatus 是 RISC-V 的 S-mode 状态寄存器，保存当前处理器在 Supervisor 模式下的状态信息。
组成结构：
- UIE (bit 0): User 模式中断使能
- SIE (bit 1): Supervisor 模式中断使能（全局开关）
- UPIE (bit 4): 进入陷入前的 User 模式中断使能状态
- SPIE (bit 5): 进入陷入前的 Supervisor 模式中断使能状态
- SPP (bit 8): 进入陷入前的特权级（0=User, 1=Supervisor）
- FS/XS (bit 13-16): 浮点和扩展状态
- PUM (bit 18): 保护用户内存访问
注意：
- SSTATUS_SIE 是 S-mode 的全局中断使能位（第1位）
- 这是中断系统的"总开关"：只有当这一位为 1 时，CPU 才会响应任何中断
- 即使在 sie 中使能了特定中断源，如果 SSTATUS_SIE 为 0，所有中断都会被屏蔽
- 当中断发生时，硬件会自动清除 SIE 位并保存到 SPIE 位，防止中断嵌套； sret 返回时会从 SPIE 恢复 SIE
*/
// 中断使能状态位置位
// SSTATUS_SPP本来就是0，无需置位
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
