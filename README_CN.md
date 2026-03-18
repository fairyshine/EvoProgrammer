# EvoProgrammer

[English README](./README.md)

**一个能自我演进的程序员，自动迭代你的代码库。**

给它一个自然语言目标，指向一个目录，然后你就可以去喝咖啡了 — EvoProgrammer 会不断循环调用 coding agent（Codex、Claude Code 或你自己的），读取自己的输出，修复自己的错误，一轮接一轮地推进项目，直到任务完成或你按下 `Ctrl+C`。

## 为什么选 EvoProgrammer

**自迭代代码演进** — 不同于一次性的 agent 调用，EvoProgrammer 会把 agent 反复投入同一个仓库（它实际上也在迭代这个代码仓库，它本身的仓库）。每一轮都建立在上一轮的基础上：第 1 轮搭脚手架，第 2 轮写测试，第 3 轮修 bug，第 4 轮打磨细节……循环持续进行，直到代码库收敛或达到你设定的上限。

**广泛的语言、框架和项目覆盖** — 开箱即用支持 20 种语言、31 个框架、19 种项目类型，全部可从仓库自动检测。无论你在做 Next.js SaaS、Expo 或 React Native 移动应用、Flutter 移动应用、Bevy 多人游戏、FastAPI 微服务、Spring 后端、Phoenix 服务、Astro 或 Nuxt 前端、Shiny 应用、Terraform 基础设施，还是基于 CMake 的原生工具，EvoProgrammer 都会在每次 agent 调用中注入正确的惯用写法、工具链命令和架构指导。

| 语言 (20) | 框架 (31) | 项目类型 (19) |
|---|---|---|
| Python, TypeScript, JavaScript, Rust, Go, C, C++, Java, C#, Kotlin, Swift, Dart, PHP, Ruby, GDScript, Elixir, Scala, Lua, R, Terraform | React, Next.js, Vue, Svelte, Nuxt, Astro, Expo, React Native, Django, Flask, FastAPI, Streamlit, Express, NestJS, Rails, Laravel, Spring, Gin, Actix-web, Axum, Bevy, Flutter, Godot, Unity, Unreal, Electron, Tauri, Pygame, Qt, Phoenix, Shiny | Web App, Backend Service, CLI Tool, Library, Desktop App, Mobile App, Browser Game, 单机游戏, 手游, 联网游戏, AI Agent, 数据管线, 插件, 嵌入式系统, 基础设施, 论文, 科学实验, PPT, Office |

最近这一轮还强化了项目类型自动识别，不再过度偏向 shell 仓库：非 shell CLI、Spring 或 Phoenix 风格后端、Expo 或 React Native 移动应用、Nuxt 或 Astro 前端、Electron 或 Tauri 桌面应用、Shiny Web 应用、Terraform 基础设施仓库、以及游戏引擎仓库都会更准确地命中。Node 框架检测的热点路径现在也会先建立缓存的 package token 索引，减少重复扫描 `package.json`，同时让框架识别更精确。`inspect` / `verify` 也能为 Gradle、Maven、.NET、SwiftPM、Mix、sbt、LuaRocks、R、Terraform、CMake、Expo 和 React Native 项目推导出更完整的默认命令。

## 快速开始

### 1. 克隆 & 安装

```zsh
git clone https://github.com/user/EvoProgrammer.git
cd EvoProgrammer
chmod +x bin/EvoProgrammer install.sh LOOP.sh MAIN.sh DOCTOR.sh INSPECT.sh VERIFY.sh CLEAN.sh STATUS.sh PROFILES.sh
./install.sh            # 创建符号链接到 ~/.local/bin/EvoProgrammer
```

> **注意：** 克隆后你可能需要对上面这些脚本执行 `chmod +x`。安装脚本会创建一个符号链接，请确保 `~/.local/bin` 在你的 `PATH` 中。

### 2. 最简单的用法

```zsh
mkdir my-project && cd my-project
EvoProgrammer "做一个带登录和测试的待办应用"
```

就这样。EvoProgrammer 会自动检测一切，持续迭代，直到你按 `Ctrl+C`。

### 3. 单次模式

```zsh
EvoProgrammer once "初始化一个 Vite + React + TypeScript 项目"
```

### 4. 限定迭代次数

```zsh
EvoProgrammer --max-iterations 5 "构建一个带评论和部署脚本的全栈博客"
```

## 更多示例

```zsh
# 使用 Claude Code 而不是 Codex
EvoProgrammer --agent claude "实现一个卡牌对战主循环"

# 显式指定语言 + 框架 + 项目类型
EvoProgrammer --language rust --framework bevy --project-type online-game \
  "先搭建专用服务器、同步逻辑和测试脚手架"

# Godot 单机游戏
EvoProgrammer --language gdscript --framework godot --project-type single-player-game \
  "先做出第一版可玩循环、场景切换和存档点"

# Flutter 移动应用
EvoProgrammer --language dart --framework flutter --project-type mobile-app \
  "Build offline auth, app navigation, and widget tests"

# Expo 移动应用
EvoProgrammer --language typescript --framework expo --project-type mobile-app \
  "实现登录流程、导航和设备端表单校验"

# 完全自动检测
EvoProgrammer "构建一个支持专用服务器的多人竞技原型"

# 指向其他目录
EvoProgrammer --target-dir /path/to/project "完善 README、测试和 CI"

# 每次成功迭代后自动提交
EvoProgrammer --auto-commit --auto-commit-message "feat: evolve repo" \
  "Add the missing mobile flow and tighten verification"

# 向 agent CLI 透传额外参数
EvoProgrammer --agent-args '["--model","gpt-5"]' "生成完整项目并持续修复问题"

# 从文件加载长提示词
EvoProgrammer --prompt-file ./prompt.txt

# 只预览命令不执行
EvoProgrammer --max-iterations 3 --dry-run "完善项目结构并补测试"

# 复用 inspect 导出的 env 上下文快照
EvoProgrammer inspect --target-dir /path/to/project \
  --report-file ./project-context.env --report-format env
EvoProgrammer verify --context-file ./project-context.env --steps lint,test
EvoProgrammer once --context-file ./project-context.env "Optimize startup time"

# 检查运行环境
EvoProgrammer doctor --target-dir /path/to/project

# 查看仓库自动检测结果
EvoProgrammer inspect --target-dir /path/to/project
EvoProgrammer inspect --target-dir /path/to/project --format commands
EvoProgrammer inspect --target-dir /path/to/project --format json
EvoProgrammer inspect --target-dir /path/to/project --format diagnostics
EvoProgrammer inspect --target-dir /path/to/project --format profiles
EvoProgrammer inspect --target-dir /path/to/project --format env
EvoProgrammer inspect --target-dir /path/to/project \
  --report-file ./inspect-report.json --report-format json

# 执行自动推导出的验证命令链
EvoProgrammer verify --target-dir /path/to/project
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --list --list-format json
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --require-all
EvoProgrammer verify --target-dir /path/to/project \
  --report-file ./verify-report.json --report-format json

# 查看版本
EvoProgrammer --version

# 清理旧产物（默认 30 天以上）
EvoProgrammer clean --dry-run

# 查看最近运行记录
EvoProgrammer status --last 5
EvoProgrammer status --kind session --status completed
EvoProgrammer status --format json --report-file ./status-report.json --report-format json

# 浏览内置 profile 目录
EvoProgrammer profiles
EvoProgrammer profiles --category languages
EvoProgrammer profiles --category frameworks --format json
```

## 环境要求

- zsh 4.3+
- `PATH` 中至少有一个受支持的 agent CLI（`codex` 或 `claude`）

## 开发校验

```zsh
zsh tests/run_tests.sh
zsh tests/run_lint.sh
zsh tests/run_extended_tests.sh
```

`tests/run_lint.sh` 与当前 zsh-only 运行时模型保持一致：它只对 POSIX
bootstrap shim 运行 `shellcheck`，其余脚本统一使用 `zsh -n` 做语法校验。

## 子命令

| 命令 | 说明 |
|---|---|
| `EvoProgrammer [prompt]` | 循环模式 — 持续迭代直到停止 |
| `EvoProgrammer once [prompt]` | 单次迭代 |
| `EvoProgrammer doctor` | 检查本地环境 |
| `EvoProgrammer inspect` | 查看检测到的仓库上下文与命令计划 |
| `EvoProgrammer verify` | 执行检测到的 lint/typecheck/test/build 命令 |
| `EvoProgrammer clean` | 清理旧产物目录 |
| `EvoProgrammer status` | 查看运行历史、筛选结果和机器可读报告 |
| `EvoProgrammer profiles` | 列出内置语言、框架和项目类型 profile |
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
| `--context-file FILE` | 复用 `inspect --format env` 生成的上下文快照 |
| `-n, --max-iterations N` | 迭代 N 次后停止（0 = 不限） |
| `-d, --delay-seconds N` | 迭代间隔秒数 |
| `-c, --continue-on-error` | 失败后继续循环 |
| `-q, --quiet` | 静默模式 |
| `-v, --verbose` | 详细输出 |
| `--dry-run` | 只打印命令不执行 |
| `--agent-args JSON` | 额外 agent 参数（JSON 字符串列表） |
| `--auto-commit` | 每次成功迭代后提交本次新增的 git 变更 |
| `--auto-commit-message TEXT` | 覆盖自动提交信息 |

## 检测与验证

当你想先看清 EvoProgrammer 检测到了什么，再决定是否调用 agent，可以用
`inspect`：

```zsh
EvoProgrammer inspect --target-dir /path/to/project --format summary
EvoProgrammer inspect --target-dir /path/to/project --format commands
EvoProgrammer inspect --target-dir /path/to/project --prompt "修复失败测试" --format prompt
EvoProgrammer inspect --target-dir /path/to/project --format json
EvoProgrammer inspect --target-dir /path/to/project --format diagnostics
EvoProgrammer inspect --target-dir /path/to/project --format profiles
EvoProgrammer inspect --target-dir /path/to/project --format env
EvoProgrammer inspect --target-dir /path/to/project --report-file ./inspect-report.env --report-format env
```

当你想让 EvoProgrammer 自己去执行仓库里的验证命令链时，可以用 `verify`：

```zsh
EvoProgrammer verify --target-dir /path/to/project
EvoProgrammer verify --target-dir /path/to/project --steps lint,test
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --list --list-format env
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --require-all
EvoProgrammer verify --target-dir /path/to/project --dry-run
EvoProgrammer verify --target-dir /path/to/project --report-file ./verify-report.env --report-format env
```

`inspect --format diagnostics` 会额外输出仓库检测 facts 缓存的命中、未命中和条目数，
方便分析一次检测为什么快或慢。

`once` 和循环模式现在也支持 `--auto-commit` 与
`--auto-commit-message`。自动提交只会 stage/commit 当前这一次迭代里新产生
的变更路径，不会把仓库里原本就存在的脏改动一起提交。

`inspect --format profiles` 会输出命中的语言、框架、项目类型候选项及其检测分数，
方便理解和排查自动检测的决策过程。

`inspect --format commands` 会输出一个更聚焦的命令视图，适合只看
dev/build/test/lint/typecheck 计划而不关心完整仓库分析的时候使用。

`inspect --format env` 会把同一份检测上下文导出为可直接 `source` 的
`EVOP_INSPECT_*` 环境变量，方便 CI 和脚本复用，而不必再解析面向人的文本输出。

`inspect --report-file` 可以把任意 inspect 输出格式落盘，包括 JSON 和可 `source`
的 env 导出，方便在 CI 或包装脚本里直接消费。

`--context-file` 允许 `inspect`、`verify`、`doctor`、`once` 和循环模式复用先前
`inspect --format env` 生成的上下文快照，而不是每次都重新做同一轮仓库检测。
这对 CI 包装脚本和同一仓库上的连续运行更稳定，也更快。

`verify` 和 agent prompt、`doctor`、`inspect` 共用同一套命令检测层，因此各处
看到的命令计划保持一致。

`verify --report-file` 会把实际执行过的步骤结果、退出码、耗时和日志路径输出成
JSON 或可 `source` 的 `EVOP_VERIFY_*` 环境变量，方便在 CI 或外层脚本里复用，
不用再解析标准输出。

`verify --list --list-format json|env` 会在不执行命令的情况下输出当前选中的验证计划，
方便 CI 包装脚本先检查解析出的命令。

`verify --require-all` 会在所选步骤里存在未检测到命令时直接失败，方便把自动化流程
收紧成可复现的契约。

`status` 现在支持 `--kind`、`--status`、`--agent` 筛选，以及 `--format json|env`
和 `--report-file`，方便把运行历史导出给 CI 或包装脚本消费。

`profiles` 会列出内置的语言、框架和项目类型 profile，并附带从 prompt 指导语里
提取的简要说明和定义文件路径。它支持 `--category`、`--format summary|json|env`
以及 `--report-file`，方便包装脚本和 CI 直接消费。

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
| `PROFILES.sh` | 内置 profile 目录输出 |
| `lib/inspect.sh` | inspect 格式校验，以及 stdout/report-file 输出分发 |
| `lib/status.sh` | status 的筛选、元数据解析和 summary/json/env 渲染 |
| `lib/agents/definitions/` | 可插拔 agent 定义 |
| `lib/profiles/diagnostics.sh` | 命中的 profile 候选项和检测分数 |
| `lib/profiles/report.sh` | profile 目录的 summary/json/env 渲染 |
| `lib/profiles/candidates.sh` | 在执行 profile hook 前先做廉价候选筛选，减少不必要的加载 |
| `lib/profiles/definitions/` | 语言、框架和项目类型 profile |
| `lib/project-context/` | 仓库检测、命令推导与 prompt 渲染 |

当前架构分层说明见 [`docs/architecture.md`](./docs/architecture.md)。

## 验证

```zsh
zsh tests/run_tests.sh
```
