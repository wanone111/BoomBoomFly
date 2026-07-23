# RealSense 更换 USB 接口后复检报告

## 1. 范围与结论

- 复检时间：2026-07-23 13:46:06 至 13:50:17（Asia/Shanghai）。
- 对照报告：[realsense_runtime_check.md](/home/c/px4_ws/docs/realsense_runtime_check.md)。
- 主机/环境未变：Jetson Orin Nano、Ubuntu 20.04.6、aarch64、ROS 2 Foxy；检查 shell source 了 `/opt/ros/foxy/setup.bash` 和 `/home/c/px4_ws/install/setup.bash`。
- 检查前没有 RealSense 进程或 ROS 节点。
- 发现的设备仍为 D435（`241122070080`）和 T265（`952322110550`）。
- **换口只使 T265 升级到 USB 3.1 / 5000M；D435 仍为 USB 2.1 / 480M。**
- D435 在相同 640×480@15 配置下，本次彩色约 14.99 Hz、深度约 14.51 Hz，较换口前明显改善；CameraInfo 与 TF 正常。
- T265 pose、gyro、accel 与动态 TF 正常，且上一轮的 USB 2.1 不可靠错误已经消失。
- 总体状态：**WARN**。T265 换口成功，但 D435 仍没有进入 USB 3.x，UVC control 告警和 SDK 多版本风险仍存在。

本次仍未启动完整 bringup、PX4、Micro XRCE-DDS Agent、MAVROS、RPLIDAR、Nav2、SLAM、串口或飞控节点；未使用 sudo；未执行固件或系统修改。

## 2. 换口前后 USB 对照

现场证据来自 `rs-enumerate-devices`、`lsusb`、`lsusb -t` 和 ROS 运行日志。

| 设备 | 换口前 | 换口后 | 结论 |
|---|---|---|---|
| D435 `241122070080` | 物理端口 `1-2.1`，USB 2.1，480M | 物理端口 `1-2.3`，USB 2.1，480M | 端口改变，但仍未进入 USB 3.x |
| T265 `952322110550` | 物理端口 `1-2.2`，USB 2.1，480M | 物理端口 `2-1.4`，SDK ID `2-1.4-3`，USB 3.1，5000M | 换口成功，已进入 SuperSpeed Gen 1 |

最终 `lsusb -t` 的关键结构：

```text
Bus 02 root_hub 10000M
  RealSense T265 branch: 5000M
Bus 01 root_hub 480M
  RealSense D435 video interfaces: 480M
```

内核日志在 13:46:09 明确记录：

```text
usb 2-1.4: new SuperSpeed Gen 1 USB device ...

Product: Intel(R) RealSense(TM) Tracking Camera T265
SerialNumber: 952322110550
```

D435 则记录为：

```text
usb 1-2.3: new high-speed USB device ...
Intel(R) RealSense(TM) Depth Camera 435 (8086:0b07)
```

“high-speed”及 480M 对应 USB 2.x，不是 SuperSpeed。

## 3. 设备、固件与权限

| 设备 | Product ID | 固件 | USB 描述符 | 普通用户访问 |
|---|---:|---:|---:|---|
| Intel RealSense D435 | `0B07` | `05.13.00.50`，与推荐版本相同 | `2.1` | PASS |
| Intel RealSense T265 | `0B37` | `0.2.0.951` | `3.1` | PASS |

`v4l2-ctl --list-devices` 将 `/dev/video0..5`、`/dev/media1..2` 识别为 D435，物理路径已更新到 `usb-3610000.xhci-2.3`。这些节点均对当前用户可读写，普通用户也成功完成 SDK 和 ROS 运行验证。

T265 在 SDK 初始化前短暂显示为 Movidius `03e7:2150`，初始化后重新枚举为 `8087:0b37` 并进入 Bus 02 的 5000M 分支；这是本轮现场命令确认的转态过程。

## 4. SDK、ROS wrapper 与工作区配置

这些项目与上一轮一致：

- 工作区工具 `/home/c/px4_ws/install/librealsense2/bin/rs-enumerate-devices`：2.50.0。
- dpkg 安装的 `librealsense2*`：2.56.5。
- ROS wrapper：`realsense2_camera` 4.0.4，来源 `/home/c/px4_ws/install/realsense2_camera`。
- wrapper 实际动态链接：`/usr/local/lib/librealsense2.so.2.50`。
- `ros-foxy-realsense2-camera` deb 未安装。

因此 dpkg 2.56.5、`/usr/local` 2.50、工作区 2.50 三来源风险仍然存在。

`ros2 launch realsense2_camera rs_launch.py --show-args` 再次确认支持 `camera_name`、`serial_no`、`usb_port_id`、`device_type`、彩色/深度/红外/IMU/pose 开关、profile、点云、对齐、TF 与 diagnostics 参数；仍没有独立 `camera_namespace` argument。

工作区静态配置没有变化：

- 主入口仍通过 [px4_fly.launch.py](/home/c/px4_ws/src/px4_bringup/launch/include/px4_fly.launch.py:14) 引用 `rs_t265_launch.py`。
- [t265_all_nodes_launch.py](/home/c/px4_ws/src/ros2_foxy_vision_to_mavros/launch/t265_all_nodes_launch.py:14) 仍硬编码 `usb_port_id=2-2`，与现场 T265 的 `2-1.4` 不匹配；而且该文件会带起 MAVROS，本次未运行。
- D400 RTAB-Map 路径仍订阅 `/camera/color/*` 和 `/camera/aligned_depth_to_color/image_raw`，证据见 [realsense_d400.launch.py](/home/c/px4_ws/src/rtabmap_ros/rtabmap_examples/launch/realsense_d400.launch.py:24)。本次按最小验证要求关闭 depth alignment。

## 5. D435 运行复测

### 5.1 启动配置

直接使用 `realsense2_camera/rs_launch.py`，限定 `device_type=d435`：

```text
color=true, depth=true
infra1/2=false, gyro=false, accel=false, pose=false
pointcloud=false, align_depth=false
depth profile=640,480,15
color profile=640,480,15
diagnostics_period=0.0
```

节点 `/camera/camera` 成功启动。日志确认：

```text
Device with port number 1-2.3 was found.
Device USB type: 2.1
Device ... is connected using a 2.1 port. Reduced performance is expected.
Open profile: Depth Z16 640x480 FPS 15
Open profile: Color RGB8 640x480 FPS 15
RealSense Node Is Up!
```

### 5.2 频率对照

使用两个并发、line-buffered、10 秒受控 `ros2 topic hz` 探针；最终窗口：

| 话题 | 配置 | 换口前测量 | 本次测量 | 结论 |
|---|---:|---:|---:|---|
| `/camera/color/image_raw` | 15 Hz | 最终约 10.686 Hz | **14.992 Hz**，最大间隔 0.076 s | 明显改善，接近配置值 |
| `/camera/depth/image_rect_raw` | 15 Hz | 最终约 12.154 Hz | **14.506 Hz**，最大间隔 0.134 s | 明显改善，接近配置值 |

本轮测量负载比上一轮更小，因此对频率对比更有利；但 D435 物理链路仍是 USB 2.1，不能据此推断高分辨率或 30/60/90 Hz profile 也会稳定。

### 5.3 消息、CameraInfo 与 TF

现场重新采集成功：

| 项目 | 结果 |
|---|---|
| 彩色图像 | 640×480，`rgb8`，frame `camera_color_optical_frame` |
| 深度图像 | 640×480，`16UC1`，frame `camera_depth_optical_frame` |
| 彩色 CameraInfo | 640×480，`plumb_bob`，K/P 非零，frame 有效 |
| 深度 CameraInfo | 640×480，`plumb_bob`，K/P 非零，frame 有效 |
| TF | `camera_link -> camera_depth_optical_frame` 可由 `tf2_echo` 连续解析 |

内参与上一轮一致：彩色焦距约 607.45/607.29，深度焦距约 386.84/386.84。

### 5.4 D435 告警

- `Device USB type: 2.1` 和 reduced-performance 告警仍在。
- `rgb_camera.power_line_frequency` 值 3 超出设备范围 `[0,2]` 的告警仍在。
- `journalctl -k` 在两轮 D435 启动期间仍记录多条 `uvcvideo: Failed to query (GET_CUR) ... -32`。
- 本轮 ROS 日志中**没有再出现**上一轮的 `Left MIPI error`。
- 本轮没有 dropped-frame、USB bandwidth、metadata timeout 文本。

因此 D435 的低带宽 15 Hz 运行可判 PASS，但 USB/UVC 状态仍为 WARN。

## 6. T265 USB 3 运行复测

为避免 MAVROS，直接使用通用 `rs_launch.py`，限定 `device_type=t265`、`camera_name=tracking`，关闭双 fisheye，只启用 pose、gyro、accel，`unite_imu_method=0`。

ROS 日志确认：

```text
Device with port number 2-1.4 was found.
Device USB type: 3.1
Gyro 200 FPS
Accel 62 FPS
Pose 200 FPS
RealSense Node Is Up!
```

本次没有 `Reduced performance`，也没有上一轮的：

```text
Streaming T265 video over USB 2.1 is unreliable
```

测量结果：

| 话题 | 类型 | 换口前 | 换口后 |
|---|---|---:|---:|
| `/tracking/pose/sample` | `nav_msgs/msg/Odometry` | 200.058 Hz | **199.607 Hz** |
| `/tracking/gyro/sample` | `sensor_msgs/msg/Imu` | 200.009 Hz | **199.594 Hz** |
| `/tracking/accel/sample` | `sensor_msgs/msg/Imu` | 63.262 Hz | **63.197 Hz** |

频率与额定值及换口前基本一致。消息 frame 仍有效：

- pose：`odom_frame` → `tracking_pose_frame`。
- gyro：`tracking_gyro_optical_frame`。
- accel：`tracking_accel_optical_frame`。

`tf2_echo odom_frame tracking_pose_frame` 连续获得动态变换，TF 验证通过。

## 7. 内核日志判断

- 用户换口产生的 13:44 断开/重新连接与 13:46 SDK 初始化转态有明确时间对应，不能视作运行期随机掉线。
- 复测运行期间没有新的 USB disconnect/reset/timeout。
- T265 已稳定留在 Bus 02 的 5000M 分支。
- D435 留在 Bus 01 的 480M 分支，并仍有 UVC GET_CUR `-32`。
- `dmesg` 仍因普通用户权限不足不可读；按安全边界未使用 sudo，改用可读的 `journalctl -k`。

## 8. PASS / WARN / NOT TESTED

| 项目 | 状态 | 本轮证据 |
|---|---|---|
| 1. USB 枚举 | PASS | D435、T265 均可由 SDK 和 ROS 识别 |
| 2. USB 连接速率 | WARN | T265 已 USB 3.1；D435 仍 USB 2.1 |
| 3. 普通用户设备权限 | PASS | V4L2 节点可读写，SDK/ROS 无 sudo 成功 |
| 4. librealsense SDK | WARN | 运行正常，但三来源/多版本风险不变 |
| 5. ROS 2 wrapper | PASS | 4.0.4 分别启动 D435、T265 |
| 6. 型号与工作区配置 | WARN | T265/D400 路径存在，但旧 `usb_port_id=2-2` 与现场不符；D435i 示例仍不匹配 D435 |
| 7. 彩色图像 | PASS | 640×480 rgb8，14.992 Hz |
| 8. 深度图像 | PASS | 640×480 16UC1，14.506 Hz |
| 9. CameraInfo | PASS | 彩色/深度 K、P、frame_id 有效 |
| 10. TF | PASS | D435 static optical TF、T265 dynamic pose TF 均可解析 |
| 11. IMU | PASS | T265 gyro 199.594 Hz、accel 63.197 Hz |
| 12. 点云 | NOT TESTED | 按最小验证要求关闭 |
| 13. depth alignment | NOT TESTED | 按最小验证要求关闭；RTAB-Map 路径仍依赖它 |
| 14. namespace/下游匹配 | WARN | 默认 `/camera` 匹配；自定义名称及多入口行为仍需统一 |
| 15. overlay/版本风险 | WARN | dpkg 2.56.5、`/usr/local` 2.50、workspace 2.50 |
| 16. 进程清理 | PASS | 最终进程表与 `ros2 node list --no-daemon` 均为空 |

## 9. 最重要的风险与建议

1. **D435 仍接在 USB 2.x。** 当前 640×480@15 可用，但若目标是 30 Hz、更高分辨率、红外、点云或对齐，仍应把 D435 移到 `lsusb -t` 明确显示 5000M 的分支后再测。
2. **UVC control `-32` 仍存在。** D435 运行虽然稳定且本轮无 MIPI error，但内核告警未消失；USB 3 复测后若仍存在，再区分电缆/Hub、Jetson UVC 和 SDK 版本问题。
3. **SDK 与工作区配置风险没有因换口解决。** 应统一 librealsense 来源，并修正/评审硬编码的 T265 `usb_port_id=2-2`；不要用会启动 MAVROS 的集成 launch 做单相机测试。

下一步首选动作是：只移动 D435 到真正的 USB 3.x 端口，先用 `lsusb -t` 确认 D435 的 Video 接口显示 5000M，再用相同 640×480@15 复测作基线，随后逐步验证实际目标 profile、pointcloud 和 alignment。

## 10. 执行命令与清理

执行了题目允许的只读系统/ROS 环境命令、`lsusb`/`lsusb -t`、SDK 完整枚举、V4L2 权限、dpkg/apt policy、ROS package/launch arguments、关键工作区配置 grep、`journalctl -k`、受 timeout 限制的 D435/T265 直接相机 launch、topic type/hz/echo、CameraInfo 和 `tf2_echo`。

完整合并运行日志：`/tmp/realsense_runtime_recheck_20260723_1346.log`（检查结束时 136 行、15,135 bytes）。

没有执行 GUI viewer、固件升级、sudo、apt、udev/权限/内核/USB 参数修改、完整 bringup、PX4/MAVROS/RPLIDAR/串口/Nav2/SLAM、点云或 depth alignment。

所有相机进程均通过 timeout/SIGINT 监督并由日志确认 Stop/Close；最终没有 RealSense 进程或 ROS 节点残留。除本报告外，没有修改工作区文件。

