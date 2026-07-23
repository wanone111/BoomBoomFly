# 下一阶段任务

> 本计划以 2026-07-23 当前源码、配置和 Git 状态为依据；任务完成后把有效产物并入权威基线，并从本待办中移除完成条目。  
> 标记：`立即` 可在不连接硬件时开始；`硬件` 必须等待设备；`版本` 必须等待固件/依赖版本确认；`外部` 依赖仓库外资料或源码；`串行` 不允许与标明的任务并行。

## 下一阶段建议执行顺序

1. `P0-03` 获取并核验 PX4 firmware/board/参数/`dds_topics.yaml`。
2. `P1-01` 固化系统依赖、RealSense cache 和 `uav_common` 来源。
3. `P1-02` 在空输出目录完成分组构建与测试基线。
4. `P1-03` 修复并静态验证分级 launch；默认入口不得接管控制。
5. `P1-04` 建立 Offboard/vision/serial 无硬件测试门禁。
6. `P0-05` 修复 Offboard 安全状态机和控制权仲裁，并只在 SITL 验证。

`P0-03 → P1-01 → P1-02 → P1-03/P1-04 → P0-05` 为剩余硬主线。已完成的源码与控制权前置分别固化在 [源码基线](SOURCE_BASELINE.md)、[ADR-0001](adr/0001-dds-only-control-authority.md) 和 [控制权矩阵](CONTROL_AUTHORITY_MATRIX.md)。D435、T265 和雷达的资料准备可并行，但实际设备测试按阶段 2 串行执行。

## 阶段 0：仓库与依赖基线

### P0-03 — 固定 PX4 firmware、board 与参数基线

- **状态：** `NOT STARTED`；等待维护者提供 PX4-Autopilot/firmware、board、参数和 `dds_topics.yaml` 的只读来源。
- **优先级/标记：** P0；`版本`、`外部`、最终需 `硬件`；阶段 0。
- **目的/当前问题：** 仓库只证明 `px4_msgs v1.16.2`；实际固件、board、airframe、参数和 DDS topic 集未知。
- **步骤：** 获取固件 commit/tag、board target、submodule、参数快照、`dds_topics.yaml`、DDS transport、RC/Offboard/vision/low-battery failsafe。
- **影响文件/包：** 外部 PX4 基线、`px4_msgs`、`offboard_cpp` 和 DDS 配置。
- **输入/依赖：** 飞控维护者提供只读资料；参数导出须在安全维护窗口。
- **风险与硬件/安全：** 资料阶段无需硬件；现场只读且禁止 arm/set_mode/参数写入。
- **推荐验证命令：** 固件仓 `git describe --always --dirty`；后续只读导出参数和 `ros2 topic info -v /fmu/...`。
- **输出：** firmware/board/parameter manifest、消息差异表和 failsafe 基线。
- **验收标准：** 所需 `px4_msgs` 字段/type 与固件一致；所有安全参数有值、来源和恢复方法。
- **回滚/失败处理：** 保持 PX4/Offboard 禁用；在 SITL 候选版本继续软件工作。
- **建议责任角色：** PX4 firmware 负责人 + 飞行安全负责人。
- **可并行性：** 资料收集可与阶段 1 的非 PX4 静态工作并行；是阶段 3—6 的硬前置。

接续说明见 [handoff](handoff.md)。

## 阶段 1：无硬件静态验证和构建验证

### P1-01 — 固化外部依赖与构建环境

- **优先级/标记：** P1；`立即`、`外部`；阶段 1。
- **目的/当前问题：** 系统依赖和 RealSense firmware cache 临时化，`common` 未锁定，manifest 不完整。
- **步骤：** 固定 Ubuntu/ROS deb 版本和校验；为 RealSense cache 建 manifest；确定 `uav_common` 发布/嵌入方式；补依赖声明方案。
- **影响文件/包：** 构建脚本、manifest、`serial_driver`、RealSense/MAVROS 依赖。
- **输入/依赖：** [源码基线](SOURCE_BASELINE.md)。
- **风险与硬件/安全：** 不需要硬件；不要在生产机直接卸载/升级 SDK。
- **推荐验证命令：** `rosdep check --from-paths src --ignore-src`；`sha256sum <cached-artifacts>`；`cmake`/`ctest` 独立验证 `common`。
- **输出：** dependency lock、cache 校验清单、无绝对布局的 `common` 方案。
- **验收标准：** 新环境不依赖 `/tmp` 或未声明目录即可准备同一构建依赖。
- **回滚/失败处理：** 保存当前 sysroot/cache 校验，只做容器/临时环境试验，不改变生产机。
- **建议责任角色：** 构建/发布工程师。
- **可并行性：** 可与 `P1-04` 测试设计并行；必须先于 `P1-02` 完整验收。

### P1-02 — 空输出目录分组构建与测试基线

- **优先级/标记：** P1；`立即`；阶段 1。
- **目的/当前问题：** 只有 10 包历史 M1 证据，DDS/serial/全量未验证，旧 install 可能掩盖依赖。
- **步骤：** 新目录依次构建接口、serial、DDS、MAVROS/RealSense、导航/仿真 profile；启用 `BUILD_TESTING=ON`；重复两次。
- **影响文件/包：** 79 包，重点 `px4_msgs`、`offboard_cpp`、`vision_to_dds`、`serial_driver`。
- **输入/依赖：** [源码基线](SOURCE_BASELINE.md)、`P1-01`；依赖声明修正进入审批变更。
- **风险与硬件/安全：** 不需要硬件；只构建，不运行 Agent/节点。
- **推荐验证命令：** 采用 [构建状态](BUILD_AND_RUNTIME_STATUS.md#73推荐分组验证) 中的临时 `build/install/log` 命令；`colcon test-result --verbose`。
- **输出：** 每个 profile 的 package、环境、stdout/stderr、test result 和耗时。
- **验收标准：** 同一 lock 和环境连续两次从空目录通过；失败包无“被旧 overlay 掩盖”。
- **回滚/失败处理：** 缩小到首个失败依赖；保留日志，不在现有 `build/install` 上修补。
- **建议责任角色：** ROS 2 构建负责人 + 包 owner。
- **可并行性：** profile 可在独立 runner 并行；同一源码基线不得边构建边改动。

### P1-03 — 建立安全分级 launch 并清除失效引用

- **优先级/标记：** P1；`立即`；阶段 1。
- **目的/当前问题：** 根 launch 引用缺失文件/包/executable，且默认触碰真实硬件并用固定延时。
- **步骤：** 设计 `offline`、`single_device`、`px4_readonly`、`sitl`、`bench`、`production` profile；修正依赖；readiness/lifecycle 取代 TimerAction。
- **影响文件/包：** `px4_bringup`、RealSense/vision launch、Offboard launch。
- **输入/依赖：** [ADR-0001](adr/0001-dds-only-control-authority.md)、[控制权矩阵](CONTROL_AUTHORITY_MATRIX.md)、`P1-02`；本轮之后另行授权修改 launch。
- **风险与硬件/安全：** 前期不需要硬件；默认 profile 不允许 arm、set_mode、setpoint 或打开串口。
- **推荐验证命令：** `ros2 launch <pkg> <file> --show-args`；launch_testing 检查 `FindPackageShare`、文件、executable。
- **输出：** profile 矩阵、依赖图、静态解析与失败阻断测试。
- **验收标准：** 每个入口可解析；默认无硬件/无控制；依赖未 ready 时控制节点不启动。
- **回滚/失败处理：** 保留新 profile 为实验入口，继续禁用旧 `start_all`。
- **建议责任角色：** bringup 负责人 + 安全评审人。
- **可并行性：** 可与 `P1-04` 并行；生产 profile 验收必须串行等待 P0 关闭。

### P1-04 — 建立无硬件安全测试与 CI

- **优先级/标记：** P1；`立即`；阶段 1。
- **目的/当前问题：** Offboard/vision/bringup/serial 的关键逻辑几乎没有测试，根无 CI。
- **步骤：** Offboard fake clock/topic/ACK harness；vision 纯坐标+静态 TF；serial codec+PTY；launch 存在性；sanitizer；CI build/test/result。
- **影响文件/包：** `offboard_cpp`、两个 vision 包、`serial_driver`、`px4_bringup`、CI。
- **输入/依赖：** [源码基线](SOURCE_BASELINE.md)；接口测试设计可先行。
- **风险与硬件/安全：** 不需要硬件；mock 使用独立 ROS domain，生产不安装危险 RC mock。
- **推荐验证命令：** `colcon test --packages-select offboard_cpp vision_to_dds vision_to_mavros serial_driver px4_bringup`；`colcon test-result --verbose`。
- **输出：** 测试矩阵、故障夹具、CI 结果和 sanitizer 日志。
- **验收标准：** 首帧、NaN、越界、超时、ACK 拒绝、TF freeze、碎片/粘包、断连均有断言。
- **回滚/失败处理：** 测试以独立 target 加入，不改变生产默认；失败即阻止上板。
- **建议责任角色：** 测试负责人 + 各包 owner。
- **可并行性：** 各包夹具可并行；SITL 门禁等待 `P0-03`。

## 阶段 2：单设备硬件验证

### P1-05 — D435 单机基线

- **优先级/标记：** P1；`硬件`；阶段 2。
- **目的/当前问题：** 只有旧 Jetson 15 Hz PASS/30 Hz WARN；当前设备、SDK 和 profile 未确认。
- **步骤：** 绑定序列号；USB3/权限；15 Hz → 30 Hz；CameraInfo/TF；再逐项 alignment/pointcloud；记录告警和资源。
- **影响文件/包：** `librealsense2`、`realsense2_camera`、后续 D435 参数。
- **输入/依赖：** `P1-01`、`P1-03` 单设备 profile；设备台账。
- **风险与硬件/安全：** 需要 D435；不启动 PX4/MAVROS/Offboard。
- **推荐验证命令：** 未来在专用 profile 使用 `rs_launch.py`；`ros2 topic hz`、`topic info -v`、`tf2_echo`、`lsusb -t`。
- **输出：** 序列/USB/profile、频率、TF、告警、CPU/内存/带宽报告。
- **验收标准：** 目标 profile 长时稳定，无 reset；频率/数据/TF 达标；SDK 来源唯一。
- **回滚/失败处理：** 回到旧已知 640×480@15、关闭 alignment/pointcloud。
- **建议责任角色：** 视觉硬件负责人。
- **可并行性：** 资料准备可并行；实际 USB 资源测试建议与 T265 串行。

### P1-06 — T265 单机与坐标标定

- **优先级/标记：** P1；`硬件`；阶段 2。
- **目的/当前问题：** 旧报告有 pose/IMU；当前序列、安装方向、TF/reset/时间未冻结。
- **步骤：** 只启 pose，再加 gyro/accel；绑定序列；静止与逐轴移动；检查 reset/relocalization、TF age 和长时漂移。
- **影响文件/包：** `realsense2_camera`、两个 vision 桥的 frame/rotation 参数。
- **输入/依赖：** [ADR-0001](adr/0001-dds-only-control-authority.md) 选定视觉路径；`P1-03` 单设备 profile。
- **风险与硬件/安全：** 需要 T265；不连接 PX4 视觉输入。
- **推荐验证命令：** `ros2 topic hz /tracking/pose/sample`；`tf2_echo <target> <source>`；受控 bag 记录。
- **输出：** 安装外参、轴向/量纲、reset、频率、延迟和漂移报告。
- **验收标准：** 坐标契约可由已知运动复核；TF 唯一；冻结/重定位可被检测。
- **回滚/失败处理：** 保留原始 T265 topic，只读记录，不启用视觉桥。
- **建议责任角色：** 定位/标定负责人。
- **可并行性：** 算法/测试可与 D435 并行；同 USB 主机现场建议串行。

### P1-07 — MCU 串口协议与安全链

- **优先级/标记：** P1；`硬件`、`外部`；阶段 2。
- **目的/当前问题：** 对端是否 STM32 未确认；协议无版本/watchdog/reconnect，路径不稳定。
- **步骤：** 先 codec/PTY；获取 MCU 固件；定义协议版本、端序、缩放、CRC、heartbeat/watchdog；执行器断电连接实物。
- **影响文件/包：** `serial_driver`、`uav_common`、外部 MCU firmware。
- **输入/依赖：** [源码基线](SOURCE_BASELINE.md)、`P1-04`；对端资料。
- **风险与硬件/安全：** 最终需要 MCU；执行器物理断电，禁止首次测试直接发布运动命令。
- **推荐验证命令：** codec unit tests、PTY 集成测试；现场只读串口诊断和 golden frames。
- **输出：** wire spec、golden frame、stable device ID、断线/超时矩阵。
- **验收标准：** 所有帧切分/粘包/校验错安全处理；失联在阈值内输出安全值；重连受控。
- **回滚/失败处理：** 保持串口节点禁用，使用离线捕获/loopback。
- **建议责任角色：** 嵌入式/串口负责人。
- **可并行性：** 纯软件部分可与相机任务并行；实物链独立串行。

### P2-01 — RPLIDAR 单机基线

- **优先级/标记：** P2；`硬件`；阶段 2。
- **目的/当前问题：** 型号/transport 未确认；launch 默认 `ttyUSB0`；udev 权限过宽且未采用 symlink。
- **步骤：** 识别型号；选择 serial/TCP/UDP；建立 stable name/IP；只验证 `scan`、frame、频率、量程和断连。
- **影响文件/包：** `rplidar_ros`、未来项目参数/udev。
- **输入/依赖：** 设备台账；`P1-03` 单设备 profile。
- **风险与硬件/安全：** 需要雷达；不启动 Nav/控制。
- **推荐验证命令：** 对应型号 launch；`ros2 topic hz /scan`、`topic info -v /scan`；网络型号先只读检查路由。
- **输出：** 型号/firmware/transport、stable ID、scan/TF 报告。
- **验收标准：** 三次重插/重启映射一致；频率/量程/方向达标；无 0777 依赖。
- **回滚/失败处理：** 停止节点，回到设备枚举和厂商工具；不尝试随机 baud。
- **建议责任角色：** 雷达/导航负责人。
- **可并行性：** 可与视觉报告分析并行；`ttyUSB0` 设备测试必须串行。

## 阶段 3：PX4 通信链路验证

### P0-04 — DDS 只读通信与接口核验

- **优先级/标记：** P0；`硬件`、`版本`、`串行`；阶段 3。
- **目的/当前问题：** Agent transport 和实机 topic 集未知，消息/时间/QoS 未验证。
- **步骤：** 显式配置 Agent；只建立 `/fmu/out/*` 遥测；核对 type hash/QoS/rate/namespace/time，不发布 `/fmu/in/*`。
- **影响文件/包：** Agent、`px4_msgs`、未来 DDS bringup。
- **输入/依赖：** [ADR-0001](adr/0001-dds-only-control-authority.md) 已确定 DDS-only；还依赖 `P0-03`、`P1-02/P1-03`。
- **风险与硬件/安全：** 需要 PX4，拆桨；禁止 arm、mode、setpoint、vehicle command。
- **推荐验证命令：** `ros2 topic list -t`；`ros2 topic info -v /fmu/out/vehicle_status`；`ros2 topic hz`。
- **输出：** transport、topic/type/QoS/frequency/time 表。
- **验收标准：** 所需遥测稳定、版本一致；断 Agent 可检测并恢复；无 `/fmu/in/*` publisher。
- **回滚/失败处理：** 断开 Agent，保留日志；不切换到 MAVROS 同时测试。
- **建议责任角色：** DDS/PX4 负责人 + 安全监督。
- **可并行性：** 唯一 PX4 通信验证任务；不得同时启动任何旧 MAVROS 路径。

## 阶段 4：感知与控制链路集成

### P1-09 — 单一路视觉注入与控制前数据验证

- **优先级/标记：** P1；先 `立即` 离线，后 `硬件`、`串行`；阶段 4。
- **目的/当前问题：** DDS 视觉的 ENU/NED、FLU/FRD、时间戳、质量/协方差尚未闭环。
- **步骤：** 抽纯变换测试；bag/SITL 对测；只启 `vision_to_dds_node` 注入 PX4，保持非 Offboard；检查 EKF 接受、reset、age、漂移。
- **影响文件/包：** `vision_to_dds`、T265 参数、PX4 EKF 参数。
- **输入/依赖：** [ADR-0001](adr/0001-dds-only-control-authority.md)、`P0-03`、`P1-06`、`P0-04`。
- **风险与硬件/安全：** 离线无需；最终需 T265+PX4，拆桨且不进入 Offboard。
- **推荐验证命令：** unit tests、bag replay、`tf2_echo`、`/fmu/in/vehicle_visual_odometry` 的 publisher/age 检查。
- **输出：** 坐标/时间契约、EKF acceptance、reset/freeze 故障报告。
- **验收标准：** 唯一 publisher；逐轴正确；age/quality/covariance 达标；失效时 EKF/上层可检测。
- **回滚/失败处理：** 停止视觉注入，只保留相机/TF 记录。
- **建议责任角色：** 定位算法负责人 + PX4 estimator 负责人。
- **可并行性：** 离线算法可并行；实机注入严格单路径串行。

## 阶段 5：安全机制与异常恢复

### P0-05 — 修复 Offboard 安全状态机与命令仲裁

- **优先级/标记：** P0；`立即` 软件、`串行`；阶段 5。
- **目的/当前问题：** 未初始化、RC 语义、mock、自动 arm、ACK、freshness、finite/frame、owner 和降级缺陷。
- **步骤：** 修复初始化/首帧；正确 RC；参数约束；默认不 arm；ACK/状态门；owner/lease；输入 finite/range/frame；确定性退化。
- **影响文件/包：** `offboard_cpp`、内部控制接口、配置和 tests。
- **输入/依赖：** [ADR-0001](adr/0001-dds-only-control-authority.md)、`P0-03`、`P1-04` 测试夹具。
- **风险与硬件/安全：** 开发无需硬件；验证先 unit/SITL，实机只到后续拆桨台架。
- **推荐验证命令：** `colcon test --packages-select offboard_cpp`；sanitizer；SITL 故障矩阵。
- **输出：** 状态机规范、测试、owner 诊断、ACK/timeout/降级日志。
- **验收标准：** 无首帧/NaN/断流/RC loss/ACK拒绝/低电/多发送者时不误 arm，且进入预定义安全状态。
- **回滚/失败处理：** 控制包保持不可安装/不可由生产 launch 启动。
- **建议责任角色：** 飞控控制负责人 + 独立安全审查人。
- **可并行性：** 单元实现可分模块；状态机、仲裁和接口变更需同一评审串行合并。

### P1-10 — 断线、重连与 PX4 failsafe 联合验证

- **优先级/标记：** P1；先 SITL，后 `硬件`、`串行`；阶段 5。
- **目的/当前问题：** Agent/MAVLink/T265/RC/battery/serial 断线恢复和参数级 failsafe 未形成矩阵。
- **步骤：** 故障注入；核对 `COM_OF_LOSS_T` 等实际版本参数；验证上层状态、PX4 行为、恢复条件和人工接管。
- **影响文件/包：** Offboard、vision、MAVROS/DDS、serial、PX4 参数。
- **输入/依赖：** `P0-05`、`P0-03`；SITL 基线。
- **风险与硬件/安全：** SITL 先行；实机拆桨台架，执行器隔离。
- **推荐验证命令：** 自动故障测试脚本；按矩阵 kill/restart/断 topic；记录 PX4 status/ACK/diagnostics。
- **输出：** fault-injection matrix、恢复时序、人工接管和停止条件。
- **验收标准：** 每种故障有唯一安全结果；恢复不自动 arm；状态与 PX4 一致；无无限重试风暴。
- **回滚/失败处理：** 停止升级验证等级，回到 SITL 重现。
- **建议责任角色：** 安全测试负责人 + PX4/控制负责人。
- **可并行性：** 各故障脚本可开发并行；执行和结论必须按风险阶梯串行。

## 阶段 6：系统级联调

### P1-11 — 阶梯式系统联调与 soak

- **优先级/标记：** P1；`硬件`、`串行`；阶段 6。
- **目的/当前问题：** 无全系统 USB/CPU/内存/时延/失效数据。
- **步骤：** 基线 → T265 → D435 → RPLIDAR → MCU → PX4只读 → 视觉 → SITL控制 → 拆桨台架；每步 2 h soak 和故障恢复。
- **影响文件/包：** 所有已选生产模块。
- **输入/依赖：** 阶段 0—5 对应门禁全部通过。
- **风险与硬件/安全：** 需要全套硬件；执行器隔离，任何失败不增加下一模块。
- **推荐验证命令：** `ros2 topic hz/bw/info -v`、系统资源/内核日志、诊断和 fault scripts；不得使用旧 `start_all`。
- **输出：** 资源预算、频率/age、USB/串口/TF、恢复和稳定性报告。
- **验收标准：** 2 h 内资源有界、无 USB reset/内存线性增长；单故障可诊断恢复；安全门不被绕过。
- **回滚/失败处理：** 移除最后加入模块，回到上一个已通过组合。
- **建议责任角色：** 系统集成负责人 + 现场安全官。
- **可并行性：** 不允许；严格阶梯串行。

## 阶段 7：部署、回归和文档冻结

### P2-02 — 发布、回归、部署与文档冻结

- **优先级/标记：** P2；软件 `立即` 可设计，最终 `硬件`、`外部`；阶段 7。
- **目的/当前问题：** 无 release manifest、systemd 安全分层、日志轮转、冷启动回滚和回归清单。
- **步骤：** 版本/参数/设备 manifest；CI/SITL/bench 回归；默认只读服务；控制需显式授权；日志/诊断/回滚；冻结当前文档。
- **影响文件/包：** 仓库发布资产、部署配置、所有 production profile 和 `docs/`。
- **输入/依赖：** `P1-11` 通过；所有 P0/P1 关闭。
- **风险与硬件/安全：** 模板设计无需；冷启动需全系统、拆桨/执行器隔离；系统级安装另行审批。
- **推荐验证命令：** `systemd-analyze verify <unit>`；完整 `colcon test-result`；release manifest SHA 校验；冷启动检查表。
- **输出：** release manifest、SBOM/依赖 lock、unit、logrotate、回归报告、回滚手册和冻结文档。
- **验收标准：** 新机可复现；默认启动不 arm；失败可诊断；上一 release 可一键回滚；文档链接和状态一致。
- **回滚/失败处理：** 禁用新服务，回滚上一 release；控制服务保持 disabled。
- **建议责任角色：** 发布/运维负责人 + 安全负责人 + 文档维护者。
- **可并行性：** 文档/模板可并行；正式发布验收严格串行。

## 状态标签汇总

| 标签 | 任务 |
|---|---|
| 可以立即执行 | `P1-01`、`P1-02`（前置满足后）、`P1-03`、`P1-04`、`P0-05` 软件部分 |
| 必须等待硬件 | `P1-05`、`P1-06`、`P1-07` 实物、`P2-01`、`P0-04`、`P1-09` 实机、`P1-10` 台架、`P1-11`、`P2-02` 冷启动 |
| 必须等待版本确认 | `P0-03`、`P0-04`、`P1-09`、`P0-05` 的 PX4 接口部分 |
| 存在外部依赖 | `P0-03`、`P1-01`、`P1-07`、`P2-02` |
| 不允许并行执行 | DDS/MAVROS 同飞控验证；两条视觉注入；阶段 6 阶梯；阶段 7 正式发布；所有从 SITL 到实机的风险升级 |
