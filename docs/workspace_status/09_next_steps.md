# Next steps

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

本清单与 [风险清单](08_risks_and_technical_debt.md) 一一对应：每个 `R-nnn` 恰好有一个同号任务。执行以下源码修复需要另行授权；本次审查未实施。

## 立即处理

| 风险/任务 | 任务 | 原因 | 涉及路径 | 前置条件 | 验证标准 | 风险 | 复杂度 |
|---|---|---|---|---|---|---|---|
| R-002 | 解析 CMake 冲突并确认目标名 | 当前重建被阻断 | `src/offboard_cpp/CMakeLists.txt:125-134` | 确认希望保留的 executable | 干净单包 build=0 | 误删目标 | 小 |
| R-004 | 强化串口接收边界 | 奇数 payload 可越界 | `serial_driver_ros2/src/serial_driver.cpp` | 明确帧格式/最大长度 | ASan fuzz 无越界 | 拒绝旧异常帧 | 小 |

## 构建恢复

| 风险/任务 | 任务 | 原因 | 涉及路径 | 前置条件 | 验证标准 | 风险 | 复杂度 |
|---|---|---|---|---|---|---|---|
| R-001 | 获取并锁定实际 PX4 firmware 基线 | 固件版本/target 全部未知 | 独立 PX4 树、部署清单 | 飞控维护者提供来源 | commit/tag/board/submodule/参数可复现 | 选错实机版本 | 中 |
| R-003 | 确认并恢复或正式移除两个整包删除 | 旧 install 可能掩盖依赖缺失 | `navigation_msgs/map_msgs`、`vision_opencv/image_geometry` | 确认删除意图 | 干净依赖解析及受影响包 build=0 | 恢复错误版本 | 中 |
| R-012 | 建立多仓库锁定清单并归零权限噪声 | 当前组合无单一 revision | 19 个 `src/*` 仓库 | 先备份真实内容改动 | 新目录 checkout 后 clean 且 commit 一致 | 混淆内容与 mode | 中 |
| R-014 | 补全 package/build 环境声明 | 当前依赖本机和旧 install | bringup/serial package manifests、colcon metadata | R-002/R-003 完成 | 空环境依赖解析与构建通过 | 暴露更多隐式依赖 | 中 |
| R-020 | 用新 install 空间替代过期入口 | 现有生成物可误导运维 | `install/serial_driver/` | 源码构建恢复；保留旧目录备份 | executables 与当前 CMake 完全一致 | 清理误伤旧运行环境 | 小 |
| R-021 | 修正 whitespace 与发布元数据 | 降低 CI 噪声/版本歧义 | vision launch、serial driver、vision package.xml | 功能改动边界确认 | `git diff --check=0`，version 对齐 tag | 低 | 小 |

## SITL 验证

| 风险/任务 | 任务 | 原因 | 涉及路径 | 前置条件 | 验证标准 | 风险 | 复杂度 |
|---|---|---|---|---|---|---|---|
| R-007 | 校验禁飞区并实现任务中 HOLD/重规划 | 越界与动态更新均不安全 | `offboard_cpp/src/2025_Ti_main.cpp` | R-002；定义合法 ID | 非法输入被拒；SITL 更新后不进入禁区 | 重规划改变任务轨迹 | 大 |
| R-008 | 增加遥测 freshness/finite/estimator gate | 陈旧/NaN 可推进状态机 | offboard control/base state machine | 可用 PX4 SITL 与 MAVROS | 断流/NaN/invalid 时拒绝解锁或安全退出 | failsafe 策略选择 | 大 |
| R-009 | 将 LAND 改为有界、可确认请求 | 20 Hz 异步风暴 | `offboard_control_node.cpp`、`2025_Ti_main.cpp` | mock 服务或 SITL | 延迟/拒绝时 future 有界且 fallback 明确 | 错误 fallback | 中 |
| R-013 | 用 readiness 与监督替代固定延时 | 慢启动/进程退出不可控 | `px4_bringup/launch/`、MAVROS YAML | 定义健康 topic/service | 延迟/kill 各节点时不进入 Offboard | 复杂启动依赖 | 中 |
| R-015 | 建立自动测试与 CI 基线 | 当前无功能回归证据 | 所有自定义包 | R-002/R-014 | unit/launch/SITL 结果由 CI 留档 | 初期暴露大量缺陷 | 大 |
| R-017 | 参数化飞行配置并校验范围 | 场地/机型差异需改源码 | offboard C++ headers/sources/launch | 定义单位与安全范围 | 两套配置 launch test 通过，越界拒绝 | 默认值变化 | 中 |
| R-018 | 增加 Offboard 控制权仲裁 | 多 publisher 可竞争 | C++/Python offboard 包 | 定义单一 owner/lease | 第二控制器无法获得控制权 | 影响调试流程 | 中 |

## 硬件在环验证

| 风险/任务 | 任务 | 原因 | 涉及路径 | 前置条件 | 验证标准 | 风险 | 复杂度 |
|---|---|---|---|---|---|---|---|
| R-005 | 固化并对测 STM32 wire protocol | 缩放/长度/数值边界不确定 | serial driver 与 STM32 firmware | 获得 MCU 协议/源码 | 双向 golden frames、边界值一致 | 固件同步升级 | 中 |
| R-006 | 强化飞行开始命令与双重许可 | 简单 `0x99` 可推进任务 | `serial_orinnano.cpp`、Offboard gate | 明确认证/序列策略 | 重放/噪声/过期命令不能启动 | 与旧上位机不兼容 | 中 |
| R-016 | 验证持久 parser 与稳定设备名 | 分片丢失、设备可能冲突 | serial driver、RPLidar launch/udev | STM32 与雷达同时连接 | 全切分点/粘包通过，重枚举路径稳定 | udev 部署差异 | 中 |

## 实机前验证

| 风险/任务 | 任务 | 原因 | 涉及路径 | 前置条件 | 验证标准 | 风险 | 复杂度 |
|---|---|---|---|---|---|---|---|
| R-011 | 对 T265 安装姿态做可追溯标定 | active 旋转值与默认/说明不一致 | vision launch/source、TF 配置 | 实际安装完成；桨叶拆除台架 | 静止与逐轴运动方向/量纲均正确，日志留档 | 坐标误判可致控制异常 | 中 |

## 长期重构

| 风险/任务 | 任务 | 原因 | 涉及路径 | 前置条件 | 验证标准 | 风险 | 复杂度 |
|---|---|---|---|---|---|---|---|
| R-010 | 解耦实时 vision pose 与有界调试 Path | 100 Hz 历史轨迹导致 O(t²) 累计开销 | `vision_to_mavros.cpp`、launch | 定义调试保留长度/频率 | 2 h soak 中 RSS/CPU/pose age 有界 | 改变可视化行为 | 中 |
| R-019 | 收束 Action 与实验性实现 | 声明和实际功能不一致 | `offboard_cpp/action`、action lib、未跟踪源码 | 明确产品需求 | 要么完整 action 集成测试通过，要么不安装接口 | 丢弃潜在实验代码 | 中 |

## 推荐首先执行的三个动作

1. R-001：取得并锁定真实 PX4 firmware、board target 和参数快照。
2. R-002：解析 `offboard_cpp/CMakeLists.txt` 冲突，并在隔离生成目录重建。
3. R-004/R-005/R-007/R-008：在任何带桨测试前修复输入边界和状态新鲜度门控，并先通过 sanitizer + SITL 故障注入。
