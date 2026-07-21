# Tests and validation

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

## 测试体系判定

状态：**部分验证（ROS 包测试结构）/ 未验证（PX4 firmware）**。工作区没有 PX4-Autopilot、`Tools/`、`platforms/`、`boards/`、`ROMFS/`、顶层 `test/`、`px4_msgs` 或 `px4_ros_com`。因此 PX4 firmware unit tests、board build matrix、SITL、MAVSDK、JMAVSim、PX4 Gazebo/GZ models 均未验证；这不是测试失败，而是审查对象缺失。

## 自定义包现有测试

| 包 | 现有测试/配置 | 结论 |
|---|---|---|
| `src/offboard_cpp` | 无 `test/`；CMake 无 `BUILD_TESTING` / `add_test`；package 仅声明 lint 依赖 | 无功能测试；CMake 第 95 行所谓“主测试节点”只是普通 executable |
| `src/offboard_py` | `test/` 只有 copyright、flake8、pep257 模板 | 无节点或状态机测试 |
| `src/px4_bringup` | 同样只有 3 个模板 lint | 无 launch test |
| `src/ros2_foxy_vision_to_mavros` | `CMakeLists.txt:40-50` 仅 ament lint；第 44、48 行跳过 copyright/cpplint | 无坐标、时间戳、频率或消息测试 |
| `src/serial_driver_ros2` | 无测试目录与测试声明 | 本地协议改动无覆盖 |
| `src/serial-ros2` | `CMakeLists.txt:61-64` 注释测试子目录；`tests/CMakeLists.txt:2,9` 仍用 ROS 1 `catkin_add_gtest` | 当前 ament 构建不注册这些测试 |

`src/offboard_cpp/src/new.cpp` 与 `offboard_layered_example.cpp` 未跟踪、未加入 target，因此不会被常规 build/test 覆盖。

## 本次实际验证

本次没有运行构建、pytest、colcon test、CTest、仿真或硬件测试，因为它们会创建/更新缓存、日志或生成物，违反仅允许修改 `docs/workspace_status/` 的要求。

| 检查 | 退出码 | 结果 |
|---|---:|---|
| Python AST parse（offboard_py、bringup、vision/serial launch，共 19 文件） | 0 | 19/19 语法可解析；不证明 ROS 依赖或运行正确 |
| `git diff --check`：offboard_cpp/offboard_py/px4_bringup/serial-ros2 | 0 | 当前 diff 无 whitespace 错误；不检测 HEAD 内已有冲突标记 |
| `git diff --check`：vision bridge | 2 | `launch/t265_tf_to_mavros_launch.py:38` trailing whitespace |
| `git diff --check`：serial_driver_ros2 | 2 | `src/serial_driver_ros2/src/serial_driver.cpp:113` new blank line at EOF |

## 历史构建与测试证据

`offboard_cpp`、`offboard_py`、`px4_bringup`、`vision_to_mavros`、`serial_driver`、`serial` 的现有 `build/<package>/colcon_build.rc` 均为 0。但：

- `offboard_cpp` 最后成功约 2025-12-29 17:20，早于冲突 CMakeLists 修改（20:45）和 2026-01-02 的未跟踪源码。
- vision build 记录为 2025-07-26，早于 2026-03-12 的 launch 修改。
- 六个包都没有 `build/<package>/test_results/`；根 `log/` 只有历史 `build_*`，没有 `test_*`。

所以历史 rc 只证明旧快照曾构建，不是当前源码测试通过的证据。

## CI 状态

自定义仓库 `offboard_cpp`、`offboard_py`、`px4_bringup`、`ros2_foxy_vision_to_mavros`、`serial-ros2`、`serial_driver_ros2` 均无 `.github/workflows/`。第三方 MAVROS workflow 的 Foxy 项被注释（`src/mavros/.github/workflows/main.yml:11-19`）；其 Humble/Iron/Rolling CI 与 MAVLink generator CI 不覆盖本地自定义集成。

未发现本地 coverage、ASan、UBSan、TSan、cppcheck 或 clang-tidy 执行结果。

## 测试缺口

- P1：`src/offboard_cpp/CMakeLists.txt:125-134` 当前冲突标记，且无有效测试覆盖。
- P1：Offboard 的连接、预热、切模、解锁、轨迹、服务失败、断流 failsafe 没有 SITL/MAVSDK/launch 回归。
- P2：串口协议的短帧、奇数帧、坏校验、粘包/分片、数值边界、断线重连无测试。
- P2：视觉链没有坐标变换、时间戳、频率、新鲜度和资源 soak 测试。
- P2：自定义包无 CI、覆盖率或 sanitizer 证据。
- P3：两处 diff whitespace 错误。

## 推荐验证矩阵

| 阶段 | 验证 | 范围 | 通过标准 |
|---|---|---|---|
| 1 | 干净 ROS build | 五个自定义包及 serial | 全新 build/install/log，colcon 返回 0 |
| 2 | lint/静态检查 | 全部自定义包 | colcon test/result 全通过，补 sanitizer/静态分析 |
| 3 | 单元测试 | 状态机、串口协议、视觉转换 | 超时、坏帧、NaN、坐标边界均有断言 |
| 4 | ROS launch test | bringup、vision、serial | 参数/remap/readiness/设备缺失路径可重复 |
| 5 | PX4 SITL + MAVROS | C++/Python offboard | 切模、解锁、轨迹、断流 failsafe 全通过 |
| 6 | 故障注入 | FCU、串口、TF/视觉 | 断连、陈旧数据、服务拒绝进入预期安全状态 |
| 7 | HIL/实机前台架 | 整体系统 | 串口、电源、传感器、时间同步、互斥控制和 failsafe 留有日志证据 |

完整 PX4 测试必须在获得与实际飞控一致的 firmware 仓库、commit、board target 和参数后进行。
