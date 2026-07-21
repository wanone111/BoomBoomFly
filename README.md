# BoomBoomFly

BoomBoomFly 是面向 Ubuntu 20.04、ROS 2 Foxy 和 PX4 的无人机伴随计算机工程，覆盖 MAVROS/uXRCE-DDS 通信、T265 视觉定位、Offboard 控制、串口通信、导航建图以及比赛/实机启动编排。

仓库主要维护安装脚本、可复现依赖清单、启动说明和仿真入口。ROS 2 功能包恢复到工作区 `src/`，PX4-Autopilot 固件源码不在本仓库的受管依赖中。

## 当前依赖基线

2026-07-21 工作区审查结果：

- `src/` 中有 19 个 Git 仓库、79 个 `package.xml`，`colcon list` 可发现 77 个包。
- 安装脚本、`workspace.repos` 和 `workspace.lock.repos` 共同管理 20 个可获取仓库。
- PX4 消息固定为 `px4_msgs v1.16.2`。
- ROS 2 Foxy 使用 `Micro-XRCE-DDS-Agent v2.4.2`。
- RealSense 基线固定为 `librealsense v2.50.0` 和 `realsense-ros 4.0.4`。
- 不使用“自动选择最新版本”；稳定组件固定 tag，无对应 tag 时固定审查 commit。

完整审查结果见：

- [src 依赖清单](docs/src_dependency_inventory.md)
- [安装脚本更新报告](docs/uav_install_script_update.md)

## 目录结构

```text
BoomBoomFly/
├── README.md
├── workspace.repos              # 人工维护的 branch/tag/commit 意图
├── workspace.lock.repos         # 全部仓库的精确 commit SHA
├── Scripts/
│   ├── README.md
│   ├── installation/
│   │   ├── uav_px4_dds_install.sh
│   │   └── car_install.sh
│   └── simulation/
│       └── uav_sim.sh
├── Simulator/
│   ├── README.md
│   ├── gazebo_simulator/
│   └── realsense_gazebo_plugin/
├── docs/
│   ├── src_dependency_inventory.md
│   └── uav_install_script_update.md
└── src/                         # 本地 ROS 2 源码工作区
```

`build/`、`install/`、`log/` 和 `src/` 属于本地构建/运行工作区。不要把构建产物当作依赖来源。

## 环境要求

必需环境：

- Ubuntu 20.04
- ROS 2 Foxy
- Bash
- Git
- `colcon`
- PX4 1.16.2 固件或兼容的 PX4 SITL/实机

按需要安装：

- `vcstool`：从 `.repos` 文件恢复源码
- `rosdep`：检查和安装系统依赖
- RealSense/T265 设备规则与系统库
- MAVROS GeographicLib 数据集
- 串口和 udev 权限配置

安装脚本只恢复源码仓库，不负责安装 ROS 2、系统包、固件、udev 规则或硬件配置。

## 快速开始

### 1. 进入工程目录

```bash
cd /home/c/BoomBoomFly
```

### 2. 先查看下载计划

```bash
bash Scripts/installation/uav_px4_dds_install.sh --dry-run
```

`--dry-run` 会显示每个仓库的 URL、目标路径和 branch/tag/commit，不会创建目录、clone、fetch 或 checkout。

指定其他源码目录：

```bash
bash Scripts/installation/uav_px4_dds_install.sh \
  --dry-run \
  --src-dir /path/to/ros2_ws/src
```

### 3. 恢复源码

确认 dry-run 输出后执行：

```bash
bash Scripts/installation/uav_px4_dds_install.sh
```

脚本行为：

- 目标不存在时 clone，并 checkout 指定 tag/branch/SHA。
- 目标已经是 Git 仓库时跳过，避免重复 clone。
- 目标存在但不是 Git 仓库时停止并输出错误。
- 完成后执行 `colcon list --base-paths <src>`。
- 检查 `px4_msgs`、`offboard_cpp`、`px4_bringup` 和 `serial_driver`。

`serial_driver_ros2` 是仓库目录名，ROS package 的实际名称是 `serial_driver`。

更新已有仓库：

```bash
bash Scripts/installation/uav_px4_dds_install.sh --update
```

`--update` 会 fetch 并切换到清单指定 ref。执行前务必检查子仓库是否 dirty；脚本不会替你清理、reset 或覆盖本地修改。

### 4. 使用 repos 清单恢复

希望按人工维护版本意图导入：

```bash
vcs import < workspace.repos
```

希望按精确 commit 恢复可复现基线：

```bash
vcs import < workspace.lock.repos
```

`workspace.lock.repos` 是部署和复现实验的首选。脚本、`workspace.repos` 与 lock 文件当前拥有相同的 20 个目标路径。

### 5. 安装系统依赖并构建

所有源码准备完成后：

```bash
source /opt/ros/foxy/setup.bash
rosdep install --from-paths src --ignore-src -r -y
colcon build --symlink-install
source install/setup.bash
```

首次部署应在独立的新工作区验证，不要直接对包含本地修改的飞行工作区执行更新。

## 受管软件组成

| 分类 | 主要仓库 | 版本策略 |
|---|---|---|
| PX4/DDS | `px4_msgs`, `Micro-XRCE-DDS-Agent` | `v1.16.2`, `v2.4.2` |
| MAVLink | `mavlink`, `mavros` | Foxy release tag, `2.7.0` |
| 飞控与启动 | `offboard_cpp`, `px4_bringup`, `serial_driver_ros2`, `ros2_foxy_vision_to_mavros` | 当前分支仍存在时用分支，否则用审查 SHA |
| RealSense/视觉 | `librealsense`, `realsense-ros`, `vision_opencv` | `v2.50.0`, `4.0.4`, `3.0.7` |
| 导航/SLAM | `navigation2`, `navigation_msgs`, `slam_toolbox`, `rtabmap`, `rtabmap_ros`, `imu_tools` | Foxy tag或审查 SHA |
| 仿真/传感器 | `gazebo_ros_pkgs`, `rplidar_ros`, `serial-ros2` | 审查 SHA |

逐仓库 URL、ref、commit 和 package 依赖请直接查看 [workspace.repos](workspace.repos) 与 [依赖清单](docs/src_dependency_inventory.md)。

## 已知的不可自动恢复项

当前脚本不能字节级还原审查时的整个 `src/`：

1. `offboard_py` 的历史 remote 已返回 `Repository not found`，因此没有硬编码到下载列表。
2. `cv_yolo_paddle_pkg` 和 `opencv_cpp` 没有 Git 元数据或可信源码 URL。
3. 审查时有 9 个子仓库包含未提交修改；lock 只能恢复其提交基线。
4. 本地删除、未跟踪源码和文件权限变化不会进入 commit lock。
5. PX4-Autopilot 固件源码不在当前工作区，因此没有虚构安装项。

要实现完整新设备一键部署，需先重新发布 `offboard_py`，为两个本地视觉包建立仓库，并把需要保留的本地修改提交到可访问 remote。

## 常用启动入口

构建并 source 工作区后，按硬件配置启动：

```bash
# 完整流程：PX4、视觉、串口、检测和 Offboard 主节点
ros2 launch px4_bringup start_all_2025TI.launch.py

# 串口与图像检测节点
ros2 launch px4_bringup serial_and_image_2025TI.launch.py

# Offboard 控制
ros2 launch offboard_cpp offboard_control.launch.py

# 多机 Offboard 示例
ros2 launch offboard_cpp offboard_swarm_control.launch.py
```

部分 bringup 文件引用当前无法自动恢复的 `opencv_cpp`、`cv_yolo_paddle_pkg` 或 `offboard_py`。缺包时不要启动对应组合入口。

实机起飞前至少确认：

```bash
colcon list
ros2 topic list
ros2 topic list | grep -E 'fmu|mavros'
```

同时检查飞控模式、遥控器、里程计、DDS Agent/MAVROS 链路、电池、失控保护和急停方案。源码构建成功不等于可以安全起飞。

## 仿真

仿真目录位于 `Simulator/`，入口为 `Scripts/simulation/uav_sim.sh`。当前仿真脚本以及 `gazebo_simulator`、`realsense_gazebo_plugin` 文档仍需要结合实际 PX4 SITL 环境完善。

## 小车

小车安装入口为 `Scripts/installation/car_install.sh`，当前仍为占位内容。

## 维护依赖版本

修改依赖前：

1. 审查 `src/` 中的 package、remote、branch、HEAD、dirty 和 detached 状态。
2. 只选择经过兼容性验证的 tag/commit，不追随 latest。
3. 同步修改脚本、`workspace.repos` 和 `workspace.lock.repos`。
4. 用精确 SHA 更新 lock 文件。
5. 执行 `bash -n`、`shellcheck`、默认 dry-run、空目录 dry-run、清单去重和 YAML 校验。
6. 在新工作区完成 `rosdep`、`colcon build` 和硬件前验证。

## 参考文档

- [Scripts 使用说明](Scripts/README.md)
- [Simulator 说明](Simulator/README.md)
- [工作区依赖清单](docs/src_dependency_inventory.md)
- [安装脚本更新报告](docs/uav_install_script_update.md)
- [PX4 ROS 2 User Guide](https://docs.px4.io/main/en/ros2/)
- [PX4 uXRCE-DDS](https://docs.px4.io/main/en/middleware/uxrce_dds)
- [Micro-XRCE-DDS-Agent](https://github.com/eProsima/Micro-XRCE-DDS-Agent)
- [Intel RealSense ROS](https://github.com/IntelRealSense/realsense-ros)
