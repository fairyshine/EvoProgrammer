# EvoProgrammer

[English README](./README.md)

**一个能自我演进的程序员，自动迭代你的代码库。**

给它一个自然语言目标，指向一个目录，然后你就可以去喝咖啡了 — EvoProgrammer 会不断循环调用 coding agent（Codex、Claude Code 或你自己的），读取自己的输出，修复自己的错误，一轮接一轮地推进项目，直到任务完成或你按下 `Ctrl+C`。

## 为什么选 EvoProgrammer

**自迭代代码演进** — 不同于一次性的 agent 调用，EvoProgrammer 会把 agent 反复投入同一个仓库（它实际上也在迭代这个代码仓库，它本身的仓库）。每一轮都建立在上一轮的基础上：第 1 轮搭脚手架，第 2 轮写测试，第 3 轮修 bug，第 4 轮打磨细节……循环持续进行，直到代码库收敛或达到你设定的上限。

**广泛的语言、框架和项目覆盖** — 开箱即用支持 13 种语言、24 个框架、17 种项目类型，全部可从仓库自动检测。无论你在做 Next.js SaaS、Bevy 多人游戏、FastAPI 微服务还是 Godot 单机游戏，EvoProgrammer 都会在每次 agent 调用中注入正确的惯用写法、工具链命令和架构指导。

| 语言 (13) | 框架 (24) | 项目类型 (17) |
|---|---|---|
| Python, TypeScript, JavaScript, Rust, Go, C++, Java, C#, Kotlin, Swift, PHP, Ruby, GDScript | React, Next.js, Vue, Svelte, Django, Flask, FastAPI, Streamlit, Express, NestJS, Rails, Laravel, Spring, Gin, Actix-web, Axum, Bevy, Godot, Unity, Unreal, Electron, Tauri, Pygame, Qt | Web App, Backend Service, CLI Tool, Library, Desktop App, Browser Game, 单机游戏, 手游, 联网游戏, AI Agent, 数据管线, 插件, 嵌入式系统, 论文, 科学实验, PPT, Office |

## 快速开始

### 1. 克隆 & 安装

```bash
git clone https://github.com/user/EvoProgrammer.git
cd EvoProgrammer
chmod +x bin/EvoProgrammer install.sh LOOP.sh MAIN.sh DOCTOR.sh INSPECT.sh VERIFY.sh CLEAN.sh STATUS.sh
./install.sh            # 创建符号链接到 ~/.local/bin/EvoProgrammer
```

> **注意：** 克隆后你可能需要对上面这些脚本执行 `chmod +x`。安装脚本会创建一个符号链接，请确保 `~/.local/bin` 在你的 `PATH` 中。

### 2. 最简单的用法

```bash
mkdir my-project && cd my-project
EvoProgrammer "做一个带登录和测试的待办应用"
```

就这样。EvoProgrammer 会自动检测一切，持续迭代，直到你按 `Ctrl+C`。

### 3. 单次模式

```bash
EvoProgrammer once "初始化一个 Vite + React + TypeScript 项目"
```

### 4. 限定迭代次数

```bash
EvoProgrammer --max-iterations 5 "构建一个带评论和部署脚本的全栈博客"
```

## 更多示例

```bash
# 使用 Claude Code 而不是 Codex
EvoProgrammer --agent claude "实现一个卡牌对战主循环"

# 显式指定语言 + 框架 + 项目类型
EvoProgrammer --language rust --framework bevy --project-type online-game \
  "先搭建专用服务器、同步逻辑和测试脚手架"

# Godot 单机游戏
EvoProgrammer --language gdscript --framework godot --project-type single-player-game \
  "先做出第一版可玩循环、场景切换和存档点"

# 完全自动检测
EvoProgrammer "构建一个支持专用服务器的多人竞技原型"

# 指向其他目录
EvoProgrammer --target-dir /path/to/project "完善 README、测试和 CI"

# 向 agent CLI 透传额外参数
EvoProgrammer --agent-args '["--model","gpt-5"]' "生成完整项目并持续修复问题"

# 从文件加载长提示词
EvoProgrammer --prompt-file ./prompt.txt

# 只预览命令不执行
EvoProgrammer --max-iterations 3 --dry-run "完善项目结构并补测试"

# 检查运行环境
EvoProgrammer doctor --target-dir /path/to/project

# 查看仓库自动检测结果
EvoProgrammer inspect --target-dir /path/to/project

# 执行自动推导出的验证命令链
EvoProgrammer verify --target-dir /path/to/project

# 查看版本
EvoProgrammer --version

# 清理旧产物（默认 30 天以上）
EvoProgrammer clean --dry-run

# 查看最近运行记录
EvoProgrammer status --last 5
```

## 环境要求

- Bash 4.3+
- `PATH` 中至少有一个受支持的 agent CLI（`codex` 或 `claude`）

## 子命令

| 命令 | 说明 |
|---|---|
| `EvoProgrammer [prompt]` | 循环模式 — 持续迭代直到停止 |
| `EvoProgrammer once [prompt]` | 单次迭代 |
| `EvoProgrammer doctor` | 检查本地环境 |
| `EvoProgrammer inspect` | 查看检测到的仓库上下文与命令计划 |
| `EvoProgrammer verify` | 执行检测到的 lint/typecheck/test/build 命令 |
| `EvoProgrammer clean` | 清理旧产物目录 |
| `EvoProgrammer status` | 查看运行历史 |
| `EvoProgrammer --version` | 打印版本号 |
| `EvoProgrammer help` | 显示帮助 |

## 常用选项

| 标志 | 说明 |
|---|---|
| `-g, --agent NAME` | 选择 agent：`codex` 或 `claude` |
| `--language NAME` | 语言 profile（省略则自动检测） |
| `--framework NAME` | 框架 profile（省略则自动检测） |
| `--project-type NAME` | 项目类型 profile（省略则自动检测） |
| `-p, --prompt TEXT` | 提示词 |
| `-f, --prompt-file FILE` | 从文件读取提示词 |
| `-t, --target-dir DIR` | 目标仓库目录 |
| `-o, --artifacts-dir DIR` | 自定义产物存储位置 |
| `-n, --max-iterations N` | 迭代 N 次后停止（0 = 不限） |
| `-d, --delay-seconds N` | 迭代间隔秒数 |
| `-c, --continue-on-error` | 失败后继续循环 |
| `-q, --quiet` | 静默模式 |
| `-v, --verbose` | 详细输出 |
| `--dry-run` | 只打印命令不执行 |
| `--agent-args JSON` | 额外 agent 参数（JSON 字符串列表） |

## 检测与验证

当你想先看清 EvoProgrammer 检测到了什么，再决定是否调用 agent，可以用
`inspect`：

```bash
EvoProgrammer inspect --target-dir /path/to/project --format summary
EvoProgrammer inspect --target-dir /path/to/project --prompt "修复失败测试" --format prompt
```

当你想让 EvoProgrammer 自己去执行仓库里的验证命令链时，可以用 `verify`：

```bash
EvoProgrammer verify --target-dir /path/to/project
EvoProgrammer verify --target-dir /path/to/project --steps lint,test
EvoProgrammer verify --target-dir /path/to/project --dry-run
```

`verify` 和 agent prompt、`doctor`、`inspect` 共用同一套命令检测层，因此各处
看到的命令计划保持一致。

## 项目配置文件

在项目根目录放一个 `.evoprogrammer.conf` 来设置默认值：

```ini
agent=claude
language=typescript
framework=nextjs
project_type=web-app
verbosity=0
```

优先级：CLI 标志 > 环境变量 > `.evoprogrammer.conf` > 内置默认值。

## 生命周期钩子

在 `.evoprogrammer/hooks/` 下放置可执行脚本：

- `pre-iteration` — 每次 agent 调用前执行
- `post-iteration` — 每次 agent 调用后执行

钩子是建议性的：失败只会打印警告，不会中断运行。

## 内部结构

| 文件 | 职责 |
|---|---|
| `bin/EvoProgrammer` | CLI 入口和子命令分发 |
| `LOOP.sh` | 单次 agent 迭代 |
| `MAIN.sh` | 重复迭代循环 |
| `DOCTOR.sh` | 环境检查 |
| `INSPECT.sh` | 面向人的仓库检测与 prompt 预览 |
| `VERIFY.sh` | 自动推导验证命令链并执行 |
| `CLEAN.sh` | 产物清理 |
| `STATUS.sh` | 运行历史查看 |
| `lib/agents/definitions/` | 可插拔 agent 定义 |
| `lib/profiles/definitions/` | 语言、框架和项目类型 profile |
| `lib/project-context/` | 仓库检测、命令推导与 prompt 渲染 |

当前架构分层说明见 [`docs/architecture.md`](./docs/architecture.md)。

## 验证

```bash
bash tests/run_tests.sh
```
