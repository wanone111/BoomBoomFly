# Scripts

本目录存放 BoomBoomFly 的安装和仿真辅助脚本。当前已实现的是无人机 PX4 + Micro XRCE-DDS 方案的依赖拉取脚本；小车安装脚本和无人机仿真脚本仍是占位文件。

## 目录结构

```text
Scripts/
├── README.md
├── installation/
│   ├── uav_px4_dds_install.sh
│   └── car_install.sh
└── simulation/
    └── uav_sim.sh
```

## installation

### 无人机仓库恢复

脚本路径：

```bash
Scripts/installation/uav_px4_dds_install.sh
```

该脚本只负责恢复源码仓库，不安装 ROS 2、系统依赖、udev 规则、PX4 固件或硬件配置。默认读取仓库根目录的 `workspace.lock.repos`，把其中20个仓库恢复到精确 commit SHA。

恢复后的依赖仓库统一处于 detached HEAD；脚本不会创建本地开发分支，也不会执行 `git pull`。

#### 在其他平台创建相同仓库集

```bash
git clone https://github.com/wanone111/BoomBoomFly.git
cd BoomBoomFly

# 先确认20个仓库及精确 SHA，不创建文件
./Scripts/installation/uav_px4_dds_install.sh \
  --dry-run \
  --skip-package-check \
  --src-dir /path/to/ros2_ws/src

# 确认后恢复源码；没有 ROS/colcon 的主机也可以执行
./Scripts/installation/uav_px4_dds_install.sh \
  --src-dir /path/to/ros2_ws/src
```

如果目标就是当前 BoomBoomFly 工作区，可省略 `--src-dir`：

```bash
./Scripts/installation/uav_px4_dds_install.sh --dry-run
./Scripts/installation/uav_px4_dds_install.sh
```

#### 已有仓库的处理规则

- origin URL、HEAD 和工作树状态都会被检查。
- dirty 仓库会被拒绝，脚本不会覆盖本地修改。
- HEAD 与 lock SHA 不一致时，默认拒绝并提示使用 `--update`。
- `--update` 只 fetch 并切换到锁定提交，仍然保持 detached HEAD，不创建分支、不 pull。
- 目标路径已存在但不是 Git 仓库时直接报错。
- `--verify-only` 只核对现有仓库，不克隆、不更新。

示例：

```bash
# 将已有的干净仓库同步到 lock SHA
./Scripts/installation/uav_px4_dds_install.sh --update

# 只验证另一工作区
./Scripts/installation/uav_px4_dds_install.sh \
  --verify-only \
  --src-dir /path/to/ros2_ws/src
```

#### Manifest 选择

- 默认 `workspace.lock.repos`：20个仓库全部固定为40位 commit SHA，推荐用于部署、CI和跨平台复现。
- `workspace.repos`：记录 tag/branch/SHA 的维护意图。若明确需要使用它，必须同时传入 `--allow-moving-refs`。

```bash
./Scripts/installation/uav_px4_dds_install.sh \
  --manifest workspace.repos \
  --allow-moving-refs \
  --dry-run
```

#### ROS 包检查

- 找到 `colcon` 时，脚本默认执行包发现并检查核心包。
- 非 ROS 平台没有 `colcon` 时，仅输出警告，仓库恢复仍可成功。
- `--require-colcon` 将包发现改为强制检查。
- `--skip-package-check` 完全跳过 ROS 包发现。

#### 其他选项

- 默认递归初始化 Git submodule；使用 `--skip-submodules` 可关闭。
- 所有写操作前都可通过 `--dry-run` 查看。
- `--help` 显示完整参数和安全规则。

#### 当前明确排除的内容

以下包已确认不进入 T265 + D435 Offboard 首版恢复、构建和集成范围，源码目录仅作为历史参考保留：

- `offboard_py`
- `cv_yolo_paddle_pkg`
- `opencv_cpp`

机器可读清单为仓库根目录的 `workspace.excluded_packages`。安装脚本不会恢复这些包，M1 构建脚本也会显式传入 `--packages-skip`。如需重新纳入，必须先更新排除清单、仓库清单、依赖和验收计划。

#### M1 最小构建

仓库恢复后，先打印 T265 + D435 + MAVROS 最小构建计划：

```bash
./Scripts/build/m1_build.sh --src-dir /path/to/ros2_ws/src --output-root /path/to/ros2_ws --print-plan
```

ROS 2 Foxy 上的 MAVROS 2.7.0 需要仓库内已审查的 `tf2_eigen.hpp` → `tf2_eigen.h` 兼容补丁。确认后执行：

```bash
./Scripts/build/m1_build.sh --src-dir /path/to/ros2_ws/src --output-root /path/to/ros2_ws --apply-patches
```

该脚本会清除继承的 ROS overlay，仅重新加载 `/opt/ros/foxy`，并构建 `mavros`、`vision_to_mavros`、`realsense2_camera`、`px4_bringup` 及其工作区依赖。它不会启动 ROS 节点或硬件。

#### 构建工作区

源码恢复后，在具备 Ubuntu 20.04、ROS 2 Foxy 和依赖包的环境中单独执行：

```bash
cd /path/to/ros2_ws
source /opt/ros/foxy/setup.bash
rosdep check --from-paths src --ignore-src
colcon build --symlink-install
source install/setup.bash
```

构建成功不等于可以启动完整 bringup 或进行 Offboard 飞行。

### 小车

脚本路径：

```bash
Scripts/installation/car_install.sh
```

当前文件为空，后续可在这里补充小车依赖拉取和构建流程。

## simulation

### 无人机仿真

脚本路径：

```bash
Scripts/simulation/uav_sim.sh
```

当前文件为空，后续可在这里补充 PX4 SITL、Gazebo、RealSense 仿真插件等启动流程。

## 常见检查

拉取依赖后可以检查目录：

```bash
find src -maxdepth 1 -type d
```

构建前确认 ROS 2 Foxy 环境：

```bash
source /opt/ros/foxy/setup.bash
echo $ROS_DISTRO
```

连接 PX4 后确认 DDS 话题：

```bash
ros2 topic list
ros2 topic list | grep fmu
```
