# BoomBoomFly 文档中心

> 状态基线：2026-07-23 23:23（Asia/Shanghai）  
> 仓库：`/home/aa/px4_ws/BoomBoomFly`

本目录是仓库维护状态、架构、安全风险和后续计划的唯一文档入口。初始状态审查未修改源码或硬件；后续 P0-01 已更新 manifest、恢复脚本和说明，但仍未构建、启动节点或访问设备。

## 当前结论

- **已确认：** 顶层为 `master` 分支，HEAD `b10fe78f01953b8ec1071693a9abab8671c3e899`；治理前工作树不干净。
- **已确认：** `src/` 含 21 个独立嵌套 Git 仓库、80 个 `package.xml`、79 个 `colcon` 包；它们不是顶层 submodule。
- **本地现状：** DDS 与 MAVROS 源码目录仍并存，但当前没有可确认的权威 production bringup。
- **P0-01 决策：** 后续受管源码已收敛为 DDS-only；MAVROS、旧串口和 MAVROS-only bringup 已退出 manifest，当前本地旧目录仅是未清理遗留。
- **已确认：** `workspace.lock.repos` 现含 15 个精确 DDS 条目；`communication/main` 是唯一明确不锁 SHA 的 moving dependency。
- **P0-02 决策：** 单机根 namespace；唯一 PX4 控制 writer 为 `offboard_control_node`，唯一视觉 writer 为 `vision_to_dds_node`，每个 profile 只允许一个 mission owner。
- **下一任务：** P0-03 固定 PX4 firmware、board、airframe、参数、`dds_topics.yaml` 和 Agent transport；当前等待维护者提供只读资料来源。
- **已确认：** 当前 `start_all_2025TI.launch.py` 存在缺失 launch、缺失包和缺失 executable 引用，禁止作为首轮或生产入口。
- **已确认：** 历史 M1 日志证明 10 包子集曾构建成功；本轮未构建，不能据此声称当前 79 包或 DDS 控制链可构建。
- **需要现场验证：** PX4 固件/板型/参数、RealSense 当前状态、RPLIDAR、串口对端、设备权限和所有运行态能力。

## 文档导航

| 文档 | 用途 |
|---|---|
| [窗口交接](handoff.md) | 新窗口首读：当前决策、dirty 状态、安全边界和 P0-03 接续步骤 |
| [源码基线](SOURCE_BASELINE.md) | P0-01 的精确 SHA、moving 例外、退出项和恢复流程 |
| [控制权矩阵](CONTROL_AUTHORITY_MATRIX.md) | PX4 输入、视觉、反馈、mission owner 与 profile 白名单 |
| [ADR-0001](adr/0001-dds-only-control-authority.md) | DDS-only 控制权和 namespace 的正式决策 |
| [仓库状态](REPOSITORY_STATUS.md) | Git、目录、ROS 2 包、能力边界与未验证假设 |
| [架构总览](ARCHITECTURE_OVERVIEW.md) | DDS-only 目标、节点/话题、本地遗留冲突与目标架构 |
| [构建与运行状态](BUILD_AND_RUNTIME_STATUS.md) | 构建链、79 包、依赖、有效与失效入口 |
| [硬件集成状态](HARDWARE_INTEGRATION_STATUS.md) | PX4、RealSense、RPLIDAR、串口和现场验证顺序 |
| [风险与阻塞项](RISKS_AND_BLOCKERS.md) | P0—P3 风险、证据、影响和验收标准 |
| [下一阶段任务](NEXT_STAGE_TASKS.md) | 阶段 0—7 的可执行任务、命令、回退和负责人 |

## 当前安全边界

在 [P0 阻塞项](RISKS_AND_BLOCKERS.md#p0安全或架构阻塞) 关闭前：

1. 不运行 `px4_bringup/start_all_2025TI.launch.py`。
2. 不启动 `offboard_node`、`offboard_demo`、`animal_testing` 或任何会发布 `/fmu/in/*`、MAVROS setpoint、arming、mode 命令的节点。
3. 不同时连接 MAVROS 与 DDS 控制发送路径。
4. 不把旧 `build/`、`install/`、`log/` 或历史现场报告当作当前通过证据。
5. 不清理、reset 或覆盖 dirty 的嵌套仓库及 `/home/aa/px4_ws/common`。

## 文档维护规则

1. `docs/` 只保留当前基线、架构契约、风险、未完成任务和交接信息；一次性报告在有效事实并入权威文档后删除。
2. 关键结论必须标记为“已确认”“从代码推断”“需要现场验证”或“无法确定”，并给出仓库内证据路径。
3. 构建、测试和硬件能力只有在实际执行并保存结果后才能标记通过。
4. 架构、版本或安全门变化时，同步更新 `REPOSITORY_STATUS.md`、`RISKS_AND_BLOCKERS.md` 和 `NEXT_STAGE_TASKS.md`，不要复制长报告。
5. 文档移动、删除或重命名后必须检查相对链接。
6. `docs/README.md` 的状态基线时间是整个文档集的更新时间。
7. 每次阶段任务结束后同步更新 `handoff.md`，使下一窗口不依赖聊天历史。
