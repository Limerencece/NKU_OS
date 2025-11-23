#ifndef __LIBS_ERROR_H__
#define __LIBS_ERROR_H__

/* kernel error codes -- keep in sync with list in lib/printfmt.c */
#define E_UNSPECIFIED       1   // Unspecified or unknown problem
#define E_BAD_PROC          2   // Process doesn't exist or otherwise
#define E_INVAL             3   // Invalid parameter
#define E_NO_MEM            4   // Request failed due to memory shortage
#define E_NO_FREE_PROC      5   // Attempt to create a new process beyond
#define E_FAULT             6   // Memory fault

/* the maximum allowed */
#define MAXERROR            6

#endif /* !__LIBS_ERROR_H__ */

/*
在 uCore 里，约定“函数返回负数表示出错，值的绝对值对应错误码”。因此 `-E_NO_MEM`、`-E_NO_FREE_PROC` 都是“带符号”的错误返回，方便调用者统一通过 `if (ret < 0)` 判断失败，而正数（如 pid）就表示成功。

这些宏在 `libs/error.h` 定义：

- `E_NO_MEM`：值为 `4`，含义是“内存不足导致请求失败”，用于像 `setup_kstack` 这类需要申请页框的操作；
- `E_NO_FREE_PROC`：值为 `5`，表示“系统里的进程数量已经达上限，无法再创建新进程”，用于 `nr_process >= MAX_PROCESS` 时的提示。

带上负号后就分别表示“内存不足的错误返回”和“进程数量超限的错误返回”。
*/