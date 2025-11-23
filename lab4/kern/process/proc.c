#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc,
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:

  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  +
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;  // 全局进程链表

#define HASH_SHIFT 10
#define HASH_LIST_SIZE (1 << HASH_SHIFT)
#define pid_hashfn(x) (hash32(x, HASH_SHIFT)) //根据 pid 计算出它应该放到进程哈希表的哪一链上。

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;
//加进程日志
static void
log_proc_created(const char *tag, struct proc_struct *proc)
{
    cprintf("[proc] %s pid=%d name=\"%s\" parent=%d\n", tag, proc->pid,
            proc->name, (proc->parent != NULL) ? proc->parent->pid : -1);
}
//到这里
void kernel_thread_entry(void);  //process/entry.S
void forkrets(struct trapframe *tf); // trapentry.s?
void switch_to(struct context *from, struct context *to); //switch.S

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
    // LAB4:EXERCISE2 /*解子萱 2312585 、崔颖欣 2311136 、范鼎辉 2312326*/
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        proc->state = PROC_UNINIT;  // 进程状态
        proc->pid = -1;  // 进程号
        proc->runs = 0;  // 运行次数
        proc->kstack = 0;  // 内核栈
        proc->need_resched = 0;  // 是否需要重新调度
        proc->parent = NULL;  // 父进程
        proc->mm = NULL;  // 内存管理
        memset(&(proc->context), 0, sizeof(struct context));  // 上下文
        proc->tf = NULL;  // 陷阱帧
        proc->pgdir = boot_pgdir_pa;  // 页表基址
        proc->flags = 0;  // 标志位
        memset(proc->name, 0, sizeof(proc->name));  // 进程名
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name)
{
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc)
{
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// get_pid - alloc a unique pid for process
static int
get_pid(void)
{
    static_assert(MAX_PID > MAX_PROCESS);  // 断言：可用 PID 空间大于最大进程数
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;  // last_pid 记录上次分配，next_safe 标记安全上界
    if (++last_pid >= MAX_PID)
    {
        last_pid = 1;  // 超界后回绕到 1
        goto inside;
    }
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;  // 重新扫描前先将安全上界设为最大值
    repeat:
        le = list;
        while ((le = list_next(le)) != list)
        {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;  // 再次超界则回绕
                    }
                    next_safe = MAX_PID;  // 重置安全上界并重新扫描
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;  // 更新下一个安全上界
            }
        }
    }
    return last_pid;  // 返回最终可用的唯一 PID
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void proc_run(struct proc_struct *proc) //让 CPU 从当前进程切换到给定的进程 proc
{
    if (proc != current)
    {
        // LAB4:EXERCISE3 /*解子萱 2312585 、崔颖欣 2311136 、范鼎辉 2312326*/
        /*
         * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
         * MACROs or Functions:
         *   local_intr_save():        Disable interrupts
         *   local_intr_restore():     Enable Interrupts
         *   lsatp():                   Modify the value of satp register
         *   switch_to():              Context switching between two processes
         */
        bool intr_flag;  // 中断标志位
        local_intr_save(intr_flag); //  关中断，避免切换时被打断
        struct proc_struct *prev = current; //然后保存老进程，切到新进程，把 current 先保存成 prev，
        current = proc; //再把 current 指向目标 proc，这样后面 switch_to 才知道从谁切到谁：
        lsatp(proc->pgdir); 
        //satp 寄存器决定地址空间，新进程的页表基址在 do_fork 结束前就放到 proc->pgdir 里了，proc_run 只要调用 lsatp(proc->pgdir) 就能切换地址空间 
        switch_to(&(prev->context), &(proc->context));  
        //这两个 context 一个在 alloc_proc 里清零，另一个在 copy_thread 里设置好返回点、栈顶，所以下一次 CPU 真正执行的是新的 trapframe / 上下文 
        local_intr_restore(intr_flag); //  开中断，允许进程响应外部中断
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc)
{
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid)
{
    if (0 < pid && pid < MAX_PID)
    {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list)
        {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid)
            {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to
//       proc->tf in do_fork-->copy_thread function
// 功能：以 fn 为入口、arg 为参数，构造内核线程的初始寄存器现场，并通过 do_fork 创建内核线程
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags)
{
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;  // 设置为在 S 态返回，并初始化中断相关标志位
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags | CLONE_VM, 0, &tf);  // 调用 do_fork，以 tf 为模板创建新线程/进程（共享地址空间）
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc)
{
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL)
    {
        proc->kstack = (uintptr_t)page2kva(page); // pmm.h 定义 page2kva 为将物理页转换为内核虚拟地址
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc)
{
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc)
{
    assert(current->mm == NULL);
    /* do nothing in this project */
    return 0;
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void  //子进程要从 父进程被中断的位置继续执行，fork 的返回值让父子不同：父返回子 pid，子返回 0，所以子进程需要把 a0 = 0
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf)
{
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); //栈顶减去 trapframe 大小就是放 trapframe 的位置
    *(proc->tf) = *tf; //复制父进程的tf寄存器快照给子进程

    // Set a0 to 0 so a child process knows it's just forked
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; //设置用户态的 sp

    proc->context.ra = (uintptr_t)forkret; //子进程在第一次被调度时，会跳转到 forkret()
    proc->context.sp = (uintptr_t)(proc->tf); //切换到子进程时，它的内核栈起点是 trapframe 的位置
}

/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) //标志位，用户栈指针，trapframe 指针
{
    int ret = -E_NO_FREE_PROC; //默认返回值
    struct proc_struct *proc;
    if (nr_process >= MAX_PROCESS)
    {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    // LAB4:EXERCISE2 /*解子萱 2312585 、崔颖欣 2311136 、范鼎辉 2312326*/
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

    //    1. call alloc_proc to allocate a proc_struct
    //    2. call setup_kstack to allocate a kernel stack for child process
    //    3. call copy_mm to dup OR share mm according clone_flag
    //    4. call copy_thread to setup tf & context in proc_struct
    //    5. insert proc_struct into hash_list && proc_list
    //    6. call wakeup_proc to make the new child process RUNNABLE
    //    7. set ret vaule using child proc's pid
    if ((proc = alloc_proc()) == NULL) //分配进程结构体
    {
        // 分配失败则直接返回
        goto fork_out;
    }
    proc->parent = current;  // 记录父进程指针

    if ((ret = setup_kstack(proc)) != 0) //分配内核栈
    {
        // 内核栈分配失败，释放proc
        goto bad_fork_cleanup_proc;
    }

    if ((ret = copy_mm(clone_flags, proc)) != 0) //复制内存空间
    {
        // 复制内存空间失败，释放内核栈
        goto bad_fork_cleanup_kstack;
    }

    copy_thread(proc, stack, tf);  // 复制上下文到子进程

    proc->pid = get_pid();  // 获取唯一pid
    hash_proc(proc);        // 加入哈希表方便查找
    list_add(&proc_list, &(proc->list_link));  // 挂入进程链表

    nr_process++;  // 全局进程计数加一
    wakeup_proc(proc);  // 置为可运行
    log_proc_created("do_fork", proc);  //日志日志
    ret = proc->pid;    // 返回子进程pid
    
fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int do_exit(int error_code)
{
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char *)arg);
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
    int i;

    // list_init:proc_list.prev = proc_list.next = &proc_list
    list_init(&proc_list);  // 初始化进程链表
    for (i = 0; i < HASH_LIST_SIZE; i++)
    {
        list_init(hash_list + i);  // 初始化哈希表，find_proc里有用，快速查找
    }

    if ((idleproc = alloc_proc()) == NULL)  // 这里调用我们写的alloc_proc，分配PCB
    {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    // 做检查用的，确定是全0
    int *context_mem = (int *)kmalloc(sizeof(struct context));  //创建一个context结构体，进程上下文，定义见proc.h
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if (idleproc->pgdir == boot_pgdir_pa && idleproc->tf == NULL && !context_init_flag && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0 && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag)
    {
        cprintf("alloc_proc() correct!\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
    set_proc_name(idleproc, "idle");
    nr_process++;
    log_proc_created("proc_init", idleproc);  //日志日志

    current = idleproc;

    int pid = kernel_thread(init_main, "Hello world!!", 0);  // 以context为参数，创建init_main线程（或者说进程，似乎这概念没分的那么清晰）
    if (pid <= 0)
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// 死循环，不断轮转找到可执行状态的进程
// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
    while (1)
    {
        if (current->need_resched)
        {
            schedule(); //../schedule/sched.c
        }
    }
}
