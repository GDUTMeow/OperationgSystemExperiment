# 实现 O(1)调度器算法

## 实验目的

根据实验手册，实现给定的 O(1) 调度器算法。

## 实验内容及要求

编写查表法调度算法，核心机制是利用 `OSRdyGrp` 变量记录哪些任务组有就绪任务，利用 `OSRdyTbl` 数组记录具体哪个任务就绪，并结合一个预先计算好的 256 元素常量数组 `OSUnMapTbl` 来快速定位最低位的1

## 程序流程图

```mermaid
flowchart TD
    %% 主函数流程
    subgraph MainFlow [main 主函数]
        M_Start([开始]) --> M_Vars[定义变量: y, x, highest_prio]
        M_Vars --> M_Call1[调用 make_task_ready 45]
        M_Call1 --> M_Call2[调用 make_task_ready 12]
        M_Call2 --> M_Call3[调用 make_task_ready 27]
        
        M_Call3 --> M_Y["查表寻找最高就绪组:\n y = OSUnMapTbl[OSRdyGrp]"]
        M_Y --> M_X["查表寻找组内最高就绪位:\n x = OSUnMapTbl[OSRdyTbl[y]]"]
        M_X --> M_Calc["合并还原最高优先级:\n highest_prio = (y << 3) + x"]
        
        M_Calc --> M_Print[打印已添加的任务和计算出的最高优先级]
        M_Print --> M_End([结束并返回 0])
    end

    %% 子函数流程
    subgraph SubFlow ["make_task_ready(prio) 子函数"]
        S_Start([进入函数]) --> S_Grp["更新就绪组标记位 \n OSRdyGrp |= (1 << (prio >> 3))"]
        S_Grp --> S_Tbl["更新就绪表中对应的具体位 \n OSRdyTbl[prio >> 3] |= (1 << (prio & 0x07))"]
        S_Tbl --> S_End([返回调用处])
    end

    %% 函数调用指向关系
    M_Call1 -.->|参数 prio = 45| S_Start
    M_Call2 -.->|参数 prio = 12| S_Start
    M_Call3 -.->|参数 prio = 27| S_Start
```

## 程序运行结果

![](./img/CleanShot_2026-06-12_14.27.35@2x.png)

可以看到，我们添加了优先级为 `45` `12` `27` 的三个任务，在其中经过调度后，优先级最高的任务是 `12`

## 结果分析与实验小结

在实验过程中，我们编写并运行了相关的 C 语言代码，对算法进行了实际验证

- 模拟向就绪表中添加了优先级为 45、12、27 的三个任务。
- 运行调度算法后，程序首先通过 `y = OSUnMapTbl[OSRdyGrp]` 锁定了最高优先级组为第 1 组，随后通过 `x = OSUnMapTbl[OSRdyTbl[y]]` 定位到该组内的偏移量为 4。
- 最终拼接计算得出最高优先级任务为 12。实验运行结果与理论预期完全一致，验证了调度逻辑的正确性。
