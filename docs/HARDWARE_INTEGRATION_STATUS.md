# 硬件集成状态

> 本轮仅静态审查。未访问 `/dev`、未枚举 USB、未打开串口、未启动节点。旧 Jetson 现场报告只作为历史证据。

> **P0-01 更新：** 后续受管路径为 DDS-only；MAVROS 与旧 serial 已退出 manifest，串口来源改为 moving `../communication`。

## 1. 总览

| 设备/接口 | 软件与配置 | 静态状态 | 运行状态 |
|---|---|---|---|
| PX4 飞控 / MAVROS | 本地旧 `mavros`、`px4_bringup` | 已退出受管组合；不得运行 | 不再验证 |
| PX4 / DDS-XRCE | `px4_msgs v1.16.2`、Agent `v2.4.2`、`offboard_cpp` | 控制源码存在；无 Agent transport launch | 需要版本与现场验证 |
| RealSense D435 | `librealsense v2.50.0`、`realsense-ros 4.0.4` | 官方驱动存在 | 旧 Jetson 15 Hz PASS；当前未验证 |
| RealSense T265 | 官方驱动、目标 `vision_to_dds`；本地仍有旧 MAVROS 桥 | DDS 视觉 owner 已冻结；无生产 launch | 旧 Jetson pose/IMU PASS；当前未验证 |
| RPLIDAR | `rplidar_ros` | 多型号 launch/udev 存在 | 未验证 |
| 自定义串口/MCU | `../communication @ main` | moving 来源已确定；接口/协议未冻结 | 对端和设备未确认 |
| STM32 | 无固件/板型/协议版本 | 只能推断为可能的串口对端 | 无法确认 |
| ESP8266/ESP32 | 未发现项目实现/配置 | 无部署契约 | 无法确认 |

## 2. PX4 / 飞控

### 2.1 已退出的 MAVROS

- 包：`mavros 2.7.0`、`mavlink`、`mavros_msgs`、`libmavconn`。
- launch：`src/px4_bringup/launch/include/px4.launch.py`。
- 配置：`src/px4_bringup/config/mavros_params.yaml`。
- 主设备：`/dev/ttyTHS0:921600`。
- fallback：`/dev/ttyACM0:57600`。
- 协议：MAVLink v2；`respawn_mavros=false`。
- 数据流：T265 TF → `vision_to_mavros` → `/mavros/vision_pose/pose` → MAVROS → PX4。

以下仅为本地遗留风险，不再是目标部署配置：

1. 仓库没有 Jetson pinmux、电平、线序、流控或 PX4 UART 实例配置。
2. 另一入口硬编码 `serial:///dev/ttyUSB0:57600` 并包含 `apm.launch`，与主 PX4 入口冲突。
3. MAVROS command/setpoint 插件与 DDS 控制可形成第二控制发送路径。

### 2.2 DDS-XRCE

- 消息：`px4_msgs v1.16.2`。
- Agent：Micro XRCE-DDS Agent `v2.4.2`。
- 控制：`offboard_cpp/offboard_node`。
- 视觉：`vision_to_dds`。
- 数据流：ROS 2 `/fmu/in/*` ↔ Agent ↔ 外部 PX4 uXRCE-DDS client。

缺口：

- 无 Agent 串口/UDP/TCP transport、端口、domain、namespace launch。
- 无 PX4 firmware、board、`dds_topics.yaml` 或参数快照。
- 未确认 RC、电池和着陆检测 topic 是否由实机固件导出。
- `vision_to_dds` 不在 lock 且没有 launch/config。

## 3. Intel RealSense

### 3.1 软件

| 组件 | 版本/状态 |
|---|---|
| `src/librealsense` | `v2.50.0`，与 lock 匹配 |
| `src/realsense-ros` | `4.0.4`，与 lock 匹配 |
| 通用 launch | `realsense2_camera/launch/rs_launch.py` |
| 双机 launch | `rs_d400_and_t265_launch.py` |
| 项目飞行 include | 引用当前不存在的 `rs_t265_launch.py` |

通用 launch 默认访问真实硬件，未固定 `serial_no` 或 `usb_port_id`。双机入口仅以 `device_type` 区分，无法替代生产序列号绑定。

### 3.2 D435

已提取的旧 Jetson 现场结论：

- D435 序列号 `241122070080`。
- 更换线材后 USB 3.2/5000M。
- 640×480@15 color/depth PASS。
- 640×480@30 有可重复 `Depth stream start failure` 通知，状态 WARN。
- pointcloud、depth alignment 未测试。
- 旧环境存在 librealsense dpkg 2.56.5、`/usr/local` 2.50、workspace 2.50 多来源。

这些结果来自 `/home/c` Jetson，不能作为当前 WSL 或下一次部署的通过证据；旧的一次性报告已在结论提取后清理。

### 3.3 T265

已提取的旧 Jetson 现场结论：

- 序列号 `952322110550`。
- USB 3.1。
- pose 约 200 Hz、gyro 约 200 Hz、accel 约 63 Hz。

当前风险：

- 飞行入口缺 `rs_t265_launch.py`。
- 另一入口硬编码旧 `usb_port_id=2-2`。
- 生产配置未绑定序列号。
- 实际安装方向、TF、重定位/reset、时间延迟与坐标转换未冻结。

## 4. RPLIDAR

### 4.1 驱动与 transport

`src/rplidar_ros` 是 Slamtec 官方 ROS 2 驱动，默认发布 `sensor_msgs/LaserScan` 到 `scan`，未被项目 bringup 或 PX4 控制引用。

| 型号/入口 | 默认 transport |
|---|---|
| A1 / A2M8 | `/dev/ttyUSB0:115200` |
| A2M7 / A2M12 / A3 | `/dev/ttyUSB0:256000` |
| C1 | `/dev/ttyUSB0:460800` |
| S1 | serial 256000；TCP `192.168.0.7:20108` |
| S2 / S3 | `/dev/ttyUSB0:1000000` |
| S2E / T1 | UDP `192.168.11.2:8089` |

必须先确认实物型号，不能通过试错波特率寻找设备。

### 4.2 udev

源码规则以 VID:PID `10c4:ea60` 创建 `/dev/rplidar`，但：

- 所有 launch 仍默认 `/dev/ttyUSB0`。
- 源脚本规则 MODE=0777，权限过宽；debian 规则为 0666。
- 项目安装脚本不安装规则。
- 当前机器安装状态未检查。

## 5. 自定义串口与 STM32

### 5.1 已退出的旧软件链

```text
/cmd_vel
  → serial_cmd_sender
  → serial library
  → /dev/ttyS1:115200
  → 外部对端
```

- launch 配置：`src/serial_driver_ros/config/serial_config.yaml`。
- 源码 fallback：`/dev/ttyUSB0:115200`。
- 发送：`Twist.linear.x`、`Twist.angular.z` 转 `int16(value*1000)`。
- 帧：`0x0F 0xF0` + length + payload + 8-bit sum。
- 接收头：`0x0F 0xFF`。

### 5.2 后续 communication 缺口

- 旧 `serial_driver*` 与旧 `/home/aa/px4_ws/common` 已退出，不应再修补后纳入 BoomBoomFly。
- `communication` 按维护者决策不锁 SHA；每次验证需记录实际 HEAD。
- 其远端 `main` 当前未包含本地看到的两个未跟踪嵌套 ROS 2 仓库，正式发布结构待 communication owner 处理。
- stable udev/by-id、watchdog、重连、finite/range、粘包处理和 owner 契约仍需在新实现中冻结。

### 5.3 无法确认

仓库没有 STM32 芯片、板卡、固件、VID/PID、串口电平、接线、字节序、协议版本、CRC 或 watchdog 契约。因此不得写成“STM32 已接入”；当前只能确认 communication 被指定为后续通信源码来源。

## 6. ESP8266 与其他网络模块

排除第三方网络实现后，项目自研源码/launch/config 中没有 ESP8266、ESP32、Wi-Fi socket、认证、IP、端口或失联策略。若现场使用此类模块，必须补充独立硬件/固件/协议台账。

## 7. 模式与无硬件路径

| 路径 | 状态 |
|---|---|
| PX4 SITL | 无 PX4-Autopilot 源码或项目入口 |
| Gazebo | 上游 `gazebo_ros_pkgs` 存在，项目脚本为空 |
| RealSense bag | 驱动支持 `rosbag_filename`，项目未封装 |
| RPLIDAR mock | 未发现 |
| 串口 loopback/PTY | 未形成项目测试 |
| Offboard mock | `mock_rc_control.py` 存在但未被测试/launch 治理，且能伪造 RC |

结论：没有统一、可信的无硬件 smoke profile。

## 8. 现场验证前置条件

### 通用

1. 建立设备台账：型号、序列号、固件、VID/PID、物理端口、供电、电缆和 stable symlink。
2. 核对用户组 `dialout`、`plugdev`、`video` 和实际 udev 规则，不用 MODE=0777 作为生产方案。
3. 每个设备使用独立 launch/profile；不运行 `start_all_2025TI.launch.py`。
4. 执行器断电、飞行器拆桨，PX4 首次只读。

### PX4

- 固件 commit/tag、board、airframe、参数快照。
- MAVLink UART 实例、波特率、电平、流控。
- DDS transport/domain/Agent 参数和 `dds_topics.yaml`。
- RC kill、人工接管、Offboard loss、vision loss、低电和 estimator failsafe。

### RealSense

- 序列号绑定、USB 3 拓扑、供电/Hub、SDK 唯一来源。
- T265 安装方向、TF、时间和 reset 行为。
- D435 目标 profile、alignment/pointcloud 需求与带宽预算。

### RPLIDAR/MCU

- RPLIDAR 确切型号/transport/frame/安装方向。
- MCU 身份、固件、协议版本、缩放、端序、校验、watchdog 和执行器隔离。

## 9. 推荐单设备测试顺序

1. **D435 单机：** 绑定序列号；USB3/权限 → 640×480@15 → 30 Hz → CameraInfo/TF → alignment → pointcloud，逐项增加负载。
2. **T265 单机：** 只启 pose，再加 gyro/accel；检查 TF、坐标、挂载、频率、reset/断连；不启动 MAVROS/DDS。
3. **RPLIDAR 单机：** 确认型号/transport，采用 stable name 或显式 IP；只验证 `scan`、frame、频率和距离。
4. **MCU 串口：** 先纯编码测试和 PTY/loopback，再在执行器断电时接对端；验证协议、缩放、checksum、watchdog、断线。
5. **PX4 通信：** MAVROS 或 DDS 二选一，只遥测、不 arm、不 set_mode、不发 setpoint。
6. **T265 → PX4 外部视觉：** 只启一条视觉路径，不进入 Offboard；验证 EKF 接受、坐标、延迟和重定位。
7. **多设备资源：** 在只读 PX4 条件下逐项叠加 D435/RPLIDAR，观察 USB、CPU、内存和时间。
8. **Offboard：** 最后进入 SITL，再到拆桨台架；现有主入口不能作为起点。

## 10. 禁止直接联调的组合

- MAVROS 控制与 DDS 控制同时连接同一 PX4。
- `vision_to_mavros` 与 `vision_to_dds` 同时向 PX4 EKF 注入视觉。
- 未确认设备归属时并发打开 `/dev/ttyUSB0`。
- D435/T265/pointcloud/alignment/RPLIDAR/SLAM 一次性全开。
- MCU 执行器通电时首次验证 `/cmd_vel`。
- 当前 `start_all_2025TI.launch.py` 与任何实机飞行测试。
