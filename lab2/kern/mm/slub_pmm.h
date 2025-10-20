#ifndef __KERN_MM_SLUB_PMM_H__
#define  __KERN_MM_SLUB_PMM_H__

#include <pmm.h>

// SLUB 基于 buddy system 的页级分配之上，提供小对象分配能力。
// 与其他 pmm 保持一致，只导出管理器符号以便在 pmm.c 中切换。
extern const struct pmm_manager slub_pmm_manager;

#endif /* ! __KERN_MM_SLUB_PMM_H__ */