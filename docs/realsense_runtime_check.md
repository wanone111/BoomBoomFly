# RealSense 系统、SDK、ROS 2 与运行状态检查报告

## 1. 检查范围与结论摘要

- 检查时间：2026-07-23 13:28:40 至 13:39:12（Asia/Shanghai，UTC+08:00）。
- 主机：Jetson Orin Nano，原生 Ubuntu 20.04.6 LTS，aarch64，内核 `5.10.104-tegra`；`systemd-detect-virt` 返回 `none`。
- ROS：ROS 2 Foxy；当前 shell 已加载 `/opt/ros/foxy/setup.bash` 和 `/home/c/px4_ws/install/setup.bash`。
- RMW：`RMW_IMPLEMENTATION` 未显式设置；现场只找到 `rmw_fastrtps_cpp` 前缀 `/opt/ros/foxy`，因此默认 Fast DDS 是有依据的推断，不是环境变量的显式事实。
- 发现两台 RealSense：D435（彩色/深度）和 T265（追踪/IMU），均可由普通用户枚举并由 ROS 2 wrapper 启动。
- 两台设备都接在 480 Mb/s 的 USB 2.x 树上，SDK 报告 `Usb Type Descriptor: 2.1`，不是 USB 3.x。
- D435 彩色、深度、CameraInfo 与 TF 现场可用；T265 pose、gyro、accel 现场可用。
- 总体结论：**基本可用但为 WARN**。主要原因是 USB 2.1 降速、librealsense 多版本覆盖，以及运行期间出现 D435 UVC/MIPI 告警和低于配置值的图像测量频率。

本次未启动完整 bringup、PX4、Micro XRCE-DDS Agent、MAVROS、RPLIDAR、Nav2、SLAM、串口节点或飞控控制节点；未使用 `sudo`；未执行固件升级或系统配置修改。

## 2. 主机、用户与 ROS 环境

现场命令：`pwd`、`date --iso-8601=seconds`、`uname -a`、`cat /etc/os-release`、`systemd-detect-virt`、`id`、`groups`、指定前缀的环境变量过滤、setup 文件查找。

关键证据：

```text
pwd: /home/c/px4_ws
uname: Linux orinnano 5.10.104-tegra ... aarch64 GNU/Linux
OS: Ubuntu 20.04.6 LTS (Focal)
virtualization: none
uid/gid: 1000(c)/1000(c)
groups include: video, plugdev, render, i2c, dialout
ROS_DISTRO=foxy
ROS_VERSION=2
ROS_LOCALHOST_ONLY=0
AMENT_PREFIX_PATH begins with /home/c/px4_ws/install/... and ends with /opt/ros/foxy
COLCON_PREFIX_PATH=/home/c/px4_ws/install
```

判断：原生 Jetson/ARM 边缘设备，不是 WSL、Docker 或 x86_64 主机。当前终端在检查前已经加载 Foxy 与工作区 overlay；为保证每条独立检查 shell 一致，本次明确 source：

```text
/opt/ros/foxy/setup.bash
/home/c/px4_ws/install/setup.bash
```

未修改 `.bashrc` 或其他环境文件。

## 3. USB、设备与 SDK 枚举

### 3.1 设备身份

`rs-enumerate-devices -s` 与完整枚举结果：

| 设备 | Product ID | 序列号 | 固件 | USB 描述符 | 物理端口 |
|---|---:|---:|---:|---:|---|
| Intel RealSense D435 | `0B07`（USB `8086:0b07`） | `241122070080` | `05.13.00.50` | `2.1` | `1-2.1`，V4L2 `/dev/video0` 起 |
| Intel RealSense T265 | `0B37`（应用态 USB `8087:0b37`） | `952322110550` | `0.2.0.951` | `2.1` | `1-2.2`，SDK 物理 ID `1-2.2-8` |

D435 的推荐固件也为 `05.13.00.50`；未执行任何固件更新。T265 在 SDK 初始化前由 `lsusb` 显示为 Movidius `03e7:2150`，`rs-enumerate-devices` 初始化后转为 `8087:0b37`；`journalctl -k` 在 13:29:01 记录了这次受控探测触发的断开/重新枚举。

### 3.2 USB 速率

`lsusb -t` 的最终结果显示两台相机均位于 Bus 01 的 480M 根集线器和 480M USB 2.0 hub 下；Bus 02 虽有 10000M USB 3 根集线器，但相机没有连接在那里。ROS 日志分别明确输出：

```text
Device 241122070080 is connected using a 2.1 port. Reduced performance is expected.
Device 952322110550 is connected using a 2.1 port. Reduced performance is expected.
```

T265 运行日志还输出：

```text
Streaming T265 video over USB 2.1 is unreliable, please use USB 3 or only stream poses
```

因此“已连接 USB 3.x”为否；当前是明确的 USB 降速状态。

### 3.3 传感器和主要 profile

- D435 Stereo Module：Depth Z16、Infrared 1/2 Y8。现场枚举的代表 profile 包括 1280×720@6、848×480@6/8/10、640×480@6/15/30、640×360@30、480×270@15/30/60，以及 Depth 256×144@90。
- D435 RGB Camera：代表 profile 包括 1920×1080@8、1280×720@6/10/15、640×480@6/15/30、424×240@6/15/30/60；可见 RGB8/YUYV 等格式。
- D435 型号不是 D435i；现场没有 D435 IMU 传感器。
- T265 Tracking Module：双 848×800@30 fisheye、Gyro 200 Hz、Accel 62 Hz、Pose 200 Hz。

### 3.4 V4L2 节点与普通用户权限

`v4l2-ctl --list-devices` 将 `/dev/video0` 至 `/dev/video5`、`/dev/media1` 和 `/dev/media2` 归属为 D435。节点权限为 `root:plugdev` 且均对当前用户可读写；用户也属于 `video` 和 `plugdev`。普通用户成功运行完整 SDK 枚举和两类 ROS 驱动验证，未发现“仅 sudo 可见”的证据。

`/dev/media0` 是 NVIDIA Tegra Video Input Device，不属于 RealSense；本次未驱动它。

### 3.5 内核日志

- `dmesg --ctime`：普通用户收到 `read kernel buffer failed: Operation not permitted`；按安全边界未使用 sudo。
- `journalctl -k -n 250 --no-pager`：可读，确认 D435 UVC 1.50 枚举和 T265 的应用态重新枚举。
- 每次 D435 ROS 启动附近均出现多条 `uvcvideo: Failed to query (GET_CUR) UVC control 1 on unit 3: -32 (exp. 1024)`。
- 运行日志捕获一次 `Hardware Notification: Left MIPI error ... Hardware Error`。
- 未在本次 ROS 运行窗口内观察到持续 USB reset 或重复相机 disconnect；13:29 的 T265 disconnect/new-device 对应 SDK 初始化转态。
- 未出现明确的 `USB bandwidth` 或 dropped-frame 文本，但 USB 2.1、MIPI 告警和实际 FPS 偏低仍构成带宽/稳定性风险。

## 4. 安装版本、来源与覆盖关系

### 4.1 系统包

`dpkg -l`/`apt-cache policy`：

```text
librealsense2             2.56.5-0~realsense.6681 arm64
librealsense2-dev         2.56.5-0~realsense.6681 arm64
librealsense2-gl          2.56.5-0~realsense.6681 arm64
librealsense2-udev-rules  2.56.5-0~realsense.6681 arm64
librealsense2-utils       2.56.5-0~realsense.6681 arm64
ros-foxy-realsense2-camera: not installed as deb
```

### 4.2 工作区与实际运行版本

- `command -v rs-enumerate-devices`：`/home/c/px4_ws/install/librealsense2/bin/rs-enumerate-devices`。
- 该工具自报版本 `2.50.0`。
- 源码清单 [src/librealsense/package.xml](/home/c/px4_ws/src/librealsense/package.xml:10) 为 `2.50.0`，Git describe 为 `v2.50.0-dirty`。
- `ros2 pkg prefix realsense2_camera`：`/home/c/px4_ws/install/realsense2_camera`。
- wrapper 和消息包均为 `4.0.4`；源码清单证据见 [realsense2_camera/package.xml](/home/c/px4_ws/src/realsense-ros/realsense2_camera/package.xml:5)。Git describe 为 `4.0.4-dirty`。
- ROS 日志：`Built with LibRealSense v2.50.0`、`Running with LibRealSense v2.50.0`。
- `ldd /home/c/px4_ws/install/realsense2_camera/lib/librealsense2_camera.so` 实际解析到 `/usr/local/lib/librealsense2.so.2.50`，不是 dpkg 的 2.56.5，也不是工作区 `install/librealsense2/lib` 下那一份 2.50 动态库。

结论：现场至少存在 dpkg 2.56.5、`/usr/local` 2.50、工作区 overlay 2.50 三个 SDK 来源。运行时版本当前一致落在 2.50，但路径多重且系统包版本不同，升级、重建或环境顺序变化后很容易发生 ABI/行为覆盖；状态为 WARN。

## 5. 实际 launch 参数能力

`ros2 launch realsense2_camera rs_launch.py --show-args` 成功。安装前缀中的实际入口为 `share/realsense2_camera/launch/rs_launch.py`；源码权威参数表见 [rs_launch.py](/home/c/px4_ws/src/realsense-ros/realsense2_camera/launch/rs_launch.py:25)。

本版本支持：

- `camera_name`，但没有独立 `camera_namespace` 参数；launch 将 `camera_name` 同时作为 namespace 和 node name，见 [rs_launch.py](/home/c/px4_ws/src/realsense-ros/realsense2_camera/launch/rs_launch.py:118)。
- `serial_no`、`usb_port_id`、`device_type`。
- `enable_color`、`enable_depth`、`enable_infra1/2`、`enable_accel`、`enable_gyro`、`enable_pose`、`enable_fisheye1/2`。
- `depth_module.profile`、`rgb_camera.profile`、`tracking_module.profile`。
- `pointcloud.enable`、`align_depth.enable`、`tf_publish_rate`、`diagnostics_period`。
- `publish_tf` 没有作为 launch argument 显示，但节点运行参数中存在且为 `true`；`diagnostics_period` 本次保持 `0.0`，因此未期待 diagnostics 话题。

注意：运行参数树实际使用 `align.enable`，而 4.0.4 launch argument 名为 `align_depth.enable`。本次两者均保持禁用，没有验证启用映射；对依赖对齐深度的下游属于静态配置风险。

## 6. 工作区静态配置

### 6.1 入口与相机选择

- 主飞行 bringup 的相机入口 [px4_fly.launch.py](/home/c/px4_ws/src/px4_bringup/launch/include/px4_fly.launch.py:8) 包含 `realsense2_camera/rs_t265_launch.py`，随后还会启动 vision bridge 和 PX4/MAVROS 路径；本次未启动该文件。
- T265 专用包装 [rs_t265_launch.py](/home/c/px4_ws/src/realsense-ros/realsense2_camera/launch/rs_t265_launch.py:38) 限定 `device_type=t265`，默认启用 pose 和双 fisheye；该文件在 `realsense-ros` Git 状态中为未跟踪文件，但已经进入 install，存在重建可复现风险。
- 另一入口 [t265_all_nodes_launch.py](/home/c/px4_ws/src/ros2_foxy_vision_to_mavros/launch/t265_all_nodes_launch.py:13) 同时定义 T265、MAVROS 和 bridge；它硬编码 `usb_port_id=2-2`，而现场 T265 为 `1-2.2`，并在 [第 68 行](/home/c/px4_ws/src/ros2_foxy_vision_to_mavros/launch/t265_all_nodes_launch.py:68) 起包含 MAVROS。本次因安全边界未使用。
- 官方源码还提供通用 `rs_launch.py`、双设备 `rs_d400_and_t265_launch.py` 和 multi-camera 入口，存在多个可选入口，但其用途不同；生产使用时应明确唯一权威入口。
- 工作区未绑定 D435 或 T265 序列号。两设备并存时，仅靠默认空选择会有选错设备的风险；专用 launch 的 `device_type` 能降低但不能消除同型号多机风险。

### 6.2 namespace、frame 与下游

- 默认 `camera_name=camera` 产生节点 `/camera/camera` 和 `/camera/...` 话题，符合 RTAB-Map 示例。
- T265 bridge 默认 `source_frame_id=camera_link`，证据见 [t265_tf_to_mavros_launch.py](/home/c/px4_ws/src/ros2_foxy_vision_to_mavros/launch/t265_tf_to_mavros_launch.py:31)；实际默认 T265 相机命名也生成 `camera_link`，静态命名相符。
- D400 RTAB-Map 示例订阅 `/camera/color/image_raw`、`/camera/color/camera_info` 和 `/camera/aligned_depth_to_color/image_raw`，见 [realsense_d400.launch.py](/home/c/px4_ws/src/rtabmap_ros/rtabmap_examples/launch/realsense_d400.launch.py:23)。前两项已现场存在；aligned depth 本次按要求关闭，未验证发布。
- D435i 示例明确要求 D435i、IMU 和 `/camera/imu`，见 [realsense_d435i_color.launch.py](/home/c/px4_ws/src/rtabmap_ros/rtabmap_examples/launch/realsense_d435i_color.launch.py:1)。现场深度相机是 D435，不是 D435i，因此该示例与 D435 硬件不匹配；T265 IMU 不能直接等同于 D435i 的同机同步 IMU。
- RViz 默认配置订阅 `/camera/depth/color/points`，而当前 wrapper 的点云默认关闭；本次也按安全最小化要求关闭。
- 未发现专用 ROS 1 RealSense launch 与 ROS 2 wrapper 并存的证据；工作区内其他大型第三方树包含 ROS 1 风格脚本，但本次识别到的 RealSense 权威入口均为 ROS 2 Python launch。

### 6.3 启用状态与 profile

- 通用 `rs_launch.py` 默认彩色/深度开启，红外、gyro、accel、pointcloud、depth alignment 关闭；源码见 [rs_launch.py](/home/c/px4_ws/src/realsense-ros/realsense2_camera/launch/rs_launch.py:34)。
- T265 飞行入口通过 `rs_t265_launch.py` 默认启用 pose 和双 fisheye，但没有显式启用 gyro/accel。
- `t265_all_nodes_launch.py` 则关闭双 fisheye、启用 gyro/accel/pose，二者行为不同。
- 未发现工作区生产入口固定 D435 彩色/深度分辨率和 FPS；本次运行选择现场已枚举支持的 640×480@15，以降低 USB 2.1 带宽压力。

## 7. 受控 ROS 2 运行验证

### 7.1 启动前基线

检查前 `ros2 node list` 为空；`pgrep -af 'realsense|rs_launch|realsense2_camera'` 只有检查命令自身，没有实际相机进程。不存在占用相机的 RealSense 节点。

### 7.2 D435 彩色/深度

核心启动参数：

```bash
timeout --signal=INT --kill-after=8s 30s \
  ros2 launch realsense2_camera rs_launch.py \
  camera_name:=camera device_type:=d435 \
  enable_depth:=true enable_color:=true \
  enable_infra1:=false enable_infra2:=false \
  enable_gyro:=false enable_accel:=false \
  enable_fisheye1:=false enable_fisheye2:=false enable_pose:=false \
  pointcloud.enable:=false align_depth.enable:=false \
  depth_module.profile:=640,480,15 rgb_camera.profile:=640,480,15
```

完整合并日志：`/tmp/realsense_runtime_check.log`（184 行，检查结束时 20,780 bytes）。

节点：`/camera/camera`。关键话题及类型：

| 话题 | 类型 | 现场结果 |
|---|---|---|
| `/camera/color/image_raw` | `sensor_msgs/msg/Image` | 640×480，`rgb8`，frame `camera_color_optical_frame` |
| `/camera/color/camera_info` | `sensor_msgs/msg/CameraInfo` | 640×480，`plumb_bob`，K/P 非零，frame 有效 |
| `/camera/depth/image_rect_raw` | `sensor_msgs/msg/Image` | 640×480，`16UC1`，frame `camera_depth_optical_frame` |
| `/camera/depth/camera_info` | `sensor_msgs/msg/CameraInfo` | 640×480，`plumb_bob`，K/P 非零，frame 有效 |
| `/camera/extrinsics/depth_to_color` | `realsense2_camera_msgs/msg/Extrinsics` | 已广告 |
| `/tf_static` | `tf2_msgs/msg/TFMessage` | publisher 可靠、transient-local |

`/camera/aligned_depth_to_color/*`、`/camera/imu` 等话题名虽被节点广告，但参数确认 alignment、IMU 均关闭；“话题存在”不能当作对应流已发布。

10 秒并发测量：

- 彩色：最初窗口约 13.024 Hz，最终窗口 10.686 Hz；观察到最大间隔 1.402 s。
- 深度：最初窗口约 14.997 Hz，最终窗口 12.154 Hz；观察到最大间隔 0.601 s。
- 配置值为 15 Hz。并发 graph/echo 探针会增加 Jetson 负载，因此不能把全部偏差只归因于相机；但结合 USB 2.1 与 MIPI/UVC 告警，不能判定满帧稳定通过。

CameraInfo 代表性内参：

```text
color K: [607.4507, 0, 318.6535; 0, 607.2875, 255.1354; 0, 0, 1]
depth K: [386.8392, 0, 324.8732; 0, 386.8392, 239.0984; 0, 0, 1]
D: five zeros for both rectified streams; frame_id non-empty
```

TF：`ros2 topic info -v /tf_static` 确认 publisher QoS；`tf2_echo` 现场解析成功：

```text
camera_link -> camera_depth_optical_frame
translation [0, 0, 0], quaternion [-0.500, 0.500, -0.500, 0.500]

camera_link -> camera_color_optical_frame
translation approximately [0, 0.015, 0], quaternion approximately [-0.499, 0.501, -0.500, 0.501]
```

### 7.3 T265 pose 与 IMU

本次没有使用会启动 MAVROS 的工作区集成文件，而是直接使用通用相机 launch，限定 `device_type:=t265`，关闭双 fisheye，仅启用 pose、gyro、accel，`unite_imu_method:=0`。

节点：`/tracking/tracking`。现场话题：

| 话题 | 类型 | 测得频率/内容 |
|---|---|---|
| `/tracking/pose/sample` | `nav_msgs/msg/Odometry` | 200.058 Hz；frame `odom_frame`，child `tracking_pose_frame` |
| `/tracking/gyro/sample` | `sensor_msgs/msg/Imu` | 200.009 Hz；frame `tracking_gyro_optical_frame` |
| `/tracking/accel/sample` | `sensor_msgs/msg/Imu` | 63.262 Hz；frame `tracking_accel_optical_frame` |
| `/tracking/imu` | `sensor_msgs/msg/Imu` | 被广告；因 `unite_imu_method=0` 未作为合并 IMU 频率验证目标 |
| `/tf`、`/tf_static` | `tf2_msgs/msg/TFMessage` | 运行期间被广告；本轮监督器到期后查询已不存在 |

日志确认实际 profile：Pose 200、Gyro 200、Accel 62。T265 runtime 监督器返回 124（达到预设 timeout），子进程日志显示 Stop/Close 完成并 `process has finished cleanly`。

### 7.4 运行告警

- D435：USB 2.1 reduced performance。
- D435：`rgb_camera.power_line_frequency` 尝试值 3，但设备范围为 `[0,2]`，参数最终为 null；这是 wrapper/设备能力兼容告警。
- D435：内核反复出现 UVC `GET_CUR ... -32`。
- D435：一次 `Left MIPI error` hardware notification。
- T265：USB 2.1 reduced performance，并明确提示 USB 2.1 下视频不可靠；本次已关闭 fisheye。
- 未观察到明确 dropped-frame、metadata timeout 或 USB bandwidth 字符串。

## 8. 分级结果

| 项目 | 状态 | 证据与边界 |
|---|---|---|
| 1. USB 枚举 | PASS | `lsusb`、`rs-enumerate-devices` 均识别 D435 和 T265 |
| 2. USB 连接速率 | WARN | 两台均为 480M / USB 2.1，SDK 明确提示降速 |
| 3. 普通用户设备权限 | PASS | `/dev/video0..5` 可读写；普通用户 SDK/ROS 运行成功 |
| 4. librealsense SDK | WARN | 2.50 能枚举和运行；但与 dpkg 2.56.5 多版本并存且有 UVC/MIPI 告警 |
| 5. ROS 2 RealSense wrapper | PASS | overlay 4.0.4 分别成功启动 D435、T265 |
| 6. 相机型号与工作区配置匹配 | WARN | T265 与主飞行入口匹配，D400 示例与 D435 匹配；D435i 示例不匹配，且存在旧 USB 端口 `2-2` |
| 7. 彩色图像 | WARN | 消息/尺寸/编码有效，但 15 Hz 配置下最终窗口约 10.686 Hz |
| 8. 深度图像 | WARN | 消息/尺寸/编码有效，初始接近 15 Hz，最终窗口约 12.154 Hz |
| 9. CameraInfo | PASS | 彩色/深度 K、P、frame_id 有效 |
| 10. TF | PASS | `/tf_static` QoS 正确，`tf2_echo` 可解析两条 optical frame 关系 |
| 11. IMU | PASS | T265 gyro 200.009 Hz、accel 63.262 Hz；D435 本身不支持 IMU |
| 12. 点云配置 | NOT TESTED | 按最小验证要求关闭；静态 RViz/RTAB-Map 存在相关依赖 |
| 13. depth alignment 配置 | NOT TESTED | 按要求关闭；RTAB-Map D400 路径需要它，且参数名存在版本差异风险 |
| 14. ROS namespace 与下游订阅匹配 | WARN | 默认 `/camera` 与 RTAB-Map 匹配；多相机/自定义 camera_name 会改变 namespace，且多个入口行为不同 |
| 15. 版本冲突或 overlay 风险 | WARN | dpkg 2.56.5、`/usr/local` 2.50、workspace 2.50 三来源；wrapper 实际链接 `/usr/local` |
| 16. 进程清理 | PASS | 最终进程表为空，`ros2 node list --no-daemon` 为空；无本次 RealSense 节点残留 |

## 9. 风险与阻塞项

按优先级：

1. **USB 2.1 是首要风险。** D435 和 T265 共用 480M hub；D435 帧率偏低且有 MIPI/UVC 告警，T265 SDK 明确不建议 USB 2.1 视频流。
2. **SDK 来源冲突。** 系统 deb 是 2.56.5，工具/源码/运行却为 2.50，且 wrapper 实际从 `/usr/local/lib` 加载。任何 rebuild、环境或动态链接搜索顺序变化都可能改变行为。
3. **工作区入口不一致。** 主入口 `rs_t265_launch.py`、`t265_all_nodes_launch.py` 和通用/multi-camera launch 的传感器开关、namespace、设备选择不同；`t265_all_nodes_launch.py` 的 `usb_port_id=2-2` 与现场不符，且会带起 MAVROS。
4. D435 出现一次 Left MIPI hardware error，内核每次启动都有 UVC control `-32`，需在 USB 3 连接后复测以区分带宽、电缆/Hub、Jetson UVC 与版本因素。
5. D435i 示例不能用于当前 D435 的同机 IMU假设；T265 IMU/pose 是另一设备和时间域。
6. `align_depth.enable`/运行时 `align.enable`、旧 wrapper 4.0.4 与较新 SDK 包并存，对 RTAB-Map aligned-depth 路径存在未验证风险。

## 10. 建议的下一步

这些是建议，均未在本次执行：

1. 将 D435 与 T265 接到真正的 USB 3.x 路径；优先避免二者共享 480M hub。重新执行 `lsusb -t`，必须看到相机分支为 5000M 或更高，再复测图像 FPS 和内核告警。
2. 明确一个 librealsense 来源和版本策略：检查 `/usr/local/lib/librealsense2*`、工作区 `librealsense` 与 dpkg 2.56.5 的预期关系；在变更前先记录依赖与回滚方案。本报告不建议直接安装/删除/升级。
3. 为生产入口明确唯一 RealSense launch；在有两台设备时使用现场确认的 `device_type`，如未来可能有同型号多机，再显式绑定受版本支持的序列号。
4. 修正前先评审 `t265_all_nodes_launch.py` 的旧 `usb_port_id=2-2`；不要直接运行该文件做相机单测，因为它包含 MAVROS。
5. 在 USB 3 和版本统一后，以单独、受控测试验证 D435 640×480@30 或目标 profile、pointcloud 和 depth alignment，再验证 RTAB-Map 下游。不要在问题未隔离前启动完整 bringup。
6. 若仍有 UVC `GET_CUR -32` 或 Left MIPI error，保留 `journalctl -k` 与 ROS 日志，检查电缆/Hub/供电和 Jetson RealSense 支持矩阵；需要 sudo 的诊断只应由维护者另行授权。

## 11. 执行命令与未执行操作

实际执行的只读/受控命令类别：

- 主机环境：题目列出的 `pwd`、`date`、`uname`、`os-release`、虚拟化、用户组、ROS 环境命令。
- USB/SDK：`lsusb`、`lsusb -t`、`command -v`、`rs-enumerate-devices -s`、完整枚举、`v4l2-ctl --list-devices`、设备节点权限。
- 日志：无 sudo 的 `dmesg`（权限不足）和 `journalctl -k -n 250` 关键词过滤。
- 包/版本：`dpkg -l`、`apt-cache policy`、`ros2 pkg list/prefix/executables/xml`、`ldd`、源码 Git describe。
- 静态配置：题目给出的 `find` 范围；因 `rg` 未安装，改用 `grep -RInE`；随后对关键文件执行 `nl -ba`。
- launch：实际 `rs_launch.py --show-args`。
- 运行：受 timeout 约束的 D435 与 T265 直接相机 launch；`ros2 node/topic/service/param`、QoS-aware echo、`topic hz`、`tf2_echo`；日志写入 `/tmp/realsense_runtime_check.log`。
- 清理：多次进程表、`pgrep`、`ros2 node list --no-daemon` 复核。

未执行：`realsense-viewer` GUI、固件升级、udev/权限/USB/内核/用户组修改、`sudo`、`modprobe`、apt 安装或升级、任何 PX4/MAVROS/RPLIDAR/STM32/串口/网络端点操作、完整 bringup、Nav2/SLAM、点云和 depth alignment 运行验证。

`rg` 不存在，所属常见组件为 ripgrep；未安装。`dmesg` 权限不足，建议维护者如确有需要在单独授权场景自行运行 `sudo dmesg --ctime | tail -n 250`，本次没有执行。

## 12. 清理与文件变更声明

- 最终 `ps`/`pgrep` 无 `realsense2_camera_node`、`rs_launch.py` 或 RealSense launch 进程。
- 最终 `ros2 node list --no-daemon` 为空。
- D435 前两轮正常 SIGINT 清理；TF 专项轮监督器曾到达强制阶段并返回 137，但相机子进程随后完成 Stop/Close，最终无残留。T265 监督器返回预期 timeout 124，子进程干净退出。
- Foxy 的一次 `ros2 param dump` 因未先加 `--print`，短暂生成工作区根目录 `camera__camera.yaml`；发现后立即删除，并用 `test` 确认不存在。后续使用 `--print`。最终没有除本报告外的工作区文件变更。
- `docs/` 检查前不存在；为存放本报告而创建。
- 受用户明确流程要求，运行日志保存在 `/tmp/realsense_runtime_check.log`；ROS 2 launch 也在用户标准 `~/.ros/log` 下生成了运行日志目录。未修改源码、launch、YAML、CMakeLists、package.xml、环境文件、系统权限或系统配置。

