# 文件系统底层存储调试与扇区映射实验

## 实验目的

观察 Linux 文件系统，熟练使用相关命令

## 实验内容及要求

本实验使用 `debugfs`、`blkcat`、`blktrace`、`blkparse` 观察真实 Linux 文件系统中的 inode、数据块和块 I/O。

## 实验步骤

### 确认根文件系统所在设备

运行 `df -h /` 查看根目录 `/` 的设备

```bash
$ df -h /
文件系统        大小  已用  可用 已用% 挂载点
/dev/nvme0n1p3   34G   30G  2.5G   93% /
```

可以发现目前挂载的设备是 `/dev/nvme0n1p3`，即第一块 nvme 磁盘 `/dev/nvme0n1` 的第 3 个分区

通过 `findmnt /` 也能得到类似的结果

```bash
$ findmnt /
TARGET
  SOURCE                                                                                                         FSTYPE OPTIONS
/ /dev/nvme0n1p3[/ostree/deploy/kylin/deploy/3fcab022d9bba85f62d1a4905ccd48adaa7a8e2bc8d103d0c7792742be45d50c.1] ext4   rw,relatime
```

将设备名设置为变量

```bash
$ export ROOT_DEV=/dev/nvme0n1p3
$ echo $ROOT_DEV
/dev/nvme0n1p3
```

### 创建测试文件

尝试创建测试文件并同步

```bash
$ cd ~
$ echo "Hello folks, this is fs lab of kylin edu, enjoy!!!" > debugfs.txt
$ sync
```

可以确认一下文件是否存在

```bash
$ cat ~/debugfs.txt 
Hello folks, this is fs lab of kylin edu, enjoyclear!
```

### 查看文件 inode 和数据块

注意到 `/home` 分区为独立分区

```bash
$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sr0          11:0    1  7.8G  0 rom  
nvme0n1     259:0    0   64G  0 disk 
├─nvme0n1p1 259:1    0  512M  0 part /boot/efi
├─nvme0n1p2 259:2    0    2G  0 part /boot
├─nvme0n1p3 259:3    0 34.1G  0 part /sysroot/ostree/deploy/kylin/var
│                                    /var
│                                    /sysroot
│                                    /usr
│                                    /
├─nvme0n1p4 259:4    0 22.8G  0 part /root
│                                    /home
│                                    /data
└─nvme0n1p5 259:5    0  4.6G  0 part [SWAP]
```

这里需要改下 `ROOT_DEV`

```bash
$ export ROOT_DEV=/dev/nvme0n1p4
```

运行命令查看其信息

```bash
$ sudo debugfs -R "stat $HOME/debugfs.txt" "$ROOT_DEV"
Inode: 132411   Type: regular    Mode:  0664   Flags: 0x80000
Generation: 4013946096    Version: 0x00000000:00000003
User:  1000   Group:  1000   Project:     0   Size: 54
File ACL: 532482
Links: 1   Blockcount: 16
Fragment:  Address: 0    Number: 0    Size: 0
 ctime: 0x6a2baf35:7e315a7c -- Fri Jun 12 15:03:17 2026
 atime: 0x6a2baf3c:2c10bcb4 -- Fri Jun 12 15:03:24 2026
 mtime: 0x6a2baf35:7e315a7c -- Fri Jun 12 15:03:17 2026
crtime: 0x6a2baf35:7e315a7c -- Fri Jun 12 15:03:17 2026
Size of extra inode fields: 32
Extended attributes:
  security.ksaf (29) = 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 4f f9 cf ec b7 bb a9 15 05 00 00 00 04 
  security.exectl (16) = ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff 
Inode checksum: 0x1105be13
EXTENTS:
(0):570731
```

此时可以得到

- `Inode` = `132411`
- `Size` = `54`
- `EXTENTS` = `(0):570731` -> `570731`

### 由数据块反查 inode

先设置一下变量

```bash
$ export INODE=132411
$ export EXTENTS=570731
```

然后直接反查

```bash
$ sudo debugfs -R "icheck $EXTENTS" "$ROOT_DEV"
Block   Inode number
570731  132411
```

得到结果 `132411` 与先前查询的 `Inode = 132411` 相符

### 由 inode 反查路径

```bash
$ sudo debugfs -R "ncheck $INODE" "$ROOT_DEV"
debugfs 1.47.0 (5-Feb-2023)
Inode   Pathname
132411  /home/gamernotitle/debugfs.txt
```

发现反查得到路径为 `/home/gamernotitle/debugfs.txt`，与我们新建文件的位置相符

```bash
$ pwd
/home/gamernotitle
$ ls -l
总计 76
drwxr-xr-x 2 gamernotitle gamernotitle 4096  6月 5日 15:46 模板
drwxr-xr-x 2 gamernotitle gamernotitle 4096  6月 5日 16:40 视频
lrwxrwxrwx 1 gamernotitle gamernotitle   15  6月 5日 16:40 数据盘 -> /data/usershare
drwxr-xr-x 2 gamernotitle gamernotitle 4096  6月 5日 16:40 图片
drwxr-xr-x 3 gamernotitle gamernotitle 4096  6月 5日 16:41 文档
drwxr-xr-x 2 gamernotitle gamernotitle 4096  6月 5日 16:40 下载
drwxr-xr-x 2 gamernotitle gamernotitle 4096  6月 5日 16:40 音乐
drwxr-xr-x 2 gamernotitle gamernotitle 4096  6月 5日 16:40 桌面
-rw-rw-r-- 1 gamernotitle gamernotitle   54  6月12日 15:03 debugfs.txt
drwxrwxr-x 4 gamernotitle gamernotitle 4096  6月12日 14:21 labs
$ cat /home/gamernotitle/debugfs.txt 
Hello folks, this is fs lab of kylin edu, enjoyclear!
```

### 直接读取磁盘块内容

运行命令

```bash
$ sudo blkcat $ROOT_DEV $EXTENTS
Hello folks, this is fs lab of kylin edu, enjoyclear!
```

发现成功看到了文件的内容

### 观察块 I/O

先运行监听命令

```bash
$ sudo blktrace -d "$ROOT_DEV" -o - | sudo blkparse -i - > blkparse-log
```

打开新终端，对文件使用 `dd` 进行复制操作

```bash
$ dd if=debugfs.txt of=blkparse-test.txt oflag=sync
```

进行一次同步

```bash
$ sync
```

回到运行监听命令的终端，结束监听，查看日志，找到本次复制的相关内容

> - `Q` = `Queue`，请求排入队列
> - `G` = `Get Request`，分配内核 I/O 请求结构
> - `P` = `Plug`，临时阻塞队列，等待更多邻近的写请求
> - `M` = `Merge`，内核发现连续写入，将后续的扇区写入请求合并到先前的请求中
> - `D` = `Dispatch`，内核将写入、同步、更新元数据的任务交给 NVME 控制器

```bash
259,0    0      115     5.341612579   589  A WSM 98198280 + 8 <- (259,4) 21342984
259,4    0      116     5.341612663   589  Q WSM 98198280 + 8 [jbd2/nvme0n1p4-]
259,4    0      117     5.341613079   589  G WSM 98198280 + 8 [jbd2/nvme0n1p4-]
259,4    0      118     5.341613163   589  P   N [jbd2/nvme0n1p4-]
259,0    0      119     5.341613288   589  A WSM 98198288 + 8 <- (259,4) 21342992
259,4    0      120     5.341613371   589  Q WSM 98198288 + 8 [jbd2/nvme0n1p4-]
259,4    0      121     5.341613538   589  M WSM 98198288 + 8 [jbd2/nvme0n1p4-]
259,0    0      122     5.341613663   589  A WSM 98198296 + 8 <- (259,4) 21343000
259,4    0      123     5.341613704   589  Q WSM 98198296 + 8 [jbd2/nvme0n1p4-]
259,4    0      124     5.341613788   589  M WSM 98198296 + 8 [jbd2/nvme0n1p4-]
259,0    0      125     5.341613954   589  A WSM 98198304 + 8 <- (259,4) 21343008
259,4    0      126     5.341614038   589  Q WSM 98198304 + 8 [jbd2/nvme0n1p4-]
259,4    0      127     5.341614121   589  M WSM 98198304 + 8 [jbd2/nvme0n1p4-]
259,4    0      128     5.341614913   589  D WSM 98198280 + 32 [jbd2/nvme0n1p4-]
259,4    0      129     5.342000206     0  C WSM 98198280 + 32 [0]
```

这里可以看到分成了两个步骤，首先 `jbd2` 请求排入队列，操作为 `Q`，然后请求分配 I/O 结构，操作为 `G`

然后出现了 `P` 请求，进行了阻塞，等待更多的临近写入请求

接着出现了临近的更多写入，出现了 `M` 操作，将多次写入的请求合并为一次请求

后续进行了 `D` 操作，将任务交给了 NVME 控制器

最后控制器确认完成了请求，发出了 `C` 信号，表示 `Completed`

## 结果分析与实验小结

本次实验完成了从路径到物理磁盘扇区的双向链路映射调试以及对文件的复制进行了操作的 trace，捕获并分析了 Linux 内核块设备层的底层 I/O 生命周期，进一步加深了对文件系统的理解。



