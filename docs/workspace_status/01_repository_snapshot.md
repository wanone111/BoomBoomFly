# Repository snapshot

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

## 仓库身份与版本结论

状态：**已验证**。

`git rev-parse --show-toplevel` 和 `git status --short --branch` 在工作区根目录均以 128 退出并报告 `not a git repository`。`src/` 下发现 19 个独立 Git 仓库，因此不能用任一子仓库的 branch、commit 或 tag 代表整个工作区。

以下 PX4 固件特征均不存在：`Makefile`、`CMakeLists.txt`、`boards/`、`ROMFS/`、`platforms/`、`src/modules/`、`src/lib/parameters/`、`src/modules/mavlink/`、`src/modules/uxrce_dds_client/`、`msg/` 和 `dds_topics.yaml`。所以 PX4 firmware 的 branch、commit、tag、`git describe` 和版本均为**未验证**。`src/mavlink/package.xml:4-5` 的 `mavlink 2022.12.30` 与 `src/mavros/mavros/package.xml:3-4` 的 `mavros 2.7.0` 是 ROS/MAVLink 组件版本，不是 PX4 firmware 版本。

## 源码仓库状态

基于现有本地 tracking refs，10 个仓库 clean、9 个 dirty，所有仓库 staged 文件数均为 0。ahead/behind 的 `0/0` 未经过 `fetch`，仅代表本地 remote-tracking ref，远端实时状态**未验证**。

| 仓库 | 分支/状态 | HEAD/describe | 本地状态摘要 |
|---|---|---|---|
| `src/gazebo_ros_pkgs` | `foxy`，upstream 0/0 | `b6f7bf121d0c` / `3.5.0-25-gb6f7bf1` | clean |
| `src/imu_tools` | `foxy`，0/0 | `d28555e487e4` / `2.0.3` | clean |
| `src/librealsense` | detached | `c94410a420b7` / `v2.50.0-dirty` | 3347 个 tracked mode changes |
| `src/mavlink` | detached | `22b62f8d55feb72f306d4c0147467beee490030d` / `release/foxy/mavlink/2022.12.30-1-dirty` | 233 个 tracked mode changes；8 个 `.pyc` 未跟踪 |
| `src/mavros` | detached | `48b53ccdf95f10b2ab3366c6e061fad2a76bd6c8` / `2.7.0-dirty` | 325 个 unstaged；其中 26 个文件有内容差异 |
| `src/navigation2` | `foxy-devel`，0/0 | `ca482808a7a7` / `0.4.7-19-gca482808` | clean |
| `src/navigation_msgs` | `foxy`，0/0 | `fe880e99d993` / `2.0.2-dirty` | 整个 `map_msgs/` 的 13 个 tracked 文件删除 |
| `src/offboard_cpp` | `master`，0/0 | `77a02dc09212cdaa1d8ee654f0ae42ae0f04e275` / `77a02dc` | 2 个未跟踪源码文件 |
| `src/offboard_py` | `master`，0/0 | `38887f08dd91719d3efa5d969d9cb7eceff7463d` / `38887f0` | clean |
| `src/px4_bringup` | `master`，0/0 | `0fbdcbf6ee53d6927de75af1d98f22cf5bd4f917` / `0fbdcbf` | clean |
| `src/realsense-ros` | detached | `8abb4657c0add15f87b0edbfb67eaba2c1c2c439` / `4.0.4-dirty` | 98 个 unstaged；1 个未跟踪 launch 文件 |
| `src/ros2_foxy_vision_to_mavros` | `main`，0/0 | `3d395fdc0d034758f8846f8a4cb6dc7e22185d63` | launch 文件 1 个 unstaged 修改 |
| `src/rplidar_ros` | `ros2`，0/0 | `24cc9b6dea97` / `2.1.4-7-g24cc9b6` | clean |
| `src/rtabmap` | `foxy-devel`，0/0 | `0070de4aafab` / `0.21.1-foxy` | clean |
| `src/rtabmap_ros` | `foxy-devel`，0/0 | `b341e2a776a7` / `0.21.1-foxy` | clean |
| `src/serial-ros2` | `master`，0/0 | `ae46504ae7d4` / `1.2.1-40-gae46504` | clean |
| `src/serial_driver_ros2` | `main`，0/0 | `8614989c8b9e60176a83d5d32a058801fafdb8d6` | 4 个修改、1 个未跟踪源码文件 |
| `src/slam_toolbox` | `foxy-devel`，0/0 | `4786e90c06a4` / `2.4.1-4-g4786e90` | clean |
| `src/vision_opencv` | `foxy`，0/0 | `72152d9d1d8e` / `3.0.7-dirty` | 整个 `image_geometry/` 的 17 个 tracked 文件删除 |

合计：4038 个 unstaged tracked 文件、12 个未跟踪文件。大部分数量来自权限位从 `100644` 到 `100755` 的噪声，但 `mavros` 另有 26 个一增一删的内容差异，不能归为纯权限变化。

## 当前变更重点

- `src/offboard_cpp/src/new.cpp` 与 `src/offboard_cpp/src/offboard_layered_example.cpp` 未跟踪；后者自述尚未接入 CMake（第 1–2 行）。
- `src/ros2_foxy_vision_to_mavros/launch/t265_tf_to_mavros_launch.py:37-40` 将输出频率由 30 Hz 改为 100 Hz；`git diff --check` 退出 2，当前第 38 行有 trailing whitespace。
- `src/serial_driver_ros2/{CMakeLists.txt,config/serial_config.yaml,launch/serial_driver.launch.py,src/serial_driver.cpp}` 已修改，`src/serial_driver_ros2/src/serial_orinnano.cpp` 未跟踪；`git diff --check` 退出 2，`src/serial_driver_ros2/src/serial_driver.cpp:113` 报文件尾新增空行。
- `src/navigation_msgs/map_msgs/` 与 `src/vision_opencv/image_geometry/` 被整包删除，可能破坏干净重建和依赖解析。
- `src/librealsense`、`src/mavlink`、`src/mavros`、`src/realsense-ros` 处于 detached HEAD 且 dirty，真实定制与权限位噪声混杂。

## Remote 与最近提交（飞控相关）

- `src/mavlink`：origin `https://github.com/mavlink/mavlink-gbp-release.git`；HEAD `22b62f8d Rebase from upstream`。
- `src/mavros`：origin `git@github.com:mavlink/mavros.git`；HEAD `48b53ccd (tag: 2.7.0) 2.7.0`。
- `src/offboard_cpp`：origin `git@hly:AyasOwen/offboard_cpp.git`，upstream `git@hly:BoomBoomFly/px4_offboard_cpp.git`；HEAD `77a02dc 优化框架`。
- `src/offboard_py`：origin `git@hly:BoomBoomFly/px4_offboard_py.git`；HEAD `38887f0 将launch文件转移至px4_bringup`。
- `src/px4_bringup`：origin `git@hly:AyasOwen/px4_bringup.git`；HEAD `0fbdcbf 0.0.1`。
- `src/ros2_foxy_vision_to_mavros`：origin `git@github.com:AyasOwen/ros2_foxy_vision_to_mavros.git`；HEAD `3d395fd 0.0.2`。
- `src/serial_driver_ros2`：origin `https://github.com/BoomBoomFly/serial_driver_ros2.git`；HEAD `8614989 init`。

## Submodule、gitlink、LFS 与嵌套仓库

- 19 个源码仓库均未发现 mode `160000` gitlink，`git submodule status --recursive` 无条目。
- `src/mavlink/.gitmodules` 声明 `pymavlink`，但索引中的 `pymavlink/*` 是普通文件而非 gitlink。这是保留的元数据不一致，不能据此判定 submodule 未初始化。
- `git lfs` 不可用；扫描到的 `.gitattributes` 未发现 `filter=lfs`。LFS 对象完整性为**未验证（工具缺失）**。
- `build/librealsense2/third-party/libcurl/.git` 是构建目录中的嵌套依赖仓库，clean detached，HEAD `2f33be817cbce6ad7a36f27dd7ada9219f13584c`、tag `curl-7_75_0`；它不是主要源码仓库。

## 可重复性限制

远端未 fetch，远端最新领先/落后状态未验证；根目录没有 superproject lockfile 或统一 commit，因此当前 19 个仓库组合不能由单个 commit 精确重建。
