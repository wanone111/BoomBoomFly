# 构建与运行状态

> 本轮默认静态审查；没有执行 `colcon build`、`colcon test`、launch 或节点。文中“成功”只引用已存在的历史日志，并明确其范围。

> **P0-01 更新：** 受管源码已收敛为 DDS-only。下文 79 包和 M1 是当前本地遗留工作区/历史证据，不是新 manifest 的包数或目标构建链。精确恢复清单见 [源码基线](SOURCE_BASELINE.md)。

## 1. 构建系统与环境线索

| 项目 | 已确认状态 |
|---|---|
| 工作区 | ROS 2/colcon 多仓工作区 |
| ROS 发行版 | Foxy；构建脚本固定 `/opt/ros/foxy/setup.bash` |
| 当前 OS | Ubuntu 20.04.6、WSL2、x86_64 |
| Python | 3.8.10 |
| CMake | 3.16.3 |
| GCC/G++ | 9.4.0 |
| 构建类型 | 70 `ament_cmake`、4 `ament_python`、3 `ros.cmake`、1 `cmake`、1 `ros.catkin` |
| C++ 标准 | 混合；不是统一 C++17 |
| 顶层生成目录 | `build/`、`install/`、`log/` 存在但被 Git 忽略 |

语言标准证据：

- `offboard_cpp`、`serial_driver`：C++17。
- `vision_to_dds`、`vision_to_mavros`：C++14。
- 当前 MAVROS 源码使用更高标准。
- 第三方包各自维护标准，不能由根文档统一外推。

## 2. 包清单

`colcon --log-base /dev/null list --base-paths src` 发现 79 包。

| 分组 | 包 |
|---|---|
| DDS/PX4（4） | `microxrcedds_agent`、`px4_msgs`、`offboard_cpp`、`vision_to_dds` |
| MAVROS（6） | `mavlink`、`mavros_msgs`、`libmavconn`、`mavros`、`mavros_extras`、`vision_to_mavros` |
| RealSense/vision（8） | `librealsense2`、`realsense2_camera`、`realsense2_camera_msgs`、`realsense2_description`、`cv_bridge`、`image_geometry`、`opencv_tests`、`vision_opencv` |
| 项目启动/I/O（4） | `px4_bringup`、`serial`、`serial_driver`、`rplidar_ros` |
| Gazebo（5） | `gazebo_dev`、`gazebo_msgs`、`gazebo_plugins`、`gazebo_ros`、`gazebo_ros_pkgs` |
| IMU（4） | `imu_complementary_filter`、`imu_filter_madgwick`、`imu_tools`、`rviz_imu_plugin` |
| Navigation messages（2） | `map_msgs`、`move_base_msgs` |
| Navigation2（31） | `costmap_queue`、`dwb_core`、`dwb_critics`、`dwb_msgs`、`dwb_plugins`、`nav2_amcl`、`nav2_behavior_tree`、`nav2_bringup`、`nav2_bt_navigator`、`nav2_common`、`nav2_controller`、`nav2_core`、`nav2_costmap_2d`、`nav2_dwb_controller`、`nav2_gazebo_spawner`、`nav2_lifecycle_manager`、`nav2_map_server`、`nav2_msgs`、`nav2_navfn_planner`、`nav2_planner`、`nav2_recoveries`、`nav2_regulated_pure_pursuit_controller`、`nav2_rviz_plugins`、`nav2_system_tests`、`nav2_util`、`nav2_voxel_grid`、`nav2_waypoint_follower`、`nav_2d_msgs`、`nav_2d_utils`、`navigation2`、`smac_planner` |
| RTAB-Map（15） | `rtabmap`、`rtabmap_conversions`、`rtabmap_demos`、`rtabmap_examples`、`rtabmap_launch`、`rtabmap_msgs`、`rtabmap_odom`、`rtabmap_python`、`rtabmap_ros`、`rtabmap_rviz_plugins`、`rtabmap_slam`、`rtabmap_sync`、`rtabmap_util`、`rtabmap_viz`、`slam_toolbox` |

合计 79。`rtabmap_msgs` 被识别为唯一 `ros.catkin` 包，但源码 CMake 使用 `ament_package()`；这是全量构建风险。

## 3. 主要构建链

```text
DDS:
px4_msgs ─┬─> offboard_cpp
          └─> vision_to_dds
Micro-XRCE-DDS-Agent 独立构建

已退出的历史 MAVROS + T265:
mavlink → mavros_msgs → libmavconn → mavros
librealsense2 → realsense2_camera_msgs → realsense2_camera
mavros_msgs + TF/nav/geometry → vision_to_mavros
以上运行依赖 → px4_bringup

已退出的历史 Serial:
serial
/home/aa/px4_ws/common (uav_common)
  → serial_driver
```

## 4. 外部依赖

### 4.1 源码依赖

- `workspace.lock.repos`：15 个精确 DDS-only 仓库。
- `workspace.repos`：上述维护 refs，加 `../communication @ main` moving dependency。
- `vision_to_dds` 已正式纳入 lock。
- 旧 `serial_driver_ros` 和 `/home/aa/px4_ws/common` 已退出受管组合，不再作为构建依赖。
- `communication` 的 ROS 2 串口发布内容尚未形成稳定、可锁定的 BoomBoomFly 构建接口。

### 4.2 系统依赖

历史 M1 验证曾通过临时 sysroot 提供：

- `libusb-1.0-0-dev`
- `python3-future`
- `ros-foxy-geographic-msgs`
- `ros-foxy-diagnostic-updater`
- `ros-foxy-eigen-stl-containers`
- `libasio-dev`
- `libgeographic-dev` / `libgeographic19`

这些依赖没有形成持久的系统包 lock。RealSense T265 构建还可能需要显式、带校验的固件缓存。

## 5. 依赖声明问题

| 包 | 已确认问题 |
|---|---|
| `px4_bringup` | 已退出；旧源码仍缺 buildtool/运行依赖 |
| `vision_to_mavros` | 已退出；旧源码存在依赖声明问题 |
| `vision_to_dds` | 使用 `builtin_interfaces` 但 manifest 未声明；描述/许可证仍 TODO |
| `offboard_cpp` | 声明 rosidl generator/group，但当前包无自定义接口生成 |
| `serial_driver` | 已退出；后续接口由 `communication` 重新定义 |
| `rtabmap_msgs` | 缺正确 ament build type export |

## 6. 构建证据

### 6.1 历史已成功的 M1 子集

历史日志 `log/m1_profile/build_2026-07-23_21-27-42/events.log` 记录 10 包返回 0：

```text
cv_bridge
librealsense2
mavlink
mavros_msgs
px4_bringup
realsense2_camera_msgs
libmavconn
realsense2_camera
vision_to_mavros
mavros
```

限制：

- 未包含 `px4_msgs`、`offboard_cpp`、`vision_to_dds`、`serial_driver`。
- 未覆盖 Navigation2、RTAB-Map、SLAM、Gazebo、RPLIDAR。
- 构建脚本设置 `BUILD_TESTING=OFF`。
- 本轮没有复现日志中的构建。

### 6.2 当前可构建性判断

| 范围 | 判断 |
|---|---|
| 包发现 | **已确认：** 79 包可被 colcon 发现 |
| 历史 M1 子集 | **历史已确认：** 曾成功 |
| 当前干净 M1 | **尚未验证** |
| DDS 控制链 | **lock 已冻结且 clean 验证；构建和安全语义尚未验证** |
| 串口链 | **不在精确 lock；等待 `communication` 发布可构建接口** |
| 79 包全量 | **不具备可重复条件；尚未执行** |

## 7. 推荐环境初始化与构建顺序

以下命令只作为下一阶段计划；本轮未执行。必须使用新的输出目录，避免旧产物掩盖依赖。

### 7.1 只读包发现

```bash
cd /home/aa/px4_ws/BoomBoomFly
source /opt/ros/foxy/setup.bash
colcon --log-base /dev/null list --base-paths src
```

### 7.2 版本基线核验

```bash
bash Scripts/installation/uav_px4_dds_install.sh --verify-only
git -C src/offboard_cpp status --short --branch
git -C /home/aa/px4_ws/communication status --short --branch
```

在 P0-01 完成前不要加 `--update`。

### 7.3 推荐分组验证

1. 接口：`px4_msgs realsense2_camera_msgs`。
2. DDS：`microxrcedds_agent vision_to_dds offboard_cpp`，只构建不运行。
3. RealSense/视觉依赖。
4. 新 DDS bringup 的静态解析和依赖存在性测试（当前尚未实现）。
5. Gazebo、Nav2、RTAB-Map、SLAM、RPLIDAR 分 profile 验证。
6. `communication` 在其仓库形成稳定 ROS 2 接口后单独验证；不混入精确 DDS 核心的首次构建。

示例输出隔离形式：

```bash
VERIFY_ROOT="$(mktemp -d /tmp/boomboomfly-build.XXXXXX)"
colcon --log-base "$VERIFY_ROOT/log" build \
  --base-paths src \
  --build-base "$VERIFY_ROOT/build" \
  --install-base "$VERIFY_ROOT/install" \
  --packages-select px4_msgs vision_to_dds offboard_cpp
```

该命令不会驱动硬件，但只能在 lock/版本决策完成后执行。

## 8. 当前构建阻塞项

1. `communication` 按决策不锁 SHA，且当前本地 dirty；串口不具备可复现构建接口。
2. 系统依赖和 RealSense 固件缓存未形成持久 lock。
3. 受管 package manifest 仍有缺失/冗余。
4. `rtabmap_msgs` build type 不一致。
5. 历史 `build/install/log` 和已退出源码可能掩盖当前缺失依赖。

## 9. 运行入口

### 9.1 仿真入口

| 入口 | 状态 |
|---|---|
| `Scripts/simulation/uav_sim.sh` | 0 字节 |
| `Simulator/gazebo_simulator/README.md` | 0 字节 |
| `Simulator/realsense_gazebo_plugin/README.md` | 0 字节 |
| PX4-Autopilot/SITL | 仓库中不存在 |
| 项目级 mock/smoke | 未形成；仅有未治理的 `mock_rc_control.py` |

结论：**没有已验证的项目级仿真运行入口。**

### 9.2 硬件入口

| 入口 | 行为 | 状态 |
|---|---|---|
| `px4_bringup/start_all_2025TI.launch.py` | 旧 T265 + MAVROS + 串口 + 感知 + 控制 | **已退出 manifest；禁止运行** |
| `px4_bringup/serial_and_image_2025TI.launch.py` | 串口 + 两个缺失感知包 | **失效** |
| `px4_bringup/include/px4_fly.launch.py` | T265 + vision_to_mavros + MAVROS | **失效：缺 `rs_t265_launch.py`** |
| `vision_to_mavros/t265_all_nodes_launch.py` | 旧 T265 + `apm.launch` + `/dev/ttyUSB0` | **已退出 manifest；禁止运行** |
| `offboard_cpp/*.launch.py` | DDS 控制/示例 | 源码可解析性待构建；无 Agent 编排 |
| `realsense2_camera/rs_launch.py` | 真实相机 | 仅适合满足现场安全条件后的单设备验证 |
| `rplidar_ros/*launch.py` | 真实雷达 | 仅适合确认型号/transport 后的单设备验证 |

### 9.3 禁止同时启动

- 本地遗留 MAVROS command/setpoint 与 DDS 路径。
- 本地遗留 `vision_to_mavros` 与 `vision_to_dds` 对同一 PX4 EKF 的外部视觉注入。
- `offboard_demo`、`animal_testing` 或其他发布者在没有 owner 仲裁时同时发布内部命令。
- 使用同一 `/dev/ttyUSB0` 的 MAVROS、RPLIDAR 和自定义串口入口。
- 多个 `offboard_node` 对同一 PX4 namespace。

## 10. 尚未执行的验证项目

- 当前源码的任何 build/test。
- 79 包全量依赖解析。
- launch 文件静态加载测试。
- 无硬件 smoke、SITL、HIL。
- PX4、Agent、MAVROS、RealSense、RPLIDAR 或串口运行。
- 所有现场设备、权限、QoS、TF、频率、时间戳和 failsafe。
