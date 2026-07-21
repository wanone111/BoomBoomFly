# Parameters and startup

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

## 范围判定

状态：**部分验证**。工作区没有 `src/lib/parameters/`、`ROMFS/`、`boards/`、`platforms/` 或 `PX4-Autopilot/`。因此 PX4 `rcS`、airframe/autostart、mixer/actuator、board startup，以及 commander、EKF、MAVLink、offboard、failsafe、circuit-breaker 参数全部**未验证**。本页仅记录实际存在的 ROS 2 launch、YAML 参数和伴随端硬编码飞行值。

## 实际启动顺序

主入口为 `src/px4_bringup/launch/start_all_2025TI.launch.py:7-49`：

1. 立即 include `px4_fly.launch.py`。
2. `px4_fly.launch.py:8-53` 立即启动 T265，8 秒后启动 `vision_to_mavros`，12 秒后启动 MAVROS。
3. 15 秒后 include `serial_and_image_2025TI.launch.py`；该文件第 8–54 行立即启动 serial driver，3 秒后 OpenCV，5 秒后 YOLO。
4. 25 秒后执行 `ros2 run offboard_cpp 2025_Ti_main_node`。

被引用的 realsense、serial driver、OpenCV、YOLO、vision bridge 和 MAVROS launch 文件均已验证存在。启动编排依赖固定 TimerAction，不验证 TF、FCU connection、service 或视觉数据 ready。

## MAVROS 与串口配置

`src/px4_bringup/config/mavros_params.yaml:1-11`：

- `fcu_url=/dev/ttyTHS0:921600`
- `gcs_url` 为空
- system/component ID 均为 1
- MAVLink v2
- `respawn_mavros=false`
- namespace `mavros`

`src/px4_bringup/launch/include/px4.launch.py:15-30` 在 YAML 不存在或键缺失时回退到 `/dev/ttyACM0:57600` 等默认值。实际 active YAML 存在，故当前使用 Jetson UART 值；飞控端串口参数、设备权限和波特率匹配未验证。

## 伴随端飞行配置

以下值来自源码而非 ROS 参数：

| 配置 | 当前值 | 证据 |
|---|---:|---|
| 控制周期 | 50 ms / 20 Hz | `src/offboard_cpp/src/lib/offboard_control_node.cpp:30-32` |
| setpoint 预热 | 100 个，约 5 s | `src/offboard_cpp/src/2025_Ti_main.cpp:398-405` |
| OFFBOARD/arm 重试 | 每 2 s | `src/offboard_cpp/src/2025_Ti_main.cpp:424-455` |
| 飞行高度 | 1.2 m | `src/offboard_cpp/src/2025_Ti_main.cpp:457-476,489-490` |
| 下降速度 | -0.3 m/s | `src/offboard_cpp/src/2025_Ti_main.cpp:498-503` |
| 位置/速度到达阈值 | 0.1 m / 0.09 m/s | `src/offboard_cpp/include/lib/offboard_control_node.hpp:53-56`；`.cpp:73-79` |
| 落地切换阈值 | 高度 0.5 m、垂速 0.05 m/s | `src/offboard_cpp/src/2025_Ti_main.cpp:498-508` |
| 地图 | 9×7、0.5 m 网格、起点 91 | `src/offboard_cpp/src/2025_Ti_main.cpp:31-45,123-143,198-220` |

`offboard_cpp` 中未发现 `declare_parameter` 或 `get_parameter`；上述值不能按机型或场地配置，也没有统一范围校验或动态更新。

## 视觉参数

Active launch 在 `src/ros2_foxy_vision_to_mavros/launch/t265_tf_to_mavros_launch.py:25-74` 设置 target `odom_frame`、source `camera_link`、100 Hz，roll/pitch/yaw/gamma 全为 0。节点源码默认则是 target `/camera_odom_frame`、20 Hz、yaw `+pi/2`、gamma `-pi/2`（`src/ros2_foxy_vision_to_mavros/src/vision_to_mavros.cpp:24-43`）。launch 文件是本地修改；这可能是有意标定，但没有标定记录或运行数据，因此状态为**待确认/部分验证**。

## 参数与启动风险

- P1：固定 8/12/15/25 秒启动延时不构成 readiness gate；设备慢启动/失败后仍会启动 offboard 控制。
- P1：位置、速度与 state 没有 received flag/freshness gate；初值为 0（`offboard_control_node.cpp:5-10,35-45`），GCS 信号后仍可请求 OFFBOARD/arm（`2025_Ti_main.cpp:392-455`）。
- P1：`src/offboard_cpp/CMakeLists.txt:125-134` 冲突标记导致当前源码不可可靠重建；`install/` 可能是旧产物。
- P2：`src/px4_bringup/package.xml:15-17` 只声明 launch/launch_ros/rclpy，却运行时依赖 mavros、realsense、vision bridge、serial、OpenCV、YOLO 和 offboard 包。
- P2：`respawn_mavros=false`；MAVROS 退出后下游没有监督恢复或自动阻断。
- P2：视觉旋转覆盖值缺少标定证据。
- P2：串口与波特率硬编码，顶层 launch 未暴露为部署参数。
- P2：高度、速度、容差、地图和重试间隔硬编码，无范围校验。
- P2：`AUTO.LAND` response 未检查且以 20 Hz 重复请求（`offboard_control_node.cpp:186-190`；`2025_Ti_main.cpp:506-517`）。

固件侧参数默认值与伴随端逻辑是否匹配均**未验证**；获得实际 PX4 firmware 仓库、参数导出和飞控日志后才能核对。
