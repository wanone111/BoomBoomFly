# DDS-only 源码基线与恢复说明

> P0-01 状态：**完成；15 项 DDS-only 精确核心已通过 clean 验证。**  
> 决策时间：2026-07-23（Asia/Shanghai）

## 1. 维护者决策

本轮已由维护者确认：

1. 后续只保留 PX4 uXRCE-DDS 路径，不保存或恢复 MAVROS。
2. `offboard_cpp` 跟随 `BoomBoomFly/offboard_cpp` 的最新 `DDS` 分支。
3. 旧 `serial-ros2`、`serial_driver_ros2`、`serial_driver_ros` 和工作区外旧 `common` 不再保留为 BoomBoomFly 依赖。
4. 后续串口代码来自同级仓库 `/home/aa/px4_ws/communication`。
5. `communication` 不锁定 SHA，始终跟随最新 `main`。

因此，P0-01 的可恢复性分为：

- **精确核心：** `workspace.lock.repos` 中 15 个 DDS-only 仓库。
- **移动外部依赖：** `workspace.repos` 中的 `../communication @ main`。它可以获取，但按维护者决策不保证跨时间字节级复现。

## 2. 精确 lock

2026-07-23 通过本地 Git 对象、origin 和 HEAD 核验；Offboard 的远端分支另以只读 `git ls-remote` 核验。

| 路径 | 来源 | 锁定 SHA |
|---|---|---|
| `src/px4_msgs` | `PX4/px4_msgs` | `392e831c1f659429ca83902e66820d7094591410` |
| `src/Micro-XRCE-DDS-Agent` | `eProsima/Micro-XRCE-DDS-Agent` | `57d086216d01ec43121845d385894a25987f8a2c` |
| `src/gazebo_ros_pkgs` | `ros-simulation/gazebo_ros_pkgs` | `b6f7bf121d0c607825b65a28b227a5459a71821b` |
| `src/imu_tools` | `ccny-ros-pkg/imu_tools` | `d28555e487e4c1278c9a2e94143dc79dcc8941bf` |
| `src/librealsense` | `IntelRealSense/librealsense` | `c94410a420b74e5fb6a414bd12215c05ddd82b69` |
| `src/navigation2` | `ros-navigation/navigation2` | `ca482808a7a7c52ce01ae3c662dc2b980968fc16` |
| `src/navigation_msgs` | `ros-planning/navigation_msgs` | `fe880e99d993e9d4dfbf37f00d839d32994610e1` |
| `src/offboard_cpp` | `BoomBoomFly/offboard_cpp` | `8925f8ae82258fb9f1378543f1a0dea16c15a282` |
| `src/realsense-ros` | `IntelRealSense/realsense-ros` | `8abb4657c0add15f87b0edbfb67eaba2c1c2c439` |
| `src/rplidar_ros` | `Slamtec/rplidar_ros` | `24cc9b6dea97e045bda1408eaa867ce730fd3fc3` |
| `src/rtabmap` | `introlab/rtabmap` | `0070de4aafab0feaf5e37b497b1354d2264d41c8` |
| `src/rtabmap_ros` | `introlab/rtabmap_ros` | `b341e2a776a743b8d6741b8aae8ab560471cd966` |
| `src/slam_toolbox` | `SteveMacenski/slam_toolbox` | `4786e90c06a4dc6fa811c5057d4e88387fba3829` |
| `src/vision_opencv` | `ros-perception/vision_opencv` | `72152d9d1d8edcfcafd707a1d0103810db8613ba` |
| `src/vision_to_dds` | `wanone111/vision_to_dds` | `0c3a00137f3c90a4051ac1bc1029ec56beb669b6` |

`workspace.lock.repos` 中所有 `version` 均为 40 位 SHA。`vision_to_dds` 已从本地额外仓库变成正式锁定项。

## 3. Moving refs

| 路径 | 来源 | 分支 | 2026-07-23 远端 HEAD | 策略 |
|---|---|---|---|---|
| `src/offboard_cpp` | `BoomBoomFly/offboard_cpp` | `DDS` | `8925f8ae82258fb9f1378543f1a0dea16c15a282` | 维护清单跟随分支；部署 lock 固定核验时 SHA |
| `src/vision_to_dds` | `wanone111/vision_to_dds` | `main` | 本地/缓存 `0c3a00137...` | 维护清单跟随；部署 lock 固定 |
| `../communication` | `wanone111/communication` | `main` | `df256c180dbd4167f879b697e38d547521f1f8e2` | 明确不锁定；每次使用记录实际 HEAD |

`communication` 当前本地工作树是 dirty，且其中两个 ROS 2 串口目录是未跟踪的嵌套 Git 仓库。它们不在远端 `main @ df256c18...` 中。按维护者决策，本轮不把这些本地内容打包进 BoomBoomFly；`communication` 自身的整理和发布由其仓库单独负责。

## 4. 已退出受管组合

以下仓库/包不再出现在 DDS-only manifest：

| 退出项 | 原因 | 本地目录处理 |
|---|---|---|
| `mavlink`、`mavros` | 维护者决定不再保存 MAVROS 路径 | 可能仍在当前 `src/`；不恢复、不构建 |
| `ros2_foxy_vision_to_mavros` | 只服务旧 MAVROS 视觉链 | 同上 |
| `px4_bringup` | 当前实现完全编排 MAVROS，且入口失效 | 同上；不得运行 |
| `serial-ros2`、旧 `serial_driver*` | 后续统一转向 `communication` | 同上；不保存现有 dirty 内容 |
| `/home/aa/px4_ws/common` | 只被退出的旧 serial 组合使用 | 不进入 BoomBoomFly manifest |

已有 `patches/mavros/foxy_tf2_eigen_h.patch` 已按维护者要求删除。当前本地第三方仓库中的改动和缓存不会被打包为恢复资产。

本轮没有递归删除上述本地嵌套仓库，避免在基线治理中执行不必要的破坏性清理。判断“是否属于基线”只以 manifest 为准。

## 5. 当前本地差异

| 位置 | 当前情况 | 是否进入基线 | 处理 |
|---|---|---|---|
| `src/offboard_cpp` | HEAD 与远端 `DDS` 一致；当前 clean | 是 | 已通过 exact verify |
| `../communication` | HEAD 与远端 `main` 一致；tracked 删除/修改及未跟踪嵌套仓库 | 不锁定、不打包 | moving dependency；同步前由其 owner 处理 |
| 本地 MAVROS/旧 serial 目录 | 仍可能存在且 dirty | 否 | 视为本地遗留，不参与恢复验证 |
| 其余 14 个 lock 仓库 | path、origin、HEAD、clean 匹配 | 是 | 已通过本地只读核验 |

验收前曾存在两处 Offboard 本地修改：

- `src/lib/CtrlFSM.cpp`：`ARMING_STATE_STANDBY` → `ARMING_STATE_DISARMED`
- `src/lib/input.cpp`：`voltage_filtered_v` → `voltage_v`

维护者要求 Offboard 跟随最新仓库，并明确批准丢弃上述修改及未跟踪 `.codex/`。处理后 `src/offboard_cpp` clean，未生成补丁或备份。

## 6. 恢复流程

### 6.1 精确 DDS 核心

```bash
cd /home/aa/px4_ws/BoomBoomFly
bash Scripts/installation/uav_px4_dds_install.sh \
  --dry-run \
  --skip-package-check

bash Scripts/installation/uav_px4_dds_install.sh
```

只读核验：

```bash
bash Scripts/installation/uav_px4_dds_install.sh \
  --verify-only \
  --skip-package-check
```

### 6.2 跟随维护分支和 communication

```bash
bash Scripts/installation/uav_px4_dds_install.sh \
  --manifest workspace.repos \
  --allow-moving-refs \
  --dry-run \
  --skip-package-check
```

确认计划后去掉 `--dry-run`。moving 模式不是可复现实验入口；每次必须保存：

```bash
git -C src/offboard_cpp rev-parse HEAD
git -C ../communication rev-parse HEAD
```

### 6.3 安全规则

- dirty 仓库不会被 checkout、reset 或覆盖。
- origin 不一致会停止。
- lock HEAD 不一致时默认停止。
- manifest 只允许 `src/*` 和唯一外部路径 `../communication`。
- `communication` 不会被默认精确 lock 恢复。
- 恢复源码不会构建、启动节点或访问硬件。

## 7. 更新 lock 的流程

1. 只读查询 `offboard_cpp/DDS` 和其他 moving ref 的远端 HEAD。
2. 在隔离工作区审查变更；不得在飞行工作区直接追新。
3. 更新 `workspace.lock.repos` 的 URL/SHA。
4. 确认 15 个 lock 条目全是 40 位 SHA、路径无重复、URL 唯一。
5. 执行 `bash -n` 和两种 manifest 的 dry-run。
6. 在空输出目录执行 P1-02 分组构建与测试。
7. 记录 `communication` 当次 HEAD，但不写入 lock。

## 8. 本轮验证结果

| 检查 | 结果 |
|---|---|
| 安装脚本 shell 语法 | PASS |
| lock 条目数 | PASS：15 |
| moving manifest 条目数 | PASS：16 |
| lock SHA 格式 | PASS：15/15 为 40 位 SHA |
| 路径约束 | PASS：`src/*` + 唯一 `../communication` |
| lock dry-run | PASS：15 项计划可恢复 |
| 当前 exact `--verify-only` | PASS：15 verified，0 blockers |
| moving dry-run | 15 PASS，1 BLOCK：本地 communication dirty；属于其仓库待处理状态 |
| Offboard 远端最新 SHA | PASS：远端 `DDS` 与当前 HEAD 均为 `8925f8ae...` |
| communication 远端最新 SHA | PASS：`main` 为 `df256c18...` |
| 构建/测试/硬件 | 未执行；不属于 P0-01 |

## 9. P0-01 验收状态

- 源码来源决策：完成。
- DDS-only manifest：完成。
- 精确核心 lock：完成。
- Moving communication 例外：已记录并由维护者确认。
- 旧 MAVROS/serial/common 退出：完成。
- 恢复脚本与说明：完成。
- 当前本机 exact verify：完成，15 项全部 path/origin/HEAD/clean 匹配。
- P0-01：**完成**。

剩余的 `communication` dirty 不影响精确核心验收；它是维护者明确不锁定的独立 moving 仓库，由其 owner 在使用 moving 同步前处理。
