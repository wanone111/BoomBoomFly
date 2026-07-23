# Intel RealSense D435 更换线材后专项复检

## 1. 结论摘要

- 检查时间：2026-07-23 14:00:21 至 14:10:20（Asia/Shanghai）。
- 设备：Intel RealSense D435，Product ID `8086:0b07`，ROS 序列号 `241122070080`，ASIC/USB 序列 `227323021826`，固件 `05.13.00.50`。
- **新线材有效：D435 已从 USB 2.1 / 480M 变为 USB 3.2 / 5000M。**
- sysfs 报告 USB version `3.20`、speed `5000`；ROS 日志报告 `Device USB type: 3.2`；`lsusb -t` 的五个 UVC 接口均为 5000M。
- 640×480@15：彩色 14.79 Hz、深度 15.00 Hz，未出现深度启动失败，状态 PASS。
- 640×480@30：两轮都能持续发布；复现轮彩色 29.81 Hz、深度 29.65 Hz，但两次启动均报告 `Depth stream start failure` hardware notification，状态 WARN。
- 彩色/深度消息、CameraInfo 和 TF 均有效。
- 换线后没有 D435 USB reset/disconnect，也未再出现此前的 `Left MIPI error`；但内核 UVC `GET_CUR ... -32` 和 wrapper 的 power-line-frequency 告警仍存在。
- 最终没有 RealSense ROS 进程或节点残留。

总体判断：**线材与 USB 3 链路通过；D435 的 15 Hz 运行通过；30 Hz 数据流基本达到目标，但可重复的深度启动硬件通知使 30 Hz 配置仍为 WARN。**

## 2. 安全范围与环境

- 主机：Jetson Orin Nano，Ubuntu 20.04.6，aarch64，内核 `5.10.104-tegra`。
- ROS：ROS 2 Foxy；检查 shell source `/opt/ros/foxy/setup.bash` 和 `/home/c/px4_ws/install/setup.bash`。
- 检查前 `ros2 node list --no-daemon` 为空，进程表无 RealSense camera node。
- 未启动完整 bringup、PX4、Micro XRCE-DDS Agent、MAVROS、RPLIDAR、Nav2、SLAM、串口或飞控节点。
- 未使用 sudo，未执行固件升级或系统配置修改。
- 本轮只启动 D435 ROS 节点；没有启动 T265 ROS 节点或采集 T265 话题。

## 3. USB 与设备识别

### 3.1 换线前后对照

| 项目 | 上一轮（旧线材/接口状态） | 本轮新线材 |
|---|---|---|
| D435 物理端口 | `1-2.3` | `2-1.3` |
| USB bus | Bus 01，480M | Bus 02，5000M |
| SDK/ROS USB 描述 | 2.1 | 3.2 |
| sysfs USB version | 未进入 USB 3 | `3.20` |
| UVC 接口速度 | 480M | 五个接口全部 5000M |

现场 sysfs：

```text
/sys/bus/usb/devices/2-1.3/speed      = 5000
/sys/bus/usb/devices/2-1.3/version    = 3.20
/sys/bus/usb/devices/2-1.3/idVendor   = 8086
/sys/bus/usb/devices/2-1.3/idProduct  = 0b07
```

内核枚举证据：

```text
usb 2-1.3: new SuperSpeed Gen 1 USB device ...
Product: Intel(R) RealSense(TM) Depth Camera 435
SerialNumber: 227323021826
uvcvideo: Found UVC 1.50 device ... (8086:0b07)
```

ROS 驱动证据：

```text
Device with serial number 241122070080 was found.
Device with port number 2-1.3 was found.
Device USB type: 3.2
Device FW version: 05.13.00.50
Device Product ID: 0x0B07
```

本轮不再出现 `connected using a 2.1 port. Reduced performance is expected`。

### 3.2 V4L2 与权限

`v4l2-ctl --list-devices` 将 `/dev/video0..5`、`/dev/media1..2` 识别为 D435，路径为 `usb-3610000.xhci-1.3`。这些节点对当前用户均可读写，普通用户成功完成所有 ROS 运行验证；权限状态 PASS。

## 4. SDK 和 ROS 驱动版本

版本关系与前两份报告一致：

- 工作区 `rs-enumerate-devices`：2.50.0。
- ROS wrapper：`realsense2_camera` 4.0.4，来源 `/home/c/px4_ws/install/realsense2_camera`。
- wrapper 实际加载 `/usr/local/lib/librealsense2.so.2.50`。
- 系统 dpkg 同时安装 librealsense 2.56.5。

因此换线解决了 USB 速率，但没有解决 SDK 2.50/2.56.5 多来源覆盖风险。

本轮没有运行完整 `rs-enumerate-devices`，以避免主动枚举其他 RealSense；D435 的身份、USB 速度、固件和 Product ID 由 sysfs、udev 和 D435 ROS 日志交叉确认。

## 5. ROS 运行验证

两类测试都使用通用 `realsense2_camera/rs_launch.py`，限定 `device_type=d435`：

```text
enable_color=true
enable_depth=true
enable_infra1/2=false
enable_gyro/accel/pose=false
pointcloud.enable=false
align_depth.enable=false
diagnostics_period=0.0
```

### 5.1 640×480@30 主测试

节点 `/camera/camera` 成功启动；实际参数与日志均确认 color/depth profile 为 640×480@30。

第一次 10 秒测量：

| 话题 | 早期窗口 | 最终窗口 | 最大间隔 |
|---|---:|---:|---:|
| `/camera/color/image_raw` | 30.054 Hz | 27.777 Hz | 0.368 s |
| `/camera/depth/image_rect_raw` | 30.018 Hz | 29.981 Hz | 0.035 s |

彩色出现一次长间隔，导致累计平均下降；深度频率稳定。

第二次独立复现测量：

| 话题 | 最终窗口 | 最大间隔 |
|---|---:|---:|
| `/camera/color/image_raw` | **29.814 Hz** | 0.068 s |
| `/camera/depth/image_rect_raw` | **29.645 Hz** | 0.067 s |

第二轮没有复现第一次的 0.368 s 彩色间隔，两路均接近 30 Hz。

但是两次 30 Hz 启动均在 node up 后约两秒报告：

```text
Hardware Notification: Depth stream start failure ... Error, Hardware Error
```

该错误具有可重复性，不能归类为一次性日志噪声。由于深度流随后持续以约 30 Hz 发布、消息有效，它不是“驱动启动失败”，但仍使 30 Hz profile 状态为 WARN。

### 5.2 640×480@15 对照

第三轮使用与此前报告相同的 640×480@15：

| 话题 | 最终测量 |
|---|---:|
| `/camera/color/image_raw` | **14.787 Hz** |
| `/camera/depth/image_rect_raw` | **14.995 Hz** |

15 Hz 对照没有出现 `Depth stream start failure`、MIPI error、bandwidth 或 timeout 告警。因此当前证据支持：该硬件通知与 30 Hz 启动路径更相关，而不是所有 D435 启动都会发生。

### 5.3 消息内容

30 Hz 运行期间重新采集：

| 项目 | 结果 |
|---|---|
| 彩色图像 | 640×480，`rgb8`，step 1920，frame `camera_color_optical_frame` |
| 深度图像 | 640×480，`16UC1`，step 1280，frame `camera_depth_optical_frame` |
| 彩色 CameraInfo | `plumb_bob`，K/P 非零，frame 有效 |
| 深度 CameraInfo | `plumb_bob`，K/P 非零，frame 有效 |
| TF | `camera_link -> camera_depth_optical_frame` 可连续解析 |

代表性内参仍与之前一致：

```text
color fx/fy ≈ 607.451 / 607.288
depth fx/fy ≈ 386.839 / 386.839
```

## 6. 运行与内核告警分析

### 已改善

- D435 已明确进入 USB 3.2 / 5000M。
- 没有 USB 2.1 reduced-performance 告警。
- 三轮运行期间没有 D435 USB disconnect、reset、timeout。
- 没有再出现上一份报告中的 `Left MIPI error`。
- 30 Hz 两路均可持续发布，复现轮接近额定频率。

### 仍存在

1. 两次 30 Hz 启动均出现 `Depth stream start failure` hardware notification；15 Hz 不出现。
2. 每次启动仍有多条内核告警：

   ```text
   uvcvideo: Failed to query (GET_CUR) UVC control 1 on unit 3: -32 (exp. 1024)
   ```

3. wrapper 仍尝试设置不支持的 power-line-frequency 值：

   ```text
   rgb_camera.power_line_frequency with 3 Range: [0, 2]
   ```

4. librealsense 2.50 与系统 2.56.5 多来源风险仍在。

`dmesg` 仍因普通用户权限不足未执行；使用 `journalctl -k` 获得内核证据，未使用 sudo。

## 7. 状态表

| 项目 | 状态 | 证据 |
|---|---|---|
| D435 USB 枚举 | PASS | sysfs、udev、lsusb、ROS 均确认 8086:0b07 |
| USB 连接速率 | PASS | USB 3.2，5000M，五个 UVC 接口均为 5000M |
| 普通用户权限 | PASS | V4L2/media 节点可读写；无 sudo 运行成功 |
| ROS wrapper 启动 | PASS | 4.0.4 三轮均 node up 并干净退出 |
| 640×480@15 彩色 | PASS | 14.787 Hz |
| 640×480@15 深度 | PASS | 14.995 Hz，无深度启动失败 |
| 640×480@30 彩色 | WARN | 复现轮 29.814 Hz，但首轮有一次 0.368 s 间隔 |
| 640×480@30 深度 | WARN | 29.645–29.981 Hz，但启动硬件通知可重复 |
| Image 消息 | PASS | width/height/encoding/frame_id 有效 |
| CameraInfo | PASS | K/P 与 frame_id 有效 |
| TF | PASS | camera_link 到 depth optical frame 可解析 |
| UVC/硬件日志 | WARN | GET_CUR `-32` 持续；30 Hz depth-start hardware notification 可重复 |
| SDK/overlay | WARN | 2.50/2.56.5 多来源未解决 |
| 点云 | NOT TESTED | 按最小范围关闭 |
| depth alignment | NOT TESTED | 按最小范围关闭 |
| 进程清理 | PASS | 最终进程表与无 daemon ROS graph 均为空 |

## 8. 建议

1. 当前若优先稳定性，使用 640×480@15：该 profile 本轮频率达标且没有 depth-start hardware notification。
2. 若任务必须使用 640×480@30，不应仅凭帧率判定完全通过；应先解决或解释重复的 `Depth stream start failure`，并进行更长时间、低系统负载的持续帧率与数据完整性测试。
3. 在维护窗口统一 librealsense 来源，避免 `/usr/local` 2.50、工作区 2.50 和 dpkg 2.56.5 混用；统一后重新检查 UVC GET_CUR 与 30 Hz 启动通知。
4. 评审 wrapper 4.0.4 的 `rgb_camera.power_line_frequency` 默认/映射，不要在本轮直接修改源码或设备参数。
5. 后续若验证目标包含 pointcloud 或 depth alignment，应在 D435 单机、USB 3.2 条件下逐项启用并单独测量带宽与 FPS。

## 9. 清理与文件声明

- 完整运行日志：`/tmp/d435_cable_recheck_20260723_140021.log`（136 行，检查结束时 15,283 bytes）。
- 三轮 D435 ROS 节点均受 timeout 监督，并通过 SIGINT/Stop/Close 干净退出。
- 最终无 `realsense2_camera_node`、RealSense launch 或 ROS 节点残留。
- D435 启动过程中，内核在 14:03 记录已连接 T265 从 Movidius 状态转为 USB 应用态；这是 librealsense context 枚举所有连接设备所致的合理推断。本轮未启动 T265 ROS 节点、未采集 T265 数据，也未将其纳入结论。
- 除本报告外，没有修改工作区文件；未修改源码、launch、YAML、CMakeLists、package.xml、环境或系统配置。

