# BoomBoomFly 迁移状态与后续计划

> 核对日期：2026-07-23
> 源工作区：`/home/c/px4_ws`（继续作为只读备份基线）
> 目标工作区：`/home/c/BoomBoomFly`
> 主线目标：T265 + D435 融合定位，首版通过 MAVROS 接入 PX4 Offboard；STM32 暂不进入主线。

## 1. 当前结论

迁移已推进到 **M1 最小软件构建闭环通过、完整跨平台恢复尚有网络阻塞** 的阶段。

- M0 基线冻结已完成：顶层仓库及 19 个嵌套仓库已有可恢复快照和校验和。
- 用户已确认删除 `docs/missions.md`。
- 用户已明确排除 `offboard_py`、`cv_yolo_paddle_pkg`、`opencv_cpp`；三者不参与首版恢复、构建和集成。
- 恢复脚本已按 `workspace.lock.repos` 管理 20 个仓库，使用精确 SHA、detached HEAD，不创建本地分支。
- 当前本地对象可精确恢复 18/20 个仓库；缺少 `px4_msgs` 与 `Micro-XRCE-DDS-Agent`。
- GitHub HTTPS TLS 失败且 SSH 22 超时，故公网 20/20 恢复尚未通过。
- 干净 ROS 2 Foxy 环境中的 M1 最小 profile 已完成 10/10 包构建，耗时 44 分 13 秒。
- 本轮未启动相机、串口、MAVROS、PX4、Offboard 或完整 bringup，不能据此判断硬件和飞行控制可用。

| 项目 | 状态 |
|---|---|
| `/home/c/px4_ws` 备份保留 | 已确认，不修改 |
| M0 可恢复快照 | 完成并校验 |
| `docs/missions.md` 删除 | 用户确认 |
| 三个包明确排除 | 已落实到机器清单和构建参数 |
| 公开仓库锁文件 | 20 个精确 SHA |
| 本地锁定恢复 | 18/20 通过 |
| 公网空目录恢复 | 阻塞：GitHub 网络 |
| M1 最小构建 | 10/10 通过 |
| 连续两次干净构建 | 尚未执行 |
| 双相机 M2 回归 | 尚未执行 |
| PX4 只读链 M3 | 尚未执行 |
| Offboard 安全控制 | 不具备测试条件 |

详细执行证据见 `docs/m1_execution_report.md`。

## 2. 版本和恢复基线

顶层仓库：

- 分支：`master`。
- 基线 HEAD：`03c8889`。
- 远端：`https://github.com/wanone111/BoomBoomFly.git`。
- 本次未创建分支、提交或推送。

可恢复快照：

```text
/home/c/migration_backups/BoomBoomFly_m0_20260723T174116+0800
/home/c/migration_backups/BoomBoomFly_phase1_20260723T163830+0800
```

前者覆盖 M0 前的顶层和 19 个嵌套仓库状态，包含 tracked archive、diff、未跟踪清单和 SHA-256 校验；后者是更早的完整迁移快照。两者均应保留，直到 M2/M3 验收完成。

## 3. 已确认迁移决策

### 3.1 删除与排除

- `docs/missions.md`：删除已由用户确认，不恢复。
- `offboard_py`：排除。
- `cv_yolo_paddle_pkg`：排除。
- `opencv_cpp`：排除。

机器可读清单：

```text
workspace.excluded_packages
```

安装脚本不会恢复这三个包，M1 构建脚本会通过 `--packages-skip` 显式排除。源码目录只保留为历史参考，不能作为首版运行时依赖。

### 3.2 首版技术路线

- T265：候选主视觉里程计，实际安装方向、外参、坐标轴和时间戳仍待 M2/M3 验证。
- D435：首版先作为深度/环境数据源；是否参与定位融合需在 M3 明确。
- 飞控接入：MAVROS 作为首版候选权威链路。
- PX4 DDS：保留为后续路线；在控制 owner 未冻结前不得与 MAVROS 同时发送控制指令。
- STM32、RPLIDAR、Nav2、RTAB-Map、YOLO：不进入当前最小闭环。

## 4. Git 和仓库状态

目标工作区是一个顶层 Git 仓库，`src/` 中有 19 个嵌套 Git 仓库。迁移前核对显示 9 个嵌套仓库 dirty、4 个 detached；这些本地修改已纳入 M0 快照，不得直接 reset、clean 或覆盖。

已完成的 remote 治理：

- `src/offboard_cpp` origin 规范化为 `https://github.com/AyasOwen/offboard_cpp.git`。
- `src/px4_bringup` origin 规范化为 `https://github.com/AyasOwen/px4_bringup.git`。

当前恢复 dry-run：

```text
planned=20 cloned=2 updated=0 verified=9 blockers=9
```

9 个 blocker 均是 dirty 仓库的安全阻止；这表明脚本会保护本地修改，不代表这些仓库代码不可用。

重点技术债：

- `offboard_cpp/CMakeLists.txt` 的锁定基线仍含冲突标记，禁止纳入当前控制构建。
- MAVROS 有 Foxy `tf2_eigen` 兼容需求，已提取为最小、可审核补丁。
- `navigation_msgs/map_msgs`、`vision_opencv/image_geometry` 有删除状态，完整工作区构建前必须确认。
- 第三方仓库存在大量权限位噪声，应与真实内容改动分离治理。

## 5. M1 执行结果

### 5.1 恢复

锁文件共 20 个仓库：

- 18 个从本地 Git 对象精确恢复成功。
- 18 个均为 detached HEAD，零本地分支，HEAD 与锁 SHA 一致。
- 缺少 `px4_msgs`、`Micro-XRCE-DDS-Agent` 本地对象。
- 公网恢复因 GitHub TLS/SSH 网络失败被阻塞。
- 恢复树 `colcon list` 发现 76 个包，排除的三个包均不存在。

### 5.2 依赖

完整树 `rosdep check` 尚未闭环，已确认问题包括：

- `offboard_cpp`：`opencv` rosdep key 无定义。
- `librealsense2`：`catkin` rosdep key 无定义。
- RTAB-Map/Nav2 延后模块：`libpointmatcher`、`ompl`、`turtlebot3` 无定义。
- 系统缺少 `libceres-dev`，会影响完整树但未阻塞 M1 最小 profile。

本轮未自动安装或修改依赖。

### 5.3 最小构建

隔离构建显式清除旧 overlay，仅使用 `/opt/ros/foxy`，不依赖 `/home/c/px4_ws/install`。目标为：

```text
mavros vision_to_mavros realsense2_camera px4_bringup
```

连同依赖共 10 个包全部通过：

```text
cv_bridge
librealsense2
mavlink
mavros_msgs
px4_bringup
realsense2_camera_msgs
libmavconn
realsense2_camera
vision_to_mavros
mavros
```

最终摘要：

```text
Summary: 10 packages finished [44min 13s]
```

静态安装核验确认：`mavros_node`、`vision_to_mavros_node`、`realsense2_camera_node` 和 `px4_bringup` launch 均可被隔离安装空间发现。本轮未运行它们。

## 6. 可复现资产

- `Scripts/installation/uav_px4_dds_install.sh`：跨平台锁定恢复工具。
- `Scripts/build/m1_build.sh`：M1 最小 profile 构建入口。
- `workspace.lock.repos`：20 仓库精确版本。
- `workspace.excluded_packages`：三包排除清单。
- `patches/mavros/foxy_tf2_eigen_h.patch`：MAVROS Foxy 最小兼容补丁。
- `Scripts/README.md`：恢复、排除和构建说明。
- `docs/m1_execution_report.md`：本次详细证据和验收判断。

`.gitignore` 已添加窄范围例外，确保 M1 构建脚本和补丁不会在后续上传时被漏掉。

## 7. 模块迁移状态

| 模块 | 静态/构建状态 | 运行验证状态 | 当前判断 |
|---|---|---|---|
| ROS 2 Foxy | M1 最小 profile 通过 | 未启动 | 具备进入 M2 的部分软件基础 |
| MAVROS | 补丁后构建通过 | 仅有历史串口记录 | M3 前保持只读策略 |
| PX4 DDS | 锁文件存在 | 两仓库尚未恢复 | 暂不作为首版控制链 |
| D435 | 驱动构建通过 | 本轮未连接 | M2 单机验证 |
| T265 | 驱动与桥接构建通过 | 本轮未连接 | M2 单机验证 |
| T265+D435 融合 | 基础包存在 | 未验证 | M3 设计并验收 |
| Offboard C++ | 锁定基线有冲突标记 | 禁止运行 | M4 前单独治理 |
| 三个排除包 | 明确排除 | 不验证 | 不进入首版 |
| STM32 | 延期 | 不验证 | 不进入当前主线 |

## 8. 当前阻塞项

### P0

1. 公网无法恢复 `px4_msgs` 与 `Micro-XRCE-DDS-Agent`，跨平台 20/20 恢复未闭环。
2. 9 个 dirty 嵌套仓库尚未逐个形成正式提交/补丁归属策略。
3. `offboard_cpp` 冲突标记及控制安全门未治理，禁止启动控制。
4. MAVROS 与 DDS 的唯一控制 owner 尚未由人工正式冻结。
5. PX4 board、固件、参数、RC/failsafe 和视觉 EKF 参数没有完整版本化基线。

### P1

1. M1 仅完成一次干净构建，尚未满足连续两次复现标准。
2. 完整工作区 rosdep 未闭环。
3. T265/D435 的 TF、外参、时间、QoS 和资源门限未验证。
4. 历史运行记录不等于当前 BoomBoomFly 构建产物已通过硬件回归。

## 9. 阶段路线

### M0：基线冻结

状态：**完成**。

输出：可恢复快照、仓库锁、remote 规范化、删除/排除决策。

### M1：跨平台恢复与独立构建

状态：**部分完成**。

已完成：18/20 本地精确恢复、最小 profile 10/10 构建、安装产物发现、复现脚本和补丁。

未完成：公网 20/20 恢复、目标平台连续两次干净构建、完整依赖闭环。

### M2：T265 与 D435 单设备回归

状态：**未开始**。

顺序：D435 单机 → T265 单机 → 双相机最低负载。每次记录序列号、USB 拓扑、topic、QoS、频率、时间戳、CPU、内存和错误计数。不得启动完整 bringup。

### M3：融合定位与 PX4 只读链

状态：**未开始**。

冻结唯一 TF owner、T265/D435 外参、ENU/NED 与 FLU/FRD、时间同步和融合方案；随后只读验证 MAVROS state/IMU/timesync/battery/estimator，不调用 arming 或 set_mode，不发布 setpoint。

### M4：Offboard 安全闭环

状态：**禁止进入**。

必须依次经过离线状态机、SITL、仅心跳且禁止 arm、拆桨、受控台架和风险评审后的低高度测试。M0 至 M3 未通过前不得进入。

### M5：部署与维护

状态：**未开始**。

只在系统级 soak 和安全控制验证后处理 systemd、设备命名、日志轮转、版本发布和回滚。默认开机服务不得自动解锁或进入 Offboard。

## 10. 下一步顺序

1. 恢复 GitHub 网络，验证 20/20 空目录恢复；或制作离线 Git bundle。
2. 在目标平台执行第二次干净 M1 构建。
3. 治理完整依赖清单，但继续排除延期模块。
4. 审核并归档 9 个 dirty 仓库的真实内容修改。
5. 正式确认 MAVROS 是首版唯一飞控链，DDS 不发送控制。
6. 冻结 PX4 固件、board、airframe、参数、RC 和 failsafe 基线。
7. 进入 M2：D435 单机回归。
8. 进入 M2：T265 单机回归。
9. 完成双相机最低负载和资源测试。
10. 进入 M3：TF/时间/坐标与 PX4 只读链。

可并行：公网恢复/离线 bundle、dirty 仓库审计、PX4 参数资料收集、TF 规范草案。

必须串行：

```text
M1 完整恢复与重复构建
  → D435 单机
  → T265 单机
  → 双相机并行
  → TF/时间/融合
  → PX4 只读链
  → SITL
  → 拆桨/台架
  → 低风险飞行
```

## 11. 当前禁止事项

- 不运行 `start_all_2025TI.launch.py`。
- 不自动解锁、切换模式、发送 setpoint 或进行 Offboard 飞行。
- 不同时启用 MAVROS 和 DDS 控制路径。
- 不同时启动多个控制 demo/controller。
- 不一次性开启双相机、点云、YOLO、SLAM 等全负载功能。
- 不 reset/clean dirty 仓库，不覆盖或删除 `/home/c/px4_ws`。
- 不在 M1/M2 阶段配置开机自动控制。

## 12. 进入 M2 的闸门

至少满足：

1. 20 个锁定仓库可通过公网或离线 bundle 恢复，或书面确认首版不需要 DDS 两仓库。
2. M1 profile 在目标平台连续两次干净构建成功。
3. 构建环境不含 `/home/c/px4_ws` overlay。
4. M1 脚本、补丁、排除清单和锁文件进入待上传变更集。
5. M2 每台相机都有单独 launch/参数、日志目录、通过标准和停止条件。

## 13. 仍需人工确认

1. 是否正式确认 MAVROS 为首版唯一飞控链。
2. `px4_msgs` 与 Agent 是 M1 必须恢复，还是允许延后到 DDS 评估阶段。
3. PX4 1.16.2 的固件来源、board、airframe 和参数快照。
4. T265 的实际安装方向和外参。
5. D435 首版仅做深度/避障，还是参与定位融合。
6. `map_msgs`、`image_geometry` 删除是否有意。
7. 9 个 dirty 仓库各自修改的 owner 和提交策略。
