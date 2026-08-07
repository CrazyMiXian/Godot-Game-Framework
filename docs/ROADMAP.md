# GGF 功能开发路线表

> 从头搭建，逐个模块手动编写调试。按阶段推进，每完成一个功能点勾选 `[x]`。

---

## 0. 项目骨架（一切的前提）

```
res://
├── project.godot              # Godot 项目文件
├── config.json                # 配置文件（放在 res:// 根目录）
├── src/
│   ├── core/                  # 核心层
│   ├── event/                 # 事件总线
│   ├── scene/                 # 场景管理
│   ├── ui/                    # UI 框架
│   ├── audio/                 # 音频管理
│   ├── input/                 # 输入管理
│   ├── data/                  # 数据与存档
│   ├── pool/                  # 对象池
│   ├── entity/                # 实体与角色
│   ├── fsm/                   # 有限状态机
│   ├── ability/               # 技能与 Buff
│   ├── localization/          # 本地化
│   ├── camera/                # 摄像机
│   ├── debug/                 # 调试与性能
│   └── utils/                 # 工具集
└── assets/                    # 框架自带资源
    ├── fonts/
    ├── textures/
    ├── sounds/
    └── shaders/
```

### Phase 0 任务

- [x] 创建 Godot 4 项目
- [x] 建立上述目录结构
- [x] 创建最小 `config.json`
- [x] 配置 `.gitignore`

---

## 依赖关系图

```
                    ┌─────────────┐
                    │   Logger    │  ← 所有模块都依赖它打印日志
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │   Utils  │ │ EventBus │ │ConfigMgr │  ← 无依赖的基础模块
        └──────────┘ └────┬─────┘ └────┬─────┘
                          │            │
              ┌───────────┼────────────┤
              ▼           ▼            ▼
        ┌──────────┐ ┌──────────┐ ┌──────────┐
        │GameManager│ │SceneMgr │ │ SaveSys  │
        └─────┬─────┘ └──────────┘ └──────────┘
              │
    ┌────┬────┼────┬────┬────┬────┐
    ▼    ▼    ▼    ▼    ▼    ▼    ▼
   UI  Audio Input Pool Locale Camera
    │                        │
    ▼                        ▼
┌──────────┐           ┌──────────┐
│  Entity  │           │  Debug   │
└────┬─────┘           │ Console  │
     │                 │ FPS等    │
┌────┼────┐            └──────────┘
▼    ▼    ▼
FSM Buff Ability
```

**开发顺序建议**：从上到下、从左到右。

---

## Phase 1 — 基础层（没有这些，后面寸步难行）

### 1.1 Logger（日志系统）

> **目标**：能往文件和控制台输出日志。这是第一个要写的模块，后续调试全靠它。
>
> **完成标志**：任意脚本中调用 `Logger.info("hello")`，控制台有彩色输出 + `user://logs/` 下有文件。

- [x] 1. `class_name Logger extends Node` — Autoload 注册到 project.godot
- [x] 2. 四级日志 `debug()` `info()` `warn()` `error()` — 低于设定级别的自动跳过
- [x] 3. 控制台彩色输出 — `print_rich` 带颜色区分级别
- [x] 4. 写入日志文件 — `user://logs/game_时间戳.log`
- [x] 5. 自动创建 `logs/` 目录 — `DirAccess.make_dir_recursive_absolute`
- [x] 6. 保留最近 5 个日志文件 — 启动时自动清理旧文件
- [x] 7. `log_level` 支持从 `config.json` 读取（ConfigManager 不存在时默认 `debug`）
- [x] 8. `get_recent(n)` 返回最近 N 条日志 — 供 DebugConsole 调用
- [x] 9. `log_added` 信号 — 实时推送新日志条目
- [x] 10. ERROR 级别自动 `push_error` — 调试构建中弹出断点

---

### 1.2 Utils（工具集）

> **目标**：纯静态工具方法，零依赖，所有模块都会用到。
>
> **完成标志**：调用 `Easing.ease_out_bounce(0.5)` 返回正确值，`FileUtils.read_json` 能正常解析。

- [ ] 1. `Easing` 缓动函数类 — `ease_out_quad` `ease_out_bounce` `ease_out_elastic` `ease_in_out_cubic` 等 10+ 个
- [ ] 2. `RandomUtils.weighted_choice(dict)` — `{"sword":30, "shield":20}` → 按权重返回 key
- [ ] 3. `RandomUtils.shuffle(arr)` — Fisher-Yates 洗牌
- [ ] 4. `RandomUtils.normal_random(mean, std)` — Box-Muller 正态分布随机数
- [ ] 5. `TimeUtils.delay(scene_tree, seconds)` — 返回 `await` 用的 Signal
- [ ] 6. `TimeUtils.wait_frames(scene_tree, frames)` — 等待 N 帧
- [ ] 7. `FileUtils.read_json(path)` — 读取 JSON 文件返回 Dictionary
- [ ] 8. `FileUtils.write_json(path, data)` — 写入 JSON 文件
- [ ] 9. `FileUtils.list_files(dir, ext)` — 列出目录下指定扩展名的文件
- [ ] 10. `GDExtensions.array_random(arr)` — 数组随机取一个元素

---

### 1.3 EventBus（事件总线）

> **目标**：任意模块之间解耦通信，无需持有对方引用。
>
> **完成标志**：A 脚本 `EventBus.on("test", f)`，B 脚本 `EventBus.emit("test", {...})`，A 收到回调。

- [x] 1. `class_name EventBus extends Node` — Autoload
- [x] 2. `on(event_name, callable)` → 返回 `int` 监听 ID — 持久监听
- [x] 3. `once(event_name, callable)` → 返回 `int` — 触发一次后自动移除
- [x] 4. `off(listener_id)` — 通过 ID 取消监听
- [x] 5. `emit(event_name, data)` — data 为 null 时不传参
- [x] 6. `emit_deferred(event_name, data)` — 下一帧触发
- [x] 7. `clear_event(event_name)` — 清除某事件全部监听
- [x] 8. `clear_all()` — 清空所有监听
- [x] 9. 回调中修改监听列表不崩溃 — emit 时先 `duplicate()` 列表再遍历
- [x] 10. `callable.is_valid()` 检查 — 防止已释放对象的回调

---

### 1.4 ConfigManager（配置管理）

> **目标**：从 `config.json` 读配置，支持点号路径访问。
>
> **完成标志**：`ConfigManager.get_value("debug.log_level", "debug")` 在 config.json 中写入 `info` 时返回 `"info"`。

- [x] 1. `class_name ConfigManager extends Node` — Autoload
- [x] 2. `initialize()` 加载 `res://config.json` — 文件不存在时用内置默认配置
- [x] 3. `get_value("audio.bgm_volume", 0.7)` — 点号分隔路径 + 默认值回退
- [x] 4. `get_value` 返回 `Variant` — 调用方自行转换，灵活通用
- [ ] 5. `_default_config()` — 内置默认值，覆盖所有配置项
- [x] 6. JSON 解析错误不崩溃 — `JSON.new().parse()` 错误处理

---

## Phase 2 — 核心层（串联所有系统）

### 2.1 GameManager（框架入口）

> **目标**：生命周期总控，子系统初始化调度，暂停管理。
>
> **完成标志**：启动后控制台按顺序打印各子系统初始化日志，`pause(GAMEPLAY)` 后场景冻结。

- [x] 1. `class_name GameManager extends Node` — Autoload
- [x] 2. `_ready()` 中收集有 `initialize()` 的 Autoload — 遍历 `root.get_children()`
- [x] 3. 按序调用各子系统的 `initialize()` — 顺序 = autoload 声明顺序即可
- [x] 4. `framework_ready` 信号 — 所有初始化完成后发射
- [x] 5. `game_quitting` 信号 — `NOTIFICATION_WM_CLOSE_REQUEST` 时发射
- [x] 6. `register_subsystem(name, node)` — 其他 Autoload 可主动注册
- [x] 7. `get_subsystem(name)` — 按名查找已注册子系统
- [x] 8. 内置 `PauseLayer` 枚举 — `NONE / GAMEPLAY / UI / SYSTEM`
- [x] 9. `pause(layer, source)` → 返回 `int` — 多层暂停栈，返回取消 ID
- [x] 10. `unpause(pause_id)` — 通过 ID 取消暂停
- [x] 11. `is_layer_paused(layer)` — 判断某层是否被暂停
- [x] 12. 暂停自动调用 `get_tree().paused` — GAMEPLAY 及以上层级暂停场景树

---

## Phase 3 — 通用系统层

### 3.1 SceneManager（场景管理）

> **目标**：场景切换 + 过渡动画 + 场景栈 + 子场景层。
>
> **完成标志**：`SceneManager.change_scene("res://b.tscn")` 黑屏过渡→新场景显示→淡入。

- [x] 1. `class_name SceneManager extends Node` — Autoload
- [x] 2. `change_scene(path, data, transition)` — 带过渡的异步场景切换
- [x] 3. `push_scene(path, data, transition)` — 压入新场景，保留当前场景
- [x] 4. `pop_scene(transition)` — 弹出恢复上一层
- [x] 5. `load_progress` 信号 — 异步加载进度 `0~100`
- [x] 6. `scene_changed` 信号 — 切换完成后发射
- [x] 7. `add_sub_scene(layer_name, path, data)` — 叠加子场景（UI层、对话层等）
- [x] 8. 过渡效果 FadeIn/FadeOut — CanvasLayer + ColorRect + Tween
- [x] 9. 场景数据传递 — `_on_scene_enter(data)` 方法约定
- [x] 10. 场景挂起/恢复 — `process_mode = DISABLED/INHERIT`

---

### 3.2 UIManager & UIPanel（UI 框架）

> **目标**：面板管理、弹窗系统、通用组件。
>
> **完成标志**：`UIManager.show_dialog("confirm").set_title("?")...show()` 弹出确认框，确认后回调执行。

- [ ] 1. `class_name UIManager extends Node` — Autoload
- [ ] 2. 创建独立 UI CanvasLayer — 确保 UI 渲染在所有内容之上
- [ ] 3. `show(panel_path, data)` → 返回 UIPanel — 打开面板
- [ ] 4. `close_top()` — 关闭当前最顶层
- [ ] 5. `close_to(panel)` — 关闭到指定面板
- [ ] 6. `show_dialog(type)` → `DialogBuilder` — 链式弹窗 API
- [ ] 7. `class_name UIPanel extends Control` — 面板基类
- [ ] 8. 打开/关闭动画 — AnimationPlayer 驱动 `open`/`close` 动画
- [ ] 9. `pause_game` 属性 — 打开时自动暂停游戏
- [ ] 10. `block_input` 属性 — 拦截背景点击
- [ ] 11. `set_interactable(bool)` — 被覆盖时禁用交互
- [ ] 12. `class_name DialogBuilder extends RefCounted` — 链式构建器
- [ ] 13. 链式方法 `set_title()` `set_content()` `on_confirm()` `on_cancel()` `show()`

---

### 3.3 AudioManager（音频管理）

> **目标**：多频道音频、音量控制、BGM 淡入淡出、音效池。
>
> **完成标志**：`AudioManager.play_bgm(bgm_stream)` 音乐渐入播放，`play_sfx` 多个音效同时响。

- [ ] 1. `class_name AudioManager extends Node` — Autoload
- [ ] 2. 6 个 AudioBus 频道 — Master / BGM / BGS / SFX / Voice / UI
- [ ] 3. `play_bgm(stream, fade_in)` — 背景音乐播放 + 淡入
- [ ] 4. BGM 淡出切换 — 切歌时先淡出再淡入
- [ ] 5. `play_sfx(stream, pitch_var)` — 音效播放，可选随机音高
- [ ] 6. `play_ui_sfx(stream)` — UI 交互音效
- [ ] 7. `set_channel_volume(channel, vol)` — 线性 0-1 映射到 dB
- [ ] 8. 音量从 ConfigManager 恢复 — `initialize()` 中读取
- [ ] 9. SFXPool 音效池 — 预创建 N 个 AudioStreamPlayer，用完回收
- [ ] 10. 池满时临时创建 — 不拒绝播放，池缩容再回收

---

### 3.4 InputManager（输入管理）

> **目标**：输入抽象、按键映射、输入缓冲。
>
> **完成标志**：`InputManager.get_move_vector()` 返回正确的移动方向，缓冲攻击能在动作结束前提前输入。

- [x] 1. `class_name InputManager extends Node` — Autoload
- [x] 2. `is_action_just_pressed(action, buffer_frames)` — 刚按下 + 缓冲帧
- [x] 3. `is_action_just_released(action)` — 刚释放
- [x] 4. `get_action_strength(action)` — 按压强度（0-1）
- [x] 5. `get_move_vector()` — 统一 WASD + 手柄左摇杆
- [x] 6. `get_aim_vector(from_pos)` — 鼠标位置 or 右摇杆方向
- [x] 7. `_ensure_input_map()` — 确保默认 Input Map 存在
- [x] 8. `InputBuffer` 类 — 指令缓冲：`push_event()` `match_sequence()` `clear()`
- [x] 9. 缓冲窗口可配置 — 默认 10 帧

---

### 3.5 SaveSystem（存档系统）

> **目标**：多槽存档、加密、版本迁移、配置独立存储。
>
> **完成标志**：`SaveSystem.save(0, data)` → 重启 → `SaveSystem.load(0)` 数据一致。

- [ ] 1. `class_name SaveSystem extends Node` — Autoload
- [ ] 2. 多槽管理 — `save(slot, SaveData)` `load(slot)` `delete(slot)`
- [ ] 3. `get_slots()` 返回槽列表 — 含元数据（时间、场景、玩家名）
- [ ] 4. AES 加密 — `FileAccess.open_encrypted_with_pass`
- [ ] 5. 版本号 + 迁移管线 — SaveData 带 version 字段
- [ ] 6. `class_name SaveData extends Resource` — 存档数据结构
- [ ] 7. `serialize()` / `deserialize(data)` — Dictionary 序列化
- [ ] 8. 元数据独立存储为 `.json` — 快读槽列表不需解密
- [ ] 9. 自动存档 — 定时器触发 + 事件触发

---

### 3.6 ObjectPool（对象池）

> **目标**：通用对象池，减少频繁创建销毁。
>
> **完成标志**：100 发子弹从池中循环取用，FPS 稳定无 GC 抖动。

- [x] 1. `class_name ObjectPool extends RefCounted` — 不是 Node，轻量
- [x] 2. `_init(scene, parent, preload, max)` — 构造参数
- [x] 3. `acquire()` → Node — 获取实例，自动激活
- [x] 4. `release(instance)` — 回收，自动禁用并从场景树移除
- [x] 5. `release_all()` — 全部回收
- [x] 6. `get_stats()` — 可用数/活跃数/命中率
- [x] 7. 池满拒绝创建 — `acquire()` 返回 null
- [x] 8. 预热 — 构造时 `preload` 个实例就绪
- [x] 9. `pool_initialize()` / `pool_reset()` 约定 — 对象生命周期钩子

---

## Phase 4 — 玩法基础层

### 4.1 Entity & Character（实体与角色）

> **目标**：统一实体基类、属性系统、阵营、伤害计算。
>
> **完成标志**：创建 Orc 阵营敌对 Player，Player 攻击 Orc 伤害递减，Orc 生命归零触发 `die()`。

- [ ] 1. `class_name Entity extends Node2D` — 基础实体
- [ ] 2. `entity_id` 自动生成 — 唯一标识
- [ ] 3. `faction: Faction` — 阵营引用
- [ ] 4. `take_damage(amount, source)` — 伤害接口
- [ ] 5. `take_heal(amount)` — 治疗接口
- [ ] 6. `die()` — 死亡 + `died` 信号
- [ ] 7. `is_alive` — 存活状态
- [ ] 8. `class_name Character extends Entity` — 角色基类
- [ ] 9. `current_health / max_health` — 生命值 + `health_changed` 信号
- [ ] 10. `move_speed` `level` — 基础属性
- [ ] 11. `class_name AttributeContainer extends Resource` — 属性容器
- [ ] 12. `base` `_bonuses` — 基础值 + 加成（平坦 + 倍率）
- [ ] 13. `get_value(name)` — 计算最终值 `(base + flat) * (1 + mult)`
- [ ] 14. `add_bonus(name, flat, mult, source_id)` — 添加加成，按源追踪
- [ ] 15. `remove_bonus(name, source_id)` — 按源移除加成
- [ ] 16. `class_name Faction extends Resource` — 阵营定义
- [ ] 17. `friendly_to[]` `hostile_to[]` — 关系列表
- [ ] 18. `get_relation(other)` — 返回 FRIENDLY / NEUTRAL / HOSTILE
- [ ] 19. 护甲减伤公式 — `defense / (defense + 100)`

---

### 4.2 FSM（有限状态机）

> **目标**：通用状态机，用于角色、UI、AI 等任何需要状态管理的场景。
>
> **完成标志**：角色 idle↔walk↔attack 状态切换流畅，受伤 any→hurt。

- [ ] 1. `class_name StateMachine extends Node` — 附加到实体上
- [ ] 2. `create_state(name, enter, update, physics, exit)` — Callable 注入
- [ ] 3. `add_transition(from, to, condition, priority)` — 条件转换，高优先级先检查
- [ ] 4. `add_any_transition(to, condition, priority)` — 任意状态转入
- [ ] 5. `start(initial_state)` — 设置初始状态并启动
- [ ] 6. `revert_to_previous()` — 返回上一状态
- [ ] 7. `state_changed` 信号 — 状态转换时发射
- [ ] 8. `active` 开关 — 暂停/恢复状态机
- [ ] 9. `class_name State extends RefCounted` — 状态对象
- [ ] 10. `elapsed_time` — 进入该状态以来的时间
- [ ] 11. 转换优先级排序 — 高优先级先检查

---

### 4.3 Ability & Buff（技能与Buff系统）

> **目标**：技能释放流程、冷却、消耗、Buff/Debuff 叠加。
>
> **完成标志**：角色使用"火球术"技能 → 扣蓝 → 冷却 → 对敌人造成伤害并附加"燃烧"Buff（每 2 秒扣血）。

- [ ] 1. `class_name Ability extends Resource` — 技能模板
- [ ] 2. `ability_name` `icon` `cooldown` `cost` — 基础属性
- [ ] 3. `target_type` 枚举 — SELF / SINGLE / AREA / DIRECTIONAL / PROJECTILE
- [ ] 4. `can_use(caster)` — 检查冷却 + 资源
- [ ] 5. `use(caster, target)` — 消耗资源 → 冷却计时 → 执行
- [ ] 6. `get_cooldown_progress()` — 冷却进度 0-1（UI用）
- [ ] 7. `class_name AbilityComponent extends Resource` — 可组合技能组件
- [ ] 8. `CooldownComponent` `CostComponent` 等 — 即插即用
- [ ] 9. `class_name Buff extends Resource` — Buff 模板
- [ ] 10. `duration` `max_stacks` `stack_policy` — 叠加策略（刷新/叠加/拒绝/独立）
- [ ] 11. `attribute_modifiers` — 属性修改字典 `{"strength": {"flat":5, "multiplier":0.1}}`
- [ ] 12. `tick_interval` 周期性效果 — 每 N 秒触发一次
- [ ] 13. `on_apply()` `on_remove()` `on_tick()` — 生命周期回调
- [ ] 14. `class_name BuffContainer extends Node` — 实体上挂载的 Buff 管理器
- [ ] 15. `apply_buff(template, source_id)` — 同名处理（刷新/叠加/拒绝）
- [ ] 16. `remove_buff(buff)` — 移除并清理属性修改
- [ ] 17. `on_damage_taken` 钩子 — Buff 修改伤害值

---

## Phase 5 — 辅助系统

### 5.1 Camera（摄像机）

> **目标**：2D/3D 摄像机控制、跟随、震屏、边界。
>
> **完成标志**：摄像机平滑跟随角色，3 次 `shake(0.5)` 叠加震感增强而非重置。

- [ ] 1. `class_name CameraController2D extends Camera2D` — 2D 摄像机控制器
- [ ] 2. `@export var target: Node2D` — 跟随目标
- [ ] 3. LERP / SNAP / SMOOTH_DAMP 三种跟随模式 — `follow_mode` 枚举
- [ ] 4. `lerp_speed` `smooth_time` — 跟随参数
- [ ] 5. 边界限制 — `limit_rect` 矩形约束
- [ ] 6. 前瞻系统 — 摄像机提前看向移动方向
- [ ] 7. `shake(intensity, duration)` — Trauma-based 震屏
- [ ] 8. `class_name CameraShake extends Node` — 震屏组件
- [ ] 9. 创伤衰减 — `trauma * trauma` 平方映射，震动更自然
- [ ] 10. FastNoiseLite 驱动 — 每次震动轨迹不同
- [ ] 11. `set_zoom_smooth(target, duration)` — 平滑缩放

---

### 5.2 Localization（本地化）

> **目标**：多语言文本、运行时切换、占位符替换。
>
> **完成标志**：`LocaleManager.tr("ui.confirm")` 中文返回"确认"，切 `en_US` 后返回"Confirm"。

- [ ] 1. `class_name LocaleManager extends Node` — Autoload
- [ ] 2. CSV 翻译文件 — `key,value` 格式
- [ ] 3. `tr(key, placeholders)` — 翻译 + `{name}` 占位符替换
- [ ] 4. `locale_changed` 信号 — 语言切换时发射
- [ ] 5. 语言从 ConfigManager 读取 — ConfigManager 不存在时默认 `zh_CN`
- [ ] 6. `class_name LocaleText extends Node` — 附加到 Control 节点自动翻译
- [ ] 7. 自动匹配 Label / Button / LineEdit — 无需手动设置 text
- [ ] 8. `supported_locales` 列表 — 声明支持的语言

---

### 5.3 Debug（调试工具）

> **目标**：游戏内控制台、性能面板、DebugDraw、Cheat 系统。
>
> **完成标志**：按 `~` 打开控制台，输入 `fps` 显示帧率面板，DebugDraw 绘制角色碰撞体。

- [ ] 1. `class_name DebugConsole extends Control` — `~` 键开关
- [ ] 2. 命令注册系统 — `register_command(name, callback, help)`
- [ ] 3. 内建命令 `help` `clear` `fps` `list_nodes`
- [ ] 4. 命令历史 — ↑↓ 键浏览历史
- [ ] 5. `class_name FPSMonitor extends Control` — FPS + 内存 + 对象数
- [ ] 6. FPS 面板可切换显隐 — EventBus 控制
- [ ] 7. `class_name DebugDraw extends Node2D` — 运行时绘制调试图形
- [ ] 8. `line()` `circle()` `rect()` `arrow()` — 静态便捷方法
- [ ] 9. 每帧自动清空 — `_process` 中 clear + `queue_redraw`
- [ ] 10. `class_name CheatManager extends Node` — Autoload，仅 debug 构建启用
- [ ] 11. `register_cheat(name)` `is_enabled(name)` `toggle(name)` — 作弊开关管理

---

## Phase 6 — 收尾

- [ ] `examples/minimal/` — 最小化示例项目
- [ ] 测试：每个模块写 1 个简单用例脚本
- [ ] `CHANGELOG.md`
- [ ] 清理所有 `print()` 诊断代码（或改为 Logger.debug）
- [ ] 导出配置：`project.godot` 最终 autoreload 顺序确认

---

## 配置文件（`res://config.json`）

开发过程中保持最小配置即可，随模块增加逐步扩展：

```json
{
    "debug": {
        "log_level": "debug",
        "show_fps": false,
        "enable_console": true,
        "enable_cheats": true
    },
    "locale": "zh_CN",
    "audio": {
        "master_volume": 0.8,
        "bgm_volume": 0.7,
        "sfx_volume": 1.0,
        "voice_volume": 0.9
    },
    "save": {
        "auto_save_interval_seconds": 300,
        "max_slots": 10
    }
}
```

---

## 每个模块的通用开发流程

```
1. 创建 .gd 文件 → class_name 或场景
2. 写 docstring（## 注释）
3. 写信号声明
4. 写 @export 变量
5. 写公开方法
6. 写私有方法
7. 在 _ready() 或测试脚本中验证
```

> 每完成一个功能点勾选 `[x]`，遇到问题在勾选框旁备注原因。
