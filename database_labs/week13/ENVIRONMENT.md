# Week13 MySQL 实验环境

> 检查日期：2026-10-11。这是环境记录，不是课程进度或生产部署建议。

## 当前入口

Ubuntu 中的新教学文件位于：

```text
/home/xgf/code/system-learning/database_labs/week13
```

```bash
cd ~/code/system-learning/database_labs/week13
bash mysql_lab.sh start
bash mysql_lab.sh sql
```

第二条命令启动独立实例，第三条进入 `mysql>` 提示符。在提示符里执行 SQL；输入 `exit` 退出客户端。停止实例用：

```bash
bash mysql_lab.sh stop
```

`stop` 不删除实验数据，下次 `start` 可以继续。`mysql_index_setup.sql` 会重建专用实验库内的 `course_scores` 表；重跑它会删除这张实验表原来的数据和索引，不影响其他数据库。

## 实际基线

| 项目 | 本次基线 |
|---|---|
| 宿主机 | Ubuntu 20.04.6，x86_64 |
| MySQL | Ubuntu 包 `8.0.42-0ubuntu0.20.04.1`，固定教学实验版本 |
| 存储引擎 | InnoDB |
| 实测 InnoDB 页大小 | 16384 bytes |
| 安装方式 | 下载 Ubuntu 包并解压运行，不执行系统包安装 |
| 数据与运行库 | `~/.local/share/gpt-infra/mysql-lab` |
| 通信 | 独立 Unix socket；关闭 TCP 和 MySQL X 网络监听 |
| 系统改动 | 不使用 sudo，不注册系统服务，不改全局配置或现有 C++ 工程 |

脚手架使用本地无密码 root 账户，父目录权限为当前用户私有，服务不开放网络。这只是同一用户的独立教学实例；不能据此部署公网数据库。生产版本、账户权限和安全配置需要另外确定，不能将这个固定快照当成当前推荐版本。

首次准备需要下载约数十 MB，解压后的程序、数据库文件还会占用更多空间。使用已准备好的运行库时不会重复下载。若软件源以后不再提供固定包，停止在环境准备阶段，不擅自换成 MariaDB 或改系统软件源；先重新核对适合本机的 MySQL 实验方案。

## SQL 的运行方式

交互运行：

```bash
bash mysql_lab.sh sql
```

文件运行：

```bash
bash mysql_lab.sh sql < mysql_index_setup.sql
bash mysql_lab.sh sql < mysql_index_lab.sql
```

一条命令运行：

```bash
bash mysql_lab.sh sql -e 'SELECT VERSION();'
```

脚手架把参数转交给真正的 `mysql` 客户端。SQL 出错时按客户端退出码报失败，不使用 `--force` 忽略错误。修改后先检查错误再继续，不用打印一行 PASS 代替实验。

## 验证归属

Codex 在私有实例上验证了 20000 行数据、课程 7 的 20 行、三组访问计划、查询列和脚手架启停。结果用于确认教程可运行，不代表用户已完成 Day1。课程里的数字示例来自这次固定环境；优化器估计行数可以在重建统计信息后变化。

当前学习实例在生成后保持停止状态，运行库和数据保留。用户开始实验时执行 `start`，不需要安装 Docker 或改 Ubuntu 系统服务。
