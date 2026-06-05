# 基于 Kylin OS 的进程调度与优先级实验

很简单，直接把这个源码编译一下运行截个图即可

## 实验目的

调度器是内核中最重要的一个模块，它来控制一个线程（也可以称之为一个任务）是否可以运行，何时开始运行，运行多长时间，以及在哪个CPU上运行。调度器主要有如下几种策略：

①完全公平调度策略CFS；

②基于FIFO和RR的实时调度RT策略；

③基于Deadline的实时调度策略。

④基于CPU算力和功耗的EAS调度策略。

本实验要求写一个简单的调度器

## 实验内容及要求

本实验要求写一个简单的调度器，实现调度器的基本功能。

## 实验设计方案及原理

操作系统的调度器核心原理可概括为：“管理任务状态，在特定的触发点（如时间片用尽或主动让出）根据特定算法选择下一个要运行的任务，并执行状态切换。”

一个简单的调度器通常包含以下四个核心要素：

**任务控制块（Task Control Block, TCB）**：用于描述和记录一个任务的全部静态和动态信息，是调度器识别、追踪和管理该任务的唯一依据。

**任务状态机（Task State Machine）**

在本实验中，任务的状态简化为四种：

- 就绪（READY）：任务已准备好，在队列中等待分配 CPU。

- 运行（RUNNING）：当前正在占用 CPU 执行。

- 阻塞（BLOCKED）：等待特定事件（如延时、I/O 等），暂时无法运行。

- 结束（TERMINATED）：任务运行完毕，等待回收资源。

**就绪队列（Ready Queue）：**用于存放所有处于 READY 状态的任务，调度器每次从中筛选出下一个执行的目标。

**时间片（Time Slice）与时钟滴答（Tick）**：系统通过周期性的硬件/模拟时钟中断（Tick）来递减当前运行任务的时间片。当时间片耗尽时，触发抢占式调度。

## 程序流程图

```mermaid
flowchart TD
    %% 主线程流程
    subgraph MainThread
        M_Start([开始]) --> M_Init[定义变量 tid, ret]
        M_Init --> M_Print[打印主线程 PID 和 TID]
        M_Print --> M_Create[调用 pthread_create 创建子线程]
        
        M_Create --> M_CheckCreate{创建失败? \n ret == -1}
        M_CheckCreate -- 是 --> M_Err1[输出 cannot create new thread] --> M_End1([退出程序, 返回 1])
        
        M_CheckCreate -- 否 --> M_Join[调用 pthread_join 等待子线程结束]
        M_Join --> M_CheckJoin{等待失败? \n != 0}
        M_CheckJoin -- 否 (成功) --> M_NormalEnd([正常退出, 返回 0])
        M_CheckJoin -- 是 (失败) --> M_Err2[输出 call pthread_join function fail] --> M_End2([退出程序, 返回 1])
    end

    %% 子线程流程
    subgraph SubThread ["子线程 (thread_fun)"]
        S_Start([线程启动]) --> S_Print[打印子线程 PID 和 TID]
        S_Print --> S_Loop[进入死循环 \n while 1]
        S_Loop --> S_Loop
        %% 逻辑上无法到达 return NULL
        S_Loop -.-> S_Return[返回 NULL] --> S_End([线程结束])
    end

    %% 线程间的交互关系
    M_Create -. 异步启动 .-> S_Start
    S_End -. 资源回收 .-> M_Join

```

## 各程序之间的调用关系

```mermaid
flowchart TD
    %% 内部调用关系
    subgraph nice-exp 用户态程序
        Main[main 函数] -->|调用 pthread_create| Create[glibc 线程创建库]
        Create -->|生成| Thread1[子线程 1 worker]
        Create -->|生成| Thread2[子线程 2 worker]
        Thread1 -->|执行| Loop1[死循环计算]
        Thread2 -->|执行| Loop2[死循环计算]
    end

    %% 外部交互与内核关系
    subgraph Kylin OS 内核及系统工具
        Create -.->|"clone() 系统调用"| Kernel[Linux/Kylin 内核 CFS 调度器]
        Top[top / ps 命令] -->|读取 /proc 状态| Kernel
        Renice[renice 命令] -->|"setpriority() 系统调用"| Kernel
        Kernel -->|根据 nice 值/权重| Loop1
        Kernel -->|根据 nice 值/权重| Loop2
    end
```



## 疑难杂症

麒麟系统默认打开了运行保护，需要关一下，不然会说不允许的操作。采用命令 `sudo setstatus -f exectl off` 就好了，这样重启也可以运行。

## 程序运行结果

对程序进行运行，其中打开两个终端，均运行 `./nice-exp &`，再打开一个终端，运行 `top` 命令

![](./img/A9834BCD-8AC7-4CD9-835E-4A9A662B0CE9.png)

![](./img/E33F487A-DB2C-40FD-91D5-03A48D102160.png)

在 `top` 页面中打开 `Last Used CPU (SMP)` 选项

![](./img/5617B85C-7FA3-4B78-BCA2-934EE9EF366C.png)

可以看到 `nice-exp` 占用了大量 CPU

![](./img/7A9FA92F-0389-4301-AE15-DE80242352C4.png)

尝试将两个同样的进程绑定到同一个核心中，因为虚拟机只分配了 2 核，这里直接全部绑定到第二个核心上面去，运行 `taskset -c 1 ./nice-exp &`

![](./img/88618335-5768-4EA3-9243-54199733AD9D.png)

![](./img/D9F7F1C7-E49E-4C4F-B34F-224B914F3F7C.png)

再到另一个终端会话使用 `top` 查看

![](./img/8D67128C-646F-42CC-894E-66B2A4B37346.png)

发现两个进程几乎各占用一半的 CPU 核心资源，尝试调整优先级

我们先获取两个 `nice-exp` 的 PID，运行 `pidof nice-exp`，发现分别为 `59250` `59249`

![CleanShot_2026-06-05_17.54.22@2x](./img/CleanShot_2026-06-05_17.54.22@2x.png)

使用 `renice` 调整进程 `59250` 的优先级为 `-5`

```bash
$ sudo renice -n -5 -g 59250
```

再次在 `top` 查看，发现 CPU 占用比约为 3:1

![](./img/CleanShot_2026-06-05_17.56.09@2x.png)

## 结果分析及实验小结

可以发现，在死循环的线程作用下，nice-exp 程序占用了几乎全部 CPU 资源。在 top 视图下，CPU 占用为 99.3%。而经过优先级调整后，CPU 占用比变成了 3:1。验证了实验手册中的计算结果。

其实还有更简单的方法，直接起两个就好了，也不用那么麻烦一个一个点，说实话

```bash
$ taskset -c 1 nice -n 0 ./nice-exp &
$ taskset -c 1 nice -n -5 ./nice-exp &
```

直接这样可以起两个绑定在同一个核心上的进程。获取程序 pid 其实也不用 ps aux 慢慢找，用 pidof <process_name> 就可以（就像我上面那样）。
