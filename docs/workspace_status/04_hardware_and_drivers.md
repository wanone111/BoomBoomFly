# Hardware and drivers

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

## 板级范围

状态：**未验证（PX4 板级）/ 部分验证（伴随端硬件）**。排除 `build/`、`install/`、`log/` 后，未找到 `boards/`、`platforms/`、`ROMFS/`、`src/drivers/`、`*.px4board`、`defconfig` 或 `board_config.h`。因此 Pixhawk/FMU target、GPIO、SPI、I2C、CAN、PWM、ADC、NuttX、bootloader、linker script、flash/RAM 及板载驱动均未验证，不能推断板级配置正常。

## 实际硬件适配地图

| 接口/设备 | 配置证据 | 审查时主机状态 | 结论 |
|---|---|---|---|
| PX4 飞控串口 | `src/px4_bringup/config/mavros_params.yaml:4`：`/dev/ttyTHS0:921600` | 节点存在，`root:dialout`、0660；用户 `c` 属于 `dialout` | 主机设备/权限已验证；飞控波特率和握手未验证 |
| MAVROS fallback | `src/px4_bringup/launch/include/px4.launch.py:23`：`/dev/ttyACM0:57600` | 节点不存在 | 仅 YAML 缺失时使用；当前 YAML 存在 |
| STM32/自定义串口 | `src/serial_driver_ros2/config/serial_config.yaml:3-4`：`/dev/ttyUSB0`、115200 | 节点不存在 | 当前收发运行未验证 |
| RPLidar | `src/rplidar_ros/launch/rplidar_a1_launch.py:14-20`：`/dev/ttyUSB0`、115200 | `/dev/ttyUSB0`、`/dev/rplidar` 均不存在 | 未枚举；也不在主 bringup 链 |
| RPLidar udev | `src/rplidar_ros/scripts/rplidar.rules:3`：VID:PID `10c4:ea60`、symlink `rplidar` | 规则是否安装未验证 | 源码提供稳定名，但默认 launch 未采用 |
| RealSense T265 | `src/px4_bringup/launch/include/px4_fly.launch.py:8-17`；`src/realsense-ros/realsense2_camera/launch/rs_t265_launch.py:38-43` | 无 `/dev/video*`；`lsusb` 无 Intel RealSense | 未连接或未透传，运行未验证 |

RPLidar 只是在工作区内可构建，并未被 `px4_bringup`、`offboard_cpp` 或 `offboard_py` 主启动引用。

## 驱动构建接入

`src/serial_driver_ros2/CMakeLists.txt:31-59` 定义 `serial_cmd_sender` 与 `cmd_qr_sender`；launch 在 `src/serial_driver_ros2/launch/serial_driver.launch.py:13-19` 选择后者。现有 `build/serial_driver/cmd_qr_sender` 晚于相关源码，`build/serial_driver/colcon_build.rc` 为 0，属于已有构建成功证据，本次没有重建。

CMake cache 把串口库解析到 `/usr/local/include` 和 `/usr/local/lib/libserial.a`，但 `src/serial_driver_ros2/package.xml:14-15` 未声明实际使用的 `std_msgs` 与 serial 依赖。`src/px4_bringup/package.xml:15-17` 同样未声明其启动的多个运行包；干净主机可重复性不足。

## 本地硬件适配改动

- `src/serial_driver_ros2/config/serial_config.yaml` 把端口从 `/dev/ttyS1` 改为 `/dev/ttyUSB0`。
- serial launch 从 `serial_cmd_sender` 改为 `cmd_qr_sender`，并新增未跟踪 `src/serial_driver_ros2/src/serial_orinnano.cpp`。
- `src/serial_driver_ros2/src/serial_driver.cpp` 删除发送 `×1000` 和接收 `/1000` 缩放，并增加逐帧十六进制输出。
- vision 输出从 30 Hz 改为 100 Hz；T265 tracking queue 本地 launch 覆盖为 256（`src/realsense-ros/realsense2_camera/launch/rs_t265_launch.py:38-43`）。
- RealSense/MAVROS 大批 dirty 主要是 executable-bit 变化；不能把权限噪声当作功能适配。

## 板级与驱动风险

- P1：`src/serial_driver_ros2/src/serial_driver.cpp:81-104` 对外部长度未验证偶数，移除校验字节后仍读取 `frame[j+1]`；奇数长度帧可越界。
- P1：`serial_driver.cpp:35-43,99-103` 删除 ×1000/÷1000 缩放但注释仍称缩放 1000；常见绝对值小于 1 的速度会被截断为 0，且可能与 STM32 wire format 数量级不一致。
- P1：`/dev/ttyUSB0` 当前缺失；`serial_driver.cpp:6-12` 在成员构造时直接打开且无异常恢复，主启动链可能失败。
- P1：未跟踪 `src/serial_driver_ros2/src/serial_orinnano.cpp:93-130` 允许单值 `0x99` 经简单 8 位和校验触发 `/start_flight=true`，缺少序列号、时效、重放与状态许可检查。
- P2：`serial_driver.cpp:63-109` 每 200 ms 使用局部 buffer；不完整帧退出后丢弃，无法跨读取处理串口分片。
- P2：自定义串口与 RPLidar 默认都指向 `/dev/ttyUSB0`，存在枚举变化或误开/争用风险。
- P2：T265 100 Hz + queue 256 尚无端到端延迟、CPU/USB 负载数据；大队列可能放大陈旧位姿。
- P2：依赖元数据不完整，当前成功依赖本机 `/usr/local` 和既有 install 空间。
- P3：`install/serial_driver/share/serial_driver/launch/Ti_2025_serial_driver.launch.py` 是 dangling symlink；旧 `cmd_qr_publisher` 仍残留但当前 CMake 不再定义。

## 未验证项

没有连接 PX4、STM32、RPLidar 或 T265 做通信/传感测试；未验证 `/dev/ttyTHS0` pinmux、电平、接线、硬件流控、误码率和飞控端 921600 配置；未安装或修改 udev；未运行节点或构建。固件 UART instance 与 GPIO/SPI/I2C/CAN/PWM 冲突完全不可验证。

## 关键只读检查

- 板级目录/config 搜索退出 0，无匹配。
- 根 `git status` 退出 128；19 个嵌套仓库状态检查退出 0。
- `git diff --check`（serial driver）退出 2，报告 `src/serial_driver_ros2/src/serial_driver.cpp:113` 文件尾空行。
- 设备节点、用户组、build/install 检查退出 0；只有 `/dev/ttyTHS0` 存在。
- `lsusb` 退出 0，未枚举 RealSense、RPLidar 或明显 STM32 串口设备。
