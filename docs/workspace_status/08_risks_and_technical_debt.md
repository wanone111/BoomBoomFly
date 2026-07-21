# Risks and technical debt

- Generated at: 2026-07-21T00:06:23+08:00
- Workspace: `/home/c/px4_ws`
- Branch: 不适用（多仓库工作区；根目录不是 Git 仓库）
- Commit: 不适用（多仓库工作区；根目录不是 Git 仓库）
- PX4 version: 未验证（PX4-Autopilot firmware 源码缺失）
- Working tree status: 9/19 个源码仓库 dirty；所有仓库 staged=0

## 汇总

| 等级 | 数量 | 含义 |
|---|---:|---|
| P0 | 0 | 未发现有充分证据可直接定为当前飞行事故/硬件损坏必然风险的问题 |
| P1 | 11 | 构建阻断、任务崩溃、控制异常或重要功能不可用 |
| P2 | 8 | 稳定性、兼容性、可维护性或验证不足 |
| P3 | 2 | 文档、生成物卫生与轻微质量问题 |

以下问题已跨 subagent 去重。“已验证（静态）”只表示源码证据确定，不表示已在飞行、SITL 或硬件上复现。

## P1

### R-001 — 固件审查与部署基线缺失

- ID：R-001
- 严重程度：P1
- 状态：已验证（范围）；固件功能未验证
- 标题：工作区不含 PX4-Autopilot 源码、版本和 board target
- 影响范围：固件构建、板级、参数、uORB/DDS、SITL、failsafe
- 文件路径：工作区根；缺失 `Makefile`、`boards/`、`ROMFS/`、`platforms/`、`src/modules/`
- 行号或符号：不适用
- 证据：根 Git 命令退出 128；PX4 特征路径逐项不存在；只有 ROS 2/MAVROS 包
- 影响：无法复现实际飞控固件，也无法证明 firmware/ROS 接口与 failsafe 匹配
- 建议：取得实际飞控所用 PX4 仓库、精确 commit/tag、board target、参数导出与 submodule 状态
- 验证方法：在独立固件树记录 `git describe`、submodule、board build 与参数快照

### R-002 — Offboard 构建入口含冲突标记

- ID：R-002
- 严重程度：P1
- 状态：已验证（静态）
- 标题：当前 `offboard_cpp` 无法可靠重新配置
- 影响范围：C++ Offboard 控制包
- 文件路径：`src/offboard_cpp/CMakeLists.txt`
- 行号或符号：125–134
- 证据：HEAD 内含 `<<<<<<< HEAD`、`=======`、`>>>>>>>`；现有二进制早于该文件
- 影响：干净 colcon build 被阻断；运行中的 install 可能是旧源码
- 建议：人工解析冲突并核对目标名；本次审查不修改源码
- 验证方法：空 build/install/log 环境执行 `colcon build --packages-select offboard_cpp`

### R-003 — 两个依赖包被整包删除

- ID：R-003
- 严重程度：P1
- 状态：已验证（Git）
- 标题：`map_msgs` 与 `image_geometry` tracked 内容被删除
- 影响范围：navigation/vision 依赖图与干净重建
- 文件路径：`src/navigation_msgs/map_msgs/`、`src/vision_opencv/image_geometry/`
- 行号或符号：整个包目录
- 证据：分别 13 与 17 个 tracked 删除；无 staged 变更
- 影响：依赖解析或下游编译可能失败，当前 install 可能掩盖缺失源码
- 建议：先确认删除意图；若非有意，在相应仓库恢复正确 revision
- 验证方法：清空隔离的生成目录后解析依赖并构建受影响包

### R-004 — 串口奇数 payload 越界读取

- ID：R-004
- 严重程度：P1
- 状态：已验证（静态）
- 标题：畸形但校验可通过的串口帧可触发越界
- 影响范围：自定义串口节点、禁飞区/GCS 数据
- 文件路径：`src/serial_driver_ros2/src/serial_driver.cpp`
- 行号或符号：`readFloatArrayResponse`，81–104
- 证据：未要求 `len` 为偶数；循环按两字节读取 `frame[j+1]`
- 影响：未定义行为、节点崩溃或错误控制数据
- 建议：限制长度、拒绝奇数 payload，并在每次读取前检查边界
- 验证方法：ASan/UBSan + len 1、3、255、截断/粘包 fuzz

### R-005 — 串口发送范围与协议缩放不一致

- ID：R-005
- 严重程度：P1
- 状态：已验证（静态）；STM32 协议兼容未验证
- 标题：长度回绕、浮点转 int16 与缩放删除可破坏 wire format
- 影响范围：伴随端↔STM32 命令/速度协议
- 文件路径：`src/serial_driver_ros2/src/serial_driver.cpp`；`src/serial_driver_ros2/src/serial_orinnano.cpp`
- 行号或符号：35–51、99–103；75–83
- 证据：任意长度强转 `uint8_t`；float 未做 finite/range 检查直接转 `int16_t`；本地 diff 删除 ×1000/÷1000 而注释未更新
- 影响：帧失步、小速度截断为 0、数量级错误或未定义转换
- 建议：版本化协议，限制数组项数和数值范围，显式拒绝/饱和，分开 ID 与定点速度编码
- 验证方法：127/128 项边界、极值/NaN 和 STM32 双向 golden-frame 测试

### R-006 — 单字节命令可触发飞行开始

- ID：R-006
- 严重程度：P1
- 状态：已验证（静态）；运行未验证
- 标题：`0x99` 经简单校验即可发布 `/start_flight=true`
- 影响范围：任务启动安全边界
- 文件路径：`src/serial_driver_ros2/src/serial_orinnano.cpp`
- 行号或符号：93–130
- 证据：缺少命令类型、序列、时效、重放保护和状态许可；只有 8 位加和校验
- 影响：噪声、重放或上位机错误可能推进安全关键状态
- 建议：增加显式命令帧、计数器/nonce、超时与状态机双重许可
- 验证方法：重放、位翻转、延迟帧与错误状态故障注入

### R-007 — 禁飞区输入未校验且飞行中不重规划

- ID：R-007
- 严重程度：P1
- 状态：已验证（静态）
- 标题：非法 ID 可越界；更新后的禁飞区可能仍被穿越
- 影响范围：路径规划与任务状态机
- 文件路径：`src/offboard_cpp/src/2025_Ti_main.cpp`
- 行号或符号：`no_fly_callback` 88–110；`plan_path` 123–133；control 408–487
- 证据：只检查数量为 3，不检查范围/唯一性；`grid[r][c]` 无防御；仅 mod 0 规划
- 影响：UB/崩溃，或飞行中禁飞区变更不生效
- 建议：双层验证合法集合与唯一性；任务中变化时 HOLD 并校验剩余路径/重规划
- 验证方法：非法/重复 ID 单测，SITL 航段中动态覆盖剩余航点

### R-008 — 遥测无新鲜度与有限值门控

- ID：R-008
- 严重程度：P1
- 状态：已验证（静态）；固件 failsafe 未验证
- 标题：陈旧或 NaN pose/velocity 可推动 Offboard 状态机
- 影响范围：解锁、起飞、航点、降落状态转换
- 文件路径：`src/offboard_cpp/src/lib/offboard_control_node.cpp`；`src/offboard_cpp/src/2025_Ti_main.cpp`
- 行号或符号：35–45、`reached_target` 73–79；376–380、392–508
- 证据：只复制值，无接收时间/received flag/`isfinite`；NaN 比较可能误判到达，且连接检查前转 map ID
- 影响：跳过航点、提前降落、错误解锁/起飞或状态机异常
- 建议：对 state/pose/velocity 记录时间和有效标志；连续新鲜且有限、估计器健康时才允许推进
- 验证方法：SITL 注入断流、陈旧时间戳、NaN/Inf 与 estimator invalid

### R-009 — LAND 异步请求风暴

- ID：R-009
- 严重程度：P1
- 状态：已验证（静态）
- 标题：Landing 状态以 20 Hz 无界发送 set_mode 请求
- 影响范围：Offboard executor、MAVROS 服务与着陆可观测性
- 文件路径：`src/offboard_cpp/src/2025_Ti_main.cpp`；`src/offboard_cpp/src/lib/offboard_control_node.cpp`
- 行号或符号：506–517；31、`land` 186–190
- 证据：mod 7 不转换；每 50 ms 新建 async request，无 readiness、future、response 或退避
- 影响：outstanding 请求增长、服务过载，模式拒绝原因不可见
- 建议：单次/有界退避请求，检查响应和实际 mode，失败进入明确 fallback
- 验证方法：mock SetMode 延迟/拒绝并证明 outstanding future 有界

### R-010 — 视觉 Path 在 100 Hz 下无界增长

- ID：R-010
- 严重程度：P1
- 状态：已验证（静态资源增长）；运行压力未验证
- 标题：历史 Path 内存 O(t)、累计序列化/带宽 O(t²)
- 影响范围：vision bridge、CPU、内存、ROS 带宽与位姿时延
- 文件路径：`src/ros2_foxy_vision_to_mavros/src/vision_to_mavros.cpp`；对应 launch
- 行号或符号：157–160；`t265_tf_to_mavros_launch.py:37-39`
- 证据：每帧永久 push pose 并重发完整 Path；本地配置从 30 提到 100 Hz
- 影响：长航时资源持续恶化，可能影响外部视觉时效
- 建议：禁用/降频调试 Path 或使用固定长度 ring buffer；vision pose 与调试轨迹解耦
- 验证方法：1–2 h soak，监控 RSS、CPU、topic 带宽和 pose age

### R-011 — 视觉坐标标定缺乏证据

- ID：R-011
- 严重程度：P1
- 状态：部分验证/待确认
- 标题：active 旋转参数与安装说明及源码默认显著不一致
- 影响范围：T265 外部视觉姿态/位置融合
- 文件路径：`src/ros2_foxy_vision_to_mavros/launch/t265_tf_to_mavros_launch.py`；`src/ros2_foxy_vision_to_mavros/src/vision_to_mavros.cpp`
- 行号或符号：10–21、42–59；24–43
- 证据：active yaw/gamma 为 0；说明/源码默认包含 ±pi/2；无标定记录，硬件未连接
- 影响：若非有意标定，外部视觉轴可能旋转并影响估计/控制
- 建议：保留“待确认”，不得直接改值；用实际安装姿态建立可追溯标定
- 验证方法：静止姿态和逐轴移动，对比 TF、MAVROS vision pose 与飞控估计方向

## P2

### R-012 — 多仓库状态不可精确复现

- ID：R-012
- 严重程度：P2
- 状态：已验证
- 标题：无 superproject lock，9/19 仓库 dirty
- 影响范围：交付、审查与回归
- 文件路径：`src/*/.git`
- 行号或符号：不适用
- 证据：4038 tracked unstaged、12 untracked、4 个 detached dirty 仓库；大量 mode 噪声混入内容改动
- 影响：无法由一个 commit 复现；真实定制容易遗漏
- 建议：建立 vcs manifest/superproject 锁定 commit，并分离权限噪声与功能改动
- 验证方法：全新目录按 manifest checkout 后状态 clean、包版本一致

### R-013 — 启动依赖固定延时且 MAVROS 无监督

- ID：R-013
- 严重程度：P2
- 状态：已验证（配置）
- 标题：TimerAction 代替 readiness，`respawn_mavros=false`
- 影响范围：T265、vision、MAVROS、serial、Offboard
- 文件路径：`src/px4_bringup/launch/`；`config/mavros_params.yaml`
- 行号或符号：`px4_fly.launch.py:19-53`；`start_all_2025TI.launch.py:20-48`；YAML 第 9 行
- 证据：8/12/15/25 s 固定启动，无健康 gate
- 影响：慢启动/退出后控制节点仍继续，故障恢复不可预测
- 建议：使用 lifecycle/event/service/topic readiness 与有界监督
- 验证方法：延迟/杀死各依赖，确认 Offboard 不启动或进入安全状态

### R-014 — 包依赖与构建环境不可自描述

- ID：R-014
- 严重程度：P2
- 状态：已验证
- 标题：package metadata 缺依赖，工具链与历史配置漂移
- 影响范围：干净构建
- 文件路径：`src/px4_bringup/package.xml:15-17`；`src/serial_driver_ros2/package.xml:10-18`
- 行号或符号：见路径
- 证据：未声明实际启动/链接依赖；依赖 `/usr/local/lib/libserial.a`；`arm-none-eabi-gcc` 缺失；历史 `colcon.meta` 已不存在
- 影响：当前机器旧 install 可掩盖干净环境失败
- 建议：补全 build/exec dependencies，记录 toolchain/ROS 环境和 colcon metadata
- 验证方法：隔离的空构建目录与干净主机依赖解析

### R-015 — 功能测试、SITL 与本地 CI 缺失

- ID：R-015
- 严重程度：P2
- 状态：已验证（缺口）
- 标题：安全关键控制/串口/视觉只有模板 lint 或无测试
- 影响范围：全部自定义飞控伴随包
- 文件路径：`src/offboard_cpp/`、`src/offboard_py/test/`、`src/px4_bringup/test/`、vision/serial CMake
- 行号或符号：见 `07_tests_and_validation.md`
- 证据：无功能 test_results、无本地 workflows、无 sanitizer/coverage；仅 AST 19/19 通过
- 影响：当前 P1 无自动回归防护
- 建议：按 07 文档矩阵逐层补单测、launch test、SITL、故障注入与 HIL
- 验证方法：CI 产出可追踪 test-result、coverage 和故障场景日志

### R-016 — 串口分片处理与设备命名不稳

- ID：R-016
- 严重程度：P2
- 状态：已验证（静态/配置）；硬件未验证
- 标题：局部 buffer 丢分片，STM32/RPLidar 共享 `/dev/ttyUSB0`
- 影响范围：STM32、RPLidar 串口
- 文件路径：`serial_driver.cpp:63-109`；serial YAML；RPLidar launch/rules
- 行号或符号：见上
- 证据：未跨调用保留半帧；两设备默认同路径，稳定 udev 名未被 launch 使用
- 影响：合法帧随机丢失、误开或争用设备
- 建议：持久 ring buffer；按 VID/PID/serial 分配独立稳定 symlink
- 验证方法：任意切分/粘包测试和双设备重枚举测试

### R-017 — 飞行配置硬编码

- ID：R-017
- 严重程度：P2
- 状态：已验证
- 标题：高度、速度、容差、地图与重试不可按机型/场地配置
- 影响范围：Offboard 任务
- 文件路径：`src/offboard_cpp/src/2025_Ti_main.cpp`；`include/lib/offboard_control_node.hpp`
- 行号或符号：31–45、198–220、424–503；53–56
- 证据：未发现 `declare_parameter/get_parameter`
- 影响：部署差异需改源码，缺乏范围校验与配置留档
- 建议：声明只读启动参数、单位与边界；启动时打印有效配置
- 验证方法：参数边界单测和两套场地配置的 launch test

### R-018 — 多个控制发布者无互斥

- ID：R-018
- 严重程度：P2
- 状态：部分验证（默认只启动一个）
- 标题：C++ demo、Python demo 与示例可发布同名 setpoint/service
- 影响范围：MAVROS Offboard 控制权
- 文件路径：`src/offboard_cpp/`、`src/offboard_py/offboard_py/px4_start_demo.py`
- 行号或符号：C++ `offboard_control_node.cpp:13-31`；Python 21–74
- 证据：topic/service 名相同，未见 ownership lease；默认 launch 只启动 2025 节点
- 影响：运维误启多个节点时 setpoint 竞争
- 建议：单一控制仲裁、唯一 namespace/lease，并在启动时拒绝重复 controller
- 验证方法：同时启动两个 publisher，确认仲裁器阻止第二入口

### R-019 — 自定义 Action 与未跟踪实现未完成

- ID：R-019
- 严重程度：P2
- 状态：已验证
- 标题：接口生成但实现为空，两个源码未接入构建
- 影响范围：Offboard 扩展功能
- 文件路径：`src/offboard_cpp/action/Px4Offboard.action`、`src/offboard_cpp/include/lib/offboard_action_node.hpp`、`src/offboard_cpp/src/lib/offboard_action_node.cpp`、未跟踪源码
- 行号或符号：action 1–15；CMake 64–92
- 证据：头文件为空、cpp 仅 include；layered example 自述未接 CMake
- 影响：声明与可用功能不一致，代码不受编译/测试约束
- 建议：明确删除、完成或标为实验性，并加入独立 target/test
- 验证方法：Action client/server 集成测试或确认不安装接口

## P3

### R-020 — install 空间存在过期入口

- ID：R-020
- 严重程度：P3
- 状态：已验证
- 标题：dangling symlink 与旧 executable 残留
- 影响范围：运维可发现性
- 文件路径：`install/serial_driver/share/serial_driver/launch/Ti_2025_serial_driver.launch.py`；`install/serial_driver/lib/serial_driver/cmd_qr_publisher`
- 行号或符号：生成物
- 证据：前者悬空；后者当前 CMake 不再定义
- 影响：操作员可能误启动历史产物
- 建议：在源码修复后用隔离的新 install 验证；本次不清理
- 验证方法：比较 `ros2 pkg executables` 与当前 CMake install targets

### R-021 — 轻微质量与元数据问题

- ID：R-021
- 严重程度：P3
- 状态：已验证
- 标题：whitespace 错误与 package 描述/版本不一致
- 影响范围：代码审查与发布元数据
- 文件路径：vision launch 第 38 行；serial driver 第 113 行；vision `package.xml:4-6`
- 行号或符号：见路径
- 证据：两仓库 `git diff --check` 退出 2；package 描述仍 TODO，声明 0.0.0 与提交信息 0.0.2 不一致
- 影响：CI 噪声和版本可追踪性下降
- 建议：在功能风险处理后修正文档、版本和 whitespace
- 验证方法：`git diff --check` 返回 0，package metadata 与 release tag 一致
