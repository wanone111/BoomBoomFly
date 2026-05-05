# BoomBoomFly

BoomBoomFly 是基于 Ubuntu 20.04 和 ROS 2 Foxy 的 PX4 无人机工程集合，主要用于 PX4 与 ROS 2 的通信、T265 视觉定位、Offboard 控制、串口通信以及比赛/实机启动流程管理。

当前仓库主要维护安装脚本、启动说明和仿真相关目录；实际 ROS 2 功能包会通过脚本拉取到本地工作区中。

## 目录结构

```text
BoomBoomFly/
├── README.md
├── Scripts/
│   ├── README.md
│   ├── installation/
│   │   ├── uav_px4_dds_install.sh
│   │   └── car_install.sh
│   └── simulation/
│       └── uav_sim.sh
└── Simulator/
    ├── README.md
    ├── gazebo_simulator/
    └── realsense_gazebo_plugin/
```

根据工作区位置，仓库根目录或自定义工作区下可能会出现 `src/`、`build/`、`install/`、`log/` 等目录，这些目录用于构建和运行，不是仓库核心脚本内容。

## 环境要求

- Ubuntu 20.04
- ROS 2 Foxy
- `git`
- `colcon`
- PX4 固件或 PX4 SITL 环境
- RealSense T265 相关环境

T265 已不再被 Intel RealSense SDK 2.0 v2.54.1 及后续版本支持，因此本工程默认使用：

- `librealsense`：`v2.53.1`
- `realsense-ros`：`4.0.4`

## 快速开始

### 1. 进入工程目录

```bash
cd /home/aa/px4/BoomBoomFly
```

### 2. 拉取无人机依赖

```bash
chmod +x Scripts/installation/uav_px4_dds_install.sh
./Scripts/installation/uav_px4_dds_install.sh
```

脚本会拉取无人机 DDS 方案所需的功能包。已有仓库会被跳过；如果需要更新已有仓库：

```bash
./Scripts/installation/uav_px4_dds_install.sh --update
```

默认情况下，脚本会把依赖包拉取到仓库根目录的 `src/`。如果需要使用其他工作区位置，可以通过 `--src-dir <path>` 指定。

### 3. 构建 ROS 2 工作区

```bash
source /opt/ros/foxy/setup.bash
colcon build --symlink-install
source install/setup.bash
```

## 无人机 PX4 DDS 方案

安装脚本会拉取以下依赖：

| 模块 | 用途 |
| --- | --- |
| [px4_msgs](https://github.com/PX4/px4_msgs.git) | PX4 ROS 2 消息定义，脚本默认使用 `v1.16.1` |
| [Micro-XRCE-DDS-Agent](https://github.com/eProsima/Micro-XRCE-DDS-Agent.git) | PX4 与 ROS 2 DDS 通信代理 |
| [vision_to_dds](https://github.com/wanone111/vision_to_dds.git) | 视觉定位数据到 DDS 的转换 |
| [offboard_cpp](https://github.com/BoomBoomFly/offboard_cpp.git) | PX4 Offboard 底层控制 |
| [serial_driver_ros](https://github.com/BoomBoomFly/serial_driver_ros.git) | ROS 2 上下位机串口通信 |
| [librealsense](https://github.com/IntelRealSense/librealsense.git) | RealSense SDK，默认 `v2.53.1` |
| [realsense-ros](https://github.com/IntelRealSense/realsense-ros.git) | RealSense ROS 2 驱动，默认 `4.0.4` |
| [px4_bringup](https://github.com/BoomBoomFly/px4_bringup.git) | PX4 相关启动文件集合 |

### 常用启动入口

构建并 source 工作区后，可以按实际硬件连接启动对应流程：

`px4_bringup` 中的启动文件会引用 `mavros`、`realsense2_camera`、`vision_to_mavros`、`serial_driver`、`opencv_cpp`、`cv_yolo_paddle_pkg` 等包。安装脚本不会拉取全部视觉/检测扩展包，如果当前工作区缺少对应包，请先补齐依赖，或只启动已安装的模块。

```bash
# 启动完整流程：PX4/视觉/串口/检测/Offboard 主节点
ros2 launch px4_bringup start_all_2025TI.launch.py

# 只启动串口与图像检测相关节点
ros2 launch px4_bringup serial_and_image_2025TI.launch.py

# 启动 Offboard 控制
ros2 launch offboard_cpp offboard_control.launch.py

# 启动多机 Offboard 示例
ros2 launch offboard_cpp offboard_swarm_control.launch.py
```

实际起飞前请确认 PX4、遥控器、DDS Agent、里程计和电池等话题状态正常：

```bash
ros2 topic list
ros2 topic list | grep fmu
```

## 仿真

仿真相关目录位于 `Simulator/`，脚本入口位于 `Scripts/simulation/uav_sim.sh`。当前仓库中的仿真脚本和 `Simulator/gazebo_simulator`、`Simulator/realsense_gazebo_plugin` 文档仍是占位状态，需要按具体仿真环境继续补充。

## 小车

小车安装入口为 `Scripts/installation/car_install.sh`。当前脚本为空，占位待补充。

## 参考文档

- [Scripts 使用说明](Scripts/README.md)
- [Simulator 说明](Simulator/README.md)
- [PX4 ROS 2 User Guide](https://docs.px4.io/main/en/ros2/)
- [Micro-XRCE-DDS-Agent](https://github.com/eProsima/Micro-XRCE-DDS-Agent)
- [Intel RealSense ROS](https://github.com/IntelRealSense/realsense-ros)
