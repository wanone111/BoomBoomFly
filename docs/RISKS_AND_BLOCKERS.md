# 风险与阻塞项

> 严重度：P0 安全或架构阻塞；P1 上板前必须解决；P2 集成阶段必须解决；P3 质量和维护性改进。  
> “当前是否已发生”只描述静态代码/仓库状态，不推断实机事故。

## P0：安全或架构阻塞

### R-P0-01 — 无权威控制路径和跨传输仲裁

- **风险描述：** P0-02 已冻结 DDS-only、单控制 writer、单视觉 writer 和单 mission owner；但源码尚未实现 owner/lease、graph guard 和项目级 Agent/控制 bringup。
- **证据位置：** `src/offboard_cpp/src/node.cpp:21-89`；`src/px4_bringup/launch/include/px4_fly.launch.py`；MAVROS plugin 配置；[架构总览](ARCHITECTURE_OVERVIEW.md)。
- **影响范围：** PX4 mode、arming、trajectory、外部视觉与所有 Offboard 测试。
- **触发条件：** MAVROS 和 DDS 同连一台 PX4，或多个内部命令发布者同时运行。
- **当前是否已发生：** 架构决策冲突已关闭；运行时强制缺失和内部多发布者风险仍存在，实机竞争未验证。
- **建议措施：** 按 [ADR-0001](adr/0001-dds-only-control-authority.md) 实现 profile 隔离、owner/lease/序列、publisher 诊断和 fail-closed graph guard。
- **验收标准：** 静态 launch 图和运行图均证明同一时刻只有一个可达 PX4 的控制源；第二 owner 请求被拒并记录。

### R-P0-02 — PX4、`px4_msgs` 与 Offboard 版本未闭环

- **风险描述：** 当前 `px4_msgs v1.16.2`，但实际 PX4 固件缺失；`offboard_cpp` 文档仍按 1.14.3，工作树还有未提交 v1.16 字段修补。
- **证据位置：** `workspace.lock.repos:2-9`；`src/offboard_cpp/README.md:11,29-50`；`src/offboard_cpp/src/lib/input.cpp`、`CtrlFSM.cpp` 的工作树 diff。
- **影响范围：** `/fmu/*` type、字段、RC/battery/land topics、时间戳和模式状态。
- **触发条件：** 使用与消息定义不一致的固件或恢复 lock 中旧 Offboard。
- **当前是否已发生：** 文档/源码/lock 分歧已发生；实机消息不匹配未验证。
- **建议措施：** 获取 firmware commit、board、参数、`dds_topics.yaml`；逐消息比对；冻结 Offboard 权威 commit 和兼容补丁。
- **验收标准：** 固件与 `px4_msgs` 来源可复现；所需消息/字段/type hash 一致；干净源码无需本地临时修补。

### R-P0-03 — Offboard 输入初始化、RC 语义和自动解锁不安全

- **风险描述：** 多个 RC/Odom/land 成员未初始化；首帧判断失效；未收到数据在启动约 0.5 s 内被判新鲜；v1.16 RC `-1..1` 被按 PWM 解析；`TEXT_RC` 无条件启用；自动 arm 默认开启。
- **证据位置：** `src/offboard_cpp/include/lib/input.hpp:46-168`；`src/offboard_cpp/src/lib/input.cpp:6-15,37-66,117-151,238-251`；`CMakeLists.txt:29-35`；`config/ctrl_param.yaml:11-16`。
- **影响范围：** RC 接管、起飞、状态机转移、位置跳变和所有实机控制。
- **触发条件：** 节点启动、首帧、通道配置错误、ROS 参数修改、无 RC 起飞请求。
- **当前是否已发生：** 缺陷静态存在；实机误动作未验证。
- **建议措施：** 完整初始化和显式 `received` 标志；按消息语义解析并校验 channel_count/signal_lost；移除生产 mock 编译；默认禁止自动 arm；加入 preflight/safety/failsafe/ACK 门。
- **验收标准：** 无首帧、错误 RC、错误参数、preflight false、ACK 拒绝等测试中永不 arm/切模；sanitizer 无未初始化或越界。

### R-P0-04 — 仓库与外部依赖无法由 lock 重建

- **风险描述：** P0-01 已形成并验证 15 项 DDS-only 精确 lock；`communication/main` 是维护者明确接受的不锁 SHA 例外。
- **证据位置：** `workspace.lock.repos`；`workspace.repos`；[源码基线](SOURCE_BASELINE.md)。
- **影响范围：** 构建、部署、回滚、代码审查和故障复现。
- **触发条件：** 新主机恢复、执行安装脚本 `--update`、清理 dirty 仓库。
- **当前是否已发生：** 精确核心已关闭；communication 不可跨时间复现是已接受、需持续记录的残余风险。
- **建议措施：** 每次实验记录 communication 实际 HEAD；串口发布由 communication 仓库独立治理。
- **验收标准：** 15 项 lock 在空目录恢复并 clean 匹配；communication 来源/分支可获取且当次 HEAD 被记录；无未声明旧 `common`/serial 依赖。

### R-P0-05 — 当前主 bringup 失效且默认触碰真实硬件

- **风险描述：** `start_all_2025TI` 引用不存在的 T265 launch、已排除感知包和不存在的 `2025_Ti_main_node`，同时计划打开相机、PX4 串口、自定义串口和控制。
- **证据位置：** `src/px4_bringup/launch/start_all_2025TI.launch.py`；`serial_and_image_2025TI.launch.py`；`include/px4_fly.launch.py`；`src/offboard_cpp/CMakeLists.txt:71-114`。
- **影响范围：** 启动、硬件占用、控制安全和现场排障。
- **触发条件：** 运行根 launch。
- **当前是否已发生：** 失效引用已存在；本轮未运行。
- **建议措施：** 保持禁用；拆分 offline/device/read-only/SITL/bench/production profile；readiness 取代固定延时；静态 launch tests。
- **验收标准：** 每个入口依赖可解析；默认入口不打开控制或真实设备；失败节点阻止下游安全关键节点启动。

## P1：上板前必须解决

### R-P1-01 — Offboard 状态机缺少完整确认和降级闭环

- **风险描述：** 不订阅 `VehicleCommandAck`；`VehicleStatus` 无 freshness；进入 Offboard 缺少可靠预发送/确认/重试；低电和降落状态有覆盖/退化问题。
- **证据位置：** `src/offboard_cpp/src/lib/CtrlFSM.cpp:105-337,614-739`；`src/offboard_cpp/src/node.cpp`。
- **影响范围：** mode/arm、起降、失联和低电保护。
- **触发条件：** PX4 拒绝命令、遥测断流、低电、降落中定位/RC 丢失。
- **当前是否已发生：** 逻辑缺口静态存在；运行后果未验证。
- **建议措施：** ACK/timeout/retry 状态；连续 setpoint 预发送；状态一致性检查；确定性 HOLD/LAND/退出 Offboard；PX4 参数级 failsafe 联动。
- **验收标准：** SITL 故障矩阵覆盖拒绝、断流、低电、land、RC loss；状态机和 PX4 nav/arming state 始终一致或进入定义的安全退化。

### R-P1-02 — 坐标系、时间戳、QoS 与视觉健康未验证

- **风险描述：** 两视觉桥 frame/旋转默认冲突；DDS 输出 FRD/NED 契约无测试；ROS/PX4 时钟关系未知；内部安全话题 best-effort；视觉 TF 冻结无健康门。
- **证据位置：** `src/vision_to_dds/src/vision_to_dds.cpp:24-31,78-121,262-350`；`vision_to_mavros.cpp:20-166`；`t265_tf_to_mavros_launch.py`；`offboard_cpp/src/node.cpp:21-24`。
- **影响范围：** PX4 EKF、位置控制、精降和失控保护。
- **触发条件：** 相机姿态变化、时钟偏差、TF freeze、QoS 不兼容、双视觉输入。
- **当前是否已发生：** 配置分歧已发生；实机误差未验证。
- **建议措施：** 纯函数坐标测试、bag/静态 TF 回放、逐轴现场标定、sample age/reset/quality/covariance 设计、逐端点 QoS 核对。
- **验收标准：** 静止和逐轴方向/尺度/yaw 正确；时间 age 在批准阈值内；冻结/重定位触发安全降级；只有一个 EKF 视觉输入。

### R-P1-03 — 自研安全关键路径缺少测试和 CI

- **风险描述：** Offboard 无功能测试；视觉只有 lint；bringup 无 launch test；serial 只测日志；根无 CI，M1 关闭测试。
- **证据位置：** 各自研包 `CMakeLists.txt`/`test/`；`Scripts/build/m1_build.sh:224,272-285`；根目录无 `.github/workflows`。
- **影响范围：** 所有修复的回归可信度和发布门禁。
- **触发条件：** 任何代码/配置变更。
- **当前是否已发生：** 已发生。
- **建议措施：** GTest/fake clock/topic harness、PTY、launch_testing、sanitizer、SITL 和 CI 分层矩阵。
- **验收标准：** `BUILD_TESTING=ON` 的 build/test/result 全绿；P0/P1 故障场景有自动断言；合并前 CI 强制执行。

### R-P1-04 — 串口无 watchdog、重连和健壮协议处理

- **风险描述：** `/cmd_vel` 停止后不发零速；端口失败/断开不重连；NaN/Inf/超量程和负 baud 未校验；碎片/粘包处理不完整。
- **证据位置：** `src/serial_driver_ros/src/serial_main.cpp:18-57`；`serial_driver.cpp:5-121`。
- **影响范围：** 外部 MCU/执行器、移动底盘或任何串口控制对端。
- **触发条件：** 上游停止、USB 重枚举、半帧/多帧、异常速度/参数。
- **当前是否已发生：** 缺陷静态存在；对端行为未验证。
- **建议措施：** cmd watchdog/零速、有限值/饱和、持久 parser、部分写、重连退避、协议版本/CRC/golden frame。
- **验收标准：** PTY 测试覆盖所有切分点、粘包、校验错、断线；超时在批准时间内发安全值；无未捕获异常。

### R-P1-05 — 设备路径、型号和权限未形成部署契约

- **风险描述：** `ttyUSB0` 被多个入口复用；PX4、RPLIDAR、MCU 未按 serial/VID/PID 稳定命名；相机未绑定序列号；网络雷达有固定 IP。
- **证据位置：** `px4_bringup/config/mavros_params.yaml`；`serial_driver_ros/config/serial_config.yaml`；`rplidar_ros/launch/`、`scripts/rplidar.rules`；RealSense launch。
- **影响范围：** 飞控、雷达、MCU、相机和多设备重启。
- **触发条件：** USB 顺序变化、换机、同型号多设备、现场网段变化。
- **当前是否已发生：** 硬编码已存在；现场冲突未验证。
- **建议措施：** 设备台账、stable symlink、最小权限、序列号绑定、IP 分配表、每机型参数文件。
- **验收标准：** 冷启动/重插后三次设备映射一致；错误设备不会被打开；权限无需 0777。

### R-P1-06 — 依赖声明和全量构建未闭环

- **风险描述：** 多包 manifest 缺依赖，`rtabmap_msgs` build type 异常，系统依赖/固件缓存临时化，旧 install 可能掩盖问题。
- **证据位置：** `px4_bringup/package.xml`、两个 vision manifest、`serial_driver` CMake、`rtabmap_msgs/package.xml`、历史 M1 报告。
- **影响范围：** 新主机、CI、79 包 build 和部署。
- **触发条件：** 空输出目录或干净主机构建。
- **当前是否已发生：** 声明问题已存在；完整构建结果未知。
- **建议措施：** 修正 manifest；锁定系统依赖与 RealSense cache；按 profile 从空目录连续构建。
- **验收标准：** 新环境仅凭文档/lock 完成两次相同 profile 构建；不引用旧 overlay 或 `/tmp` 临时资产。

## P2：集成阶段必须解决

### R-P2-01 — 视觉桥长期资源与空实现问题

- **风险描述：** 两桥 `Path.poses` 无界增长；TF 异常阻塞 1 秒；`output_rate` 无范围校验；MAVROS 精降只创建 publisher 不发布。
- **证据位置：** 两个 vision 源码的 `run()`、`publishVisionPositionEstimate()`、`precisionLandParameters()`。
- **影响范围：** 长时间定位延迟、内存、executor 响应和精降功能。
- **触发条件：** 长时运行、TF 失败、错误频率或启用精降。
- **当前是否已发生：** 代码缺口存在；资源增长未在当前环境量化。
- **建议措施：** 有界 ring buffer、非阻塞错误处理、rate 校验、stale health、删除或完成精降。
- **验收标准：** 2 小时 soak 中 RSS/pose age 有界；TF 故障不阻塞其他回调；功能声明与实际一致。

### R-P2-02 — 无项目级仿真、mock 和分级 smoke

- **风险描述：** PX4 SITL 源码/入口缺失，仿真脚本和 README 为空；`mock_rc_control.py` 未治理且能伪造安全输入。
- **证据位置：** `Scripts/simulation/uav_sim.sh`；`Simulator/`；`src/offboard_cpp/text/mock_rc_control.py`。
- **影响范围：** 无硬件验证、安全回归和新人操作。
- **触发条件：** 在没有台架时验证控制，或误把 mock 带入生产 domain。
- **当前是否已发生：** 已发生。
- **建议措施：** 隔离 test domain、明确 mock-only build/profile、SITL 与 bag/PTY smoke、生产包不安装危险 mock。
- **验收标准：** 无设备环境能运行核心 smoke；mock 无法在生产 profile/domain 被加载；SITL 作为控制合并门。

### R-P2-03 — RealSense 历史多版本与高负载未闭环

- **风险描述：** 旧 Jetson 报告有 SDK 2.50/2.56.5 多来源；D435 30 Hz WARN；alignment/pointcloud/双机负载未测。
- **证据位置：** [硬件集成状态](HARDWARE_INTEGRATION_STATUS.md#3-intel-realsense) 中提取的旧 Jetson 现场结论。
- **影响范围：** 视觉稳定性、ABI、USB/CPU/GPU 预算。
- **触发条件：** 重建、链接顺序变化、提高 profile、双相机/SLAM 并发。
- **当前是否已发生：** 历史环境发生；当前部署状态未知。
- **建议措施：** 唯一 SDK 来源；D435/T265 单机后逐项叠加，记录频率/带宽/告警/资源。
- **验收标准：** 目标平台依赖解析唯一；目标 profile 长时稳定；USB 无 reset，频率和资源在预算内。

## P3：质量和维护性改进

### R-P3-01 — 元数据、占位与顶层可见性不足

- **风险描述：** 空脚本/README、TODO license/description/maintainer、过宽 `.gitignore`，顶层 CI 看不到多数子仓变化。
- **证据位置：** `Scripts/installation/car_install.sh`、`Scripts/simulation/uav_sim.sh`、`Simulator/*/README.md`、自研 `package.xml`、`.gitignore`。
- **影响范围：** 维护、许可证、审查和发布质量。
- **触发条件：** 新成员使用占位入口、发布包、只看顶层 diff。
- **当前是否已发生：** 已发生。
- **建议措施：** 明确实现/归档/删除决策；补元数据；锚定 ignore 规则；增加多仓状态检查。
- **验收标准：** 无空白生产入口和 TODO 元数据；CI 报告每个受管仓的 HEAD/dirty；合法新目录不会被静默忽略。
