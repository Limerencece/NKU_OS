#include <list.h>
#include <sync.h>
#include <proc.h>
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    // 唤醒进程：确保进程不是僵尸状态且不是可运行状态
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
    // 将进程状态设置为可运行
    proc->state = PROC_RUNNABLE;
}

void
schedule(void) {
    bool intr_flag;                    // 中断标志，用于保存中断状态
    list_entry_t *le, *last;           // 链表遍历指针和最后位置指针
    struct proc_struct *next = NULL;   // 下一个要调度的进程
    
    // 保存当前中断状态并禁用中断，确保调度过程原子性
    local_intr_save(intr_flag);  
    {
        // 步骤1: 重置当前进程的重新调度标志
        current->need_resched = 0;
        
        // 步骤2: 确定遍历起始点
        // 如果当前进程是空闲进程，从链表头开始；否则从当前进程位置开始
        last = (current == idleproc) ? &proc_list : &(current->list_link);
        le = last;
        
        // 步骤3: 循环遍历进程链表，寻找可运行进程
        do {
            // 获取链表中的下一个进程
            if ((le = list_next(le)) != &proc_list) {
                // 将链表节点转换为进程结构体
                next = le2proc(le, list_link);
                // 如果找到可运行进程，跳出循环
                if (next->state == PROC_RUNNABLE) {
                    break;
                }
            }
        } while (le != last);  // 循环直到回到起始点
        
        // 步骤4: 后备选择 - 如果没有找到可运行进程，选择空闲进程
        if (next == NULL || next->state != PROC_RUNNABLE) {
            next = idleproc;
        }
        
        // 步骤5: 增加选中进程的运行次数统计
        next->runs ++;
        
        // 步骤6: 如果选中的进程不是当前进程，执行进程切换
        if (next != current) {
            proc_run(next);
        }
    }
    // 恢复之前的中断状态
    local_intr_restore(intr_flag);
}

