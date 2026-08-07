# GGF — Godot 4 具体实现方案

> 本文档详细描述 GGF 框架在 Godot 4 中的具体实现方法，涵盖 Autoload 配置、类设计、节点结构、GDScript 2.0 API 设计。

---

## 目录

- [0. 全局约定](#0-全局约定)
- [1. 项目结构与 Autoload 配置](#1-项目结构与-autoload-配置)
- [2. Core — 核心框架](#2-core--核心框架)
- [3. EventBus — 事件总线](#3-eventbus--事件总线)
- [4. Scene — 场景管理](#4-scene--场景管理)
- [5. UI — UI 框架](#5-ui--ui-框架)
- [6. Audio — 音频管理](#6-audio--音频管理)
- [7. Input — 输入管理](#7-input--输入管理)
- [8. Data — 数据与存档](#8-data--数据与存档)
- [9. Pool — 对象池](#9-pool--对象池)
- [10. Entity — 实体与角色](#10-entity--实体与角色)
- [11. FSM — 有限状态机](#11-fsm--有限状态机)
- [12. Ability & Buff — 技能与Buff](#12-ability--buff--技能与buff)
- [13. Localization — 本地化](#13-localization--本地化)
- [14. Camera — 摄像机](#14-camera--摄像机)
- [15. Debug — 调试与性能](#15-debug--调试与性能)
- [16. Utils — 工具集](#16-utils--工具集)
- [17. Autoload 初始化顺序与依赖拓扑](#17-autoload-初始化顺序与依赖拓扑)

---

## 0. 全局约定

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| `class_name` | PascalCase，不缩写 | `GameManager`, `EventBus`, `ObjectPool` |
| 文件 | snake_case | `game_manager.gd`, `event_bus.gd` |
| 函数 | snake_case，动词开头 | `get_config()`, `spawn_entity()` |
| 变量 | snake_case | `current_scene`, `pool_size` |
| 常量 | UPPER_SNAKE_CASE | `MAX_POOL_SIZE`, `DEFAULT_FADE_DURATION` |
| 信号 | snake_case，过去式 | `scene_changed`, `player_died` |
| `@export` 变量 | snake_case + 类型注解 | `@export var max_health: float = 100.0` |

### 类型注解

所有公共 API 必须有完整的类型注解。利用 GDScript 2.0 的类型系统：

```gdscript
func acquire() -> Node:
func change_scene(path: String, transition: TransitionType = TransitionType.FADE) -> void:
signal health_changed(current: float, maximum: float)
```

### 注释规范

```gdscript
## 场景管理器 — 管理场景切换、场景栈和过渡效果。[br]
## [br]
## 使用示例: [codeblock]
##   SceneManager.change_scene("res://game.tscn", {transition = "fade"})
## [/codeblock]
class_name SceneManager
extends Node
```

---

## 1. 项目结构与 Autoload 配置

### 1.1 `project.godot` 中的 Autoload 声明

Autoload 是 Godot 的全局单例机制，在项目启动时自动加载。框架核心模块以此为载体。

```ini
; project.godot — [autoload] 段

[autoload]

; ═══════ 第一层：无依赖基础 ═══════
GameManager="*res://src/core/game_manager.gd"
EventBus="*res://src/event/event_bus.gd"
ConfigManager="*res://src/core/config_manager.gd"
Logger="*res://src/debug/logger.gd"

; ═══════ 第二层：依赖 Core/EventBus ═══════
SceneManager="*res://src/scene/scene_manager.gd"
UIManager="*res://src/ui/ui_manager.gd"
AudioManager="*res://src/audio/audio_manager.gd"
InputManager="*res://src/input/input_manager.gd"
SaveSystem="*res://src/data/save_system.gd"
LocaleManager="*res://src/localization/locale_manager.gd"

; ═══════ 第三层：玩法相关（依赖上层服务） ═══════
CheatManager="*res://src/debug/cheat_manager.gd"
```

> `*` 前缀表示该 Autoload 在场景切换时**不被移除**。所有框架 Autoload 都标记为 `*`。

### 1.2 完整目录结构

```
res://
├── project.godot
│
├── src/                                    # 框架源码
│   ├── core/
│   │   ├── game_manager.gd                 # GameManager (Autoload)
│   │   ├── config_manager.gd               # ConfigManager (Autoload)
│   │   └── pause_manager.gd                # PauseManager (普通类，由 GameManager 创建)
│   │
│   ├── event/
│   │   └── event_bus.gd                    # EventBus (Autoload)
│   │
│   ├── scene/
│   │   ├── scene_manager.gd                # SceneManager (Autoload)
│   │   ├── scene_transition.gd             # 过渡效果（CanvasLayer 场景 + 脚本）
│   │   └── scene_transition.tscn
│   │
│   ├── ui/
│   │   ├── ui_manager.gd                   # UIManager (Autoload)
│   │   ├── ui_panel.gd                     # 面板基类（class_name，非 Autoload）
│   │   ├── ui_button.gd                    # 增强按钮组件
│   │   ├── ui_health_bar.gd               # 血条组件
│   │   ├── dialog/
│   │   │   ├── dialog_manager.gd
│   │   │   ├── dialog_base.gd
│   │   │   └── dialog_base.tscn
│   │   └── themes/
│   │       └── default_theme.tres          # 默认 UI 主题
│   │
│   ├── audio/
│   │   ├── audio_manager.gd                # AudioManager (Autoload)
│   │   └── sfx_pool.gd                     # SFXPool (普通类)
│   │
│   ├── input/
│   │   ├── input_manager.gd                # InputManager (Autoload)
│   │   └── input_buffer.gd                # InputBuffer (普通类)
│   │
│   ├── data/
│   │   ├── save_system.gd                  # SaveSystem (Autoload)
│   │   ├── save_data.gd                    # SaveData (Resource 子类)
│   │   └── config_store.gd                # ConfigStore (普通类)
│   │
│   ├── pool/
│   │   └── object_pool.gd                  # ObjectPool (class_name，非 Autoload)
│   │
│   ├── entity/
│   │   ├── entity.gd                       # Entity (class_name)
│   │   ├── character.gd                    # Character (class_name)
│   │   ├── attribute_container.gd          # AttributeContainer (Resource)
│   │   └── faction.gd                      # Faction (Resource)
│   │
│   ├── fsm/
│   │   ├── state_machine.gd                # StateMachine (class_name)
│   │   └── state.gd                        # State (RefCounted)
│   │
│   ├── ability/
│   │   ├── ability.gd                      # Ability (Resource)
│   │   ├── ability_component.gd            # 组件基类 (Resource)
│   │   ├── cooldown_component.gd
│   │   ├── cost_component.gd
│   │   ├── buff.gd                         # Buff (Resource)
│   │   └── buff_container.gd               # BuffContainer (class_name)
│   │
│   ├── localization/
│   │   ├── locale_manager.gd               # LocaleManager (Autoload)
│   │   └── locale_data.gd                  # LocaleData (Resource)
│   │
│   ├── camera/
│   │   ├── camera_controller_2d.gd         # CameraController2D (class_name)
│   │   ├── camera_controller_3d.gd
│   │   └── camera_shake.gd                 # CameraShake (class_name, 组件)
│   │
│   ├── debug/
│   │   ├── logger.gd                       # Logger (Autoload)
│   │   ├── debug_console.gd                # DebugConsole (class_name, 场景)
│   │   ├── debug_console.tscn
│   │   ├── fps_monitor.gd                  # FPSMonitor (class_name, 场景)
│   │   ├── fps_monitor.tscn
│   │   ├── debug_draw.gd                   # DebugDraw (class_name)
│   │   └── cheat_manager.gd               # CheatManager (Autoload)
│   │
│   └── utils/
│       ├── math_utils.gd                   # 静态方法类
│       ├── easing.gd                       # 缓动函数库（静态 const dict）
│       ├── random_utils.gd                 # 随机工具
│       ├── time_utils.gd                   # 时间工具
│       ├── file_utils.gd                   # 文件工具
│       └── gd_extensions.gd               # GD 类型扩展（static 方法）
│
├── assets/                                 # 框架自带资源
│   ├── fonts/
│   │   └── default_font.tres
│   ├── textures/
│   │   ├── white_1x1.png                  # 1×1 白色贴图（代码生成纯色块用）
│   │   └── icon_placeholder.svg
│   ├── sounds/
│   │   └── ui_click.wav
│   ├── shaders/
│   │   ├── fade_transition.gdshader        # 全屏淡入淡出
│   │   └── ui_ripple.gdshader
│   ├── default_bus_layout.tres             # 默认 AudioBus 布局
│   └── default_input_map.tres              # 默认输入映射
│
├── examples/                               # 示例
│   ├── minimal/
│   ├── platformer/
│   ├── rpg/
│   └── ui_demo/
│
├── docs/
│   └── api/
│
└── tests/
    └── unit/
```

### 1.3 为什么有些模块是 Autoload，有些不是？

| 模块 | Autoload? | 理由 |
|------|-----------|------|
| GameManager | ✅ | 唯一入口，全局访问 |
| EventBus | ✅ | 全局发布订阅 |
| ConfigManager | ✅ | 全局配置读取 |
| Logger | ✅ | 任何地方都要打日志 |
| SceneManager | ✅ | 任何地方都可能触发场景切换 |
| UIManager | ✅ | 全局 UI 面板调度 |
| AudioManager | ✅ | 全局音效播放 |
| InputManager | ✅ | 全局输入抽象 |
| SaveSystem | ✅ | 全局存档读写 |
| LocaleManager | ✅ | 全局文本翻译 |
| CheatManager | ✅ | 开发期全局作弊 |
| **ObjectPool** | ❌ | 每个池独立实例，通过 `ObjectPool.new()` 创建 |
| **StateMachine** | ❌ | 每个实体有自己的状态机实例 |
| **Entity/Character** | ❌ | 场景中的节点，`extends Character` |
| **Ability/Buff** | ❌ | Resource，挂载到实体上 |
| **PauseManager** | ❌ | 由 GameManager 内部管理，不对外暴露 |
| **SFXPool** | ❌ | 由 AudioManager 内部管理 |
| **CameraShake** | ❌ | 作为组件附加到 Camera2D/3D 上 |

---

## 2. Core — 核心框架

### 2.1 GameManager（Autoload） Done

**职责**：框架入口，子系统初始化调度，生命周期分发，暂停状态管理。

```gdscript
# src/core/game_manager.gd
class_name GameManager
extends Node

## 框架初始化完成信号 — 所有 Autoload 就绪后发射
signal framework_ready()
## 游戏即将退出信号 — 用于保存数据、释放资源
signal game_quitting()

# 暴露 PauseLayer 枚举（定义在 PauseManager 中，这里做别名方便外部引用）
const PauseLayer := PauseManager.PauseLayer

## 子系统注册表 — 声明每个子系统的初始化顺序和依赖
var _subsystems: Array[SubsystemEntry] = []

## 暂停管理器实例
var _pause_manager: PauseManager

# 内部类（定义在本文件底部或单独文件）
class SubsystemEntry:
    var name: String
    var node: Node
    var priority: int       # 数值越低越先初始化
    var depends_on: Array[String]  # 依赖的其他子系统名

    func _init(p_name: String, p_node: Node, p_priority: int = 0, p_depends: Array[String] = []):
        name = p_name
        node = p_node
        priority = p_priority
        depends_on = p_depends


func _ready() -> void:
    print("[GameManager] _ready() 开始 — 当前 Autoload 子节点:")
    for child in get_tree().root.get_children():
        print("  └─ %s (%s)" % [child.name, child.get_script().resource_path if child.get_script() else "no_script"])

    # 0. 初始化暂停管理器
    _pause_manager = PauseManager.new()

    # 1. 收集所有 Autoload 作为子系统（除自己）
    _collect_subsystems()
    print("[GameManager] 收集到 %d 个子系统:" % _subsystems.size())
    for entry in _subsystems:
        print("  └─ %s (has initialize: %s)" % [entry.name, entry.node.has_method("initialize")])

    # 2. 拓扑排序
    var sorted := _topological_sort(_subsystems)
    print("[GameManager] 拓扑排序结果 (%d 个):" % sorted.size())
    for entry in sorted:
        print("  └─ %s" % entry.name)

    # 3. 按顺序调用每个子系统的 initialize()
    for entry in sorted:
        if entry.node.has_method("initialize"):
            print("[GameManager] → 调用 %s.initialize()" % entry.name)
            entry.node.initialize()
            print("[GameManager] ← %s.initialize() 完成" % entry.name)

    # 4. 发射就绪信号
    framework_ready.emit()
    print("[GameManager] framework_ready 已发射")
    Logger.info("框架初始化完成", self)


func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        game_quitting.emit()
        # 给子系统机会保存
        for entry in _subsystems:
            if entry.node.has_method("shutdown"):
                entry.node.shutdown()
        get_tree().quit()


## 注册一个子系统（各 Autoload 在自己的 _ready 中调用）
func register_subsystem(p_name: String, p_node: Node, p_priority: int = 0, p_depends: Array[String] = []) -> void:
    _subsystems.append(SubsystemEntry.new(p_name, p_node, p_priority, p_depends))


## 获取一个已注册的子系统
func get_subsystem(p_name: String) -> Node:
    for entry in _subsystems:
        if entry.name == p_name:
            return entry.node
    return null


# ────────────────────────────────────────
# 内部方法：收集子系统 & 拓扑排序
# ────────────────────────────────────────

## 从 Autoload 列表中收集所有子系统节点
func _collect_subsystems() -> void:
    # 获取当前场景树 root 的所有子节点（Autoload 都在 root 下）
    var root := get_tree().root
    for child in root.get_children():
        if child == self:
            continue
        # 只收集有 initialize() 方法的 Autoload
        if child.has_method("initialize"):
            # 默认优先级 0，无依赖
            _subsystems.append(SubsystemEntry.new(child.name, child, 0, []))


## 拓扑排序（Kahn 算法）
func _topological_sort(entries: Array[SubsystemEntry]) -> Array[SubsystemEntry]:
    # 构建入度表和图
    var in_degree: Dictionary = {}
    var graph: Dictionary = {}  # name → Array[String]（依赖此节点的其他节点）
    var name_to_entry: Dictionary = {}

    for entry in entries:
        var n := entry.name
        if not in_degree.has(n):
            in_degree[n] = 0
        if not graph.has(n):
            graph[n] = []
        name_to_entry[n] = entry

    for entry in entries:
        for dep in entry.depends_on:
            if not graph.has(dep):
                graph[dep] = []
            graph[dep].append(entry.name)
            in_degree[entry.name] = in_degree.get(entry.name, 0) + 1

    # 入度为 0 的节点入队（按 priority 排序以保持稳定顺序）
    var queue: Array[String] = []
    for entry in entries:
        if in_degree.get(entry.name, 0) == 0:
            queue.append(entry.name)
    queue.sort_custom(func(a, b): return name_to_entry[a].priority < name_to_entry[b].priority)

    var result: Array[SubsystemEntry] = []

    while not queue.is_empty():
        var current := queue.pop_front()
        result.append(name_to_entry[current])

        for neighbor in graph.get(current, []):
            in_degree[neighbor] = in_degree[neighbor] - 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)
                queue.sort_custom(func(a, b): return name_to_entry[a].priority < name_to_entry[b].priority)

    # 检测环
    if result.size() != entries.size():
        Logger.warn("子系统依赖图中存在循环依赖！已返回部分排序结果", self)

    return result


# ────────────────────────────────────────
# 暂停管理（代理到内部 PauseManager）
# ────────────────────────────────────────

## 请求暂停
func pause(layer: PauseManager.PauseLayer = PauseManager.PauseLayer.GAMEPLAY, source: String = "unknown") -> int:
    return _pause_manager.pause(layer, source)


## 取消暂停
func unpause(pause_id: int) -> void:
    _pause_manager.unpause(pause_id)


## 判断某层是否被暂停
func is_layer_paused(layer: PauseManager.PauseLayer) -> bool:
    return _pause_manager.is_layer_paused(layer)
```

**关键实现细节**：

- `_ready()` 不会阻塞——如果子系统的 `initialize()` 是异步的（比如预加载资源），用 `await initialize()`。这与 Godot 4 的异步机制完美配合。
- 拓扑排序确保 AudioManager 在 UIManager 之前初始化（因为 UI 按钮需要音效）。
- `NOTIFICATION_WM_CLOSE_REQUEST` 是 Godot 4 的新通知，比 `get_tree().auto_accept_quit` 更精细。

### 2.2 ConfigManager（Autoload） Done

**职责**：读取配置文件，提供统一配置访问接口。

```gdscript
# src/core/config_manager.gd
extends Node

## 配置数据缓存
var _config: Dictionary = {}

## 配置文件路径（在 project.godot 中可通过 @export 预设在场景中，但 Autoload 场景不可见）
## 因此通过代码设置或使用默认路径
const CONFIG_PATH := "res://config.json"


func initialize() -> void:
    _load_config()


func _load_config() -> void:
    if not FileAccess.file_exists(CONFIG_PATH):
        Logger.warn("配置文件 %s 不存在，使用默认配置" % CONFIG_PATH, self)
        _config = _default_config()
        return

    var file := FileAccess.getopen(CONFIG_PATH, FileAccess.READ)
    if file == null:
        Logger.error("无法读取配置文件: %s" % CONFIG_PATH, self)
        return

    var text := file.get_as_text()
    file.close()

    var json := JSON.new()
    var error := json.parse(text)
    if error != OK:
        Logger.error("配置文件 JSON 解析失败: %s" % json.get_error_message(), self)
        return

    _config = json.data


## 获取配置项（支持点号分隔的路径）
func get_value(path: String, default = null):
    var keys := path.split(".")
    var current = _config
    for key in keys:
        if not current is Dictionary or not current.has(key):
            return default
        current = current[key]
    return current


func _default_config() -> Dictionary:
    return {
        "audio": {
            "master_volume": 1.0,
            "bgm_volume": 0.8,
            "sfx_volume": 1.0,
            "voice_volume": 1.0
        },
        "display": {
            "fullscreen": false,
            "vsync": true,
            "resolution_scale": 1.0
        },
        "input": {
            "deadzone": 0.2
        },
        "debug": {
            "show_fps": false,
            "log_level": "info"
        }
    }
```

配置示例 `config.json`：

```json
{
    "audio": {
        "master_volume": 0.8,
        "bgm_volume": 0.7,
        "sfx_volume": 1.0,
        "voice_volume": 0.9
    },
    "display": {
        "fullscreen": false,
        "vsync": true,
        "resolution_scale": 1.0
    },
    "debug": {
        "show_fps": true,
        "log_level": "debug"
    }
}
```

### 2.3 PauseManager（普通类，非 Autoload） Done

**职责**：多层暂停栈。UI 打开时暂停游戏逻辑，但菜单本身仍可操作；系统对话框弹出时连 UI 也暂停。

```gdscript
# src/core/pause_manager.gd
class_name PauseManager
extends RefCounted  # 不需要节点树，纯逻辑类

enum PauseLayer {
    NONE = 0,
    GAMEPLAY = 1,     # 游戏逻辑层
    UI = 2,            # UI 操作层
    SYSTEM = 3,        # 系统层（最高层，连 UI 也冻结）
}

class PauseEntry:
    var layer: PauseLayer
    var source: String   # 谁发起的暂停（用于调试）
    var id: int          # 唯一 ID，用于取消暂停

    func _init(p_layer: PauseLayer, p_source: String, p_id: int):
        layer = p_layer
        source = p_source
        id = p_id


var _pause_stack: Array[PauseEntry] = []
var _next_id: int = 0

## 当前生效的暂停层
var current_pause_layer: PauseLayer = PauseLayer.NONE:
    get = _get_max_layer


## 请求暂停
func pause(layer: PauseLayer = PauseLayer.GAMEPLAY, source: String = "unknown") -> int:
    var id := _next_id
    _next_id += 1
    _pause_stack.append(PauseEntry.new(layer, source, id))

    var previous := current_pause_layer
    _apply_pause_state(previous, current_pause_layer)

    return id


## 取消暂停
func unpause(pause_id: int) -> void:
    var idx := -1
    for i in range(_pause_stack.size()):
        if _pause_stack[i].id == pause_id:
            idx = i
            break

    if idx == -1:
        return

    var previous := current_pause_layer
    _pause_stack.remove_at(idx)

    _apply_pause_state(previous, current_pause_layer)


func _get_max_layer() -> PauseLayer:
    if _pause_stack.is_empty():
        return PauseLayer.NONE
    var max_layer := PauseLayer.NONE
    for entry in _pause_stack:
        if entry.layer > max_layer:
            max_layer = entry.layer
    return max_layer


func _apply_pause_state(old_layer: PauseLayer, new_layer: PauseLayer) -> void:
    var tree := Engine.get_main_loop() as SceneTree
    if tree == null:
        return

    # Godot 的 process_mode 在场景树节点上
    # 我们发射事件让各系统自行处理
    EventBus.emit("pause_changed", {
        "old_layer": old_layer,
        "new_layer": new_layer,
    })

    # 同时直接控制 SceneTree 的 pause
    tree.paused = (new_layer >= PauseLayer.GAMEPLAY)


## 判断某层是否被暂停
func is_layer_paused(layer: PauseLayer) -> bool:
    return current_pause_layer >= layer
```

**使用方式**：

```gdscript
# UI 面板打开时暂停游戏
var pause_id = GameManager.pause(GameManager.PauseLayer.GAMEPLAY, "inventory_ui")

# 关闭时恢复
GameManager.unpause(pause_id)
```

> GameManager 内部持有一个 `PauseManager` 实例，对外暴露代理方法。

---

## 3. EventBus — 事件总线

### 3.1 核心实现  Done   当前问题：一次性生成大量对象会缺失一部分对象。   可能是单帧无法一次性执行大量指令，需要手动添加时延

```gdscript
# src/event/event_bus.gd
class_name EventBus
extends Node

## 监听器存储：{ event_name: [{callable, flags, id}] }
var _listeners: Dictionary = {}
var _listener_id_counter: int = 0

## 事件日志（调试用）
var _event_log: Array[Dictionary] = []
var _log_enabled: bool = false


## 注册一个持久监听
func on(event_name: String, callable: Callable) -> int:
    return _add_listener(event_name, callable, false)


## 注册一次性监听（触发一次后自动移除）
func once(event_name: String, callable: Callable) -> int:
    return _add_listener(event_name, callable, true)


## 取消监听
func off(listener_id: int) -> void:
    for event_name in _listeners:
        var listeners: Array = _listeners[event_name]
        for i in range(listeners.size() - 1, -1, -1):
            if listeners[i].id == listener_id:
                listeners.remove_at(i)
                return


## 发射事件
func emit(event_name: String, data = null) -> void:
    # 调试日志
    if _log_enabled:
        _event_log.append({
            "name": event_name,
            "data": data,
            "frame": Engine.get_process_frames(),
            "time": Time.get_ticks_msec(),
        })

    if not _listeners.has(event_name):
        return

    # 复制一份再遍历（因为回调可能修改 _listeners）
    var listeners: Array = _listeners[event_name].duplicate()

    for listener in listeners:
        if listener.once:
            _remove_listener_entry(event_name, listener.id)

        if listener.callable.is_valid():
            # 根据数据是否为 null 决定传参
            if data == null:
                listener.callable.call()
            else:
                listener.callable.call(data)


## 发射延迟事件（下一帧触发）
func emit_deferred(event_name: String, data = null) -> void:
    call_deferred("emit", event_name, data)


func _add_listener(event_name: String, callable: Callable, once: bool) -> int:
    _listener_id_counter += 1
    var id := _listener_id_counter

    if not _listeners.has(event_name):
        _listeners[event_name] = []

    _listeners[event_name].append({
        "id": id,
        "callable": callable,
        "once": once,
    })

    return id


func _remove_listener_entry(event_name: String, listener_id: int) -> void:
    if not _listeners.has(event_name):
        return
    var listeners: Array = _listeners[event_name]
    for i in range(listeners.size() - 1, -1, -1):
        if listeners[i].id == listener_id:
            listeners.remove_at(i)
            return


## 清除某事件的所有监听
func clear_event(event_name: String) -> void:
    _listeners.erase(event_name)


## 清除所有监听
func clear_all() -> void:
    _listeners.clear()


## 开启/关闭事件日志
func set_log_enabled(enabled: bool) -> void:
    _log_enabled = enabled
    if enabled:
        _event_log.clear()
```

**关键设计决策**：
- 用 `int` 作为监听 ID（而非 Callable 本身），因为 Callable 可能指向不同对象的同名方法，无法唯一标识。
- `emit()` 中先复制 `_listeners` 再遍历，因为回调中可能调用 `off()` 修改原始列表。
- `callable.is_valid()` 检查防止引用已释放对象导致崩溃（Godot 4 的 Callable 自带此检查）。
- 数据通过 `Dictionary` 传递而非多个参数——调用方和监听方通过字段名约定通信，解耦更强。

### 3.2 使用模式

```gdscript
# 玩家死亡发射事件
EventBus.emit("player_died", {
    "player_id": 1,
    "killer": "enemy_orc",
    "position": player.global_position,
})

# UI 监听
var _listener_id: int

func _ready():
    _listener_id = EventBus.on("player_died", _on_player_died)

func _on_player_died(data: Dictionary):
    print("玩家 %d 被 %s 击杀" % [data.player_id, data.killer])

func _exit_tree():
    EventBus.off(_listener_id)  # 重要：防止悬垂引用
```

---

## 4. Scene — 场景管理

### 4.1 SceneManager（Autoload） Done

**职责**：场景切换、场景栈、异步加载、过渡效果。

```gdscript
# src/scene/scene_manager.gd
class_name SceneManager
extends Node

## 场景切换完成信号
signal scene_changed(new_scene_path: String)
## 场景加载进度信号
signal load_progress(progress: float)

enum TransitionType { NONE, FADE, SLIDE_LEFT, SLIDE_RIGHT, CUSTOM }

## 场景栈
var _scene_stack: Array[SceneStackEntry] = []

class SceneStackEntry:
    var path: String
    var node: Node    # 挂起的场景根节点
    var data: Dictionary  # 传递给场景的参数


func initialize() -> void:
    # 创建过渡效果 CanvasLayer
    _create_transition_layer()


func _create_transition_layer() -> void:
    var transition_scene := load("res://src/scene/scene_transition.tscn")
    var transition := transition_scene.instantiate()
    transition.name = "SceneTransition"
    # 作为 GameManager 的子节点，确保在场景切换过程中存活
    get_tree().root.call_deferred("add_child", transition)


## 切换场景（替换当前场景）
func change_scene(p_path: String, p_data: Dictionary = {}, p_transition: TransitionType = TransitionType.FADE) -> void:
    _change_scene_internal(p_path, p_data, p_transition, false)


## 压入场景（保留当前场景）
func push_scene(p_path: String, p_data: Dictionary = {}, p_transition: TransitionType = TransitionType.FADE) -> void:
    _change_scene_internal(p_path, p_data, p_transition, true)


## 弹出当前场景，恢复上一层
func pop_scene(p_transition: TransitionType = TransitionType.FADE) -> void:
    if _scene_stack.is_empty():
        Logger.warn("场景栈为空，无法 pop", self)
        return

    await _play_transition(p_transition, true)  # true = 出动画

    # 移除当前场景
    var current := _scene_stack.pop_back()

    # 恢复上一层
    if not _scene_stack.is_empty():
        var previous := _scene_stack.back()
        # 重新激活挂起的场景
        previous.node.process_mode = Node.PROCESS_MODE_INHERIT
        if previous.node.has_method("_on_scene_resumed"):
            previous.node._on_scene_resumed(current.data)

    await _play_transition(p_transition, false)  # false = 入动画


func _change_scene_internal(p_path: String, p_data: Dictionary, p_transition: TransitionType, p_push: bool) -> void:
    await _play_transition(p_transition, true)

    # 挂起当前场景
    var current_root := get_tree().current_scene
    if current_root and not p_push:
        current_root.queue_free()
    elif current_root:
        # push: 挂起但不删除
        current_root.process_mode = Node.PROCESS_MODE_DISABLED
        _scene_stack.back().node = current_root

    # 异步加载新场景
    var loader := ResourceLoader.load_threaded_request(p_path)
    if loader != OK:
        Logger.error("场景加载失败: %s" % p_path, self)
        return

    # 显示加载进度
    while true:
        var status := ResourceLoader.load_threaded_get_status(p_path)
        match status:
            ResourceLoader.THREAD_LOAD_IN_PROGRESS:
                var progress_array := []
                var progress := ResourceLoader.load_threaded_get_status(p_path, progress_array)
                load_progress.emit(progress_array[0] * 100.0 if progress_array.size() > 0 else 0.0)
            ResourceLoader.THREAD_LOAD_LOADED:
                break
            ResourceLoader.THREAD_LOAD_FAILED:
                Logger.error("场景资源加载失败: %s" % p_path, self)
                return
        await get_tree().process_frame

    var new_scene: PackedScene = ResourceLoader.load_threaded_get(p_path)
    var new_root := new_scene.instantiate()

    # 压入场景栈
    _scene_stack.append(SceneStackEntry.new(p_path, new_root, p_data))

    # 添加到场景树
    get_tree().root.add_child(new_root)
    get_tree().current_scene = new_root

    # 传递数据
    if new_root.has_method("_on_scene_enter"):
        new_root._on_scene_enter(p_data)

    scene_changed.emit(p_path)

    await _play_transition(p_transition, false)
```

### 4.2 过渡效果（scene_transition.tscn） Done

```
SceneTransition (CanvasLayer)
├── ColorRect (全屏黑色，初始 alpha=0)
│   └── AnimationPlayer (控制 alpha 动画)
└── 进度条（可选，异步加载时显示）
```

```gdscript
# src/scene/scene_transition.gd
class_name SceneTransition
extends CanvasLayer

@onready var _color_rect: ColorRect = $ColorRect
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _progress_bar: ProgressBar = $ProgressBar


func fade_out(duration: float = 0.5) -> void:
    _color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击穿透
    var tween := create_tween()
    tween.tween_property(_color_rect, "color:a", 1.0, duration)
    await tween.finished


func fade_in(duration: float = 0.5) -> void:
    var tween := create_tween()
    tween.tween_property(_color_rect, "color:a", 0.0, duration)
    await tween.finished
    _color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_progress(value: float) -> void:
    if _progress_bar:
        _progress_bar.value = value
```

> Godot 4 中 `create_tween()` 替代了 Godot 3 的 `Tween` 节点，API 更简洁。

### 4.3 场景层（Layer）机制

除了场景栈，还需要"叠加场景"——比如 UI 层永远在游戏世界上方：

```gdscript
# 在 SceneManager 中扩展

## 场景层容器
var _layers: Dictionary = {}  # { "gameworld": Node, "ui": Node, "overlay": Node }

func _ready():
    # 在 root 上创建固定层
    _layers["gameworld"] = _create_layer("Layer_GameWorld", 0)
    _layers["ui"] = _create_layer("Layer_UI", 1)
    _layers["overlay"] = _create_layer("Layer_Overlay", 2)


func _create_layer(name: String, z_index: int) -> Node:
    var layer := Node.new()
    layer.name = name
    get_tree().root.add_child(layer)
    return layer


## 在指定层加载子场景
func add_sub_scene(layer_name: String, scene_path: String, data: Dictionary = {}) -> Node:
    var scene: PackedScene = load(scene_path)
    var instance := scene.instantiate()
    _layers[layer_name].add_child(instance)

    if instance.has_method("_on_scene_enter"):
        instance._on_scene_enter(data)

    return instance
```

使用：
```gdscript
# 加载游戏世界
SceneManager.add_sub_scene("gameworld", "res://scenes/world.tscn")
# 加载 HUD（永远在上层）
SceneManager.add_sub_scene("ui", "res://ui/hud.tscn")
```

---

## 5. UI — UI 框架

### 5.1 UIManager（Autoload）koi

```gdscript
# src/ui/ui_manager.gd
class_name UIManager
extends Node

## UI 面板栈
var _panel_stack: Array[UIPanel] = []

## UI Canvas 层引用
var _ui_layer: CanvasLayer


func initialize() -> void:
    _ui_layer = CanvasLayer.new()
    _ui_layer.name = "UILayer"
    _ui_layer.layer = 100  # 确保在一切之上
    get_tree().root.add_child(_ui_layer)
    # 不移除——持续存活
    _ui_layer.owner = get_tree().root


## 打开一个面板（场景路径）
func show(panel_path: String, data: Dictionary = {}) -> UIPanel:
    var scene: PackedScene = load(panel_path)
    var panel: UIPanel = scene.instantiate()
    _ui_layer.add_child(panel)

    # 如果已有面板，把之前的设为非交互
    if not _panel_stack.is_empty():
        _panel_stack.back().set_interactable(false)

    _panel_stack.append(panel)
    panel.on_open(data)

    return panel


## 关闭当前最顶层面板
func close_top() -> void:
    if _panel_stack.is_empty():
        return

    var panel := _panel_stack.pop_back()
    await panel.on_close()

    # 恢复上一层交互
    if not _panel_stack.is_empty():
        _panel_stack.back().set_interactable(true)

    panel.queue_free()


## 关闭到指定面板
func close_to(panel: UIPanel) -> void:
    while not _panel_stack.is_empty() and _panel_stack.back() != panel:
        close_top()


## 显示弹窗（链式 API）
func show_dialog(dialog_type: String) -> DialogBuilder:
    return DialogBuilder.new(dialog_type, _ui_layer)
```

### 5.2 UIPanel — 面板基类

```gdscript
# src/ui/ui_panel.gd
class_name UIPanel
extends Control

## 打开动画名称（在 AnimationPlayer 中定义）
@export var open_animation: String = "open"
## 关闭动画名称
@export var close_animation: String = "close"
## 是否在打开时暂停游戏
@export var pause_game: bool = false
## 是否拦截背景输入
@export var block_input: bool = true

@onready var _animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null

var _pause_id: int = -1


func on_open(data: Dictionary = {}) -> void:
    if pause_game:
        _pause_id = GameManager.pause(GameManager.PauseLayer.UI, name)

    if block_input:
        mouse_filter = MOUSE_FILTER_STOP

    if _animation_player and _animation_player.has_animation(open_animation):
        _animation_player.play(open_animation)
        await _animation_player.animation_finished

    _on_opened(data)


func on_close() -> void:
    if _pause_id != -1:
        GameManager.unpause(_pause_id)

    if _animation_player and _animation_player.has_animation(close_animation):
        _animation_player.play(close_animation)
        await _animation_player.animation_finished

    _on_closed()


## 设置是否可交互（被覆盖时禁用）
func set_interactable(enabled: bool) -> void:
    mouse_filter = MOUSE_FILTER_STOP if enabled else MOUSE_FILTER_IGNORE
    process_mode = PROCESS_MODE_INHERIT if enabled else PROCESS_MODE_DISABLED


## 子类重写以下方法
func _on_opened(data: Dictionary) -> void:
    pass

func _on_closed() -> void:
    pass
```

### 5.3 DialogBuilder — 链式弹窗构建器

```gdscript
# src/ui/dialog/dialog_builder.gd
class_name DialogBuilder
extends RefCounted

var _dialog_type: String
var _parent: CanvasLayer
var _title: String = ""
var _content: String = ""
var _confirm_text: String = "确认"
var _cancel_text: String = "取消"
var _show_cancel: bool = true
var _on_confirm_callback: Callable
var _on_cancel_callback: Callable


func _init(p_type: String, p_parent: CanvasLayer):
    _dialog_type = p_type
    _parent = p_parent


func set_title(text: String) -> DialogBuilder:
    _title = text
    return self


func set_content(text: String) -> DialogBuilder:
    _content = text
    return self


func set_confirm_text(text: String) -> DialogBuilder:
    _confirm_text = text
    return self


func set_cancel_text(text: String) -> DialogBuilder:
    _cancel_text = text
    return self


func hide_cancel() -> DialogBuilder:
    _show_cancel = false
    return self


func on_confirm(callable: Callable) -> DialogBuilder:
    _on_confirm_callback = callable
    return self


func on_cancel(callable: Callable) -> DialogBuilder:
    _on_cancel_callback = callable
    return self


func show() -> void:
    var scene: PackedScene = load("res://src/ui/dialog/%s.tscn" % _dialog_type)
    var dialog = scene.instantiate()

    dialog.title = _title
    dialog.content = _content
    dialog.confirm_text = _confirm_text
    dialog.cancel_text = _cancel_text
    dialog.show_cancel = _show_cancel
    dialog.on_confirm_callback = _on_confirm_callback
    dialog.on_cancel_callback = _on_cancel_callback

    _parent.add_child(dialog)
```

---

## 6. Audio — 音频管理

### 6.1 AudioManager（Autoload）

```gdscript
# src/audio/audio_manager.gd
class_name AudioManager
extends Node

## AudioBus 名称常量
enum Channel { MASTER, BGM, BGS, SFX, VOICE, UI }

const CHANNEL_BUS_NAMES := {
    Channel.MASTER: "Master",
    Channel.BGM: "BGM",
    Channel.BGS: "BGS",
    Channel.SFX: "SFX",
    Channel.VOICE: "Voice",
    Channel.UI: "UI",
}

## 频道路由：每个频道对应一个 AudioStreamPlayer
var _channels: Dictionary = {}
## BGM 播放器（专门处理淡入淡出和循环）
var _bgm_player: AudioStreamPlayer
var _bgm_playlist: Array[AudioStream] = []
var _bgm_index: int = 0

## SFX 池
var _sfx_pool: SFXPool

## 音量设置（0.0 - 1.0）
var master_volume: float = 1.0:
    set(v): _set_bus_volume(Channel.MASTER, v)
var bgm_volume: float = 1.0:
    set(v): _set_bus_volume(Channel.BGM, v)
var sfx_volume: float = 1.0:
    set(v): _set_bus_volume(Channel.SFX, v)


func initialize() -> void:
    # 创建频道路由
    for channel in CHANNEL_BUS_NAMES:
        var player := AudioStreamPlayer.new()
        player.name = "AudioChannel_%s" % CHANNEL_BUS_NAMES[channel]
        player.bus = CHANNEL_BUS_NAMES[channel]
        add_child(player)
        _channels[channel] = player

    _bgm_player = _channels[Channel.BGM]
    _sfx_pool = SFXPool.new(_channels[Channel.SFX])

    # 从配置恢复音量
    _load_volume_settings()


## 播放 BGM（带淡入）
func play_bgm(stream: AudioStream, fade_in_duration: float = 1.0) -> void:
    if _bgm_player.playing:
        await _fade_out_bgm(0.5)

    _bgm_player.stream = stream
    _bgm_player.play()

    # 淡入
    var tween := create_tween()
    tween.tween_method(_set_bgm_volume_db, -40.0, 0.0, fade_in_duration)


## 播放音效
func play_sfx(stream: AudioStream, pitch_variation: float = 0.0) -> AudioStreamPlayer:
    return _sfx_pool.play(stream, pitch_variation)


## 播放 UI 音效
func play_ui_sfx(stream: AudioStream) -> void:
    var player := _channels[Channel.UI] as AudioStreamPlayer
    player.stream = stream
    player.play()


## 设置频道音量（线性 0-1）
func set_channel_volume(channel: Channel, volume: float) -> void:
    _set_bus_volume(channel, volume)


func _set_bus_volume(channel: Channel, linear: float) -> void:
    var bus_name := CHANNEL_BUS_NAMES[channel]
    var bus_idx := AudioServer.get_bus_index(bus_name)
    if bus_idx == -1:
        return
    # 线性转为 dB: 0.0 → -80dB, 1.0 → 0dB
    var db := linear_to_db(clampf(linear, 0.0, 1.0))
    AudioServer.set_bus_volume_db(bus_idx, db)


func _set_bgm_volume_db(db: float) -> void:
    var bus_idx := AudioServer.get_bus_index(CHANNEL_BUS_NAMES[Channel.BGM])
    AudioServer.set_bus_volume_db(bus_idx, db)


func _fade_out_bgm(duration: float) -> void:
    var tween := create_tween()
    tween.tween_method(_set_bgm_volume_db, 0.0, -40.0, duration)
    await tween.finished
    _bgm_player.stop()


func _load_volume_settings() -> void:
    master_volume = ConfigManager.get_value("audio.master_volume", 1.0)
    bgm_volume = ConfigManager.get_value("audio.bgm_volume", 1.0)
    sfx_volume = ConfigManager.get_value("audio.sfx_volume", 1.0)
```

### 6.2 SFXPool — 音效对象池

```gdscript
# src/audio/sfx_pool.gd
class_name SFXPool
extends RefCounted

var _parent: AudioStreamPlayer
var _pool: Array[AudioStreamPlayer] = []
var _pool_size: int = 16
var _active: Array[AudioStreamPlayer] = []


func _init(p_parent: AudioStreamPlayer, p_size: int = 16):
    _parent = p_parent
    _pool_size = p_size
    _pre_create()


func _pre_create() -> void:
    for i in range(_pool_size):
        var player := AudioStreamPlayer.new()
        player.bus = _parent.bus
        player.finished.connect(_on_finished.bind(player))
        _parent.add_child(player)
        _pool.append(player)


func play(stream: AudioStream, pitch_variation: float = 0.0) -> AudioStreamPlayer:
    var player: AudioStreamPlayer

    if _pool.is_empty():
        # 池耗尽，创建临时播放器
        player = AudioStreamPlayer.new()
        player.bus = _parent.bus
        player.finished.connect(_on_finished.bind(player))
        _parent.add_child(player)
    else:
        player = _pool.pop_back()

    player.stream = stream
    # 随机微调音高（增加音效多样性）
    if pitch_variation > 0.0:
        player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
    else:
        player.pitch_scale = 1.0

    player.play()
    _active.append(player)
    return player


func _on_finished(player: AudioStreamPlayer) -> void:
    _active.erase(player)
    player.stream = null
    if _pool.size() < _pool_size:
        _pool.append(player)
    else:
        player.queue_free()
```

### 6.3 AudioBus 布局

在 Godot 编辑器的 Audio 面板中预设 AudioBus 布局：

```
Master
├── BGM      (route to Master)
│   └── (可加 Reverb 等效果)
├── BGS      (route to Master)
├── SFX      (route to Master)
├── Voice    (route to Master)
└── UI       (route to Master)
```

> 此布局可保存为 `res://assets/default_bus_layout.tres`，在 `project.godot` 中通过 `audio/buses/default_bus_layout` 设置默认值。

---

## 7. Input — 输入管理

### 7.1 InputManager（Autoload） Done

```gdscript
# src/input/input_manager.gd
class_name InputManager
extends Node

## 输入状态（用于输入缓冲）
var _input_history: Array[InputRecord] = []
var _buffer_window: int = 10  # 缓冲窗口（帧数）

class InputRecord:
    var action: String
    var frame: int
    var pressed: bool

    func _init(p_action: String, p_frame: int, p_pressed: bool):
        action = p_action
        frame = p_frame
        pressed = p_pressed


func _process(_delta: float) -> void:
    _clean_history()


func initialize() -> void:
    # 设置输入映射（如果尚未设置）
    _ensure_input_map()


func _ensure_input_map() -> void:
    # 确保框架默认的输入动作存在
    var default_actions := {
        "ui_accept": [KEY_ENTER, KEY_SPACE],
        "ui_cancel": [KEY_ESCAPE],
        "ui_up": [KEY_UP, KEY_W],
        "ui_down": [KEY_DOWN, KEY_S],
        "ui_left": [KEY_LEFT, KEY_A],
        "ui_right": [KEY_RIGHT, KEY_D],
    }

    for action in default_actions:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
            for key in default_actions[action]:
                var event := InputEventKey.new()
                event.keycode = key
                InputMap.action_add_event(action, event)


## 判断逻辑动作是否刚按下
func is_action_just_pressed(action: String, buffer_frames: int = 0) -> bool:
    if Input.is_action_just_pressed(action):
        _record_input(action, true)
        return true
    if buffer_frames > 0:
        return _check_buffer(action, true, buffer_frames)
    return false


## 判断逻辑动作是否刚释放
func is_action_just_released(action: String) -> bool:
    return Input.is_action_just_released(action)


## 获取动作的按压值（考虑死区）
func get_action_strength(action: String) -> float:
    return Input.get_action_strength(action)


## 获取移动向量（键盘 WASD + 手柄左摇杆统一）
func get_move_vector() -> Vector2:
    return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")


## 获取瞄准方向（鼠标/右摇杆）
func get_aim_vector(from_position: Vector2) -> Vector2:
    # 优先手柄右摇杆
    var gamepad_vector := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
    if gamepad_vector.length() > 0.1:
        return gamepad_vector

    # 回退到鼠标
    return (get_viewport().get_mouse_position() - from_position).normalized()


func _record_input(action: String, pressed: bool) -> void:
    _input_history.append(InputRecord.new(action, Engine.get_process_frames(), pressed))


func _check_buffer(action: String, pressed: bool, buffer_frames: int) -> bool:
    var current_frame := Engine.get_process_frames()
    for record in _input_history:
        if record.action == action and record.pressed == pressed:
            if current_frame - record.frame <= buffer_frames:
                _input_history.erase(record)
                return true
    return false


func _clean_history() -> void:
    var current_frame := Engine.get_process_frames()
    for i in range(_input_history.size() - 1, -1, -1):
        if current_frame - _input_history[i].frame > _buffer_window:
            _input_history.remove_at(i)
```

**核心概念**：

- `InputMap` 在 Godot 4 中可直接通过代码操作（`InputMap.add_action` / `InputMap.action_add_event`），无需手动在项目设置中配置。
- 输入缓冲：格斗游戏中常见的"提前输入"机制——玩家在动作结束前 N 帧按下攻击键，动作一结束就自动触发。
- `Input.get_vector()` 是 Godot 4 提供的方法，自动处理键盘正负键和手柄摇杆的统一抽象。

### 7.2 InputBuffer — 指令缓冲（格斗/动作游戏）

```gdscript
# src/input/input_buffer.gd
class_name InputBuffer
extends RefCounted

## 指令缓冲
var _buffer: Array[InputEvent] = []
var _max_size: int = 60   # 最大缓冲帧数


func push_event(event: InputEvent) -> void:
    _buffer.append(event)
    while _buffer.size() > _max_size:
        _buffer.pop_front()


## 检测指令序列（如 ↓↘→ + A = 波动拳）
func match_sequence(sequence: Array[InputCheck]) -> bool:
    if _buffer.size() < sequence.size():
        return false

    # 从缓冲末尾向前匹配
    var buffer_idx := _buffer.size() - 1
    for i in range(sequence.size() - 1, -1, -1):
        var check := sequence[i]
        while buffer_idx >= 0:
            if check.match(_buffer[buffer_idx]):
                buffer_idx -= 1
                break
            buffer_idx -= 1
        else:
            return false

    return true


func clear() -> void:
    _buffer.clear()
```

---

## 8. Data — 数据与存档

### 8.1 SaveSystem（Autoload）

```gdscript
# src/data/save_system.gd
class_name SaveSystem
extends Node

const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".sav"
const MAX_SLOTS := 10

var _current_slot: int = 0


## 获取存档槽列表（含元数据）
func get_slots() -> Array[Dictionary]:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)
    var slots: Array[Dictionary] = []
    var dir := DirAccess.open(SAVE_DIR)
    if dir == null:
        return slots

    for i in range(MAX_SLOTS):
        var filename := "slot_%03d%s" % [i, SAVE_EXTENSION]
        if dir.file_exists(filename):
            var meta := _read_slot_meta(i)
            slots.append(meta)
        else:
            slots.append({"id": i, "empty": true})

    return slots


## 保存
func save(slot: int, save_data: SaveData) -> bool:
    _ensure_dir()
    var path := _slot_path(slot)

    # 更新元数据
    save_data.slot_id = slot
    save_data.timestamp = Time.get_unix_time_from_system()
    save_data.version = SaveData.CURRENT_VERSION

    # 序列化
    var packed := save_data.serialize()

    # 写入文件
    var file := FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _encryption_key())
    if file == null:
        Logger.error("无法创建存档文件: %s" % path, self)
        return false

    file.store_var(packed, true)  # true = 完全序列化（支持嵌套对象）
    file.close()

    # 保存元数据（独立的快读文件）
    _write_slot_meta(slot, save_data)

    EventBus.emit("save_completed", {"slot": slot})
    Logger.info("存档保存成功: slot %d" % slot, self)
    return true


## 读取
func load(slot: int) -> SaveData:
    var path := _slot_path(slot)
    if not FileAccess.file_exists(path):
        Logger.warn("存档不存在: slot %d" % slot, self)
        return null

    var file := FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _encryption_key())
    if file == null:
        Logger.error("无法读取存档文件: %s" % path, self)
        return null

    var data = file.get_var(true)
    file.close()

    if data == null:
        return null

    var save_data := SaveData.new()
    save_data.deserialize(data)

    # 版本迁移
    if save_data.version < SaveData.CURRENT_VERSION:
        _migrate(save_data)

    _current_slot = slot
    EventBus.emit("load_completed", {"slot": slot})
    return save_data


## 删除存档
func delete(slot: int) -> bool:
    var path := _slot_path(slot)
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(path)
    _delete_slot_meta(slot)
    return true


func _slot_path(slot: int) -> String:
    return SAVE_DIR + "slot_%03d%s" % [slot, SAVE_EXTENSION]


func _encryption_key() -> String:
    # 生产环境中应从更安全的地方获取
    return "ggf_default_encryption_key_2024"


func _ensure_dir() -> void:
    DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _read_slot_meta(slot: int) -> Dictionary:
    var path := SAVE_DIR + "meta_%03d.json" % slot
    if not FileAccess.file_exists(path):
        return {"id": slot, "empty": true}

    var file := FileAccess.open(path, FileAccess.READ)
    var text := file.get_as_text()
    file.close()

    var json := JSON.new()
    json.parse(text)
    return json.data


func _write_slot_meta(slot: int, save_data: SaveData) -> void:
    var meta := {
        "id": slot,
        "timestamp": save_data.timestamp,
        "version": save_data.version,
        "play_time": save_data.play_time,
        "player_name": save_data.player_name,
        "scene": save_data.current_scene,
        "empty": false,
    }
    var path := SAVE_DIR + "meta_%03d.json" % slot
    var file := FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(meta, "\t"))
    file.close()


func _migrate(save_data: SaveData) -> void:
    # 逐版本迁移（链式）
    while save_data.version < SaveData.CURRENT_VERSION:
        match save_data.version:
            1:
                _migrate_v1_to_v2(save_data)
            2:
                _migrate_v2_to_v3(save_data)
            _:
                save_data.version += 1
```

### 8.2 SaveData — 存档数据 Resource

```gdscript
# src/data/save_data.gd
class_name SaveData
extends Resource

## 存档结构版本号
const CURRENT_VERSION := 1

@export var version: int = CURRENT_VERSION
@export var slot_id: int = 0
@export var timestamp: int = 0
@export var play_time: float = 0.0
@export var player_name: String = ""
@export var current_scene: String = ""

## 游戏专用数据（Dictionary，存储任意结构）
## 注意：Godot 的 @export var 对 Dictionary 支持有限，
## 因此这里使用序列化/反序列化模式
var game_data: Dictionary = {}


## 序列化为可存储的 Dictionary
func serialize() -> Dictionary:
    return {
        "version": version,
        "slot_id": slot_id,
        "timestamp": timestamp,
        "play_time": play_time,
        "player_name": player_name,
        "current_scene": current_scene,
        "game_data": game_data,
    }


## 从 Dictionary 恢复
func deserialize(data: Dictionary) -> void:
    version = data.get("version", 0)
    slot_id = data.get("slot_id", 0)
    timestamp = data.get("timestamp", 0)
    play_time = data.get("play_time", 0.0)
    player_name = data.get("player_name", "")
    current_scene = data.get("current_scene", "")
    game_data = data.get("game_data", {})
```

> Godot 4 的 `FileAccess.open_encrypted_with_pass` 提供内置 AES-256 加密——只需一个密码短语即可自动加解密，无需手动实现。

---

## 9. Pool — 对象池

### 9.1 ObjectPool

```gdscript
# src/pool/object_pool.gd
class_name ObjectPool
extends RefCounted

var _scene: PackedScene
var _available: Array[Node] = []
var _active: Array[Node] = []
var _parent: Node
var _max_size: int


func _init(p_scene: PackedScene, p_parent: Node, p_preload: int = 10, p_max: int = 100):
    _scene = p_scene
    _parent = p_parent
    _max_size = p_max

    # 预热
    for i in range(p_preload):
        _create_and_store()


func _create_and_store() -> Node:
    var instance := _scene.instantiate()
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    if instance is Node2D or instance is Node3D:
        instance.visible = false
    _available.append(instance)
    return instance


## 获取一个实例
func acquire() -> Node:
    var instance: Node
    if _available.is_empty():
        var total := _available.size() + _active.size()
        if total >= _max_size:
            Logger.warn("对象池已满 (%d)，无法创建新实例" % _max_size, _parent)
            return null
        instance = _create_and_store()
    else:
        instance = _available.pop_back()

    _active.append(instance)
    _parent.add_child(instance)
    instance.process_mode = Node.PROCESS_MODE_INHERIT
    if instance is Node2D or instance is Node3D:
        instance.visible = true

    # 调用实例的初始化方法
    if instance.has_method("pool_initialize"):
        instance.pool_initialize()

    return instance


## 回收实例
func release(instance: Node) -> void:
    if not _active.has(instance):
        return

    _active.erase(instance)
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    if instance is Node2D or instance is Node3D:
        instance.visible = false

    # 从场景树移除（放入池中）
    if instance.get_parent():
        instance.get_parent().remove_child(instance)

    if instance.has_method("pool_reset"):
        instance.pool_reset()

    _available.append(instance)


## 回收所有活跃实例
func release_all() -> void:
    for instance in _active.duplicate():
        release(instance)


## 统计数据
func get_stats() -> Dictionary:
    return {
        "available": _available.size(),
        "active": _active.size(),
        "total": _available.size() + _active.size(),
        "max": _max_size,
        "hit_rate": _available.size() / float(max(1, _available.size() + _active.size())),
    }
```

**使用示例**：

```gdscript
# 在子弹管理器中
var bullet_pool: ObjectPool

func _ready():
    bullet_pool = ObjectPool.new(
        preload("res://entities/bullet.tscn"),
        self,   # 作为父节点
        preload = 20,
        max = 200
    )

func fire(pos: Vector2, dir: Vector2):
    var bullet := bullet_pool.acquire()
    if bullet:
        bullet.global_position = pos
        bullet.direction = dir

# 子弹命中后回收
func _on_bullet_hit(bullet: Node):
    bullet_pool.release(bullet)
```

---

## 10. Entity — 实体与角色

### 10.1 Entity 基类

```gdscript
# src/entity/entity.gd
class_name Entity
extends Node2D  # 也可用 Node3D，通过子类决定

signal died()
signal damaged(amount: float, source: Entity)
signal healed(amount: float)

## 唯一 ID（自动生成）
@export var entity_id: String = ""
## 阵营
@export var faction: Faction
## 实体名称
@export var entity_name: String = ""

## 是否存活
var is_alive: bool = true


func _ready() -> void:
    if entity_id.is_empty():
        entity_id = str(get_instance_id())  # Godot 实例 ID 作为备选唯一标识


## 受到伤害
func take_damage(amount: float, source: Entity = null) -> void:
    if not is_alive:
        return

    var final_amount := _calculate_damage(amount, source)
    damaged.emit(final_amount, source)

    if final_amount > 0:
        _on_take_damage(final_amount, source)


## 受到治疗
func take_heal(amount: float) -> void:
    if not is_alive:
        return
    healed.emit(amount)
    _on_take_heal(amount)


## 死亡
func die() -> void:
    if not is_alive:
        return
    is_alive = false
    died.emit()
    _on_die()


## 🔽 子类重写以下方法

func _calculate_damage(amount: float, source: Entity) -> float:
    return amount

func _on_take_damage(amount: float, source: Entity) -> void:
    pass

func _on_take_heal(amount: float) -> void:
    pass

func _on_die() -> void:
    pass
```

### 10.2 Character 基类

```gdscript
# src/entity/character.gd
class_name Character
extends Entity

signal health_changed(current: float, maximum: float)
signal level_up(new_level: int)

## 属性容器
@export var attributes: AttributeContainer

## 生命值
@export var max_health: float = 100.0:
    set(v):
        max_health = maxf(1.0, v)
        if current_health > max_health:
            current_health = max_health
var current_health: float = 100.0:
    set(v):
        var old := current_health
        current_health = clampf(v, 0.0, max_health)
        if current_health != old:
            health_changed.emit(current_health, max_health)

## 移动速度
@export var move_speed: float = 200.0

## 等级
@export var level: int = 1

## Buff 容器
var buff_container: BuffContainer


func _ready() -> void:
    super._ready()
    current_health = max_health
    buff_container = BuffContainer.new(self)


func _calculate_damage(amount: float, source: Entity) -> float:
    # 应用属性加成的伤害计算
    var defense := attributes.get_value("defense", 0.0)
    var reduction := defense / (defense + 100.0)  # 护甲减伤公式
    var final := amount * (1.0 - reduction)

    # 让 Buff 修改最终伤害
    final = buff_container.on_damage_taken(final, source)

    return maxf(1.0, final)  # 最少 1 点伤害


func _on_die() -> void:
    queue_free()


## 获取属性值（从 AttributeContainer）
func get_attribute(attr_name: String, default: float = 0.0) -> float:
    if attributes:
        return attributes.get_value(attr_name, default)
    return default
```

### 10.3 AttributeContainer (Resource)

```gdscript
# src/entity/attribute_container.gd
class_name AttributeContainer
extends Resource

## 基础属性 { "strength": 10.0, "agility": 8.0, ... }
@export var base: Dictionary = {}

## 加成（来自装备/Buff等） { "strength": {"bonus": 2.0, "multiplier": 0.1} }
var _bonuses: Dictionary = {}


func get_value(attr_name: String, default: float = 0.0) -> float:
    var base_value: float = base.get(attr_name, default)
    var bonus_data: Dictionary = _bonuses.get(attr_name, {})

    var flat_bonus: float = bonus_data.get("flat", 0.0)
    var multiplier: float = bonus_data.get("multiplier", 0.0)

    return (base_value + flat_bonus) * (1.0 + multiplier)


func add_bonus(attr_name: String, flat: float = 0.0, multiplier: float = 0.0, source_id: String = "") -> void:
    if not _bonuses.has(attr_name):
        _bonuses[attr_name] = {"flat": 0.0, "multiplier": 0.0, "sources": {}}

    _bonuses[attr_name]["flat"] += flat
    _bonuses[attr_name]["multiplier"] += multiplier

    if not source_id.is_empty():
        _bonuses[attr_name]["sources"][source_id] = {"flat": flat, "multiplier": multiplier}


func remove_bonus(attr_name: String, source_id: String) -> void:
    if not _bonuses.has(attr_name):
        return

    var sources: Dictionary = _bonuses[attr_name].get("sources", {})
    if sources.has(source_id):
        var entry = sources[source_id]
        _bonuses[attr_name]["flat"] -= entry["flat"]
        _bonuses[attr_name]["multiplier"] -= entry["multiplier"]
        sources.erase(source_id)
```

### 10.4 Faction (Resource)

```gdscript
# src/entity/faction.gd
class_name Faction
extends Resource

@export var faction_id: String = ""
@export var faction_name: String = ""
@export var friendly_to: Array[String] = []   # 友方阵营 ID 列表
@export var hostile_to: Array[String] = []    # 敌方阵营 ID 列表


enum Relation { FRIENDLY, NEUTRAL, HOSTILE }


func get_relation(other: Faction) -> Relation:
    if not other:
        return Relation.NEUTRAL
    if other.faction_id in hostile_to:
        return Relation.HOSTILE
    if other.faction_id in friendly_to or other.faction_id == faction_id:
        return Relation.FRIENDLY
    return Relation.NEUTRAL


func is_hostile_to(other: Faction) -> bool:
    return get_relation(other) == Relation.HOSTILE
```

---

## 11. FSM — 有限状态机

### 11.1 StateMachine

```gdscript
# src/fsm/state_machine.gd
class_name StateMachine
extends Node

signal state_changed(from: String, to: String)

## 状态字典 { "idle": State, "walk": State, ... }
var _states: Dictionary = {}

## 转换表 [ Transition, Transition, ... ]
var _transitions: Array[Transition] = []
var _any_transitions: Array[Transition] = []  # 从任意状态触发的转换

## 当前状态
var current_state: State = null
var previous_state: State = null

## 状态机是否激活
var active: bool = true:
    set(v):
        active = v
        if not active and current_state:
            current_state.on_exit()

class Transition:
    var from_state: String
    var to_state: String
    var condition: Callable  # func() -> bool
    var priority: int = 0

    func _init(p_from: String, p_to: String, p_condition: Callable, p_priority: int = 0):
        from_state = p_from
        to_state = p_to
        condition = p_condition
        priority = p_priority


## 添加状态
func add_state(p_name: String, p_state: State) -> void:
    p_state.machine = self
    _states[p_name] = p_state


## 创建并添加一个简单状态
func create_state(p_name: String, p_enter: Callable = Callable(), p_update: Callable = Callable(), p_physics_update: Callable = Callable(), p_exit: Callable = Callable()) -> State:
    var state := State.new()
    state.name = p_name
    state.enter_callback = p_enter
    state.update_callback = p_update
    state.physics_update_callback = p_physics_update
    state.exit_callback = p_exit
    add_state(p_name, state)
    return state


## 添加转换
func add_transition(p_from: String, p_to: String, p_condition: Callable, p_priority: int = 0) -> void:
    _transitions.append(Transition.new(p_from, p_to, p_condition, p_priority))
    _transitions.sort_custom(func(a, b): return a.priority > b.priority)


## 添加任意状态转换
func add_any_transition(p_to: String, p_condition: Callable, p_priority: int = 0) -> void:
    _any_transitions.append(Transition.new("", p_to, p_condition, p_priority))
    _any_transitions.sort_custom(func(a, b): return a.priority > b.priority)


## 设置初始状态并启动
func start(p_initial_state: String) -> void:
    if not _states.has(p_initial_state):
        push_error("状态机: 初始状态 '%s' 未定义" % p_initial_state)
        return
    _change_state(p_initial_state)


func _process(delta: float) -> void:
    if not active or current_state == null:
        return
    _check_transitions()
    current_state.on_update(delta)


func _physics_process(delta: float) -> void:
    if not active or current_state == null:
        return
    current_state.on_physics_update(delta)


func _check_transitions() -> void:
    # 优先检查 any_transition（高优先级）
    for trans in _any_transitions:
        if trans.condition.call():
            _change_state(trans.to_state)
            return

    # 检查当前状态的特定转换
    for trans in _transitions:
        if trans.from_state == current_state.name:
            if trans.condition.call():
                _change_state(trans.to_state)
                return


func _change_state(p_to: String) -> void:
    var new_state: State = _states.get(p_to)
    if new_state == null:
        push_error("状态机: 目标状态 '%s' 未定义" % p_to)
        return

    if current_state:
        current_state.on_exit()

    previous_state = current_state
    state_changed.emit(previous_state.name if previous_state else "", p_to)

    current_state = new_state
    current_state.on_enter()


## 返回上一状态
func revert_to_previous() -> void:
    if previous_state:
        _change_state(previous_state.name)
```

### 11.2 State

```gdscript
# src/fsm/state.gd
class_name State
extends RefCounted

var name: String = ""
var machine: StateMachine = null

var enter_callback: Callable
var update_callback: Callable
var physics_update_callback: Callable
var exit_callback: Callable

## 状态进入以来的时间
var elapsed_time: float = 0.0


func on_enter() -> void:
    elapsed_time = 0.0
    if enter_callback.is_valid():
        enter_callback.call()


func on_update(delta: float) -> void:
    elapsed_time += delta
    if update_callback.is_valid():
        update_callback.call(delta)


func on_physics_update(delta: float) -> void:
    if physics_update_callback.is_valid():
        physics_update_callback.call(delta)


func on_exit() -> void:
    if exit_callback.is_valid():
        exit_callback.call()
```

**使用示例**（角色控制器）：

```gdscript
extends Character

var fsm: StateMachine

func _ready():
    fsm = StateMachine.new()
    add_child(fsm)

    fsm.create_state("idle", _enter_idle, _update_idle)
    fsm.create_state("walk", _enter_walk, _update_walk)
    fsm.create_state("attack", _enter_attack, null, null, _exit_attack)

    fsm.add_transition("idle", "walk", func(): return InputManager.get_move_vector() != Vector2.ZERO)
    fsm.add_transition("walk", "idle", func(): return InputManager.get_move_vector() == Vector2.ZERO)
    fsm.add_any_transition("attack", func(): return InputManager.is_action_just_pressed("attack"))

    fsm.start("idle")
```

---

## 12. Ability & Buff — 技能与Buff

### 12.1 Ability (Resource)

技能定义为 Godot Resource，可以在编辑器中创建和配置，拖拽给角色。

```gdscript
# src/ability/ability.gd
class_name Ability
extends Resource

enum TargetType { SELF, SINGLE_ENEMY, SINGLE_ALLY, AREA, DIRECTIONAL, PROJECTILE }

## 技能名称
@export var ability_name: String = ""

## 技能图标
@export var icon: Texture2D

## 冷却时间（秒）
@export var cooldown: float = 1.0

## 消耗的资源（法力/体力等）
@export var cost: Dictionary = {}  # { "mana": 10, "stamina": 5 }

## 目标类型
@export var target_type: TargetType = TargetType.SELF

## 技能范围（AOE 时使用）
@export var range: float = 100.0

## 伤害倍率
@export var damage_multiplier: float = 1.0

## 是否在冷却中
var _on_cooldown: bool = false
var _cooldown_remaining: float = 0.0


## 检查是否可以使用
func can_use(caster: Character) -> bool:
    if _on_cooldown:
        return false

    # 检查消耗
    for resource in cost:
        if caster.get_attribute(resource, 0.0) < cost[resource]:
            return false

    return true


## 使用技能
func use(caster: Character, target = null) -> void:
    if not can_use(caster):
        return

    # 扣除消耗
    for resource in cost:
        caster.attributes.add_bonus(resource, -cost[resource])

    # 开始冷却
    _on_cooldown = true
    _cooldown_remaining = cooldown

    # 执行技能逻辑
    await _execute(caster, target)

    # 冷却计时
    while _cooldown_remaining > 0:
        await caster.get_tree().process_frame
        _cooldown_remaining -= caster.get_process_delta_time()

    _on_cooldown = false


## 子类重写：技能执行逻辑
func _execute(caster: Character, target) -> void:
    pass


## 冷却进度（0.0 - 1.0，UI用）
func get_cooldown_progress() -> float:
    if not _on_cooldown or cooldown <= 0:
        return 0.0
    return 1.0 - (_cooldown_remaining / cooldown)
```

### 12.2 AbilityComponent — 可组合的技能组件

```gdscript
# src/ability/ability_component.gd
class_name AbilityComponent
extends Resource

func on_cast_start(caster: Character, target) -> void:
    pass

func on_cast_end(caster: Character, target) -> void:
    pass

func on_hit(caster: Character, target: Character) -> void:
    pass
```

```gdscript
# src/ability/cooldown_component.gd
class_name CooldownComponent
extends AbilityComponent

@export var cooldown: float = 1.0
var _on_cooldown: bool = false
var _remaining: float = 0.0


func on_cast_start(caster: Character, target) -> void:
    _on_cooldown = true
    _remaining = cooldown
```

### 12.3 Buff 系统

```gdscript
# src/ability/buff.gd
class_name Buff
extends Resource

enum StackPolicy { INDEPENDENT, REFRESH_DURATION, ADD_STACK, REJECT }

@export var buff_name: String = ""
@export var icon: Texture2D
@export var duration: float = 5.0          # -1 = 永久
@export var max_stacks: int = 1
@export var stack_policy: StackPolicy = StackPolicy.REFRESH_DURATION

## 属性修改 { "strength": {"flat": 5.0, "multiplier": 0.0} }
@export var attribute_modifiers: Dictionary = {}

## 周期性效果间隔（秒，0 = 无周期效果）
@export var tick_interval: float = 0.0

## Buff 来源实体 ID
var source_id: String = ""
var current_stacks: int = 1
var remaining_time: float = 0.0
var _tick_timer: float = 0.0

## 所属容器
var container: BuffContainer = null
var owner_character: Character = null


func on_apply(character: Character) -> void:
    owner_character = character
    remaining_time = duration
    _tick_timer = tick_interval

    # 应用属性修改
    for attr in attribute_modifiers:
        var mod = attribute_modifiers[attr]
        character.attributes.add_bonus(attr, mod.get("flat", 0.0), mod.get("multiplier", 0.0), buff_name)


func on_remove() -> void:
    # 移除属性修改
    for attr in attribute_modifiers:
        owner_character.attributes.remove_bonus(attr, buff_name)


func on_tick(delta: float) -> void:
    if duration > 0:
        remaining_time -= delta
        if remaining_time <= 0:
            container.remove_buff(self)
            return

    if tick_interval > 0:
        _tick_timer -= delta
        if _tick_timer <= 0:
            _tick_timer = tick_interval
            _on_tick_effect()


func _on_tick_effect() -> void:
    # 子类重写（或通过回调）
    pass


func on_damage_taken(amount: float, source: Entity) -> float:
    return amount
```

```gdscript
# src/ability/buff_container.gd
class_name BuffContainer
extends Node

var _buffs: Array[Buff] = []


func _init(p_owner: Character):
    owner = p_owner


func _process(delta: float) -> void:
    for buff in _buffs.duplicate():
        buff.on_tick(delta)


func apply_buff(buff_template: Buff, source_id: String = "") -> Buff:
    # 检查是否已有同名 Buff
    var existing := _find_buff(buff_template.buff_name)
    if existing:
        match buff_template.stack_policy:
            Buff.StackPolicy.REFRESH_DURATION:
                existing.remaining_time = buff_template.duration
                return existing
            Buff.StackPolicy.ADD_STACK:
                if existing.current_stacks < existing.max_stacks:
                    existing.current_stacks += 1
                    existing.remaining_time = buff_template.duration
                return existing
            Buff.StackPolicy.REJECT:
                return existing
            Buff.StackPolicy.INDEPENDENT:
                pass  # 继续创建新的

    # 创建新 Buff 实例
    var new_buff := buff_template.duplicate(true)  # true = 深层复制
    new_buff.source_id = source_id
    new_buff.container = self

    var owner_char := owner as Character
    if owner_char:
        new_buff.on_apply(owner_char)

    _buffs.append(new_buff)
    return new_buff


func remove_buff(buff: Buff) -> void:
    if not _buffs.has(buff):
        return
    buff.on_remove()
    _buffs.erase(buff)


func _find_buff(buff_name: String) -> Buff:
    for buff in _buffs:
        if buff.buff_name == buff_name:
            return buff
    return null


func on_damage_taken(amount: float, source: Entity) -> float:
    var result := amount
    for buff in _buffs:
        result = buff.on_damage_taken(result, source)
    return result
```

---

## 13. Localization — 本地化

### 13.1 LocaleManager（Autoload）

```gdscript
# src/localization/locale_manager.gd
class_name LocaleManager
extends Node

## 语言切换信号
signal locale_changed(new_locale: String)

## 当前语言
var current_locale: String = "zh_CN":
    set(v):
        if current_locale != v:
            current_locale = v
            _load_translations()
            locale_changed.emit(v)

## 翻译数据 { "key": "翻译文本" }
var _translations: Dictionary = {}

## 支持的语言列表
var supported_locales: Array[String] = ["zh_CN", "en_US"]


func initialize() -> void:
    # 从配置读取上次使用的语言
    current_locale = ConfigManager.get_value("locale", "zh_CN")
    _load_translations()


func _load_translations() -> void:
    var path := "res://src/localization/data/%s.csv" % current_locale
    if not FileAccess.file_exists(path):
        Logger.warn("语言文件不存在: %s" % path, self)
        _translations.clear()
        return

    var file := FileAccess.open(path, FileAccess.READ)
    var text := file.get_as_text()
    file.close()

    _translations.clear()
    for line in text.split("\n"):
        var trimmed := line.strip_edges()
        if trimmed.is_empty() or trimmed.begins_with("#"):
            continue

        var parts := trimmed.split(",", true, 1)  # 只分割第一个逗号
        if parts.size() >= 2:
            var key := parts[0].strip_edges()
            var value := parts[1].strip_edges().replace("\\n", "\n")
            _translations[key] = value


## 翻译文本
func tr(key: String, placeholder_values: Dictionary = {}) -> String:
    var text := _translations.get(key, key)
    for placeholder in placeholder_values:
        text = text.replace("{%s}" % placeholder, str(placeholder_values[placeholder]))
    return text


## 全局快捷方法（在 gd_extensions.gd 中通过静态方法暴露）
static func _(key: String, values: Dictionary = {}) -> String:
    return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("LocaleManager").tr(key, values)
```

**翻译 CSV 格式** (`zh_CN.csv`)：

```csv
# 中文翻译表
key,value
ui.title,我的游戏
ui.confirm,确认
ui.cancel,取消
ui.back,返回
game.you_got_item,你获得了 {count} 个 {item_name}
combat.damage,造成了 {amount} 点伤害
```

### 13.2 自动更新 UI 文本的组件

```gdscript
# 附加到任何包含文本的 Control 节点上
class_name LocaleText
extends Node

@export var translation_key: String = ""
@export var placeholders: Dictionary = {}

var _parent: Control


func _ready() -> void:
    _parent = get_parent() as Control
    if _parent == null:
        return

    _update_text()
    LocaleManager.locale_changed.connect(_update_text)


func _update_text(_new_locale: String = "") -> void:
    if _parent == null or translation_key.is_empty():
        return

    var text := LocaleManager.tr(translation_key, placeholders)
    # 自动匹配父节点的文本属性
    if _parent is Label:
        (_parent as Label).text = text
    elif _parent is Button:
        (_parent as Button).text = text
    elif _parent is LineEdit:
        (_parent as LineEdit).placeholder_text = text
```

---

## 14. Camera — 摄像机

### 14.1 CameraController2D

```gdscript
# src/camera/camera_controller_2d.gd
class_name CameraController2D
extends Camera2D

enum FollowMode { LERP, SNAP, SMOOTH_DAMP }

## 跟随目标
@export var target: Node2D = null:
    set(v): _set_target(v)

## 跟随模式
@export var follow_mode: FollowMode = FollowMode.LERP

## 插值速度（LERP 模式）
@export var lerp_speed: float = 5.0

## 平滑阻尼参数（SMOOTH_DAMP 模式）
@export var smooth_time: float = 0.3

## 边界限制
@export var limit_enabled: bool = false
@export var limit_rect: Rect2 = Rect2(0, 0, 10000, 10000)

## 前瞻系统（让摄像机提前看向移动方向）
@export var look_ahead_enabled: bool = false
@export var look_ahead_factor: float = 0.3
@export var look_ahead_max: float = 200.0

var _velocity: Vector2 = Vector2.ZERO
var _shake_component: CameraShake


func _ready() -> void:
    _shake_component = CameraShake.new()
    add_child(_shake_component)


func _process(delta: float) -> void:
    if target == null:
        return

    var target_pos := target.global_position

    # 前瞻偏移
    if look_ahead_enabled:
        var offset := _velocity * look_ahead_factor
        offset = offset.limit_length(look_ahead_max)
        target_pos += offset

    # 跟随
    match follow_mode:
        FollowMode.LERP:
            global_position = global_position.lerp(target_pos, lerp_speed * delta)
        FollowMode.SNAP:
            global_position = target_pos
        FollowMode.SMOOTH_DAMP:
            global_position = _smooth_damp(global_position, target_pos, _velocity, smooth_time, delta)

    # 边界限制
    if limit_enabled:
        _apply_limit()


func _smooth_damp(current: Vector2, target: Vector2, velocity: Vector2, smooth_time: float, delta: float) -> Vector2:
    # Godot 没有内置 SmoothDamp，手动实现
    var new_velocity: Vector2 = velocity
    var result := current
    result.x = _smooth_damp_axis(result.x, target.x, new_velocity.x, smooth_time, delta)
    result.y = _smooth_damp_axis(result.y, target.y, new_velocity.y, smooth_time, delta)
    _velocity = new_velocity
    return result


func _smooth_damp_axis(current: float, target: float, velocity: float, smooth_time: float, delta: float) -> float:
    var omega := 2.0 / maxf(smooth_time, 0.0001)
    var x := omega * delta
    var exp := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
    var change := current - target
    var temp := (velocity + omega * change) * delta
    var v := (velocity - omega * temp) * exp
    var result := target + (change + temp) * exp
    # 已越过目标
    if (target - current > 0.0) == (result > target):
        result = target
        v = (result - target) / delta
    return result


func _apply_limit() -> void:
    var half_size := get_viewport_rect().size * 0.5 / zoom
    position.x = clampf(position.x, limit_rect.position.x + half_size.x, limit_rect.end.x - half_size.x)
    position.y = clampf(position.y, limit_rect.position.y + half_size.y, limit_rect.end.y - half_size.y)


func _set_target(p_target: Node2D) -> void:
    target = p_target
    if target:
        global_position = target.global_position


## 震屏快捷方法
func shake(intensity: float = 10.0, duration: float = 0.3) -> void:
    _shake_component.shake(intensity, duration)


## 设置缩放
func set_zoom_smooth(target_zoom: Vector2, duration: float = 0.5) -> void:
    var tween := create_tween()
    tween.tween_property(self, "zoom", target_zoom, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
```

### 14.2 CameraShake（Trauma-based 震屏）

```gdscript
# src/camera/camera_shake.gd
class_name CameraShake
extends Node

## 当前创伤值（0.0 - 1.0，越大震动越剧烈）
var trauma: float = 0.0
## 创伤衰减速度
@export var decay_rate: float = 0.8
## 最大偏移（像素）
@export var max_offset: Vector2 = Vector2(50, 50)
## 最大旋转（弧度）
@export var max_rotation: float = 0.1

var _noise: FastNoiseLite
var _noise_y: float = 0.0

var _parent_camera: Camera2D


func _ready() -> void:
    _parent_camera = get_parent() as Camera2D
    _noise = FastNoiseLite.new()
    _noise.seed = randi()
    _noise.frequency = 0.5


func _process(delta: float) -> void:
    if trauma <= 0.001:
        trauma = 0.0
        return

    # 衰减
    trauma = maxf(trauma - decay_rate * delta, 0.0)

    # 根据创伤计算震动
    var shake_amount := trauma * trauma  # 平方衰减更自然

    _noise_y += 0.5 * delta
    var offset_x := _noise.get_noise_1d(_noise_y * 30.0) * max_offset.x * shake_amount
    var offset_y := _noise.get_noise_1d((_noise_y + 99.0) * 30.0) * max_offset.y * shake_amount
    var rotation := _noise.get_noise_1d((_noise_y + 199.0) * 30.0) * max_rotation * shake_amount

    _parent_camera.offset = Vector2(offset_x, offset_y)
    _parent_camera.rotation = rotation


## 添加震动
func shake(intensity: float, duration: float = 0.3) -> void:
    # 创伤值: 叠加式，新震动加在当前创伤上
    trauma = minf(trauma + intensity, 1.0)
```

> **Trauma-based 震屏**参考了 Vlambeer 的经典实现：每次 `shake()` 调用只增加 `trauma` 值，每帧自动衰减。多次震动自然叠加，比传统的"开始→结束"式震动自然得多。

---

## 15. Debug — 调试与性能

### 15.1 Logger（Autoload） Done

```gdscript
# src/debug/logger.gd
extends  Node

enum Level{DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3}

## 配置项
# 日志最低等级
var min_level : Level = Level.DEBUG
# var buffer_size: int = 10
# 日志路径(自动生成)
var _log_path : String = ""
var _log_dir : String = "user://custom_logs/"
# 最大日志存在数量
const MAX_LOG_FILES := 5
# 内存中的日志条目（用于 DebugConsole 等实时查看）
var _entries: Array[Dictionary] = []

# 内部项
signal log_added(entry: Dictionary)

func _ready() -> void:
	initialize()
	debug("Hello World", self.name)
	info("Hello World", self.name)
	warn("Hello World", self.name)
	error("Hello World", self.name)

# 初始化
func initialize() -> void:
	print("[Logger]: 被调用")
	var err := DirAccess.make_dir_recursive_absolute(_log_dir)
	load_config()
	print("[Logger]: 创建日志目录 - %s" % _log_dir)
	if err != OK:
		push_error("Logger: 无法创建日志目录 - %s (错误码: %d)" % [_log_path, err])
		print("[Logger]: 日志创建失败，错误码 %d" % err)
		return
	print("[Logger]: 日志目录就绪")
	# 获取系统时间并给日志命名
	var time_str: String = Time.get_datetime_string_from_system()
	time_str = time_str.replace(":","-")
	_log_path = _log_dir + time_str + ".log"
	print("[Logger]: 创建日志 - %s"%_log_path)
	var _file := FileAccess.open(_log_path,FileAccess.WRITE)
	if _file:
		_file.store_line("=========================")
		_file.store_line("Logger - %s" % Time.get_datetime_string_from_system())
		_file.store_line("=========================")
		print("[Logger]: 日志创建成功")
	else:
		push_error("Logger: 无法创建日志文件 - %s"%_log_path)
		print("[Logger]: 日志创建失败 - %s"%_log_path)
		return
	
	_clean_up_old_logs()
	print("[Logger]: 初始化完成，准备就绪")

func debug(message:String, source = null) -> void:
	_log(Level.DEBUG, message, source)
	
func info(message:String, source = null) -> void:
	_log(Level.INFO, message, source)
	
func warn(message:String, source = null) -> void:
	_log(Level.WARN, message, source)
	
func error(message:String, source = null) -> void:
	_log(Level.ERROR, message, source)

# 日志记录核心
func _log(level:Level, message: String, source) -> void:
	if level < min_level:
		return
		# 信息字典
	var entry := {
		"level": level,
		"message": message,
		"source": str(source) if source else "",
		"time": Time.get_time_string_from_system(),
		"frame": Engine.get_process_frames(),
	}
	
	_entries.append(entry)
	log_added.emit(entry)
	
	var level_str : String = Level.keys()[level]
	var source_str := "[%s]" % entry.source if not entry.source.is_empty() else ""
	print_rich("[color=gray][%s][/color] [%s] %s%s" % [entry.time, level_str, source_str, " " + message])
	
	_write_to_file(entry)


var _write_failed_warned: bool = false

func _write_to_file(entry:Dictionary) -> void:
	# 如果文件被外部删除，重新创建文件
	if not FileAccess.file_exists(_log_path):
		var f := FileAccess.open(_log_path, FileAccess.WRITE)
		print_rich("[color=orange][%s][/color]" % "[Logger]: 日志可能丢失，尝试重新创建日志")
		if f: f.close()

	# 重新创建文件失败，则报错提示
	if _log_path.is_empty():
		if not _write_failed_warned:
			_write_failed_warned = true
			push_warning("[Logger]: _log_path为空，日志写入已跳过(initialize()是否未被调用？)")
		return
	
	# 判断日志是否能够写入
	var file := FileAccess.open(_log_path, FileAccess.READ_WRITE)
	if file == null:
		if not _write_failed_warned:
			_write_failed_warned = true
			push_warning("[Logger]: 无法打开日志进行写入 - %s" % _log_path)
		return
	_write_failed_warned = false
	# 写入日志
	file.seek_end()
	file.store_line("[%s] [%s] %s: %s" % [entry.time, Level.keys()[entry.level], entry.source, entry.message])
	file.close()


# 读取配置文件
func load_config() -> void:
	var config_level : String = "debug"
	if $"/root".has_node("ConfigManager"):
		config_level = ConfigManager.get_value("debug.log_level", "debug")
		print("[Logger]: 从ConfigManager读取log_level = %s" % config_level)
	else:
		print("[Logger]: ConfigManager未注册，使用默认log_level = debug")
	match config_level:
		"debug": min_level = Level.DEBUG
		"info": min_level = Level.INFO
		"warn": min_level = Level.WARN
		"error": min_level = Level.ERROR


# 清除旧日志文件
func _clean_up_old_logs() -> void:
	var dir := DirAccess.open(_log_dir)
	if dir == null:
		return
	
	# 获取文件夹内所有日志文件
	var log_files: Array[Dictionary] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.ends_with(".log") and not dir.current_is_dir():
			var full_path := _log_dir + file_name
			log_files.append({
				"path": full_path,
				"modified": FileAccess.get_modified_time(full_path),
			})
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# 最新的排最前
	log_files.sort_custom(func(a, b): return a.modified > b.modified)
	
	# 清除日志
	for i in range(MAX_LOG_FILES, log_files.size()):
		DirAccess.remove_absolute(log_files[i].path)
		print("[Logger]: 已清理旧日志文 - %s" % log_files[i].path)

# 获取最近的日志条目（供 DebugConsole 使用）
func get_recent(count: int = 100) -> Array[Dictionary]:
	if _entries.size() <= count:
		return _entries.duplicate()
	return _entries.slice(-count)

# 获取当前日志文件的完整路径
func get_log_file_path() -> String:
	return _log_path

```

### 15.2 DebugConsole — 游戏内控制台

```gdscript
# src/debug/debug_console.gd
class_name DebugConsole
extends Control

@onready var _input: LineEdit = $VBox/Input
@onready var _output: RichTextLabel = $VBox/Output
@onready var _panel: Panel = $Panel

## 注册的命令 { "cmd_name": { "callback": Callable, "help": "...", "args": "..." } }
var _commands: Dictionary = {}

## 命令历史
var _history: Array[String] = []
var _history_index: int = -1


func _ready() -> void:
    visible = false
    _input.text_submitted.connect(_on_command_submitted)

    # 注册内建命令
    register_command("help", _cmd_help, "显示帮助信息")
    register_command("clear", _cmd_clear, "清空控制台")
    register_command("fps", _cmd_toggle_fps, "切换 FPS 显示")
    register_command("list_nodes", _cmd_list_nodes, "列出当前场景节点", "[parent_path]")


func _input(event: InputEvent) -> void:
    if event.is_action_pressed("debug_console"):  # 默认 ~ 键
        visible = not visible
        if visible:
            _input.grab_focus()
        get_viewport().set_input_as_handled()


func register_command(name: String, callback: Callable, help: String, args: String = "") -> void:
    _commands[name] = {"callback": callback, "help": help, "args": args}


func _on_command_submitted(text: String) -> void:
    if text.strip_edges().is_empty():
        return

    _history.append(text)
    _history_index = _history.size()
    _input.clear()

    _append_output("[color=gray]> %s[/color]" % text)

    var parts := text.split(" ")
    var cmd := parts[0].to_lower()
    var args: PackedStringArray = parts.slice(1) if parts.size() > 1 else []

    if _commands.has(cmd):
        var result = _commands[cmd].callback.call(args)
        if result is String and not result.is_empty():
            _append_output(result)
    else:
        _append_output("[color=red]未知命令: %s[/color]" % cmd)


func _append_output(text: String) -> void:
    _output.append_text(text + "\n")


func _cmd_help(args: PackedStringArray) -> String:
    var lines: Array[String] = ["[b]可用命令:[/b]"]
    for cmd in _commands:
        var entry = _commands[cmd]
        var args_text := " " + entry.args if not entry.args.is_empty() else ""
        lines.append("  [color=yellow]%s%s[/color] — %s" % [cmd, args_text, entry.help])
    return "\n".join(lines)


func _cmd_clear(args: PackedStringArray) -> void:
    _output.clear()


func _cmd_toggle_fps(args: PackedStringArray) -> String:
    # 通过 EventBus 通知 FPS 面板
    EventBus.emit("toggle_fps")
    return "FPS 显示已切换"
```

### 15.3 FPSMonitor — 性能监控面板

```gdscript
# src/debug/fps_monitor.gd
class_name FPSMonitor
extends Control

@onready var _label: Label = $Label

var _fps_history: Array[float] = []
var _history_size: int = 60  # 显示最近 60 帧


func _ready() -> void:
    EventBus.on("toggle_fps", _toggle_visibility)
    visible = ConfigManager.get_value("debug.show_fps", false)


func _process(_delta: float) -> void:
    if not visible:
        return

    var fps := Engine.get_frames_per_second()
    _fps_history.append(fps)
    if _fps_history.size() > _history_size:
        _fps_history.pop_front()

    # 计算平均值
    var avg := 0.0
    for f in _fps_history:
        avg += f
    avg /= _fps_history.size()

    _label.text = "FPS: %.0f (avg: %.0f) | Mem: %.1f MB | Objs: %d" % [
        fps,
        avg,
        OS.get_static_memory_usage() / 1048576.0,
        Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
    ]


func _toggle_visibility(_data = null):
    visible = not visible
```

### 15.4 DebugDraw — 调试绘制

```gdscript
# src/debug/debug_draw.gd
class_name DebugDraw
extends Node2D

static var instance: DebugDraw = null

var _draw_commands: Array[Dictionary] = []


func _ready() -> void:
    instance = self


func _draw() -> void:
    for cmd in _draw_commands:
        match cmd.type:
            "line":
                draw_line(cmd.from, cmd.to, cmd.color, cmd.width)
            "circle":
                draw_circle(cmd.center, cmd.radius, cmd.color)
            "rect":
                draw_rect(cmd.rect, cmd.color, false)
            "arrow":
                _draw_arrow(cmd.from, cmd.to, cmd.color, cmd.width)


func _process(_delta: float) -> void:
    _draw_commands.clear()
    queue_redraw()


## 静态便捷方法（供其他脚本调用）

static func line(from: Vector2, to: Vector2, color: Color = Color.RED, width: float = 2.0) -> void:
    if instance:
        instance._draw_commands.append({"type": "line", "from": from, "to": to, "color": color, "width": width})


static func circle(center: Vector2, radius: float, color: Color = Color.GREEN) -> void:
    if instance:
        instance._draw_commands.append({"type": "circle", "center": center, "radius": radius, "color": color})


static func rect(rect: Rect2, color: Color = Color.YELLOW) -> void:
    if instance:
        instance._draw_commands.append({"type": "rect", "rect": rect, "color": color})
```

> 使用时只需 `DebugDraw.circle(player.global_position, 50.0, Color.RED)` —— 不需要持有引用，不需要手动管理绘制节点。每帧自动清空并重绘。

### 15.5 CheatManager（Autoload）

```gdscript
# src/debug/cheat_manager.gd
class_name CheatManager
extends Node

var _cheats: Dictionary = {}  # { "cheat_name": bool }

## 仅在调试构建中启用
var enabled: bool = OS.is_debug_build()


func register_cheat(name: String, default: bool = false) -> void:
    _cheats[name] = default


func is_enabled(name: String) -> bool:
    return enabled and _cheats.get(name, false)


func toggle(name: String) -> bool:
    if not _cheats.has(name):
        return false
    _cheats[name] = not _cheats[name]
    EventBus.emit("cheat_toggled", {"name": name, "enabled": _cheats[name]})
    return _cheats[name]
```

---

## 16. Utils — 工具集

### 16.1 缓动函数库

```gdscript
# src/utils/easing.gd
class_name Easing
extends RefCounted

## 所有缓动函数均为静态方法，返回 t (0-1) 映射后的值
## 来源: https://easings.net/

static func ease_in_quad(t: float) -> float:
    return t * t

static func ease_out_quad(t: float) -> float:
    return t * (2.0 - t)

static func ease_in_out_quad(t: float) -> float:
    t *= 2.0
    if t < 1.0: return 0.5 * t * t
    t -= 1.0
    return -0.5 * (t * (t - 2.0) - 1.0)

static func ease_in_cubic(t: float) -> float:
    return t * t * t

static func ease_out_cubic(t: float) -> float:
    t -= 1.0
    return t * t * t + 1.0

static func ease_in_out_cubic(t: float) -> float:
    t *= 2.0
    if t < 1.0: return 0.5 * t * t * t
    t -= 2.0
    return 0.5 * (t * t * t + 2.0)

static func ease_out_elastic(t: float) -> float:
    if t == 0.0 or t == 1.0: return t
    return pow(2.0, -10.0 * t) * sin((t - 0.1) * 5.0 * PI) + 1.0

static func ease_out_bounce(t: float) -> float:
    if t < 1.0 / 2.75:
        return 7.5625 * t * t
    elif t < 2.0 / 2.75:
        t -= 1.5 / 2.75
        return 7.5625 * t * t + 0.75
    elif t < 2.5 / 2.75:
        t -= 2.25 / 2.75
        return 7.5625 * t * t + 0.9375
    else:
        t -= 2.625 / 2.75
        return 7.5625 * t * t + 0.984375
```

### 16.2 随机工具

```gdscript
# src/utils/random_utils.gd
class_name RandomUtils
extends RefCounted

## 加权随机选择
static func weighted_choice(weights: Dictionary) -> String:
    # weights: { "sword": 30, "shield": 20, "potion": 50 }
    var total := 0.0
    for key in weights:
        total += weights[key]

    var roll := randf() * total
    var cumulative := 0.0
    for key in weights:
        cumulative += weights[key]
        if roll <= cumulative:
            return key
    return weights.keys()[0]


## 随机打乱数组（Fisher-Yates）
static func shuffle(array: Array) -> Array:
    var result := array.duplicate()
    for i in range(result.size() - 1, 0, -1):
        var j := randi() % (i + 1)
        var temp = result[i]
        result[i] = result[j]
        result[j] = temp
    return result


## 正态分布随机（Box-Muller）
static func normal_random(mean: float = 0.0, std_dev: float = 1.0) -> float:
    var u1 := randf()
    var u2 := randf()
    var z := sqrt(-2.0 * log(maxf(u1, 0.0001))) * cos(2.0 * PI * u2)
    return mean + z * std_dev
```

### 16.3 GD 扩展方法

```gdscript
# src/utils/gd_extensions.gd
class_name GDExtensions
extends RefCounted

## 为数组增加扩展方法（通过静态方法实现，因为 GDScript 不支持直接扩展）

static func array_random(arr: Array):
    if arr.is_empty():
        return null
    return arr[randi() % arr.size()]


static func array_remove_all(arr: Array, item) -> void:
    var i := arr.size() - 1
    while i >= 0:
        if arr[i] == item:
            arr.remove_at(i)
        i -= 1


## Vector2 工具
static func v2_to_angle(v: Vector2) -> float:
    return v.angle()


static func v2_from_angle(angle: float, length: float = 1.0) -> Vector2:
    return Vector2(cos(angle), sin(angle)) * length


static func v2_rotate_around(point: Vector2, pivot: Vector2, angle: float) -> Vector2:
    var diff := point - pivot
    return pivot + Vector2(
        diff.x * cos(angle) - diff.y * sin(angle),
        diff.x * sin(angle) + diff.y * cos(angle)
    )


## 时间工具
static func delay(tree: SceneTree, seconds: float) -> Signal:
    return tree.create_timer(seconds).timeout


static func wait_frames(tree: SceneTree, frames: int) -> void:
    for i in range(frames):
        await tree.process_frame
```

### 16.4 文件工具

```gdscript
# src/utils/file_utils.gd
class_name FileUtils
extends RefCounted

static func read_json(path: String, default = null):
    if not FileAccess.file_exists(path):
        return default
    var file := FileAccess.open(path, FileAccess.READ)
    var text := file.get_as_text()
    file.close()
    var json := JSON.new()
    if json.parse(text) != OK:
        return default
    return json.data


static func write_json(path: String, data) -> bool:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(data, "\t"))
    file.close()
    return true


static func list_files_in_dir(path: String, extension: String = "") -> Array[String]:
    var result: Array[String] = []
    var dir := DirAccess.open(path)
    if dir == null:
        return result
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while not file_name.is_empty():
        if not dir.current_is_dir():
            if extension.is_empty() or file_name.ends_with(extension):
                result.append(path + "/" + file_name)
        file_name = dir.get_next()
    dir.list_dir_end()
    return result
```

---

## 17. Autoload 初始化顺序与依赖拓扑

Godot 的 Autoload 按 `project.godot` 中 `[autoload]` 段**从上到下**的顺序加载。因此声明顺序直接决定初始化顺序：

### 依赖拓扑图

```
Level 0 (无依赖):
  Logger ← 最先加载，任何模块都可能打日志
  ConfigManager ← 其他模块读取配置

Level 1 (依赖 Level 0):
  GameManager ← 需要 Logger+ConfigManager 就绪
  EventBus ← 需要 Logger

Level 2 (依赖 EventBus + ConfigManager):
  SceneManager ← 需要 EventBus 发射/监听场景事件
  UIManager ← 需要 EventBus
  AudioManager ← 需要 ConfigManager 恢复音量
  InputManager ← 需要 ConfigManager 读取输入设置
  SaveSystem ← 需要 EventBus
  LocaleManager ← 需要 ConfigManager

Level 3 (依赖上层服务):
  CheatManager ← 需要 EventBus + Logger
```

### project.godot 中的 Autoload 顺序（最终版）

```ini
[autoload]

; === Level 0: 无依赖 ===
Logger="*res://src/debug/logger.gd"
ConfigManager="*res://src/core/config_manager.gd"

; === Level 1: 依赖 Level 0 ===
GameManager="*res://src/core/game_manager.gd"
EventBus="*res://src/event/event_bus.gd"

; === Level 2: 依赖 EventBus + ConfigManager ===
SceneManager="*res://src/scene/scene_manager.gd"
UIManager="*res://src/ui/ui_manager.gd"
AudioManager="*res://src/audio/audio_manager.gd"
InputManager="*res://src/input/input_manager.gd"
SaveSystem="*res://src/data/save_system.gd"
LocaleManager="*res://src/localization/locale_manager.gd"

; === Level 3: 依赖上层服务 ===
CheatManager="*res://src/debug/cheat_manager.gd"
```

### `initialize()` 调用链

```
Logger._ready()          → Logger 就绪
ConfigManager._ready()   → ConfigManager 就绪
GameManager._ready()     → 收集子系统 → 拓扑排序 → 按序调用 initialize()
  ├── ConfigManager.initialize()      → 加载配置文件
  ├── EventBus.initialize()           → (空操作)
  ├── SceneManager.initialize()       → 创建过渡层
  ├── UIManager.initialize()          → 创建 UI CanvasLayer
  ├── AudioManager.initialize()       → 创建音频频道 + 加载音量
  ├── InputManager.initialize()       → 确保输入映射
  ├── SaveSystem.initialize()         → 确保存档目录
  ├── LocaleManager.initialize()      → 加载翻译文件
  └── CheatManager.initialize()       → 注册内建作弊
  → EventBus.emit("framework_ready")
```

---

## 总结：关键实现决策一览

| 决策 | 选择 | 理由 |
|------|------|------|
| Autoload vs class_name | 全局服务 → Autoload；可多实例 → class_name | 最小化全局状态，保持模块独立性 |
| 数据传递 | Dictionary（带约定字段） | 最大灵活性，无编译期约束 |
| 存档序列化 | `FileAccess.open_encrypted_with_pass` + `store_var` | Godot 4 内置 AES 加密，零依赖 |
| 过渡效果 | CanvasLayer + Tween | 利用 Godot 原生渲染层，简单可靠 |
| 对象池实现 | `RefCounted` 而非 `Node` | 池管理器不需要在场景树中 |
| 状态机 | 独立 Node 挂到实体上 | `_process` 自动运行，无需手动驱动 |
| Buff 系统 | Resource 子类 + duplicate(true) 实例化 | 模板与实例分离，属性修改可叠加 |
| 震屏 | Trauma-based（创伤值衰减） | 多次震动自然叠加，比简单动画更真实 |
| UI 链式 API | `DialogBuilder` (RefCounted) | 符合常见 UI 框架习惯，代码清晰 |
