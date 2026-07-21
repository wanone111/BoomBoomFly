# px4_ws workspace status

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

## 项目身份与整体状态

项目名称：`px4_ws` ROS 2 Foxy 伴随计算机工作区。

审查证据表明，本目录**不是 PX4-Autopilot 固件仓库**。它运行于 Ubuntu 20.04.6 aarch64 Jetson/Tegra，包含 MAVROS 2.7.0、MAVLink 2022.12.30、自定义 Offboard、T265 vision bridge、bringup 与串口包，通过 `/dev/ttyTHS0:921600` 连接工作区外部飞控。实际 PX4 firmware branch/commit/version、FMU target、board config、参数与固件 failsafe 均未验证。

当前目标平台：**已验证为 Jetson/Tegra aarch64 + ROS 2 Foxy 伴随端；外部 PX4 board/firmware target 未验证**。

当前整体状态：**不具备“可重复构建且可证明可飞”的证据**。存在 11 项 P1，包含当前 CMake 重建阻断、串口边界/协议问题、Offboard 遥测新鲜度与 NaN 防护缺失、路径输入越界，以及 100 Hz vision Path 无界增长。没有 P0 是因为本次只读静态审查未获得足够证据证明事故必然发生；这不代表实机安全。

## 健康评分：29 / 100

未验证项不计满分；历史生成物成功不等同于当前源码通过。

| 维度 | 得分 | 满分 | 证据依据 |
|---|---:|---:|---|
| 仓库完整性 | 4 | 15 | 根无 Git/superproject；9/19 dirty、4 个 detached dirty、4038 tracked unstaged；无统一锁定清单 |
| 构建可重复性 | 3 | 20 | 旧 ROS 包 build rc=0；但当前 CMake 冲突、整包删除、隐式依赖、无 firmware/toolchain target |
| 模块完整性 | 7 | 15 | 伴随端入口和数据流可追踪；PX4 栈缺失，Action/实验代码未完成 |
| 硬件配置一致性 | 3 | 10 | `/dev/ttyTHS0` 与权限存在；STM32/T265/RPLidar 未连接，固件 UART/board 映射未知 |
| 通信接口可靠性 | 4 | 10 | MAVROS/MAVLink 链清晰；无运行 FCU topics、无 freshness/failsafe 证据、视觉标定待确认 |
| 测试和仿真 | 2 | 15 | 19 个 Python 文件 AST 通过；无当前 test_results、功能测试、SITL/MAVSDK/HIL 或本地 CI |
| 实时性与稳定性 | 2 | 10 | 静态确认多项边界、请求风暴、无界内存/带宽问题；无 sanitizer/soak/故障注入 |
| 文档完整性 | 4 | 5 | 本次生成完整状态文档；但部署 manifest、固件版本与硬件标定记录缺失 |
| **合计** | **29** | **100** | 可由各领域文档和审查清单复核 |

## 五个最重要的问题

1. [R-001](08_risks_and_technical_debt.md)：缺少实际 PX4 firmware、board target 与参数基线，固件安全链无法验证。
2. [R-002](08_risks_and_technical_debt.md)：`offboard_cpp/CMakeLists.txt:125-134` 的 HEAD 冲突标记阻断当前重建。
3. [R-004/R-005/R-006](08_risks_and_technical_debt.md)：串口输入可越界，wire scaling/长度不安全，单值 `0x99` 可触发飞行开始。
4. [R-007/R-008](08_risks_and_technical_debt.md)：禁飞区可越界且动态更新不重规划；陈旧/NaN 遥测可推进状态机。
5. [R-010/R-011](08_risks_and_technical_debt.md)：100 Hz Path 无界增长，且实际 T265 坐标标定缺乏证据。

## 五个最高优先级动作

1. 获取并锁定实机使用的 PX4 firmware commit、board target、submodule 与参数快照。
2. 解析 `src/offboard_cpp/CMakeLists.txt:125-134` 冲突，然后在隔离生成目录干净重建。
3. 修复串口长度/边界/finite/缩放，并与 STM32 firmware 做 golden-frame 对测。
4. 为 Offboard 加入 state/pose/velocity freshness、finite、estimator-health gate，并校验禁飞区输入。
5. 在无桨条件下依次执行 sanitizer 单测、PX4 SITL/MAVROS 故障注入、T265 坐标标定和资源 soak。

## 文档导航

- [01 Repository snapshot](01_repository_snapshot.md)
- [02 Architecture and modules](02_architecture_and_modules.md)
- [03 Build and targets](03_build_and_targets.md)
- [04 Hardware and drivers](04_hardware_and_drivers.md)
- [05 Communication interfaces](05_communication_interfaces.md)
- [06 Parameters and startup](06_parameters_and_startup.md)
- [07 Tests and validation](07_tests_and_validation.md)
- [08 Risks and technical debt](08_risks_and_technical_debt.md)
- [09 Next steps](09_next_steps.md)
- [10 Audit manifest](10_audit_manifest.md)

## 审查限制

本次未修改源码、构建文件、参数或测试；未运行会写入 build/install/log 的构建与测试；未连接飞控、STM32、T265、RPLidar；未 fetch 网络 remote。所有运行态和固件端结论因此保持“未验证”或“部分验证”。
