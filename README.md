# 🎮 Godot 4 通用游戏框架 (GGF — Godot Game Framework)

> 一个模块化、可扩展的 Godot 4 游戏开发框架，旨在大幅缩短游戏原型验证周期，让开发者专注于游戏玩法而非基础设施。 目前README由AI生成作为初期开发的总体参考，后续会随开发逐步人工完善README。

---

## 📋 目录

- [1. 项目愿景](#1-项目愿景)
- [2. 设计哲学](#2-设计哲学)
- [3. 整体架构总览](#3-整体架构总览)
- [4. 模块需求分析与设计](#4-模块需求分析与设计)
  - [4.1 核心框架 (Core)](#41-核心框架-core)
  - [4.2 事件总线 (EventBus)](#42-事件总线-eventbus)
  - [4.3 场景与状态管理 (Scene & State)](#43-场景与状态管理-scene--state)
  - [4.4 UI 框架 (UI)](#44-ui-框架-ui)
  - [4.5 音频管理 (Audio)](#45-音频管理-audio)
  - [4.6 输入管理 (Input)](#46-输入管理-input)
  - [4.7 数据与存档 (Data & Save)](#47-数据与存档-data--save)
  - [4.8 对象池 (Object Pool)](#48-对象池-object-pool)
  - [4.9 实体与角色 (Entity & Character)](#49-实体与角色-entity--character)
  - [4.10 有限状态机 (FSM)](#410-有限状态机-fsm)
  - [4.11 技能与Buff系统 (Ability & Buff)](#411-技能与buff系统-ability--buff)
  - [4.12 本地化 (Localization)](#412-本地化-localization)
  - [4.13 摄像机管理 (Camera)](#413-摄像机管理-camera)
  - [4.14 调试与性能 (Debug & Profiler)](#414-调试与性能-debug--profiler)
  - [4.15 工具集 (Utilities)](#415-工具集-utilities)
- [5. 目录结构](#5-目录结构)
- [6. 开发路线图](#6-开发路线图)
- [7. 快速开始](#7-快速开始)
- [8. 贡献指南](#8-贡献指南)

---

## 1. 项目愿景

在游戏开发中，大量时间耗费在**重复的基础设施搭建**上——场景切换、UI管理、存档、音效控制、输入映射……这些每个项目都需要，但每次都要重写。**GGF (Godot Game Framework)** 的目标就是**一次性解决这些通用问题**，让你在开始新项目时：

- ⏱️ **5 分钟内**搭建出可运行的游戏骨架
- 🧩 需要什么模块就**按需装配**，不引入不必要的复杂度
- 🔁 在不同类型的游戏（动作、RPG、策略、休闲等）之间**复用同一套基础设施**
- 🧪 快速验证玩法创意，**失败更快、迭代更快**

---

## 2. 设计哲学

| 原则 | 说明 |
|------|------|
| **Godot 原生优先** | 尊重 Godot 的场景树、信号、资源系统，不引入反模式，不做"框架中的引擎" |
| **模块化** | 每个模块可独立使用，不强制依赖。不写"万能"的单例，只写"够用"的工具 |
| **组合优于继承** | 多用组件（Node 组合）而非深层继承链；提供基类但不强制使用 |
| **约定优于配置** | 提供合理的默认行为，同时保留覆盖能力 |
| **编辑器友好** | 所有功能都能在 Godot 编辑器中可视化配置，导出变量优于硬编码 |
| **类型安全** | 充分利用 GDScript 2.0 的类型注解，让编辑器自动补全和静态检查发挥作用 |
| **性能敏感** | 框架本身不能成为性能瓶颈，对象池、缓存策略内建其中 |

---

## 3. 整体架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                     🎮 你的游戏                              │
├─────────────────────────────────────────────────────────────┤
│  🧩 玩法层: 实体(Entity) │ 状态机(FSM) │ 技能(Ability) │ AI  │
├─────────────────────────────────────────────────────────────┤
│  🧰 系统层: UI管理 │ 音频 │ 输入 │ 摄像机 │ 本地化 │ 存档   │
├─────────────────────────────────────────────────────────────┤
│  ⚙️ 核心层: 场景管理 │ 事件总线 │ 对象池 │ 配置 │ 工具集    │
├─────────────────────────────────────────────────────────────┤
│  🏗️ Godot 4 引擎                                           │
└─────────────────────────────────────────────────────────────┘
```

### 模块依赖关系

```
                         ┌──────────┐
                         │  Core    │  (全局单例、配置、生命周期)
                         └────┬─────┘
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
        ┌──────────┐   ┌──────────┐   ┌──────────┐
        │ EventBus │   │  Scene   │   │  Data    │
        │ 事件总线  │   │ 场景管理  │   │ 数据持久化│
        └────┬─────┘   └────┬─────┘   └──────────┘
             │              │
    ┌────────┼────────┬─────┼─────┬────────────┐
    ▼        ▼        ▼     ▼     ▼            ▼
┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐
│  UI  │ │Audio │ │Input │ │Camera│ │Pool  │ │Locale│
│ UI框架│ │音频  │ │输入  │ │摄像机│ │对象池│ │本地化│
└──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘
                                    │
                                    ▼
                              ┌──────────┐
                              │ Entity   │
                              │ 实体基类  │
                              └────┬─────┘
                         ┌─────────┼─────────┐
                         ▼         ▼         ▼
                    ┌──────┐  ┌──────┐  ┌──────┐
                    │ FSM  │  │Buff  │  │Skill │
                    │状态机 │  │Buff系│  │技能系│
                    └──────┘  └──────┘  └──────┘
```

---

## 4. 模块需求分析与设计

### 4.1 核心框架 (Core)

**需求来源**：每个项目都需要一个"入口"来管理全局配置、生命周期和模块注册。

**核心功能**：
- **GameManager 单例**：游戏的总入口，负责初始化各子系统
- **生命周期管理**：统一管理 `_ready` → `_process` → `_exit` 流程
- **配置系统**：读取 `.cfg` / `.json` 配置文件，运行时获取配置项
- **模块注册中心**：各模块向 Core 注册，Core 统一调度初始化/销毁顺序
- **暂停系统**：统一暂停/恢复（区分 UI 暂停、游戏逻辑暂停等层级）

**设计要点**：
```
GameManager (Autoload)
├── 初始化顺序控制（依赖拓扑排序）
├── 全局配置访问接口
├── 暂停状态栈（支持多层暂停，如"UI打开暂停游戏" + "系统对话框再暂停UI"）
└── 退出清理流程
```

---

### 4.2 事件总线 (EventBus)

**需求来源**：Godot 的信号需要持有引用才能连接，跨系统通信时耦合严重。事件总线提供**发布-订阅**解耦。

**核心功能**：
- 全局事件发布/订阅，无需持有发布者引用
- 支持带类型的事件数据传递
- 支持事件优先级
- 调试模式下记录事件流便于追踪
- 延迟事件（下一帧触发）

**设计要点**：
```gdscript
# 任何地方都可以发送和监听
EventBus.emit("player_died", { "player_id": 1, "killer": "enemy_orc" })
EventBus.on("player_died", _on_player_died)
EventBus.once("loading_complete", _on_loaded)  # 只触发一次
```

---

### 4.3 场景与状态管理 (Scene & State)

**需求来源**：场景切换是每个游戏的基本操作，但 Godot 原生 `change_scene_to_file` 太简陋——没有过渡动画、没有加载界面、没有状态保持。

**核心功能**：
- **场景切换器**：支持淡入淡出、加载界面、异步加载
- **场景栈**：支持 Push/Pop（如从主菜单进入游戏，返回时恢复主菜单状态）
- **子场景管理**：叠加式场景（如 UI 层、对话层叠加在游戏世界上）
- **加载策略**：同步/异步/分帧加载，防止卡顿

**设计要点**：
```
SceneManager (场景管理器)
├── 场景栈 (Scene Stack)
│   ├── Push: 压入新场景，当前场景挂起（可选保留或释放）
│   └── Pop:  弹出当前场景，恢复上一层
├── 过渡效果
│   ├── FadeIn/FadeOut
│   ├── 自定义 Shader 转场
│   └── 加载进度条
├── 子场景层 (Layer)
│   ├── GameWorld 层
│   ├── UI 层
│   ├── Dialogue 层
│   └── Overlay 层（黑屏/通知等，最高优先级）
└── 场景预加载（预加载常用场景到缓存）
```

---

### 4.4 UI 框架 (UI)

**需求来源**：游戏 UI 远比普通 App UI 复杂——需要动画、需要手柄导航、需要大量弹窗管理。Godot 的 Control 节点提供了基础，但缺少上层管理。

**核心功能**：
- **UI 管理器**：统一管理所有 UI 面板的打开/关闭/堆叠
- **面板基类**：提供打开动画、关闭动画、焦点管理、输入拦截
- **通用组件库**：按钮（带音效/动画）、滑块、开关、血条、对话框
- **UI 导航**：手柄/键盘焦点自动导航
- **弹窗系统**：确认框、提示框、加载框（链式调用）
- **UI 动画工具**：常用入场/退场动画（缩放、滑入、淡入等）

**设计要点**：
```gdscript
# 链式打开一个确认弹窗
UIManager.show_dialog("confirm")
    .set_title("确认删除?")
    .set_content("此操作无法撤销")
    .on_confirm(func(): delete_item())
    .on_cancel(func(): pass)
    .show()
```

---

### 4.5 音频管理 (Audio)

**需求来源**：游戏音频需要区分 BGM / BGS / SE / 语音等频道，需要音量分组控制，需要淡入淡出。

**核心功能**：
- **多频道管理**：Master / BGM / BGS / SFX / Voice / UI — 至少 6 个独立 AudioBus
- **音量控制**：每个频道独立音量，支持静音，配置持久化
- **BGM 播放器**：支持循环、淡入淡出切换、播放列表
- **音效池**：同时播放多个短音效（如打击声），使用对象池避免频繁创建 AudioStreamPlayer
- **3D 音效支持**：封装 AudioStreamPlayer3D 的便捷方法

---

### 4.6 输入管理 (Input)

**需求来源**：不同设备（键盘、手柄、触摸）的输入需要统一抽象，按键映射需要可配置、可运行时切换。

**核心功能**：
- **输入抽象层**：将"跳跃"、"攻击"等逻辑动作与具体按键解耦
- **Input Map 批量配置**：用配置文件批量设置 Input Map
- **输入缓冲**：格斗游戏中的指令缓冲（提前 N 帧按下也有效）
- **组合键检测**：如"↓↘→ + A"的必杀技指令
- **手柄振动**：封装振动调用

---

### 4.7 数据与存档 (Data & Save)

**需求来源**：存档是玩家的"时间投资保险"。需要支持多存档槽、自动存档、存档加密、云存档扩展。

**核心功能**：
- **多存档槽**：支持 N 个独立存档
- **自动存档**：定时/事件触发自动保存
- **数据加密**：可选 AES 加密，防止玩家修改
- **版本兼容**：存档结构带版本号，旧存档可迁移
- **配置存储**：玩家设置（音量、按键等）独立存储
- **SaveData 资源**：用 Godot Resource 定义存档结构，类型安全

**设计要点**：
```
SaveSystem (Autoload)
├── 存档槽管理 (创建/删除/读取/写入)
├── 自动存档定时器
├── 存档数据序列化 (JSON / 二进制 / 加密二进制)
├── 版本迁移管线
└── Steam Cloud / 平台云存档扩展点
```

---

### 4.8 对象池 (Object Pool)

**需求来源**：子弹、粒子、敌人、掉落物——大量短期对象的频繁创建/销毁是性能杀手。

**核心功能**：
- **通用对象池**：支持任何 PackedScene 的池化管理
- **预热**：场景加载时预创建 N 个实例
- **自动回收**：超时未使用自动回收，超出容量自动销毁
- **统计信息**：命中率、活跃数、池容量，方便调优
- **Node2D / Node3D 通用**：同时支持 2D 和 3D 对象

---

### 4.9 实体与角色 (Entity & Character)

**需求来源**：游戏中的角色、敌人、NPC、可交互物体都需要统一的属性管理（生命值、速度等）和伤害计算。

**核心功能**：
- **Entity 基类**：提供 ID、阵营、标签等基础属性
- **Character 基类**：继承 Entity，增加生命值、移动速度等 RPG 属性
- **属性系统**：`AttributeContainer` — 一套可变的属性集合（力敏智等），支持加成/惩罚
- **伤害/治疗计算**：统一的伤害公式接口，支持护甲、抗性等
- **阵营系统**：友好/中立/敌对判断
- **可破坏物体**：继承 Entity 的简单可破坏物

---

### 4.10 有限状态机 (FSM)

**需求来源**：角色状态（待机/行走/攻击/受伤/死亡）、UI 状态、游戏流程——状态机是游戏开发中最常用的模式。

**核心功能**：
- **通用 FSM**：不依赖具体节点类型，可用于角色、UI、任何需要状态管理的对象
- **状态定义**：每个状态有 `enter` / `update` / `physics_update` / `exit` 回调
- **条件转换**：基于条件自动转换，支持优先级
- **状态历史**：记录上一个状态，支持"返回上一状态"
- **可视化调试**：运行时打印状态转换图
- **动画状态机集成**：可选与 AnimationTree 联动

**设计要点**：
```gdscript
# 定义状态
var idle_state = fsm.add_state("idle", {
    enter = _on_idle_enter,
    update = _on_idle_update,
    exit = _on_idle_exit
})
# 添加转换
fsm.add_transition("idle", "walk", func(): return input_dir != Vector2.ZERO)
fsm.add_transition("walk", "idle", func(): return input_dir == Vector2.ZERO)
fsm.add_any_transition("hurt", func(): return took_damage)  # 任意状态可转入
```

---

### 4.11 技能与 Buff 系统 (Ability & Buff)

**需求来源**：RPG、动作、卡牌游戏中最复杂的部分——技能释放流程、冷却、Buff/Debuff 叠加。

**核心功能**：

**技能系统**：
- 技能基类（Ability）：定义施放条件、消耗、冷却、施放流程
- 技能组件：`CooldownComponent` / `CostComponent` / `CastComponent`
- 目标选择：单体/范围/自身/射线
- 技能队列：缓冲输入，连招系统

**Buff 系统**：
- Buff 基类：持续时间、叠加层数、刷新策略
- Buff 类型：属性修改 / 周期性效果 / 状态控制 / 触发器
- Buff 容器：管理一个实体上的所有 Buff，处理叠加和互斥
- 时间线可视化：调试时显示 Buff 剩余时间

---

### 4.12 本地化 (Localization)

**需求来源**：多语言支持应该在项目初期就规划好，后期改造代价巨大。

**核心功能**：
- **CSV/JSON 翻译表**：用表格管理文本
- **动态切换语言**：运行时切换，无需重启
- **占位符系统**：`"你获得了 {count} 个 {item}"` → 运行时填充
- **富文本支持**：BBcode 标签在翻译文本中正常工作
- **字体回退**：不同语言可能需要不同字体（中/日/韩/阿拉伯）
- **编辑器辅助**：检查缺失翻译的编辑器工具

---

### 4.13 摄像机管理 (Camera)

**需求来源**：不同游戏需要不同的摄像机行为——跟随、锁定、震屏、平滑过渡。

**核心功能**：
- **2D/3D 摄像机控制器**：跟随目标、平滑插值、边界限制
- **震屏效果**：基于 Trauma 的震屏系统，可叠加多次震动
- **摄像机切换**：在多台摄像机之间平滑切换
- **视差背景**：2D 视差滚动辅助
- **缩放控制**：捏合缩放（移动端）/ 滚轮缩放

---

### 4.14 调试与性能 (Debug & Profiler)

**需求来源**：开发过程中需要快速了解运行状态、定位 Bug、优化性能。

**核心功能**：
- **Debug 控制台**：游戏内控制台，输入命令查看/修改状态
- **性能监控面板**：FPS、内存、Draw Call、节点数量
- **Debug Draw**：绘制碰撞体、路径、射线等调试图形
- **Cheat 系统**：开发期无敌、无限资源等作弊指令
- **日志系统**：分级日志（Debug/Info/Warning/Error），可过滤、可写入文件
- **截图工具**：一键截图，支持高清截图

---

### 4.15 工具集 (Utilities)

**需求来源**：通用工具函数和扩展方法，减少重复代码。

**核心功能**：
- **GD 脚本扩展**：扩展 `Node`、`Vector2`、`Array` 等内置类型的静态方法
- **数学工具**：缓动函数库（Easing）、随机工具（加权随机、正态分布随机）
- **时间工具**：计时器辅助、帧延迟 Promise 风格调用
- **文件工具**：目录遍历、文件读写封装
- **协程工具**：更友好的异步操作封装

---

## 5. 目录结构

```
godot-game-framework/
├── project.godot                    # Godot 项目文件
├── README.md                        # 本文件
├── CHANGELOG.md                     # 版本更新日志
├── .gitignore                       # Git 忽略规则
│
├── addons/                          # Godot 插件（框架自身也可能以插件形式提供）
│   └── ggf/                         # GGF 框架插件
│       ├── plugin.cfg               # 插件配置
│       └── ...
│
├── assets/                          # 框架自带资源（最小化的占位资源）
│   ├── fonts/                       # 默认字体
│   ├── textures/                    # 占位贴图（白色方块、图标等）
│   ├── sounds/                      # 占位音效
│   └── shaders/                     # 通用 Shader（淡入淡出等）
│
├── src/                             # 框架源代码
│   ├── core/                        # 核心层
│   │   ├── game_manager.gd          # GameManager 单例
│   │   ├── config_manager.gd        # 配置管理
│   │   └── pause_manager.gd        # 暂停管理
│   │
│   ├── event/                       # 事件总线
│   │   └── event_bus.gd
│   │
│   ├── scene/                       # 场景管理
│   │   ├── scene_manager.gd         # 场景管理器
│   │   └── scene_transition.gd     # 过渡效果
│   │
│   ├── ui/                          # UI 框架
│   │   ├── ui_manager.gd           # UI 管理器
│   │   ├── ui_panel.gd             # 面板基类
│   │   ├── components/             # 通用 UI 组件
│   │   │   ├── button_ext.gd       # 增强按钮
│   │   │   ├── health_bar.gd       # 血条
│   │   │   └── ...
│   │   └── dialog/                 # 弹窗系统
│   │       ├── dialog_manager.gd
│   │       └── dialog_base.gd
│   │
│   ├── audio/                       # 音频管理
│   │   ├── audio_manager.gd        # 音频管理器
│   │   └── sfx_pool.gd             # 音效池
│   │
│   ├── input/                       # 输入管理
│   │   ├── input_manager.gd        # 输入管理器
│   │   └── input_buffer.gd         # 输入缓冲
│   │
│   ├── data/                        # 数据与存档
│   │   ├── save_system.gd          # 存档系统
│   │   ├── save_data.gd            # 存档数据资源
│   │   └── config_store.gd         # 配置存储
│   │
│   ├── pool/                        # 对象池
│   │   └── object_pool.gd
│   │
│   ├── entity/                      # 实体与角色
│   │   ├── entity.gd               # 实体基类
│   │   ├── character.gd            # 角色基类
│   │   ├── attribute_container.gd  # 属性容器
│   │   └── faction.gd              # 阵营定义
│   │
│   ├── fsm/                         # 有限状态机
│   │   ├── state_machine.gd        # 状态机
│   │   └── state.gd                # 状态定义
│   │
│   ├── ability/                     # 技能与 Buff
│   │   ├── ability.gd              # 技能基类
│   │   ├── ability_component.gd    # 技能组件
│   │   ├── buff.gd                 # Buff 基类
│   │   └── buff_container.gd       # Buff 容器
│   │
│   ├── localization/                # 本地化
│   │   ├── locale_manager.gd       # 本地化管理器
│   │   └── locale_data.gd          # 翻译数据资源
│   │
│   ├── camera/                      # 摄像机
│   │   ├── camera_controller_2d.gd
│   │   ├── camera_controller_3d.gd
│   │   └── camera_shake.gd         # 震屏效果
│   │
│   ├── debug/                       # 调试与性能
│   │   ├── debug_console.gd        # 调试控制台
│   │   ├── fps_monitor.gd          # 性能监控
│   │   ├── debug_draw.gd           # 调试绘制
│   │   ├── cheat_manager.gd        # 作弊系统
│   │   └── logger.gd               # 日志系统
│   │
│   └── utils/                       # 工具集
│       ├── math_utils.gd            # 数学工具
│       ├── easing.gd                # 缓动函数库
│       ├── random_utils.gd          # 随机工具
│       ├── time_utils.gd            # 时间工具
│       ├── file_utils.gd            # 文件工具
│       ├── coroutine_utils.gd       # 协程工具
│       └── gd_extensions.gd         # GD 脚本扩展
│
├── examples/                        # 示例项目
│   ├── minimal/                     # 最小化示例（最简单的框架使用）
│   ├── platformer/                  # 平台跳跃示例
│   ├── rpg/                         # RPG 示例
│   └── ui_demo/                     # UI 组件展示
│
├── docs/                            # 详细文档
│   ├── getting_started.md           # 入门指南
│   ├── architecture.md              # 架构详解
│   ├── api/                         # API 文档
│   └── tutorials/                   # 教程
│
└── tests/                           # 测试
    └── unit/                        # 单元测试
```

---

## 6. 开发路线图

### Phase 0 — 项目骨架 (v0.1.0)
- [x] 项目初始化、目录结构搭建
- [ ] Godot 4 项目创建（`project.godot`）
- [ ] `.gitignore` 配置
- [ ] README.md 完整文档

### Phase 1 — 核心基础设施 (v0.2.0)
- [ ] **Core**: GameManager 单例、配置管理、生命周期
- [ ] **EventBus**: 事件发布/订阅系统
- [ ] **Scene**: 场景切换管理、异步加载、过渡效果
- [ ] **Utils**: 基础工具集（扩展方法、数学工具）

### Phase 2 — 通用系统 (v0.3.0)
- [ ] **UI**: UI 管理器、面板基类、弹窗系统
- [ ] **Audio**: 多频道音频管理、音效池
- [ ] **Input**: 输入抽象层、输入缓冲
- [ ] **Data**: 存档系统、配置存储

### Phase 3 — 玩法基础 (v0.4.0)
- [ ] **Entity**: 实体基类、角色基类、属性系统、阵营
- [ ] **FSM**: 通用有限状态机
- [ ] **Pool**: 对象池

### Phase 4 — 高级系统 (v0.5.0)
- [ ] **Ability**: 技能系统、Buff 系统
- [ ] **Camera**: 摄像机控制器、震屏
- [ ] **Localization**: 本地化框架

### Phase 5 — 开发效率 (v0.6.0)
- [ ] **Debug**: 调试控制台、性能面板、Cheat 系统
- [ ] **Examples**: 各类型游戏示例项目
- [ ] **Docs**: 完整 API 文档和教程

### Phase 6 — 长期维护 (v1.0.0+)
- [ ] 网络/多人游戏模块
- [ ] 行为树 AI 模块
- [ ] 程序化生成工具
- [ ] 编辑器插件（可视化配置）

---

## 7. 快速开始

> ⚠️ 框架正在开发中，以下为预期使用方式。

### 安装

1. **作为 Godot 插件**：
   ```
   将 addons/ggf/ 复制到你的项目 addons/ 目录
   在 Project Settings → Plugins 中启用 GGF
   ```

2. **作为项目模板**：
   ```
   直接克隆本项目作为新游戏的起点
   git clone https://github.com/your-repo/godot-game-framework.git my-new-game
   ```

### 最小化使用示例

```gdscript
# 你的主场景脚本
extends Node

func _ready():
    # 初始化框架（自动加载的 Autoload 已经就绪）
    SceneManager.change_scene("res://scenes/game_world.tscn", {
        "transition": "fade",
        "duration": 0.5
    })

    # 监听事件
    EventBus.on("player_died", _on_player_died)

    # 播放音效
    AudioManager.play_sfx("explosion")

    # 打开 UI
    UIManager.show("game_hud")

func _on_player_died(data: Dictionary):
    UIManager.show_dialog("confirm")
        .set_title("你死了!")
        .set_content("是否重新开始?")
        .on_confirm(func(): SceneManager.reload_current())
        .show()
```

### 只用你需要的

框架的所有模块都可以**按需使用**。如果你只需要对象池，只需：

```gdscript
var bullet_pool = ObjectPool.new(bullet_scene, preload_count = 20)
var bullet = bullet_pool.acquire()
```

不需要配置整个框架。

---

## 8. 贡献指南

欢迎贡献！请遵循以下流程：

1. **Fork** 本项目
2. 从 `main` 分支创建 Feature 分支 (`feat/xxx`) 或 Fix 分支 (`fix/xxx`)
3. 遵循项目代码风格（见 `.reasonix/code_style.md`）
4. 编写单元测试（如适用）
5. 提交 PR，描述清楚改动内容

### 代码规范

- 使用 GDScript 2.0 类型注解
- 类名使用 PascalCase，函数/变量使用 snake_case
- 常量使用 UPPER_SNAKE_CASE
- 每个 `.gd` 文件包含 `class_name`（除非是场景局部脚本）
- 公共 API 必须包含文档注释（`##`）

---

## 📄 许可证

本项目采用 **MIT License** — 你可以自由使用、修改、分发，包括商业用途。

---

> 🚀 **GGF — 让每次游戏开发都从第 10% 的进度开始，而不是从零。**
