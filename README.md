# BoomBoomFly

BoomBoomFly 是面向 Ubuntu 20.04、ROS 2 Foxy 和 PX4 的无人机伴随计算机工程。自 2026-07-23 的 P0-01 基线决策起，仓库只维护 **PX4 uXRCE-DDS** 飞控通信路径；MAVROS、vision-to-MAVROS、旧串口仓库和 MAVROS-only bringup 不再属于受管源码组合。

PX4-Autopilot 固件源码不在本仓库的受管依赖中。`px4_msgs v1.16.2` 是当前消息定义基线，不等同于已确认的实机固件版本。

## 当前源码基线

两份 manifest 承担不同职责：

| 文件 | 条目 | 用途 |
|---|---:|---|
| `workspace.lock.repos` | 15 | DDS-only 精确 SHA；部署、CI 和可复现恢复首选 |
| `workspace.repos` | 16 | 维护意图；Offboard 跟随 `DDS`，`../communication` 跟随 `main` |

重要例外：

- `offboard_cpp` 的维护来源是 `BoomBoomFly/offboard_cpp` 的 `DDS` 分支；本次核验的远端 HEAD 为 `8925f8ae82258fb9f1378543f1a0dea16c15a282`，部署 lock 固定该 SHA。
- `/home/aa/px4_ws/communication` 按维护者要求始终跟随 `wanone111/communication` 的最新 `main`，**不进入精确 lock**。
- `vision_to_dds` 已正式纳入两份 manifest。
- `mavlink`、`mavros`、`ros2_foxy_vision_to_mavros`、`px4_bringup`、`serial-ros2` 和旧 `serial_driver` 均已退出受管组合。

完整决策、SHA 和恢复边界见 [源码基线](docs/SOURCE_BASELINE.md)。

## 目录结构

```text
/home/aa/px4_ws/
├── BoomBoomFly/
│   ├── workspace.lock.repos
│   ├── workspace.repos
│   ├── Scripts/
│   ├── docs/
│   └── src/
└── communication/               # 移动依赖：跟随 origin/main，不锁 SHA
```

`build/`、`install/`、`log/` 和当前 `src/` 是本地工作区状态，不应充当源码来源。清单中已移出的旧仓库可能暂时仍留在本机 `src/`，但不会被恢复脚本下载或视为基线组成。

## 环境要求

- Ubuntu 20.04
- ROS 2 Foxy
- Bash、Git、colcon
- 按需使用 `vcstool`、`rosdep`
- 与 `px4_msgs v1.16.2` 匹配的 PX4 firmware、board、参数和 `dds_topics.yaml`：仍待 P0-03 确认

恢复脚本只管理源码，不安装系统包、固件、udev 规则或硬件配置，也不启动任何节点。

## 恢复精确 DDS 基线

先查看计划：

```bash
cd /home/aa/px4_ws/BoomBoomFly
bash Scripts/installation/uav_px4_dds_install.sh \
  --dry-run \
  --skip-package-check
```

确认后恢复 15 个精确 SHA：

```bash
bash Scripts/installation/uav_px4_dds_install.sh
```

验证现有工作区而不修改：

```bash
bash Scripts/installation/uav_px4_dds_install.sh \
  --verify-only \
  --skip-package-check
```

脚本拒绝覆盖 dirty 仓库、错误 origin 和错误 HEAD。只有在已确认现有仓库干净且允许切换时，才使用 `--update`。

## 恢复维护组合与 communication

`workspace.repos` 包含 moving refs，必须显式允许：

```bash
bash Scripts/installation/uav_px4_dds_install.sh \
  --manifest workspace.repos \
  --allow-moving-refs \
  --dry-run \
  --skip-package-check
```

确认后去掉 `--dry-run`。该操作会把 `communication` 放在 BoomBoomFly 的同级路径 `../communication`。

注意：

- `communication/main` 每次可能解析到不同提交，因此该命令用于同步维护意图，不用于重现实验。
- 已存在且 dirty 的 `communication` 会被拒绝；脚本不会 pull、reset 或覆盖本地修改。
- 需要可审计实验时，应在实验报告中额外记录当次 `git -C ../communication rev-parse HEAD`。

## 当前受管软件

| 分类 | 仓库 |
|---|---|
| PX4 DDS | `px4_msgs`、`Micro-XRCE-DDS-Agent`、`offboard_cpp`、`vision_to_dds` |
| RealSense/视觉 | `librealsense`、`realsense-ros`、`vision_opencv` |
| 导航/SLAM | `navigation2`、`navigation_msgs`、`slam_toolbox`、`rtabmap`、`rtabmap_ros`、`imu_tools` |
| 仿真/传感器 | `gazebo_ros_pkgs`、`rplidar_ros` |
| 外部移动通信仓库 | `../communication @ main` |

## 构建边界

本轮 P0-01 不执行构建。源码准备完成后，推荐在新的输出目录中分组验证：

```bash
source /opt/ros/foxy/setup.bash
rosdep check --from-paths src --ignore-src
colcon build --symlink-install
```

当前本机仍可能发现已退出基线的 MAVROS、旧 bringup 和旧 serial 包。执行构建前应使用清单生成的新工作区，或显式排除这些本地残留，不能把当前 `src/` 的包数当作 DDS-only 基线包数。

## 运行安全

当前没有经过验证的 DDS production bringup。不要运行旧的：

```text
px4_bringup/start_all_2025TI.launch.py
```

它属于已退出基线的 MAVROS 架构，并包含失效引用和真实硬件入口。P0 安全风险关闭前，不启动 Agent、Offboard 控制、飞控 mode/arming、视觉注入或任何硬件节点。

P0-02 已冻结控制权规则：

- `/offboard_control_node` 是三个 PX4 控制输入的唯一 writer；
- `/vision_to_dds_node` 是外部视觉和可选精降目标的唯一 writer；
- 每个 profile 只允许一个 mission owner；
- 当前只支持单机根 namespace；
- production profile 在运行时 owner/lease、graph guard 和安全状态机完成前保持禁用。

详见 [ADR-0001](docs/adr/0001-dds-only-control-authority.md) 和 [控制权矩阵](docs/CONTROL_AUTHORITY_MATRIX.md)。

## 维护规则

1. `workspace.lock.repos` 的 15 个条目必须使用 40 位 SHA。
2. Offboard 更新时先核验 `origin/DDS`，再更新 lock SHA。
3. `communication` 是唯一允许不锁 SHA 的外部仓库；每次验证必须记录实际 HEAD。
4. 不重新加入 MAVROS、旧 vision-to-MAVROS、旧 serial 或旧 bringup，除非维护者重新做架构决策。
5. 不保存第三方仓库的临时构建缓存或本地补丁作为当前 DDS 基线。
6. 更新 manifest 后执行 shell 语法、清单路径、URL、SHA、重复项和 dry-run 校验。
7. 构建成功不等于可以连接飞控或安全起飞。

## 文档

- [下一窗口交接](docs/handoff.md)
- [文档中心](docs/README.md)
- [源码基线与恢复说明](docs/SOURCE_BASELINE.md)
- [控制权与发布者矩阵](docs/CONTROL_AUTHORITY_MATRIX.md)
- [ADR-0001：DDS-only 控制权](docs/adr/0001-dds-only-control-authority.md)
- [仓库状态](docs/REPOSITORY_STATUS.md)
- [构建与运行状态](docs/BUILD_AND_RUNTIME_STATUS.md)
- [风险与阻塞项](docs/RISKS_AND_BLOCKERS.md)
- [下一阶段任务](docs/NEXT_STAGE_TASKS.md)
