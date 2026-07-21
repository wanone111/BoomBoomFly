你现在位于一个 PX4项目的工作区根目录。

请对当前 PX4 工作区执行一次完整、基于证据、可重复的状态审查，并将审查结果写入：

docs/workspace_status/

本次任务的目标不是修改或优化源码，而是准确记录当前工作区的真实状态，包括 Git 状态、PX4 版本、模块结构、构建系统、板级配置、通信链路、测试状态、风险和下一步建议。

## 一、并行执行要求

使用 Codex subagents 并行完成审查。

请创建 8 个相互独立的只读 subagent，每个 subagent 负责一个检查领域。

必须遵守：

1. 所有 subagent 只读取文件、搜索代码和运行非破坏性命令。
2. subagent 不允许修改、创建或删除任何文件。
3. subagent 不允许执行 git reset、git clean、git checkout、git restore、git stash、git commit 或其他会改变工作区状态的命令。
4. subagent 不允许安装软件包、升级依赖、下载工具链或主动更新 Git submodule。
5. 等待全部 subagent 完成后，再由主 agent 汇总结果。
6. 只有主 agent 可以写入 docs/workspace_status/。
7. 主 agent必须顺序写入文档，避免多个 agent 同时编辑同一个文件。
8. 每项结论都必须提供实际文件路径、配置项、符号名称或命令输出作为依据。
9. 不要根据常见 PX4 项目结构猜测当前项目状态；必须检查当前工作区。
10. 如果某项无法验证，明确标记为“未验证”，并说明原因。

## 二、Subagent 任务划分

### Subagent 1：Git、版本和工作区状态

检查：

- 当前仓库根目录
- 当前分支
- 当前 commit hash
- 最近的 tag
- `git describe` 结果
- PX4 实际版本
- 工作区是否 dirty
- 已修改、已暂存、未跟踪文件
- 当前分支相对于上游的领先或落后状态
- remote 配置
- Git submodule 状态
- submodule 是否缺失、未初始化、版本不匹配或存在本地修改
- 是否存在 Git LFS、嵌套仓库或异常 gitlink
- 最近提交概况
- 当前变更主要集中在哪些模块

可运行只读命令，例如：

- `git status --short --branch`
- `git rev-parse --show-toplevel`
- `git rev-parse HEAD`
- `git describe --tags --always --dirty`
- `git remote -v`
- `git branch -vv`
- `git submodule status --recursive`
- `git diff --stat`
- `git diff --cached --stat`
- `git diff --check`
- `git log -n 10 --oneline --decorate`

不要假设项目版本是某个特定版本，必须从仓库中验证。

返回：

- 仓库快照
- Git 状态
- PX4 版本证据
- 当前变更摘要
- submodule 风险
- 无法验证的事项

### Subagent 2：构建系统和目标平台

检查：

- 顶层 Makefile
- CMake 构建入口
- `CMakeLists.txt`
- `cmake/`
- `Tools/`
- `platforms/`
- Kconfig
- board config
- toolchain 配置
- 构建目标定义
- 现有 `build/` 目录
- 最近使用过的构建目标
- SITL、NuttX、Linux 或其他平台状态
- 编译缓存和生成文件状态
- 可能导致构建失败的缺失文件、依赖或配置
- 当前主机操作系统、CPU 架构、编译器和 Python 环境
- PX4 构建环境是否完整

优先从以下位置查找证据：

- `Makefile`
- `CMakeLists.txt`
- `cmake/`
- `Tools/setup/`
- `platforms/`
- `boards/`
- `build/`
- `.github/workflows/`

可以运行非破坏性的版本检查和帮助命令。

不要直接执行所有 board target 的编译。

构建验证规则：

1. 先检查已有 build 目录和仓库文档，确定用户实际使用的目标。
2. 如果能够明确识别目标，并且依赖已经存在，可以运行最小化构建验证。
3. 如果无法确定实际目标，不要猜测硬件 target。
4. 可将 `px4_sitl_default` 作为通用的 SITL 健康检查，但必须先确认当前环境具备构建条件。
5. 不允许安装依赖来使构建通过。
6. 记录实际运行的命令、退出码和关键输出。
7. 如果未运行构建，说明未运行的原因。

返回：

- 构建架构
- 可识别的 target
- 当前使用过的 target
- 环境状态
- 构建验证结果
- 构建阻塞项

### Subagent 3：PX4 模块和飞行栈结构

检查：

- `src/modules/`
- `src/lib/`
- `src/systemcmds/`
- `src/examples/`
- 模块入口和任务启动方式
- commander
- navigator
- estimator
- controller
- mixer/control allocation
- sensors
- logger
- land detector
- failure detector
- events
- 参数系统
- 模块之间的主要数据流
- 当前工作区新增或修改的 PX4 模块
- 未完成实现
- TODO、FIXME、XXX
- 被禁用或没有加入构建的模块
- 模块声明与实际源码是否一致

重点识别：

- 修改过的模块
- 自定义模块
- 自定义飞行逻辑
- 状态机
- 控制环路频率
- 发布和订阅的 uORB topic
- 参数依赖
- 启动依赖
- 错误处理路径
- 模块退出和资源释放逻辑

返回：

- 飞行栈模块地图
- 关键数据流
- 自定义改动
- 未完成部分
- 潜在逻辑风险

### Subagent 4：Boards、驱动和硬件适配

检查：

- `boards/`
- `src/drivers/`
- `src/drivers/boards/`
- board default config
- board manifest
- ROMFS board startup
- GPIO
- PWM
- UART
- SPI
- I2C
- CAN
- ADC
- storage
- sensor drivers
- GPS
- RC input
- power monitor
- actuator output
- bootloader 相关配置
- linker script
- flash 和 RAM 配置
- NuttX 配置
- 自定义板卡和自定义驱动
- board config 与驱动依赖是否一致
- 设备节点、串口和总线映射是否一致
- 驱动是否已经加入目标构建
- 硬件资源冲突风险

特别检查当前修改是否涉及：

- Pixhawk
- FMU target
- 自定义飞控
- companion computer
- UART/MAVLink
- ROS 2 或 Micro XRCE-DDS
- 外接传感器
- 串口协议

返回：

- 支持的主要板级目标
- 当前相关 target
- 硬件资源映射
- 驱动状态
- 板级配置风险

### Subagent 5：uORB、MAVLink、DDS 和 ROS 2 通信

检查：

- `msg/`
- uORB message 定义
- message 生成流程
- 发布者和订阅者
- MAVLink stream
- MAVLink message 配置
- MAVLink instance 和启动脚本
- `src/modules/mavlink/`
- `src/modules/uxrce_dds_client/`
- DDS topic 映射
- ROS 2 接口
- `dds_topics.yaml`
- Micro XRCE-DDS 配置
- companion computer 通信
- 串口、UDP 和网络通信
- Offboard 控制相关数据流
- 时间同步
- QoS 或可靠性配置
- 消息版本兼容性
- px4_msgs 兼容风险
- firmware 与外部 ROS 2 工作区版本匹配风险
- 自定义消息是否完整加入生成和传输链路

重点追踪：

- Offboard 指令如何进入 PX4
- trajectory setpoint 数据路径
- vehicle command 数据路径
- vehicle status、odometry 和 sensor 数据输出路径
- MAVLink 和 DDS 是否存在重复或冲突的控制入口
- 通信超时与 failsafe 路径
- 时间戳和坐标系处理

返回：

- 通信架构
- 关键 topic/message
- Offboard 数据流
- 外部接口兼容性
- 通信风险

### Subagent 6：参数、启动流程和飞行配置

检查：

- `src/lib/parameters/`
- 参数定义
- 参数 metadata
- 模块参数依赖
- `ROMFS/`
- `rcS`
- init 脚本
- airframe 配置
- autostart
- mixer
- actuator 配置
- failsafe 参数
- MAVLink 参数
- EKF 参数
- Offboard 参数
- commander 参数
- circuit breaker
- board-specific startup
- 自定义参数
- 已废弃参数
- 参数命名冲突
- 参数定义但未使用
- 使用但未定义的参数
- 默认值和运行逻辑不一致的问题

返回：

- PX4 启动流程
- 配置入口
- 参数分组
- 自定义参数
- 参数和启动风险

### Subagent 7：测试、仿真、CI 和质量保障

检查：

- `test/`
- `src/*/test`
- unit tests
- integration tests
- SITL tests
- MAVSDK tests
- Gazebo/GZ/JMAVSim 支持
- simulation models
- `.github/workflows/`
- lint
- formatting
- static analysis
- code coverage
- board build matrix
- 当前修改涉及的测试
- 缺失的回归测试
- 被跳过或禁用的测试
- CI 配置与当前代码的匹配情况

可以执行轻量、非破坏性的检查，例如：

- Git diff whitespace 检查
- 已有 lint 命令
- 与当前修改直接相关的小型测试
- 已配置完成的最小 SITL 测试

不要擅自启动长时间运行的完整仿真或完整 CI 矩阵。

返回：

- 测试体系
- 已验证项目
- 未验证项目
- 测试缺口
- CI 风险

### Subagent 8：实时性、并发、安全性和代码质量

检查当前核心代码和本地修改，重点关注：

- work queue 使用
- pthread/task 使用
- 锁和互斥量
- 原子变量
- race condition
- ISR 与线程共享数据
- 栈空间
- 堆内存
- 内存泄漏
- 越界访问
- 空指针
- use-after-free
- 未初始化变量
- 整数溢出
- 单位和类型转换
- 时间戳溢出
- 阻塞 I/O
- 高频循环中的动态分配
- 控制循环实时性
- 订阅更新频率
- 数据新鲜度检查
- failsafe
- 错误码处理
- 日志级别
- PX4_INFO、PX4_WARN、PX4_ERR 使用
- 返回值是否被忽略
- 参数更新线程安全
- 资源初始化和释放
- 文件描述符和设备句柄
- 网络和串口输入验证
- TODO、FIXME、临时调试代码
- 明显重复代码
- 不符合附近代码风格的实现

优先检查：

1. 当前 Git 修改文件。
2. 自定义模块和驱动。
3. Offboard、控制、通信和硬件接口代码。
4. 高频执行路径。
5. 安全关键状态机。

返回的问题必须包含：

- 严重程度
- 文件路径
- 行号或符号
- 证据
- 影响
- 建议修复方向
- 是否已验证

## 三、主 Agent 汇总要求

等待全部 8 个 subagent 返回结果后，主 agent 对结果进行交叉验证。

需要特别处理：

- 合并重复问题。
- 解决不同 subagent 之间相互矛盾的结论。
- 不得将未经验证的推测写成事实。
- 对动态生成文件、submodule、构建产物和源码进行区分。
- 对上游 PX4 原始代码和当前工作区自定义改动进行区分。
- 对“项目固有复杂性”和“当前工作区实际缺陷”进行区分。
- 不要因为没有运行完整硬件测试就断言硬件功能正常。
- 不要因为编译成功就断言运行时逻辑正确。

## 四、文档输出

如果 `docs/workspace_status/` 不存在，则创建该目录。

生成以下文件：

### 1. `docs/workspace_status/README.md`

作为状态文档入口，包含：

- 项目名称
- 审查时间
- 工作区绝对路径
- 当前分支
- commit hash
- PX4 版本
- 工作区 clean/dirty 状态
- 当前目标平台
- 当前项目整体状态
- 文档导航
- 五个最重要的问题
- 五个优先级最高的下一步操作

### 2. `docs/workspace_status/01_repository_snapshot.md`

包含：

- Git 状态
- branch/tag/commit
- remote
- submodule
- 修改文件
- 未跟踪文件
- 当前差异摘要
- 版本识别依据

### 3. `docs/workspace_status/02_architecture_and_modules.md`

包含：

- PX4 目录结构
- 核心模块
- 飞行栈数据流
- 自定义模块
- uORB 关系
- Mermaid 架构图
- 关键入口文件

### 4. `docs/workspace_status/03_build_and_targets.md`

包含：

- 构建系统
- target
- toolchain
- board config
- 已有构建目录
- 实际执行的构建或检查命令
- 命令退出码
- 成功项
- 失败项
- 构建阻塞项

### 5. `docs/workspace_status/04_hardware_and_drivers.md`

包含：

- board
- UART/SPI/I2C/CAN/PWM 等接口
- 驱动
- 设备映射
- 自定义硬件适配
- 板级风险

### 6. `docs/workspace_status/05_communication_interfaces.md`

包含：

- uORB
- MAVLink
- DDS
- ROS 2
- Offboard
- UDP/串口
- 外部接口
- 消息兼容性
- Mermaid 数据流图
- failsafe 和超时路径

### 7. `docs/workspace_status/06_parameters_and_startup.md`

包含：

- 启动顺序
- airframe
- autostart
- ROMFS
- 参数分组
- 自定义参数
- 关键默认值
- 参数风险

### 8. `docs/workspace_status/07_tests_and_validation.md`

包含：

- 当前测试体系
- 可运行测试
- 实际运行结果
- 未运行测试及原因
- 仿真状态
- CI 状态
- 测试缺口
- 推荐验证矩阵

### 9. `docs/workspace_status/08_risks_and_technical_debt.md`

问题按以下严重程度分类：

- P0：可能造成飞行安全事故、失控、硬件损坏或数据破坏
- P1：可能造成构建失败、任务崩溃、控制异常或重要功能不可用
- P2：稳定性、兼容性、可维护性或测试不足
- P3：文档、风格、轻微技术债务

每个问题使用统一格式：

- ID
- 严重程度
- 状态
- 标题
- 影响范围
- 文件路径
- 行号或符号
- 证据
- 影响
- 建议
- 验证方法

不要为了凑数量而生成问题。

### 10. `docs/workspace_status/09_next_steps.md`

按优先级生成：

- 立即处理
- 构建恢复
- SITL 验证
- 硬件在环验证
- 实机前验证
- 长期重构

每个任务包含：

- 任务
- 原因
- 涉及路径
- 前置条件
- 验证标准
- 风险
- 预计复杂度：小、中、大

不要写具体工期。

### 11. `docs/workspace_status/10_audit_manifest.md`

记录本次审查过程：

- 审查时间
- Codex 执行范围
- 使用的 subagent 列表
- 运行过的命令
- 命令退出码
- 扫描过的主要目录
- 未扫描或排除的目录
- 未完成检查
- 受限条件
- 文档生成清单

## 五、状态评分

在 README 中给出 0–100 的项目健康评分，但必须展示评分依据。

至少包括：

- 仓库完整性：15 分
- 构建可重复性：20 分
- 模块完整性：15 分
- 硬件配置一致性：10 分
- 通信接口可靠性：10 分
- 测试和仿真：15 分
- 实时性与稳定性：10 分
- 文档完整性：5 分

不要仅凭主观判断给分。

未验证项目不能默认计为满分。

## 六、文档写入规则

1. 只允许修改 `docs/workspace_status/`。
2. 不修改现有源码、CMake、Kconfig、board config、参数、启动脚本或测试。
3. 不修改 `docs/workspace_status/` 之外的现有文档。
4. 如果已有状态文档，先读取并保留仍然有效的信息。
5. 删除或修正已经过时、且能够被当前代码证伪的信息。
6. 文档顶部写入：

   - Generated at
   - Workspace
   - Branch
   - Commit
   - PX4 version
   - Working tree status

7. 使用相对路径引用仓库文件。
8. 文件引用尽量附带行号或符号名称。
9. 命令输出只保留关键部分，不要复制大量日志。
10. 不要把 build 目录中的自动生成源码当作主要源码依据。
11. 对无法确认的信息使用：
    - 已验证
    - 部分验证
    - 未验证
12. 不写没有证据支持的结论。

## 七、最终验证

写完文档后执行以下检查：

1. 列出 `docs/workspace_status/` 中生成和修改的文件。
2. 检查所有 Markdown 内部链接是否有效。
3. 检查引用的仓库路径是否存在。
4. 检查 Mermaid 代码块语法是否完整。
5. 检查不同文档中的 branch、commit、version 和 target 是否一致。
6. 检查风险列表和下一步任务是否一一对应。
7. 检查是否误改了 `docs/workspace_status/` 之外的文件。
8. 使用 `git diff -- docs/workspace_status/` 审查最终文档变更。
9. 使用 `git status --short` 确认没有意外修改源码。
10. 如果存在无法解决的文档矛盾，保留明确的“待确认”标记，不要猜测。

## 八、最终终端输出

任务结束时，在终端中输出：

- 审查是否完成
- 实际启动的 subagent 数量
- 每个 subagent 的完成状态
- 当前 branch、commit 和 PX4 version
- 是否执行构建
- 构建结果
- 是否执行测试
- 测试结果
- 项目健康评分
- P0/P1/P2/P3 问题数量
- 最大的五个风险
- 生成或修改的文档列表
- 未完成或未验证的事项
- 建议首先执行的三个动作

现在开始：

1. 先确认当前目录确实是 PX4 工作区。
2. 获取 Git 和环境快照。
3. 创建并启动 8 个只读 subagent。
4. 等待全部 subagent 完成。
5. 汇总和交叉验证结果。
6. 由主 agent 写入文档。
7. 执行最终一致性检查。