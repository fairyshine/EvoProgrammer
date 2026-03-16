# EvoProgrammer

[English README](./README.md)

EvoProgrammer 是一个围绕 `codex`、`claude` 等代码 Agent 命令封装的小型 Bash CLI。它可以进入任意项目目录，对该目录执行自然语言指令，并持续迭代直到你手动停止。

## 功能概览

- `EvoProgrammer "你的指令"`：在当前目录运行所选 Agent，并持续迭代。
- `EvoProgrammer once "你的指令"`：只运行一次 Agent。
- `--agent`：在内置 Agent 预设之间切换，例如 `codex` 或 `claude`。
- `--language`：为内置语言 profile 注入适配指导，例如 `python`、`rust`、`go`、`typescript`、`gdscript`、`swift`，也可以交给 EvoProgrammer 自动检测。
- `--framework`：为内置框架 profile 注入适配指导，例如 `fastapi`、`django`、`react`、`nextjs`、`godot`、`bevy`、`axum`，也可以交给 EvoProgrammer 自动检测。
- `--project-type`：为内置项目场景 profile 注入适配指导，例如 `single-player-game`、`online-game`、`paper`、`scientific-experiment`、`ppt`、`office`、`web-app`、`backend-service`，也可以交给 EvoProgrammer 自动检测。
- `EvoProgrammer doctor`：在长时间自治运行前检查本地环境是否可用。
- `--target-dir`：将 CLI 指向其他目录。
- 默认会把运行产物写入 `TARGET_DIR/.evoprogrammer/runs`，方便回看每次执行。
- 当 `TARGET_DIR` 是 Git 仓库时，EvoProgrammer 会把 `.evoprogrammer/` 写入本地 `.git/info/exclude`，避免后续迭代把这些产物再次读回上下文。
- `--artifacts-dir`：将运行产物写入自定义目录。
- `--prompt-file`：从文件读取长提示词，而不是直接写在命令行里。
- `--dry-run`：只查看实际执行的命令和目标目录，不真正运行 Agent。
- `--max-iterations`、`--delay-seconds`、`--continue-on-error`：控制长时间循环任务。
- wrapper 级别的选项也可以写在 `once` 或 `doctor` 前面。

内部结构：

- `bin/EvoProgrammer`：面向用户的 CLI 入口。
- `LOOP.sh`：执行一次 Agent 迭代。
- `MAIN.sh`：持续重复执行迭代。
- `install.sh`：将 `EvoProgrammer` 命令安装到本地 `bin` 目录。

## 环境要求

- Bash
- `PATH` 中至少有一个受支持的 Agent CLI，例如 `codex` 或 `claude`

## 安装

安装到 `~/.local/bin`：

```bash
./install.sh
```

安装到自定义目录：

```bash
./install.sh /custom/bin
```

如果不想运行安装脚本，也可以直接把本仓库的 `bin/` 目录加入 `PATH`。

## 使用方式

进入你希望生成或演进代码的目录，然后执行：

```bash
EvoProgrammer "生成一个完整的博客系统，包含登录、文章管理、评论和部署脚本"
```

这条命令会将当前目录作为目标项目目录，并持续迭代，直到你按 `Ctrl+C` 停止。

限制迭代次数：

```bash
EvoProgrammer --max-iterations 3 "构建一个带测试的全栈待办应用"
```

只运行一次：

```bash
EvoProgrammer once "初始化一个 Vite + React + TypeScript 项目"
```

也可以把 wrapper 选项写在子命令前面：

```bash
EvoProgrammer --agent claude once "初始化一个带类型约束的 FastAPI 服务"
```

指定其他目录作为目标：

```bash
EvoProgrammer --target-dir /path/to/project "完善 README、测试和 CI"
```

使用 Claude Code 而不是 Codex：

```bash
EvoProgrammer --agent claude "实现第一版可玩的卡牌对战主循环"
```

按 Rust + Bevy 联网游戏项目来适配：

```bash
EvoProgrammer --language rust --framework bevy --project-type online-game "先搭建专用服务器、同步逻辑和测试脚手架"
```

按 Godot + GDScript 项目来适配：

```bash
EvoProgrammer --language gdscript --framework godot --project-type single-player-game "先做出第一版可玩循环、场景切换和存档点"
```

也可以完全不填，让 EvoProgrammer 从仓库和提示词自动检测：

```bash
EvoProgrammer "构建一个支持专用服务器的多人竞技原型"
```

向所选 Agent CLI 透传额外参数：

```bash
EvoProgrammer \
  --agent-args '["--model","gpt-5"]' \
  "生成完整项目并持续修复问题"
```

`--codex-arg` 仍然保留，作为面向旧脚本的兼容别名。

从文件加载长提示词：

```bash
EvoProgrammer --prompt-file ./prompt.txt
```

只预览下一条命令而不执行 Agent：

```bash
EvoProgrammer --max-iterations 3 --dry-run "完善项目结构并补测试"
```

将运行产物写入独立目录：

```bash
EvoProgrammer --artifacts-dir /tmp/evop-runs "完善项目结构并补测试"
```

检查运行环境是否已就绪：

```bash
EvoProgrammer doctor --target-dir /path/to/project
```

运行以 `-` 开头的提示词：

```bash
EvoProgrammer -- --write a changelog
```

## 底层脚本

执行一次迭代：

```bash
./LOOP.sh "improve this repo"
```

对另一个仓库执行一次迭代：

```bash
./LOOP.sh --target-dir /path/to/repo --prompt "improve test coverage"
```

向所选 Agent CLI 透传额外参数：

```bash
./LOOP.sh --agent-args '["--model","gpt-5"]' --prompt "improve this repo"
```

运行以 `-` 开头的提示词：

```bash
./LOOP.sh -- --write a changelog
```

无限循环执行：

```bash
./MAIN.sh "improve this repo"
```

设置延迟并执行三轮：

```bash
EVOPROGRAMMER_MAX_ITERATIONS=3 \
EVOPROGRAMMER_DELAY_SECONDS=5 \
./MAIN.sh "improve this repo"
```

重复迭代时继续透传 Agent 参数：

```bash
./MAIN.sh --max-iterations 3 --agent claude --agent-args '["--model","sonnet"]' "improve this repo"
```

## 配置

默认情况下，这两个脚本都以当前工作目录作为目标目录，使用 `codex` 作为默认 Agent，并在可能时自动检测语言、框架和项目场景。你可以通过 `EVOPROGRAMMER_TARGET_DIR`、`EVOPROGRAMMER_AGENT`、`--target-dir` 或 `--agent` 覆盖它。

内置语言 profile：

- `python`
- `cpp`
- `go`
- `rust`
- `typescript`
- `javascript`
- `java`
- `csharp`
- `kotlin`
- `swift`
- `php`
- `ruby`
- `gdscript`

内置 framework profile：

- `django`
- `flask`
- `fastapi`
- `streamlit`
- `pygame`
- `qt`
- `react`
- `nextjs`
- `vue`
- `svelte`
- `express`
- `nestjs`
- `electron`
- `tauri`
- `godot`
- `unity`
- `unreal`
- `bevy`
- `rails`
- `laravel`
- `spring`
- `gin`
- `actix-web`
- `axum`

内置项目类型：

- `single-player-game`
- `paper`
- `scientific-experiment`
- `mobile-game`
- `online-game`
- `ppt`
- `office`
- `web-app`
- `backend-service`
- `cli-tool`
- `library`
- `desktop-app`
- `browser-game`
- `ai-agent`
- `data-pipeline`
- `plugin`
- `embedded-system`

`LOOP.sh` 支持：

- `EVOPROGRAMMER_PROMPT`：设置提示词。
- `EVOPROGRAMMER_PROMPT_FILE`：从文件读取提示词。
- `EVOPROGRAMMER_AGENT`：指定使用哪个内置 Agent 预设。
- `EVOPROGRAMMER_AGENT_ARGS`：以 JSON 风格字符串列表传入额外 Agent 参数。
- `EVOPROGRAMMER_LANGUAGE_PROFILE`：向提示词中注入语言适配指导。
- `EVOPROGRAMMER_FRAMEWORK_PROFILE`：向提示词中注入框架适配指导。
- `EVOPROGRAMMER_PROJECT_TYPE`：向提示词中注入项目场景适配指导。
- `EVOPROGRAMMER_TARGET_DIR`：指定 Agent 命令的工作目录。
- `EVOPROGRAMMER_ARTIFACTS_DIR`：覆盖运行产物目录。默认：`TARGET_DIR/.evoprogrammer/runs`。
- `--prompt`、`--prompt-file`、`--target-dir`：用于一次性运行，不需要先导出环境变量。
- `--language`：应用内置语言适配 profile。
- `--framework`：应用内置框架适配 profile。
- `--project-type`：应用内置项目场景适配 profile。
- `--artifacts-dir`：将运行产物写入目标仓库之外的目录。
- 如果目标目录本身是 Git 仓库且产物仍写在仓库内，EvoProgrammer 会登记本地 `.git/info/exclude` 规则，避免 `.evoprogrammer/` 进入后续迭代。
- `--agent-args`：以 JSON 风格字符串列表向所选 Agent CLI 传递额外参数。
- `--agent-arg`：如果你更习惯重复参数写法，也仍然可以使用。
- `--codex-arg`：`--agent-arg` 的兼容别名。
- `--dry-run`：打印 Agent 命令但不真正执行。

每次 `LOOP.sh` 运行都会创建一个带时间戳的目录，包含：

- `prompt.txt`
- `command.txt`
- `metadata.env`
- `<agent>.log`

`MAIN.sh` 支持：

- `EVOPROGRAMMER_PROMPT`：设置提示词。
- `EVOPROGRAMMER_PROMPT_FILE`：每次迭代前从文件重新读取提示词。
- `EVOPROGRAMMER_AGENT`：指定使用哪个内置 Agent 预设。
- `EVOPROGRAMMER_AGENT_ARGS`：以 JSON 风格字符串列表传入额外 Agent 参数。
- `EVOPROGRAMMER_LANGUAGE_PROFILE`：在每轮迭代时注入语言适配指导。
- `EVOPROGRAMMER_FRAMEWORK_PROFILE`：在每轮迭代时注入框架适配指导。
- `EVOPROGRAMMER_PROJECT_TYPE`：在每轮迭代时注入项目场景适配指导。
- `EVOPROGRAMMER_TARGET_DIR`：指定每次循环迭代的目标目录。
- `EVOPROGRAMMER_ARTIFACTS_DIR`：覆盖 session 和 iteration 产物目录。
- `EVOPROGRAMMER_MAX_ITERATIONS`：达到固定次数后停止。`0` 表示不限制。
- `EVOPROGRAMMER_DELAY_SECONDS`：设置迭代之间的等待时间。
- `EVOPROGRAMMER_CONTINUE_ON_ERROR=1`：单次迭代失败后继续循环。
- `--max-iterations`、`--delay-seconds`、`--continue-on-error`：上述配置的命令行形式。
- `--prompt-file`：在每轮迭代时都从磁盘重新加载提示词。
- `--language`：在每轮迭代时应用内置语言适配 profile。
- `--framework`：在每轮迭代时应用内置框架适配 profile。
- `--project-type`：在每轮迭代时应用内置项目场景适配 profile。
- `--artifacts-dir`：将 session 产物写入目标仓库之外的目录。
- `--agent-args`：以 JSON 风格字符串列表在每轮迭代时透传额外的 Agent 参数。
- `--agent-arg`：如果你更习惯重复参数写法，也仍然可以使用。
- `--codex-arg`：`--agent-arg` 的兼容别名。
- `--dry-run`：预览下一轮循环命令，而不真正执行。
- 如果产物仍保存在 Git 目标目录内部，EvoProgrammer 会写入本地排除规则，避免 `.evoprogrammer/` 在后续轮次中再次被读取。

每次 `MAIN.sh` 运行都会创建一个带时间戳的 session 目录，里面包含 `session.env`，以及保存每轮产物的 `iterations/` 子目录。

`DOCTOR.sh` 支持：

- `EVOPROGRAMMER_LANGUAGE_PROFILE` 和 `--language`：用于检查指定语言 profile。
- `EVOPROGRAMMER_FRAMEWORK_PROFILE` 和 `--framework`：用于检查指定框架 profile。
- `EVOPROGRAMMER_PROJECT_TYPE` 和 `--project-type`：用于检查指定项目场景 profile。
- `EVOPROGRAMMER_TARGET_DIR` 和 `--target-dir`：用于检查指定仓库目录。
- `EVOPROGRAMMER_ARTIFACTS_DIR` 和 `--artifacts-dir`：用于检查运行产物目录是否可用。

简要帮助可使用 `./LOOP.sh --help` 或 `./MAIN.sh --help`。

如果提示词本身以 `-` 开头，请在提示词前加上 `--`。

## 验证

运行轻量级 Shell 测试：

```bash
bash tests/run_tests.sh
```
