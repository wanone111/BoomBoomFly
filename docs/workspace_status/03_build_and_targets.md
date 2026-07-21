# Build system and targets

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

## 构建架构

状态：**已验证（ROS 构建）/ 未验证（PX4 firmware 构建）**。

顶层 `Makefile`、`CMakeLists.txt`、`cmake/`、`Tools/`、`platforms/`、`boards/`、`Kconfig`、`.github/workflows/`、`src/PX4-Autopilot/`、`src/px4_autopilot/` 和 `build/px4_sitl_default/` 均不存在。现有工作区包含 79 个 `package.xml`、79 个 `build/` 包目录和 77 个 `install/` 包目录；`build/COLCON_IGNORE`、`install/.colcon_install_layout`、逐包 `colcon_build.rc` 与 `CMakeCache.txt` 证明它们是 ROS 2 colcon 产物，而非 PX4 firmware build。

代表性 `build/offboard_cpp/CMakeCache.txt`：

- `CMAKE_PROJECT_NAME=offboard_cpp`
- `CMAKE_HOME_DIRECTORY=/home/c/px4_ws/src/offboard_cpp`
- `CMAKE_BUILD_TYPE=Release`
- `CMAKE_INSTALL_PREFIX=/home/c/px4_ws/install/offboard_cpp`
- `CMAKE_C_COMPILER=/usr/bin/cc`，`CMAKE_CXX_COMPILER=/usr/bin/c++`
- `CMAKE_GENERATOR=Unix Makefiles`

源码构建入口是 ament/colcon：`src/offboard_cpp/CMakeLists.txt:1-139`、`src/px4_bringup/package.xml:4-6,20` 和 `src/px4_bringup/setup.py:6-25`。未发现 `px4_msgs` 包或依赖，当前飞控接口主要走 MAVROS。

## Target 识别

- 当前使用过的目标：ROS 2 包 `offboard_cpp` 与 `px4_bringup`，证据来自 `log/` 历史 colcon 日志。
- PX4 `px4_sitl_default`：**未验证**，源码和 build 目录均不存在。
- PX4 NuttX/Linux/board target：**未验证**，缺少固件构建入口、Kconfig、board config 和 toolchain 配置。
- 未发现 `.px4`、PX4 ELF 或 firmware BIN 产物。

## 主机与工具环境

| 项目 | 结果 | 状态 |
|---|---|---|
| OS/CPU | Ubuntu 20.04.6 LTS，aarch64，Jetson/Tegra kernel 5.10.104-tegra | 已验证 |
| ROS | `ROS_DISTRO=foxy`；`ros2`、`colcon` 可用 | 已验证 |
| GCC/G++ | 9.4.0 | 已验证 |
| CMake | 3.16.3 | 已验证 |
| Ninja / Make | 1.11.1 / 4.2.1 | 已验证 |
| Python / pip | 3.8.10 / 25.0.1 | 已验证 |
| ccache | 3.7.7 | 已验证 |
| Python 模块 | `em`、`jinja2`、`numpy`、`yaml`、`jsonschema`、`kconfiglib`、`toml` 可导入 | 已验证 |
| `arm-none-eabi-gcc` | 不在 PATH，检查退出 1 | 已验证（缺失） |
| Clang | 不在 PATH | 已验证（缺失） |
| PX4 固件环境完整性 | 固件源码/requirements 缺失，无法判断 | 未验证 |

## 历史构建结果

`log/latest_build` 指向 `log/build_2025-12-29_17-19-58`，其选择包为 `offboard_cpp`，Release、symlink-install，最终退出码 0。`px4_bringup` 最近记录于 2025-12-29 10:55:30，最终退出码 0。历史日志也有多次退出码 1/2。

这些结果只证明特定 ROS 包的旧源码状态曾构建成功，不证明完整 79 包工作区或 PX4 firmware 构建成功。最新成功日志引用当前已不存在的 `colcon.meta`，说明配置已漂移。

## 本次实际命令与退出码

| 命令/检查 | 退出码 | 关键结果 |
|---|---:|---|
| 根目录 `git rev-parse --show-toplevel` | 128 | 非 Git 仓库 |
| `test` 顶层 PX4 构建入口 | 1 | 所有特征入口缺失 |
| `find` 包、build/install、缓存与日志 | 0 | 确认为 colcon 工作区 |
| 编译器、CMake、Python、ROS/colcon 版本检查 | 0 | 见环境表 |
| `command -v arm-none-eabi-gcc` | 1 | NuttX ARM 工具链缺失 |
| PX4 或 ROS 实际构建 | 未运行 | 只读约束；详见下节 |

主 agent 另运行 `colcon version-check`，子命令退出 1：代理地址的端口为无效字符串 `7897~`。这不等同于本地 colcon 构建失败，但说明在线版本检查配置异常。

## 当前阻塞项

1. `src/offboard_cpp/CMakeLists.txt:125-134` 包含已提交到 HEAD 的 `<<<<<<<` / `=======` / `>>>>>>>`，当前 CMake 重新配置预计失败（P1）。
2. 缺少 PX4-Autopilot 源码，无法识别或构建任何 firmware target（P1/范围阻塞）。
3. `arm-none-eabi-gcc` 缺失；即使补入源码，ARM/NuttX 构建环境也不完整（P2）。
4. 历史构建引用已不存在的 `colcon.meta`，且最后成功产物早于当前 CMakeLists 修改（P2）。
5. 现有日志只覆盖选定 ROS 包，没有当前完整工作区重建证据（P2）。

## 为什么未运行构建

本次未执行构建：构建会写入 `build/`、`install/` 和 `log/`，与只允许修改 `docs/workspace_status/` 的要求冲突；PX4 源码和 target 又不存在；当前 ROS 构建入口已有冲突标记。历史构建结果仅作为证据，不能替代当前源码重建。
