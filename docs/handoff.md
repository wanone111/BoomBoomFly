# BoomBoomFly 维护交接

> 交接时间：2026-07-23 23:23 CST（Asia/Shanghai）  
> 下一任务：**P0-03 — 固定 PX4 firmware、board 与参数基线**  
> 工作区：`/home/aa/px4_ws/BoomBoomFly`

## 1. 新窗口应先做什么

按顺序阅读：

1. 本文件；
2. [源码基线](SOURCE_BASELINE.md)；
3. [ADR-0001：DDS-only 控制权](adr/0001-dds-only-control-authority.md)；
4. [控制权矩阵](CONTROL_AUTHORITY_MATRIX.md)；
5. [风险与阻塞项](RISKS_AND_BLOCKERS.md)；
6. [下一阶段任务](NEXT_STAGE_TASKS.md) 中的 P0-03。

然后先向维护者索取 P0-03 所需的 PX4 资料，不要猜测固件版本、board、airframe、transport 或参数。

可直接在新窗口使用：

```text
请读取 /home/aa/px4_ws/BoomBoomFly/docs/handoff.md，
保持现有 dirty 工作树，不清理、不提交、不启动硬件，
从 P0-03 — 固定 PX4 firmware、board 与参数基线继续。
```

## 2. 仓库身份

| 项目 | 当前值 |
|---|---|
| 根仓库 | `/home/aa/px4_ws/BoomBoomFly` |
| 分支 | `master` |
| HEAD | `b10fe78f01953b8ec1071693a9abab8671c3e899` |
| origin | `https://github.com/wanone111/BoomBoomFly.git` |
| 远端同步 | 仅相对本地 `origin/master`；本轮未 fetch 根仓库 |
| 工作树 | dirty；包含文档治理、P0-01/P0-02 改动和治理前已有改动 |
| commit/push | 未执行 |

不要对根仓库执行 reset、clean、强制 checkout、切换分支、commit 或 push，除非维护者另行明确授权。

## 3. 已完成事项

### P0-01 — COMPLETE

- 受管源码已收敛为 DDS-only。
- `workspace.lock.repos`：15 个精确 SHA。
- 当前 `--verify-only`：`verified=15`、`blockers=0`。
- `workspace.repos`：16 项维护意图，其中：
  - `offboard_cpp` 跟随 `BoomBoomFly/offboard_cpp:DDS`；
  - `vision_to_dds` 跟随 `main`；
  - `../communication` 跟随 `wanone111/communication:main`。
- `communication` 按维护者要求不锁 SHA，是唯一 moving external dependency。
- MAVROS、vision-to-MAVROS、旧 serial、旧 `common` 和 MAVROS-only bringup 已退出 manifest。
- MAVROS Foxy 补丁已删除。
- `offboard_cpp` 的两处本地修改和 `.codex/` 经维护者批准丢弃；当前 clean。

关键值：

| 项目 | 值 |
|---|---|
| `offboard_cpp` | `8925f8ae82258fb9f1378543f1a0dea16c15a282`，clean |
| `vision_to_dds` | `0c3a00137f3c90a4051ac1bc1029ec56beb669b6` |
| `px4_msgs` | `392e831c1f659429ca83902e66820d7094591410`，对应 tag `v1.16.2` |
| Agent | `57d086216d01ec43121845d385894a25987f8a2c`，对应 tag `v2.4.2` |
| communication 当前 HEAD | `df256c180dbd4167f879b697e38d547521f1f8e2` |

### P0-02 — COMPLETE

已接受 [ADR-0001](adr/0001-dds-only-control-authority.md)：

- 唯一 PX4 传输：uXRCE-DDS；
- 唯一控制 writer：`/offboard_control_node`；
- 唯一视觉 writer：`/vision_to_dds_node`；
- 每个 profile 只允许一个 mission owner；
- 当前只支持单机根 namespace `/`；
- `communication` 不得发布 `/fmu/*` 或 `/offboard/*`；
- production profile 保持禁用；

注意：这是架构决策，不是已经实现的运行时强制。owner/lease、graph guard、ACK 和安全状态机仍待 P1-03、P1-04、P0-05。

## 4. 已确认的发布者

| 话题 | 唯一批准 owner | 源码证据 |
|---|---|---|
| `/fmu/in/trajectory_setpoint` | `/offboard_control_node` | `src/offboard_cpp/src/node.cpp:27-28` |
| `/fmu/in/offboard_control_mode` | `/offboard_control_node` | `src/offboard_cpp/src/node.cpp:31-32` |
| `/fmu/in/vehicle_command` | `/offboard_control_node` | `src/offboard_cpp/src/node.cpp:33-34` |
| `/fmu/in/vehicle_visual_odometry` | `/vision_to_dds_node` | `src/vision_to_dds/src/vision_to_dds.cpp:80-84` |
| `/fmu/in/landing_target_pose` | `/vision_to_dds_node`，仅精降 profile | `src/vision_to_dds/src/vision_to_dds.cpp:127-162` |

`offboard_demo_node` 与 `animal_testing_node` 都发布 `/offboard/cmd`、`cmd_mode` 和 `takeoff_land`，因此只能互斥用于隔离 SITL。`mock_rc_control.py` 可伪造 `/fmu/out/rc_channels`，只允许独立测试 domain。

## 5. 当前 dirty 状态

### 根仓库

根工作树不干净。重要来源：

- 文档治理、新文档、旧路径删除及后续无效文档清理；
- P0-01 修改的 manifest、恢复脚本、README、排除清单；
- P0-02 新增的 ADR、控制权矩阵和状态更新；
- 治理前已存在的 `Scripts/build/m1_build.sh` 等用户修改。

新窗口必须把现有状态视为用户工作，不得为了“变干净”而丢弃。

### communication

`/home/aa/px4_ws/communication` 当前 HEAD 与本地缓存的 `origin/main` 相同，但工作树 dirty：

```text
 D Serial/Serial_ROS2/src/Serial_driver.cpp
 D Serial/Serial_ROS2/src/Serial_main.cpp
 D Serial/Serial_ROS2/test/send_test.py
 M common/include/common.h
?? .gitignore
?? Serial/Serial_ROS2/serial-ros2/
?? Serial/Serial_ROS2/serial_driver_ros/
?? socket/
```

两个 ROS 2 串口目录是未跟踪嵌套 Git 仓库，远端 `main @ df256c18...` 不包含它们的完整内容。本轮明确不整理、不锁定、不 reset communication；由其 owner 独立处理。

### 已退出但本地仍存在

当前 `src/` 仍可能包含：

- `mavlink`
- `mavros`
- `ros2_foxy_vision_to_mavros`
- `px4_bringup`
- `serial-ros2`
- `serial_driver_ros`

这些只是本地遗留，不属于 manifest。不要运行、构建或重新加入，除非维护者作出新架构决策。

## 6. 下一任务：P0-03

目标：固定真实 PX4 firmware、board、airframe、参数和 DDS topic/transport 基线，并核对它们与 `px4_msgs v1.16.2`、Offboard 和 `vision_to_dds` 的接口兼容性。

### 必须向维护者索取

至少需要以下信息之一的可读来源；缺少时明确标记“无法确认”：

1. PX4-Autopilot 源码仓路径或可访问仓库 URL；
2. firmware commit/tag、构建产物版本字符串；
3. board target 和硬件型号；
4. airframe/vehicle type；
5. 参数导出文件；
6. `dds_topics.yaml`；
7. uXRCE-DDS transport：serial/UDP/TCP、设备/端口、baud、domain/namespace；
8. RC、Offboard loss、data link loss、position/vision loss、battery 和 geofence failsafe 参数；
9. estimator/EKF 外部视觉配置；
10. firmware 是否有本地补丁、submodule 漂移或未提交修改。

### 推荐只读步骤

收到 PX4 仓路径后：

```bash
git -C <PX4-Autopilot> status --short --branch
git -C <PX4-Autopilot> rev-parse HEAD
git -C <PX4-Autopilot> remote -v
git -C <PX4-Autopilot> describe --tags --always --dirty
git -C <PX4-Autopilot> submodule status --recursive
find <PX4-Autopilot> \( -name dds_topics.yaml -o -name '*.params' \)
rg -n 'uxrce|dds|vehicle_visual_odometry|trajectory_setpoint|offboard_control_mode|vehicle_command' <PX4-Autopilot>
```

若维护者只提供导出文件，则只读解析文件，不连接飞控补采。

### P0-03 输出

建议新增：

- `docs/PX4_FIRMWARE_BASELINE.md`
- 必要时 `docs/adr/0002-px4-firmware-and-dds-contract.md`

并更新：

- `REPOSITORY_STATUS.md`
- `ARCHITECTURE_OVERVIEW.md`
- `BUILD_AND_RUNTIME_STATUS.md`
- `HARDWARE_INTEGRATION_STATUS.md`
- `RISKS_AND_BLOCKERS.md`
- `NEXT_STAGE_TASKS.md`
- 本 `handoff.md`

### P0-03 验收

- firmware/board/airframe/参数来源可追溯；
- `px4_msgs` 与 firmware 消息定义/字段匹配；
- Offboard 所需 `/fmu/in/*`、`/fmu/out/*` 明确出现在 DDS topic 集；
- Agent transport/domain/namespace 唯一且可复现；
- RC、Offboard、vision、battery 等 failsafe 参数有值、来源和恢复方式；
- 未验证项没有被写成已通过；
- 全过程不 arm、不 set mode、不写参数、不启动控制节点。

## 7. 安全边界

下一窗口默认不得：

- 启动 PX4、Agent、MAVROS、Offboard、vision、RealSense、RPLIDAR 或 serial 节点；
- 访问或打开 `/dev/tty*`、USB、网络控制端口；
- arm、set mode、发送 setpoint/vehicle command；
- 写入飞控参数或烧录 firmware；
- 安装依赖、修改 udev/权限或系统配置；
- reset/clean/强制 checkout 任一仓库；
- 修改 communication；
- 声称当前 production/SITL/硬件链路已通过。

如确实需要硬件或参数导出，必须先向维护者说明具体只读命令、设备和风险并获得授权。

## 8. 已执行验证

- Offboard/communication 远端 HEAD：使用只读 `git ls-remote` 核验。
- 安装脚本：`bash -n` 通过。
- 精确 lock：15 条、全为 40 位 SHA、无重复。
- 当前 exact verify：15 verified，0 blockers。
- 空目标 dry-run：15 planned clone，0 blockers。
- moving manifest dry-run：15 verified，communication dirty 形成 1 个预期 blocker。
- 受管仓库 PX4 输入发布者反查：与 ADR 白名单一致。
- 当前 Markdown 相对链接：无缺失。
- 未执行 build、test、launch、节点或硬件访问。
- `vcs validate` 未执行：当前环境没有 `vcs` 命令。
- `shellcheck` 未执行：当前环境没有 `shellcheck`。

## 9. 权威文档

- [文档中心](README.md)
- [源码基线](SOURCE_BASELINE.md)
- [ADR-0001](adr/0001-dds-only-control-authority.md)
- [控制权矩阵](CONTROL_AUTHORITY_MATRIX.md)
- [仓库状态](REPOSITORY_STATUS.md)
- [架构总览](ARCHITECTURE_OVERVIEW.md)
- [构建与运行状态](BUILD_AND_RUNTIME_STATUS.md)
- [硬件集成状态](HARDWARE_INTEGRATION_STATUS.md)
- [风险与阻塞项](RISKS_AND_BLOCKERS.md)
- [下一阶段任务](NEXT_STAGE_TASKS.md)

## 10. 交接状态

- P0-01：COMPLETE
- P0-02：COMPLETE
- P0-03：NOT STARTED；等待 PX4 firmware/board/参数资料
- production：DISABLED
- build/test：本轮未执行
- hardware：未连接、未驱动
- Git commit/push：未执行
