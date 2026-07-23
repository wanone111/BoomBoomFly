# 仓库状态

> 初始检查时间：2026-07-23 22:15—22:25（Asia/Shanghai）  
> P0-01 更新：2026-07-23；源码清单已按维护者决策收敛为 DDS-only  
> P0-02/交接更新：2026-07-23 23:17；控制权已冻结，P0-03 等待 PX4 资料  
> 检查方式：Git、文件、manifest、构建日志和源码静态审查；未构建、未测试、未启动节点

## 1. 仓库身份

| 项目 | 结论 | 证据/限定 |
|---|---|---|
| 仓库路径 | **已确认：** `/home/aa/px4_ws/BoomBoomFly` | 顶层 `.git/`、`git rev-parse --show-toplevel` |
| 当前分支 | **已确认：** `master` | `git branch --show-current` |
| HEAD | **已确认：** `b10fe78f01953b8ec1071693a9abab8671c3e899`（`update  migration`） | `git rev-parse HEAD`、`git log` |
| 远程 | **已确认：** `origin` fetch/push 均为 `https://github.com/wanone111/BoomBoomFly.git` | `git remote -v` |
| 远端同步状态 | **无法确定：** 只相对本地缓存的 `origin/master` 为 0 ahead/0 behind | 本轮未 `fetch` |
| submodule | **已确认：** 顶层无 `.gitmodules`、gitlink 或有效 submodule | `git submodule status --recursive`、mode `160000` 扫描 |

## 2. Git 工作区状态

治理前顶层工作区不干净：

- **已确认：** 9 个 tracked modified、无 staged、无 deleted。
- **已确认：** 顶层状态显示 3 个 untracked 项：`docs/README.md`、`docs/current_workspace_snapshot.md` 和 `src/`。
- **已确认：** `.gitignore` 隐藏了多数 `src/<repo>` 目录；顶层 `git status` 不能反映所有嵌套仓库漂移。
- **已确认：** `build/`、`install/`、`log/` 未被顶层 Git 跟踪；本地仍存在约 1.2 GiB/325 MiB/28 MiB 的历史产物。

本轮文档治理会使 `docs/` 产生预期变更。源码与配置的治理前状态没有被清理或覆盖。

### 2.1 21 个嵌套仓库

这些目录都是独立 Git 仓库，不是顶层 submodule。

| 状态 | 数量 | 内容 |
|---|---:|---|
| 总仓库 | 21 | `src/` 的 21 个一级目录 |
| clean / dirty | 18 / 3 | dirty：已退出的 `mavlink`、`mavros`、`serial_driver_ros` |
| detached / 有分支 | 17 / 4 | 有分支：`offboard_cpp`、`ros2_foxy_vision_to_mavros`、`serial_driver_ros`、`vision_to_dds` |
| DDS-only lock 条目 | 15 | [精确锁文件](../workspace.lock.repos) |
| lock 路径、URL、HEAD 匹配 | 15 | 全部通过 |
| lock clean | 15 | `--verify-only` blockers=0 |
| 已退出但本地仍存在 | 6 | `mavlink`、`mavros`、`px4_bringup`、`ros2_foxy_vision_to_mavros`、`serial-ros2`、`serial_driver_ros` |
| 外部 moving dependency | 1 | `../communication @ main`，按维护者决策不锁 SHA |

关键分歧：

1. **已确认：** `offboard_cpp` 来源已改为 `BoomBoomFly/offboard_cpp`；维护清单跟随 `DDS`，本次远端和本地 HEAD 均为 `8925f8ae...`，lock 固定该 SHA。
2. **已确认：** 按维护者批准，`offboard_cpp` 的 2 个 tracked 修改和未跟踪 `.codex/` 已丢弃；当前 clean 匹配 lock。
3. **已确认：** `vision_to_dds @ 0c3a001...` 已正式进入两份 manifest。
4. **维护者决策：** MAVROS、vision-to-MAVROS、旧 serial、旧 `common` 和 MAVROS-only bringup 已退出受管组合；当前目录残留不代表基线成员。
5. **维护者决策：** `/home/aa/px4_ws/communication` 跟随最新 `main`，不进入精确 lock；本次远端 HEAD 为 `df256c18...`。

逐项 SHA、退出项和恢复语义见 [DDS-only 源码基线](SOURCE_BASELINE.md)。

## 3. 最近主要变更

最近提交反映的开发方向：

| 时间 | 提交 | 方向 |
|---|---|---|
| 2026-07-23 | `b10fe78` | migration 更新 |
| 2026-07-23 | `03c8889`、`1b517c8` | RealSense 检查与复检 |
| 2026-07-21 | `90a8fe6`、`15fff7d` | 依赖/脚本/说明治理 |

**从提交历史推断：** 当前重点是跨平台迁移、依赖锁定、M1 子集构建和 RealSense 验证，而不是已完成的生产级飞控集成。

## 4. 目录结构

| 路径 | 用途 | 当前判断 |
|---|---|---|
| `Scripts/` | 仓库恢复、M1 构建、安装/仿真脚本 | `car_install.sh`、`uav_sim.sh` 是 0 字节占位 |
| `Simulator/` | Gazebo/RealSense 仿真占位 | 两个子 README 为 0 字节；无项目级 SITL 入口 |
| `docs/` | 当前状态与维护文档 | 本轮治理范围 |
| `patches/` | 历史补丁位置 | MAVROS 补丁已按维护者要求删除 |
| `src/` | 21 个独立源码仓库 | 顶层不跟踪源码内容 |
| `build/ install/ log/` | 历史 colcon 产物 | 已忽略；不可作为当前通过证据 |
| `workspace*.repos` | DDS-only 维护意图与精确 lock | 15 个精确核心 + 1 个 moving communication |
| `/home/aa/px4_ws/communication` | 后续串口/通信仓库 | 跟随 `main`；本地 dirty；不锁 SHA |
| `/home/aa/px4_ws/common` | 已退出的旧 serial 依赖 | 不再属于 BoomBoomFly 受管组合 |

未发现可直接判为项目废弃副本的根目录。第三方仓库中的 `archive/`、测试和上游构建目录不属于本轮清理对象。

## 5. ROS 2 与包清单

### 5.1 环境

- **已确认：** 当前主机是 WSL2、Ubuntu 20.04.6、x86_64。
- **已确认：** 当前 shell 为 ROS 2 Foxy，Python 3.8.10、CMake 3.16.3、GCC/G++ 9.4.0。
- **已确认：** 当前本地工作区语言标准不统一：受管 `offboard_cpp` 为 C++17、`vision_to_dds` 为 C++14；已退出的 serial/MAVROS 源码仍有各自标准。

### 5.2 当前本地 79 个 colcon 包

`colcon --log-base /dev/null list --base-paths src` 在 P0-01 清单收敛前的本地 `src/` 发现 79 包，构建类型为 70 `ament_cmake`、4 `ament_python`、3 `ros.cmake`、1 原生 `cmake`、1 被误识别为 `ros.catkin`。其中 MAVROS、旧 bringup 和旧 serial 包已退出受管组合；新的 DDS-only 空工作区包数尚未在 P1-02 重新统计。

| 分组 | 包 |
|---|---|
| PX4/DDS | `px4_msgs`、`microxrcedds_agent`、`offboard_cpp`、`vision_to_dds` |
| 本地遗留、已退出 | `mavlink`、`mavros_msgs`、`libmavconn`、`mavros`、`mavros_extras`、`vision_to_mavros` |
| RealSense/视觉 | `librealsense2`、`realsense2_camera`、`realsense2_camera_msgs`、`realsense2_description`、`cv_bridge`、`image_geometry`、`opencv_tests`、`vision_opencv` |
| 本地遗留、已退出启动/串口 | `px4_bringup`、`serial`、`serial_driver` |
| RPLIDAR/IMU | `rplidar_ros`、`imu_complementary_filter`、`imu_filter_madgwick`、`imu_tools`、`rviz_imu_plugin` |
| Gazebo | `gazebo_dev`、`gazebo_msgs`、`gazebo_plugins`、`gazebo_ros`、`gazebo_ros_pkgs` |
| Navigation2 | `costmap_queue`、`dwb_core`、`dwb_critics`、`dwb_msgs`、`dwb_plugins`、`nav2_amcl`、`nav2_behavior_tree`、`nav2_bringup`、`nav2_bt_navigator`、`nav2_common`、`nav2_controller`、`nav2_core`、`nav2_costmap_2d`、`nav2_dwb_controller`、`nav2_gazebo_spawner`、`nav2_lifecycle_manager`、`nav2_map_server`、`nav2_msgs`、`nav2_navfn_planner`、`nav2_planner`、`nav2_recoveries`、`nav2_regulated_pure_pursuit_controller`、`nav2_rviz_plugins`、`nav2_system_tests`、`nav2_util`、`nav2_voxel_grid`、`nav2_waypoint_follower`、`nav_2d_msgs`、`nav_2d_utils`、`navigation2`、`smac_planner` |
| Navigation messages | `map_msgs`、`move_base_msgs` |
| RTAB-Map | `rtabmap`、`rtabmap_conversions`、`rtabmap_demos`、`rtabmap_examples`、`rtabmap_launch`、`rtabmap_msgs`、`rtabmap_odom`、`rtabmap_python`、`rtabmap_ros`、`rtabmap_rviz_plugins`、`rtabmap_slam`、`rtabmap_sync`、`rtabmap_util`、`rtabmap_viz` |
| SLAM | `slam_toolbox`、`smac_planner` |

`rtabmap_msgs` 的 manifest 缺少正确 ament build type，因而被识别为唯一 `ros.catkin` 包；全量构建影响需要实际验证。

## 6. PX4 通信状态

| 链路 | 静态状态 | 结论 |
|---|---|---|
| DDS-XRCE 控制 | `offboard_node` 发布 `fmu/in/trajectory_setpoint`、`offboard_control_mode`、`vehicle_command` | **已确认源码存在；未形成可运行 bringup** |
| DDS 视觉 | `vision_to_dds` 发布 `/fmu/in/vehicle_visual_odometry` | **已入 lock；原型仍无 launch/config** |
| MAVROS | 本地旧源码仍存在 | **已退出 manifest；不再是候选生产链** |
| 固件 | 仓库无 PX4-Autopilot、board、参数或 `dds_topics.yaml` | **无法确定实际固件版本和消息兼容性** |

**已确认：** `px4_msgs` 是 `v1.16.2`，Agent 是 `v2.4.2`。  
**冲突：** `offboard_cpp/README.md` 仍指导 PX4 1.14.3/`release/1.14`，但受管 `px4_msgs` 已是 `v1.16.2`；两者与真实固件的兼容性等待 P0-03 核验。当前 `offboard_cpp` 工作树 clean。  
**架构决策：** 唯一候选生产传输为 DDS；`offboard_control_node` 是唯一 PX4 控制 writer，`vision_to_dds_node` 是唯一视觉 writer。详见 [ADR-0001](adr/0001-dds-only-control-authority.md)。在 Agent bringup、固件版本和运行时安全门闭环前，仍不能声称存在可运行的权威生产路径。

## 7. 硬件驱动状态

| 设备 | 仓库证据 | 当前状态 |
|---|---|---|
| PX4 飞控 | DDS 源码存在但无 transport 配置；旧 MAVROS 参数已退出基线 | 需要现场验证 |
| RealSense D435/T265 | 官方 SDK/wrapper 源码；旧 Jetson 报告有单机证据 | 历史验证，不代表当前机器 |
| RPLIDAR | 官方驱动、多型号串口/网络 launch、udev 规则 | 仅静态存在 |
| 自定义串口 | 后续由 `../communication` 维护；旧 `/dev/ttyS1` 实现已退出 | 新仓库内容和现场契约待独立验证 |
| STM32 | 无固件、芯片或协议版本证据 | 无法确认；只能称通用 MCU 串口桥 |
| ESP8266/ESP32 | 项目源码、launch、配置中未发现实现 | 无法确认是否现场存在 |

## 8. 构建与测试准备度

### 8.1 构建

- **历史已确认：** 日志记录 10 包 M1 子集返回成功：`cv_bridge`、`librealsense2`、`mavlink`、`mavros_msgs`、`px4_bringup`、`realsense2_camera_msgs`、`libmavconn`、`realsense2_camera`、`vision_to_mavros`、`mavros`。
- **本轮未验证：** 当前源码的干净 M1 重建、DDS 控制链、串口链和 79 包全量构建。
- **P0-01 已缓解：** 15 项精确 DDS lock 已形成，旧 MAVROS/serial/common 分歧已通过退出清单解决。
- **当前阻塞：** DDS Agent/bringup 缺失、package 依赖问题、混合 build type、系统依赖未形成持久基线。

### 8.2 测试

- 根目录无 CI。
- `offboard_cpp` 无单元、状态机或 launch 测试。
- `vision_to_dds` 只有 lint，无坐标/时间/TF 测试。
- 当前无 DDS 项目级 bringup 和 launch test。
- `communication` 的 ROS 2 串口内容未形成 BoomBoomFly 可锁定测试基线。
- M1 构建脚本显式 `BUILD_TESTING=OFF`。

结论：**不具备直接上板条件。**

## 9. 能力完成度

### 已完成或有证据的能力

- **已确认：** 15 项 DDS-only 精确 lock 和仓库恢复脚本存在。
- **历史已确认：** MAVROS/RealSense M1 10 包子集曾构建成功。
- **已确认：** DDS 控制、DDS 视觉和雷达源码入口可以静态追踪；串口来源已转向 moving `communication`。
- **历史已确认：** 旧 Jetson 上 D435 640×480@15 和 T265 pose/IMU 有受控运行证据。

### 部分完成

- 源码恢复：15 项精确 lock 已通过当前本地 verify；communication 是明确 moving 例外。
- DDS 控制：实现存在，但安全门、版本和 bringup 未闭环。
- MAVROS 视觉：已退出后续基线，仅保留历史证据。
- 串口：来源已改为 `communication/main`；其内容、对端、watchdog、重连和协议仍未闭环。
- RealSense：历史单机验证存在，但 SDK 来源、当前硬件和生产 profile 未冻结。

### 尚未实现或无证据

- 可重复的完整工作区构建。
- 安全默认、可解析、可分级的生产 bringup。
- PX4 固件/参数/board/RC/failsafe 版本化基线。
- 唯一 DDS 控制 owner 和内部命令仲裁。
- 无硬件 smoke、Offboard 状态机测试、SITL/HIL 回归。
- 项目级 PX4 SITL/传感器仿真入口。
- RPLIDAR、STM32/MCU、全系统联调和部署回滚验证。

## 10. 已知问题与未验证假设

最高风险详见 [风险与阻塞项](RISKS_AND_BLOCKERS.md)。当前必须保留的未知项：

1. **需要现场验证：** 实机 PX4 是否为 1.16.2、板型、airframe、参数、RC 与 failsafe。
2. **需要现场验证：** DDS Agent transport/domain 和消息集合。
3. **需要现场验证：** T265 安装方向、ENU/NED 与 FLU/FRD、时间偏差和重定位行为。
4. **需要现场验证：** D435/T265 当前序列号和 USB 拓扑是否仍与旧报告一致。
5. **无法确定：** STM32、ESP8266 是否属于当前部署；仓库没有足够资料。
6. **从代码推断：** Nav2、RTAB-Map、SLAM Toolbox、RPLIDAR 尚未进入项目权威启动链。
7. **已确认到检查时点：** 只读远端查询确认 Offboard `DDS @ 8925f8ae...`、communication `main @ df256c18...`；moving ref 之后仍可能变化。

下一窗口从 [handoff](handoff.md) 接续，不应依赖已折叠的聊天上下文。
