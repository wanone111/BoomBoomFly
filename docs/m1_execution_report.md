# M1 跨平台恢复与独立构建执行报告

> 执行日期：2026-07-23
> 目标工作区：`/home/c/BoomBoomFly`
> 构建类型：无硬件、无 ROS 节点、无串口、无飞控控制的隔离软件检查

## 1. 结论

M1 的“最小软件构建闭环”已通过，但“从公网完整恢复 20 个锁定仓库”尚未通过。因此 M1 当前状态为：**构建闭环通过，跨平台公网恢复部分阻塞**。

- 在不继承 `/home/c/px4_ws/install` 的干净 ROS 2 Foxy 环境中，T265 + D435 + MAVROS 最小 profile 的 10 个包全部构建成功。
- `mavros`、`vision_to_mavros`、`realsense2_camera`、`px4_bringup` 均可从该隔离安装空间被 `ros2 pkg` 发现；主要可执行文件和 bringup launch 已安装。
- 锁文件中的 20 个仓库有 18 个可由当前本地对象恢复到精确 SHA、detached HEAD、零本地分支。
- `px4_msgs` 与 `Micro-XRCE-DDS-Agent` 本地不存在；GitHub HTTPS 连接在 TLS 握手阶段失败，SSH 22 端口也超时，故无法在本次验证中恢复这两个仓库。
- 明确排除 `offboard_py`、`cv_yolo_paddle_pkg`、`opencv_cpp`，它们不参与恢复、构建和 M1 验收。
- 本次未连接或启动 T265、D435、串口、MAVROS 节点、PX4、Offboard 或完整 bringup；本报告不证明硬件和飞控运行能力。

## 2. 执行边界

本次执行了：

- Git/manifest 静态核对。
- 一次性目录中的锁定提交恢复。
- `colcon list` 和 `rosdep check`。
- 隔离环境下的最小 profile 构建。
- 安装产物静态发现检查。
- 脚本语法、ShellCheck 和 Git diff 检查。

本次没有执行：

- 安装或卸载系统包。
- 修改 udev、systemd、网络或 PX4 参数。
- 启动 ROS 节点或占用硬件设备。
- 打开串口、发送 MAVLink、切换模式、解锁或发送 setpoint。
- 修改 `/home/c/px4_ws` 备份内容。

## 3. M0 基线与恢复点

执行 M1 前已生成轻量可恢复快照：

```text
/home/c/migration_backups/BoomBoomFly_m0_20260723T174116+0800
```

快照覆盖顶层仓库和 19 个嵌套仓库的 HEAD、分支、remote、status、tracked archive、binary diff 和未跟踪清单，共 124 个文件、约 1.5 MiB，`SHA256SUMS` 校验通过。

此前完整迁移快照仍保留在：

```text
/home/c/migration_backups/BoomBoomFly_phase1_20260723T163830+0800
```

## 4. 仓库恢复结果

### 4.1 公网恢复

恢复脚本尝试从 `workspace.lock.repos` 取回精确 SHA。首个仓库 `px4_msgs` 即出现：

```text
fatal: unable to access 'https://github.com/PX4/px4_msgs.git/':
gnutls_handshake() failed: The TLS connection was non-properly terminated.
```

替代检查结果：

- GitHub HTTPS/curl：TLS/代理链路失败。
- GitHub SSH 22：连接超时。
- 工作区与本机缓存：未发现可用的 `px4_msgs` 或 `Micro-XRCE-DDS-Agent` Git 对象。

该项属于外部网络阻塞，不是锁文件 SHA 或恢复脚本语法失败。网络恢复前不能宣称“另一平台可从公网完整创建相同 20 仓库”。

### 4.2 本地锁定恢复

利用目标工作区已有 Git 对象，在一次性目录恢复了 18 个仓库：

- 每个仓库 HEAD 与 `workspace.lock.repos` 的 40 位 SHA 一致。
- 每个仓库处于 detached HEAD。
- 每个仓库本地分支数为 0。
- 未恢复项只有 `px4_msgs` 和 `Micro-XRCE-DDS-Agent`。
- `colcon list` 在恢复树中发现 76 个包。
- 三个明确排除包均未进入恢复树或包清单。

### 4.3 当前 BoomBoomFly dry-run

规范化 `offboard_cpp` 和 `px4_bringup` 的 origin 后，当前恢复计划为：

```text
planned=20 cloned=2 updated=0 verified=9 blockers=9
```

其中：

- `cloned=2`：缺失的 `px4_msgs`、`Micro-XRCE-DDS-Agent`，真正执行时需要网络。
- `verified=9`：当前 HEAD、origin 和工作树满足锁文件要求。
- `blockers=9`：现有本地修改被安全拒绝；脚本不会覆盖这些修改。

## 5. 依赖检查

完整恢复树的 `rosdep check` 发现：

| 包 | 问题 | 对 M1 最小 profile 的影响 |
|---|---|---|
| `offboard_cpp` | 无 `opencv` rosdep 定义 | 不影响；当前不进入控制构建 |
| `librealsense2` | 无 `catkin` rosdep 定义 | 最小 profile 实际构建通过，但依赖声明需治理 |
| `rtabmap` | 无 `libpointmatcher` rosdep 定义 | 不影响；RTAB-Map 延后 |
| `smac_planner` | 无 `ompl` rosdep 定义 | 不影响；Nav2 延后 |
| `rtabmap_demos` | 无 `turtlebot3` rosdep 定义 | 不影响；demo 延后 |
| 系统依赖 | 缺少 `libceres-dev` | 阻塞完整工作区，不阻塞本次最小 profile |

没有自动安装或修改任何依赖。

## 6. MAVROS Foxy 兼容补丁

锁定的 MAVROS 2.7.0 首次隔离构建在 `tf2_eigen/tf2_eigen.hpp` 处失败。ROS 2 Foxy 当前提供的是 `tf2_eigen/tf2_eigen.h`。已从目标工作区的既有兼容修改中提取最小补丁：

```text
patches/mavros/foxy_tf2_eigen_h.patch
```

补丁特征：

- 仅修改 24 个 MAVROS C++ 源文件的 include 名称。
- 24 行新增、24 行删除。
- 不包含权限位变化、changelog 改动或其他本地实验代码。
- 可对锁定 MAVROS SHA 应用，并可由构建脚本判断“已应用 / 需要应用 / 不兼容”三种状态。

## 7. 隔离构建结果

构建环境清除了继承的 ROS overlay 变量，只 source：

```text
/opt/ros/foxy/setup.bash
```

构建目标：

```text
mavros vision_to_mavros realsense2_camera px4_bringup
```

显式排除：

```text
offboard_py cv_yolo_paddle_pkg opencv_cpp
```

构建结果：

| 顺序 | 包 | 结果 | 时间 |
|---:|---|---|---:|
| 1 | `cv_bridge` | 通过 | 27.7 s |
| 2 | `librealsense2` | 通过 | 17 min 51 s |
| 3 | `mavlink` | 通过 | 12.4 s |
| 4 | `mavros_msgs` | 通过 | 7 min 51 s |
| 5 | `px4_bringup` | 通过 | 4.67 s |
| 6 | `realsense2_camera_msgs` | 通过 | 21.7 s |
| 7 | `libmavconn` | 通过 | 42.0 s |
| 8 | `realsense2_camera` | 通过 | 2 min 23 s |
| 9 | `vision_to_mavros` | 通过 | 15.5 s |
| 10 | `mavros` | 通过 | 14 min 2 s |

最终摘要：

```text
Summary: 10 packages finished [44min 13s]
```

9 个包有 stderr 输出，检查到的是编译警告和未使用 CMake 参数提示；没有失败包或中止包。

## 8. 安装产物核验

在仅包含 M1 安装空间和 `/opt/ros/foxy` 的环境中：

- `ros2 pkg prefix mavros`：成功。
- `ros2 pkg prefix vision_to_mavros`：成功。
- `ros2 pkg prefix realsense2_camera`：成功。
- `ros2 pkg prefix px4_bringup`：成功。
- `mavros_node`、`vision_to_mavros_node`、`realsense2_camera_node`：均被发现。
- `px4_bringup` 的两个 launch 和 `mavros_params.yaml`：均已安装。

未运行这些可执行文件或 launch。

## 9. 可复现资产

M1 新增或更新：

- `Scripts/installation/uav_px4_dds_install.sh`：锁文件精确恢复、detached HEAD、不创建分支、安全拒绝 dirty 仓库。
- `Scripts/build/m1_build.sh`：清理旧 overlay、应用审核补丁、显式排除三包、构建最小 profile。
- `workspace.excluded_packages`：机器可读排除清单。
- `patches/mavros/foxy_tf2_eigen_h.patch`：MAVROS Foxy 最小兼容补丁。
- `Scripts/README.md`：跨平台恢复和 M1 构建说明。

注意：构建输出位于一次性目录，不写入 BoomBoomFly 的 `build/`、`install/` 或 `log/`。

## 10. M1 验收判断

| 验收项 | 状态 |
|---|---|
| 排除三包 | 通过 |
| 锁定版本可由现有对象恢复 | 18/20 通过 |
| 从公网恢复 20/20 | 阻塞：GitHub 网络不可达 |
| detached HEAD 且不创建分支 | 18/18 通过 |
| 不继承 `/home/c/px4_ws/install` | 通过 |
| 最小 profile 构建 | 10/10 通过 |
| 安装产物静态发现 | 通过 |
| 完整工作区依赖闭环 | 未通过 |
| 连续两次干净构建 | 尚未执行 |
| 硬件/飞控验证 | 不在本次范围 |

因此不能将 M1 标记为“全部完成”。允许进入 M2 前，至少应完成公网 20/20 恢复或准备离线 Git bundle，并在目标平台再做一次干净构建。

## 11. 下一步

1. 修复或更换 GitHub 网络路径，重跑 20 仓库空目录恢复。
2. 若目标平台长期离线，为 20 个锁定仓库制作并校验 Git bundle。
3. 在目标平台使用 `Scripts/build/m1_build.sh` 连续完成两次干净构建。
4. 治理 `librealsense2` 的 `catkin` 依赖声明与系统依赖来源。
5. 保持 `offboard_cpp` 不参与 M1；单独处理其 CMake 冲突和控制安全门。
6. M1 完整验收后进入 M2：D435 单机、T265 单机、双相机最低负载回归。

## 12. 安全结论

当前仍不具备完整 bringup 或 PX4 控制测试条件。最不应执行的是直接运行 `start_all_2025TI.launch.py`、自动解锁或 Offboard 飞行。M2 前只允许继续做版本、依赖、构建和静态配置治理。
