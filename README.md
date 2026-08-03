# Godot Action Framework (暂定)

> A modular, production-oriented gameplay runtime framework for Godot 4.

---

=目前的readme由ai生成，之后会手动编写=

# 一、项目目标

构建一个适用于 Godot 4 的可复用 Gameplay Runtime Framework。

设计目标：

- 高扩展性（Extensible）
- 高可维护性（Maintainable）
- 数据驱动（Data Driven）
- 模块化（Modular）
- 面向多个项目复用（Reusable）
- 插件化（Addon）
- 支持快速 Prototype（Gameplay Sandbox）

框架并不是一个游戏，而是一个 Runtime。

---

# 二、设计理念

核心思想：

Everything is Data

Everything is Component

Everything is Action

Everything is Resolver

Everything is Event

即：

- Node 负责表现
- Component 提供能力
- Resource 保存数据
- Resolver 决定规则
- Action 描述行为
- FSM 管理状态
- EventBus 解耦模块

---

# 三、整体架构

```
                Game
                  │
        ──────────┼──────────
                  │
             Runtime
                  │
      ┌───────────┼────────────┐
      │           │            │
 Input System Character     World
      │           │
      │      Component
      │           │
      │      Resolver
      │           │
      │      StateMachine
      │           │
      │      Action
      │           │
      └────── Combat ─────────┘
```

---

# 四、Package 规划

```
Core
Character
Input
Action
Combat
State
Ability
AI
Inventory
World
UI
Resource
Save
Editor
Sandbox
```

预计：

- Package：13+
- Module：40+
- Class：100+

---

# 五、Core 架构

```
Bootstrap
    │
    ▼
Framework
    │
    ▼
ApplicationContext
    │
    ├── ServiceRegistry
    ├── EventBus
    ├── RuntimeContext
    └── Scheduler
            │
            ▼
        IService
            │
    ┌───────┼────────┐
    ▼       ▼        ▼
Scene   Audio    Save
```

Core 永远不依赖 Gameplay。

Gameplay 依赖 Core。

---

# 六、Core UML

## Framework

职责：

维护 ApplicationContext。

属性：

- version
- context

方法：

- initialize()
- shutdown()
- get_context()

---

## ApplicationContext

职责：

整个 Runtime 的入口。

属性：

- service_registry
- runtime_context
- event_bus

方法：

- initialize()
- shutdown()
- update()
- physics_update()
- get_service()
- publish()
- subscribe()

---

## ServiceRegistry

职责：

注册所有 Service。

方法：

- register()
- unregister()
- resolve()
- initialize_all()
- shutdown_all()

---

## IService

统一生命周期。

方法：

- initialize()
- shutdown()
- update()
- physics_update()

所有 Manager 实现 IService。

---

## RuntimeContext

保存全局运行状态。

例如：

- Pause
- TimeScale
- CurrentPlayer
- CurrentLevel
- DebugMode

---

## EventBus

事件中心。

方法：

- subscribe()
- unsubscribe()
- emit()

用于解耦：

Combat

UI

Quest

Audio

Achievement

等系统。

---

## Scheduler

负责：

延迟执行。

例如：

- Buff Tick
- 延迟爆炸
- AI Timer

---

# 七、Character Framework

Character 不负责：

- Combat
- Weapon
- Inventory

Character 只负责生命周期。

```
Character
│
├── ComponentContainer
├── StateMachine
└── ActionExecutor
```

所有能力来自 Component。

---

# 八、Component

```
HealthComponent

MovementComponent

AnimationComponent

WeaponComponent

InventoryComponent

BuffComponent

AbilityComponent

InteractionComponent
```

角色通过挂组件获得能力。

而不是继承。

---

# 九、Resolver

Resolver 是整个 Framework 的灵魂。

```
Input

↓

InputResolver

↓

Command

↓

ActionResolver

↓

Action

↓

FSM

↓

Combat
```

所有规则统一在 Resolver 中解析。

---

# 十、Action

角色不会：

attack()

而是：

perform(Action)

例如：

AttackAction

SkillAction

RollAction

JumpAction

MoveAction

InteractAction

Action 描述的是一个完整流程。

例如：

Attack：

播放动画

↓

等待前摇

↓

开启 Hitbox

↓

关闭 Hitbox

↓

后摇结束

↓

完成

---

# 十一、FSM

FSM 只负责：

状态。

```
Idle

Walk

Run

Jump

Fall

Attack

Roll

Dead
```

FSM 不负责：

动画

伤害

碰撞

---

# 十二、Combat

```
AttackAction

↓

Hitbox

↓

CombatSystem

↓

DamageCalculator

↓

HealthComponent
```

Combat 不知道：

Player

Enemy

Boss

统一操作 Component。

---

# 十三、数据驱动

全部使用 Resource。

例如：

WeaponData

SkillData

BuffData

EnemyData

ProjectileData

AnimationData

HitboxData

DropTable

所有玩法通过 Resource 配置。

---

# 十四、Sandbox

Framework 最终不仅提供 Runtime。

还提供：

```
Sandbox

├── Combat Tester

├── Ability Tester

├── AI Tester

├── Animation Tester

├── Physics Tester

└── Performance Monitor
```

用于快速 Prototype。

---

# 十五、未来路线

Version 1.0

完成：

- Core
- Character
- Input
- Action
- FSM
- Combat

Version 2.0

新增：

- Ability
- Inventory
- Buff
- AI
- Dialogue

Version 3.0

新增：

- Visual Editor
- Sandbox
- Network
- Replay
- Mod Support

---

# 十六、核心原则

Framework 不负责玩法。

Framework 提供 Runtime。

游戏只负责：

- Resource
- 美术
- UI
- 剧情
- 数值
- 玩法组合

这样：

不同项目可以共享同一套 Runtime。

---

# 十七、长期目标

打造一个：

Production Ready

Modular

Gameplay Runtime

for Godot 4

能够支撑：

- ARPG
- Metroidvania
- Soulslike
- Roguelite
- Top-down Action
- Boss Rush

等动作游戏。
