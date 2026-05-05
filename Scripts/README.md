# Scripts

本目录存放 BoomBoomFly 的安装和仿真辅助脚本。当前已实现的是无人机 PX4 + Micro XRCE-DDS 方案的依赖拉取脚本；小车安装脚本和无人机仿真脚本仍是占位文件。

## 目录结构

```text
Scripts/
├── README.md
├── installation/
│   ├── uav_px4_dds_install.sh
│   └── car_install.sh
└── simulation/
    └── uav_sim.sh
```

## installation

### 无人机：PX4 + Micro XRCE-DDS

脚本路径：

```bash
Scripts/installation/uav_px4_dds_install.sh
```

该脚本默认会在仓库根目录创建或使用 `src/`，也就是：

```text
BoomBoomFly/src/
```

随后脚本会把无人机 DDS 方案需要的功能包克隆到这个 `src/` 目录中。

#### 使用方式

在仓库根目录执行：

```bash
chmod +x Scripts/installation/uav_px4_dds_install.sh
./Scripts/installation/uav_px4_dds_install.sh
```

如果依赖仓库已经存在，脚本会跳过，不会重复克隆。需要更新已有仓库时使用：

```bash
./Scripts/installation/uav_px4_dds_install.sh --update
```

如果需要把依赖包拉取到其他 ROS 2 工作区：

```bash
./Scripts/installation/uav_px4_dds_install.sh --src-dir /path/to/workspace/src
```

执行前查看计划但不实际克隆或更新：

```bash
./Scripts/installation/uav_px4_dds_install.sh --dry-run
```

`--update` 会对已存在的 git 仓库执行：

- `git fetch --all --prune`
- 如果脚本指定了分支或 tag，则先 checkout 到对应版本
- 如果当前是分支，则执行 `git pull --ff-only`
- 如果当前是 tag 或 detached HEAD，则跳过 `git pull`

如果目标目录已存在但不是 git 仓库，脚本会报错退出，避免把异常目录误当作可用依赖。

#### 拉取内容

| 目录 | 仓库 | 版本 |
| --- | --- | --- |
| `px4_msgs` | <https://github.com/PX4/px4_msgs.git> | `v1.16.1` |
| `Micro-XRCE-DDS-Agent` | <https://github.com/eProsima/Micro-XRCE-DDS-Agent.git> | 默认分支 |
| `vision_to_dds` | <https://github.com/wanone111/vision_to_dds.git> | 默认分支 |
| `offboard_cpp` | <https://github.com/BoomBoomFly/offboard_cpp.git> | 默认分支 |
| `serial_driver_ros` | <https://github.com/BoomBoomFly/serial_driver_ros.git> | 默认分支 |
| `librealsense` | <https://github.com/IntelRealSense/librealsense.git> | `v2.53.1` |
| `realsense-ros` | <https://github.com/IntelRealSense/realsense-ros.git> | `4.0.4` |
| `px4_bringup` | <https://github.com/BoomBoomFly/px4_bringup.git> | 默认分支 |

T265 已不再被 Intel RealSense SDK 2.0 v2.54.1 及后续版本支持，因此这里固定使用 `librealsense v2.53.1` 和 `realsense-ros 4.0.4`。

#### 构建工作区

默认使用仓库根目录作为 ROS 2 工作区：

```bash
cd /home/aa/px4/BoomBoomFly
source /opt/ros/foxy/setup.bash
colcon build --symlink-install
source install/setup.bash
```

#### 常用启动入口

完成构建并 source 工作区后，可按实际硬件和依赖情况启动：

```bash
# 完整流程：PX4/视觉/串口/检测/Offboard 主节点
ros2 launch px4_bringup start_all_2025TI.launch.py

# 串口与图像检测相关节点
ros2 launch px4_bringup serial_and_image_2025TI.launch.py

# Offboard 控制
ros2 launch offboard_cpp offboard_control.launch.py

# 多机 Offboard 示例
ros2 launch offboard_cpp offboard_swarm_control.launch.py
```

`px4_bringup` 的部分 launch 文件会引用 `mavros`、`realsense2_camera`、`vision_to_mavros`、`serial_driver`、`opencv_cpp`、`cv_yolo_paddle_pkg` 等包。安装脚本不会拉取全部视觉/检测扩展包，运行前需要确认当前工作区已有对应依赖。

### 小车

脚本路径：

```bash
Scripts/installation/car_install.sh
```

当前文件为空，后续可在这里补充小车依赖拉取和构建流程。

## simulation

### 无人机仿真

脚本路径：

```bash
Scripts/simulation/uav_sim.sh
```

当前文件为空，后续可在这里补充 PX4 SITL、Gazebo、RealSense 仿真插件等启动流程。

## 常见检查

拉取依赖后可以检查目录：

```bash
find src -maxdepth 1 -type d
```

构建前确认 ROS 2 Foxy 环境：

```bash
source /opt/ros/foxy/setup.bash
echo $ROS_DISTRO
```

连接 PX4 后确认 DDS 话题：

```bash
ros2 topic list
ros2 topic list | grep fmu
```
