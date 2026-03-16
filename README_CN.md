# EvoProgrammer

[English README](./README.md)

EvoProgrammer 是一个围绕 `codex` 命令封装的小型 Bash CLI。它可以进入任意项目目录，对该目录执行自然语言指令，并持续迭代直到你手动停止。

## 功能概览

- `EvoProgrammer "你的指令"`：在当前目录运行 Codex，并持续迭代。
- `EvoProgrammer once "你的指令"`：只运行一次 Codex。
- `EvoProgrammer doctor`：在长时间自治运行前检查本地环境是否可用。
- `--target-dir`：将 CLI 指向其他目录。
- `--prompt-file`：从文件读取长提示词，而不是直接写在命令行里。
- `--dry-run`：只查看实际执行的命令和目标目录，不真正运行 Codex。
- `--max-iterations`、`--delay-seconds`、`--continue-on-error`：控制长时间循环任务。

内部结构：

- `bin/EvoProgrammer`：面向用户的 CLI 入口。
- `LOOP.sh`：执行一次 Codex 迭代。
- `MAIN.sh`：持续重复执行迭代。
- `install.sh`：将 `EvoProgrammer` 命令安装到本地 `bin` 目录。

## 环境要求

- Bash
- `PATH` 中可用的 `codex` CLI

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

指定其他目录作为目标：

```bash
EvoProgrammer --target-dir /path/to/project "完善 README、测试和 CI"
```

向 `codex exec` 透传额外参数：

```bash
EvoProgrammer \
  --codex-arg "--model" \
  --codex-arg "gpt-5" \
  --codex-arg "--profile" \
  --codex-arg "danger-full-access" \
  "生成完整项目并持续修复问题"
```

从文件加载长提示词：

```bash
EvoProgrammer --prompt-file ./prompt.txt
```

只预览下一条命令而不执行：

```bash
EvoProgrammer --max-iterations 3 --dry-run "完善项目结构并补测试"
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

向 `codex exec` 透传额外参数：

```bash
./LOOP.sh --codex-arg "--model" --codex-arg "gpt-5" --prompt "improve this repo"
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

重复迭代时继续透传 `codex exec` 参数：

```bash
./MAIN.sh --max-iterations 3 --codex-arg "--profile" --codex-arg "danger-full-access" "improve this repo"
```

## 配置

默认情况下，这两个脚本都以当前工作目录作为目标目录。你可以通过 `EVOPROGRAMMER_TARGET_DIR` 或 `--target-dir` 覆盖它。

`LOOP.sh` 支持：

- `EVOPROGRAMMER_PROMPT`：设置提示词。
- `EVOPROGRAMMER_PROMPT_FILE`：从文件读取提示词。
- `EVOPROGRAMMER_TARGET_DIR`：指定 `codex exec` 的工作目录。
- `--prompt`、`--prompt-file`、`--target-dir`：用于一次性运行，不需要先导出环境变量。
- `--codex-arg`：可重复使用，用于直接向 `codex exec` 传递额外参数。
- `--dry-run`：打印 `codex exec` 命令但不真正执行。

`MAIN.sh` 支持：

- `EVOPROGRAMMER_PROMPT`：设置提示词。
- `EVOPROGRAMMER_PROMPT_FILE`：每次迭代前从文件重新读取提示词。
- `EVOPROGRAMMER_TARGET_DIR`：指定每次循环迭代的目标目录。
- `EVOPROGRAMMER_MAX_ITERATIONS`：达到固定次数后停止。`0` 表示不限制。
- `EVOPROGRAMMER_DELAY_SECONDS`：设置迭代之间的等待时间。
- `EVOPROGRAMMER_CONTINUE_ON_ERROR=1`：单次迭代失败后继续循环。
- `--max-iterations`、`--delay-seconds`、`--continue-on-error`：上述配置的命令行形式。
- `--prompt-file`：在每轮迭代时都从磁盘重新加载提示词。
- `--codex-arg`：可重复使用，在每轮迭代时透传额外的 `codex exec` 参数。
- `--dry-run`：预览下一轮循环命令，而不真正执行。

`DOCTOR.sh` 支持：

- `EVOPROGRAMMER_TARGET_DIR` 和 `--target-dir`：用于检查指定仓库目录。

简要帮助可使用 `./LOOP.sh --help` 或 `./MAIN.sh --help`。

如果提示词本身以 `-` 开头，请在提示词前加上 `--`。

## 验证

运行轻量级 Shell 测试：

```bash
bash tests/run_tests.sh
```
