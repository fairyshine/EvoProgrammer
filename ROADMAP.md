# EvoProgrammer Zsh Refactor Roadmap

本文档将仓库的后续重构明确收敛到一个前提上：

- 统一采用 `zsh` 作为实现和运行基线
- 不再把 `bash` 兼容性作为一等目标
- 保留少量 `#!/bin/sh` 启动 shim，仅用于把入口重新切换到 `zsh`

当前日期：`2026-03-17`

## 0. 当前执行状态

截至 `2026-03-17`，本 roadmap 所覆盖的重构已经完成落地，当前仓库状态如下：

1. Phase 0 已完成
   - 运行时基线统一为 `zsh`
   - bootstrap 不再保留 `bash` 回退路径
   - README、README_CN、architecture、doctor 的表述已统一
2. Phase 1 已完成
   - `tests/run_tests.sh` 只承载功能测试
   - `tests/run_lint.sh` 成为独立 lint 入口
   - `tests/run_extended_tests.sh` 统一编排 lint、`zsh -n` 和功能测试
3. Phase 2 至 Phase 4 已完成
   - 核心动态状态访问已收敛
   - 命令槽位已集中到统一注册表
   - `render`、`facts`、`verify`、`status`、profiles 相关热点文件已完成拆分
4. Phase 5 已完成
   - shell/CLI 仓库识别、命令建议、结构提示和风险提示已增强

已完成验证：

- `zsh tests/run_tests.sh`
- `zsh tests/run_lint.sh`
- `zsh tests/run_extended_tests.sh`
- `./DOCTOR.sh --target-dir .`
- `./VERIFY.sh --target-dir . --list`

落地时有一处结构性调整与原计划略有不同：

- `lib/project-context/facts.sh` 没有继续拆出单独的 `facts-makefile.sh`
- 原因是 makefile 相关判断量不足以支撑独立模块，最终并入了 `lib/project-context/facts-files.sh`，以避免制造新的碎片化文件

## 1. 目标

本轮重构的核心目标不是增加新功能，而是让仓库在以下 4 个维度上稳定下来：

1. 运行时基线一致
   所有核心库、测试脚本、文档、检查脚本都围绕 `zsh` 展开，不再出现“代码偏 zsh、文档偏 bash、CI 还在假设 shellcheck/bash”的混合状态。
2. 测试与静态检查基线可信
   `run_tests`、`run_extended_tests`、CI 和 README 中的开发说明要表达同一套事实。
3. 模块边界更清晰
   减少大文件、减少隐式全局状态耦合、减少动态变量分发。
4. 为后续继续扩展 profiles、inspect 输出和 verify 链路留出空间

## 2. 非目标

以下事项不在本轮重构的主范围内：

- 不迁移到 Python、Go 或 Rust
- 不重写现有 profile 体系
- 不改变 CLI 对外语义，除非是为了修复当前 shell 基线冲突
- 不在本轮中大量新增语言或框架支持

## 3. 当前状态摘要

截至当前工作区，仓库状态有几个明显问题：

1. shell 基线分裂
   仓库中的大多数脚本已经切到 `#!/usr/bin/env zsh`，但入口 shim 仍保留 `#!/bin/sh`，README 也刚开始向 `zsh` 收敛，整体契约还没有完全落地。
2. 测试链路不一致
   `tests/run_extended_tests.sh` 仍然依赖 `shellcheck`，但 `shellcheck` 不支持 `#!/usr/bin/env zsh` 文件，导致扩展测试语义和当前脚本基线冲突。
3. 少数核心文件过大
   当前较大的热点文件包括：
   - `lib/project-context/facts.sh`
   - `lib/profiles/detect-helpers.sh`
   - `lib/project-context/render.sh`
   - `lib/profiles/candidates.sh`
   - `lib/verify.sh`
   - `lib/status.sh`
4. 全局状态和动态变量访问较多
   `eval`、`printf -v`、动态变量名、动态 `source` 被广泛使用，虽然在 shell 中可行，但会提高重构成本和回归风险。

## 4. 重构原则

整个重构过程遵循以下原则：

1. 先统一基线，再拆模块
   先把 shell 运行时、测试链路和文档契约统一，否则后续拆分只会把不稳定状态扩散到更多文件。
2. 先收敛接口，再内部重构
   对外 CLI 语义优先保持稳定，内部实现再逐步替换。
3. 每一阶段都必须可验证
   每个阶段都要有明确的脚本级验收条件，而不是只改结构不验证。
4. 优先减少隐式耦合
   如果一个重构能同时降低全局状态和重复 case 分支，优先做。

## 5. 分阶段计划

### Phase 0: 固化 zsh 基线

目标：

- 明确 `zsh` 是唯一受支持的开发与运行 shell
- 清理文档、测试和脚本中仍然假设 `bash` 或“bash/zsh 双基线”的部分

涉及文件：

- `README.md`
- `README_CN.md`
- `docs/architecture.md`
- `install.sh`
- `bin/EvoProgrammer`
- `lib/bootstrap.sh`
- `DOCTOR.sh`
- `tests/run_tests.sh`
- `tests/run_extended_tests.sh`

具体动作：

1. 统一文档表述
   - README 中所有 requirements、示例、开发说明都改为 `zsh` 基线
   - architecture 文档补一节，明确：
     - `#!/bin/sh` 入口只是 bootstrap shim
     - 实际运行环境是 `zsh`
2. 明确 bootstrap 行为
   - `lib/bootstrap.sh` 中只保留：
     - `sh -> zsh` 的 re-exec
     - `zsh` 缺失时报错退出
   - 删除“优先 zsh，退回 bash”的双路径逻辑
3. 调整 doctor
   - `DOCTOR.sh` 输出中增加对 `zsh` 可执行文件的明确检查
   - doctor 输出要能直接告诉用户：当前环境是否满足唯一基线
4. 统一测试入口执行方式
   - `tests/run_tests.sh`
   - `tests/run_extended_tests.sh`
   统一用 `zsh` 运行，不再用 `bash` 包一层

验收标准：

- README、architecture、doctor 对 shell 基线说法完全一致
- 所有核心脚本在缺失 `zsh` 时给出一致且明确的错误
- 本地测试入口不再显式依赖 `bash`

### Phase 1: 修复扩展测试和静态检查模型

目标：

- 让 `run_tests` 和 `run_extended_tests` 的语义清晰且可信
- 解决当前 `shellcheck` 与 zsh shebang 冲突的问题

涉及文件：

- `tests/run_tests.sh`
- `tests/run_extended_tests.sh`
- `tests/lib/test_runner.sh`
- `tests/cases/15_test_runner.sh`
- 可能新增：
  - `tests/run_lint.sh`
  - `.shellcheckrc`
  - `.github/workflows/*` 中对应测试步骤

具体动作：

1. 拆分“功能测试”和“静态检查”
   - `run_tests.sh` 只负责功能测试
   - `run_extended_tests.sh` 负责：
     - 功能测试增强版
     - 可选的静态检查
   - 如果保留 `shellcheck`，则必须只检查仍然适合 shellcheck 的文件
2. 重新定义静态检查策略
   方案优先级如下：
   - 优先方案：把 `shellcheck` 限制在 `#!/bin/sh` 入口 shim 和少量 POSIX 兼容脚本
   - 次优方案：扩展测试中不再默认跑 `shellcheck`，改成单独 lint 脚本
   - 不建议：继续对所有 `zsh` 文件执行 `shellcheck`
3. 修正测试用例预期
   - `tests/cases/15_test_runner.sh` 当前把 `run_extended_tests.sh 05_smoke` 当成稳定成功路径，但它隐含触发 shellcheck
   - 这里需要把“过滤转发正确”和“静态检查通过”拆成两条独立断言
4. 为 zsh 增加更适合的检查方式
   可选组合：
   - `zsh -n` 语法检查
   - `setopt NO_UNSET` 等行为测试通过集成测试覆盖
   - 关键模块继续靠现有黑盒测试保障

验收标准：

- `run_tests.sh` 稳定通过
- `run_extended_tests.sh` 的失败不再由错误的 shellcheck 目标触发
- 测试用例能准确区分“脚本功能失败”和“静态检查失败”

### Phase 2: 收敛运行时状态模型

目标：

- 减少当前实现对全局变量和动态变量名的依赖
- 让上下文流转更显式

涉及文件：

- `lib/cli.sh`
- `lib/metadata.sh`
- `lib/project-context/state.sh`
- `lib/project-context/snapshot.sh`
- `lib/profiles/resolve.sh`
- `lib/verify.sh`
- `lib/status.sh`

具体动作：

1. 定义一套统一的上下文字段前缀
   建议分为三类：
   - CLI 解析上下文：`EVOP_CTX_*`
   - 仓库分析上下文：`EVOP_REPO_*`
   - 运行结果上下文：`EVOP_RUN_*`
2. 限制动态变量访问范围
   - 保留必要的“命令槽位”动态映射
   - 其余地方逐步改成显式函数返回或显式 case 表
3. 缩小 `eval` 使用面
   优先替换以下位置：
   - `lib/project-context/state.sh`
   - `lib/project-context/facts.sh`
   - `lib/project-context/snapshot.sh`
   - `lib/profiles/definitions.sh`
   - `lib/profiles/diagnostics.sh`
   - `lib/verify.sh`
4. 明确“分析结果对象”的边界
   即使继续使用环境变量，也要让下面几层的输入输出变得稳定：
   - `evop_finalize_analysis_context`
   - `evop_resolve_profiles`
   - `evop_analyze_project_context`
   - `evop_apply_project_context_snapshot`

验收标准：

- 全局变量仍可存在，但核心流程中的隐式写入点明显减少
- `eval` 数量下降，并集中在极少数有明确理由的桥接函数里
- `inspect`、`verify`、`main/loop` 共享上下文时不需要依赖过多调用顺序假设

### Phase 3: 拆分热点文件

目标：

- 降低单文件复杂度
- 提高可读性、可替换性和局部测试能力

涉及文件和建议拆分：

1. `lib/project-context/render.sh`
   拆成：
   - `lib/project-context/render-summary.sh`
   - `lib/project-context/render-json.sh`
   - `lib/project-context/render-env.sh`
   - `lib/project-context/render-prompt.sh`
   - `lib/project-context/render-diagnostics.sh`
2. `lib/project-context/facts.sh`
   拆成：
   - `lib/project-context/facts-cache.sh`
   - `lib/project-context/facts-files.sh`
   - `lib/project-context/facts-makefile.sh`
   - `lib/project-context/facts-diagnostics.sh`
3. `lib/profiles/candidates.sh`
   拆成：
   - `lib/profiles/candidates-common.sh`
   - `lib/profiles/candidates-languages.sh`
   - `lib/profiles/candidates-frameworks.sh`
   - `lib/profiles/candidates-project-types.sh`
4. `lib/profiles/detect-helpers.sh`
   拆成：
   - `lib/profiles/facts-cache.sh`
   - `lib/profiles/facts-files.sh`
   - `lib/profiles/facts-text.sh`
5. `lib/verify.sh`
   拆成：
   - `lib/verify-state.sh`
   - `lib/verify-render.sh`
   - `lib/verify-plan.sh`
6. `lib/status.sh`
   拆成：
   - `lib/status-collect.sh`
   - `lib/status-render.sh`

具体动作：

1. 先抽无副作用 renderer
   `render.sh` 最适合优先拆，因为输出格式边界天然清楚。
2. 再抽缓存和事实查询
   `facts.sh` 与 `detect-helpers.sh` 的重复风格最明显，应在 Phase 3 中重点处理。
3. 最后拆 `verify/status`
   它们依赖外层上下文较多，适合在前面的状态收敛完成后再拆。

验收标准：

- 不再存在 500 行级别的核心文件
- 每个拆分后的文件只负责一种明显职责
- 拆分后接口名称和行为保持稳定

### Phase 4: 统一 schema 与重复逻辑

目标：

- 降低“加一个字段要改 5 处”的维护成本
- 让 `inspect`、`verify`、`status` 的输出格式更容易演进

涉及文件：

- `lib/project-context/state.sh`
- `lib/project-context/render*.sh`
- `lib/verify*.sh`
- `lib/status*.sh`
- `lib/metadata.sh`

具体动作：

1. 为命令槽位建立统一注册表
   当前槽位是：
   - `dev`
   - `build`
   - `test`
   - `lint`
   - `typecheck`

   应该把以下信息定义在一个地方：
   - 槽位顺序
   - 人类可读 label
   - env key
   - json key
   - 是否属于 verify 链
2. 为 verify/status report 建立统一字段表
   现在 `status`、`verify`、`metadata` 都在手写字段输出，建议改成一套注册驱动的渲染模式。
3. 把 env 与 json 输出共用同一份数据源
   避免“summary 改了、json 漏了、env 又忘了”的问题。

验收标准：

- 新增一个命令槽位或 report 字段时，只需要改动 1 到 2 个集中定义点
- `summary/json/env` 三种输出格式之间不再出现字段偏差

### Phase 5: 强化 shell/CLI 自身仓库检测

目标：

- 提升 EvoProgrammer 对自身及同类 shell 仓库的分析质量

涉及文件：

- `lib/project-context/repo-analysis.sh`
- `lib/project-context/commands.sh`
- `lib/profiles/candidates.sh`
- `lib/profiles/definitions/languages/shell/profile.sh`
- `lib/profiles/definitions/project-types/cli-tool/profile.sh`

具体动作：

1. 增补 shell 仓库结构提示
   对以下路径给出更有用的 structure hints：
   - `bin/`
   - 根目录 `*.sh`
   - `lib/`
   - `tests/`
   - `docs/`
2. 增补 shell 仓库验证命令检测
   识别：
   - `tests/run_tests.sh`
   - `tests/run_extended_tests.sh`
   - `make test`
   - `make lint`
   - 自定义 `zsh -n` 检查脚本
3. 增补 shell 仓库风险提示
   对以下风险给出更明确输出：
   - shebang 与运行时不一致
   - sourced library 改动影响多个入口
   - artifacts/metadata 目录与 git ignore/exclude 协调问题

验收标准：

- `EvoProgrammer inspect --target-dir .` 对本仓库能给出更完整的结构和验证建议
- 同类 shell CLI 仓库的自动识别准确度提升

## 6. 推荐执行顺序

建议按下面顺序实施，而不是并行打散：

1. Phase 0
2. Phase 1
3. Phase 2
4. Phase 3
5. Phase 4
6. Phase 5

原因：

- Phase 0 和 Phase 1 解决的是“基线是否可信”
- Phase 2 解决的是“重构会不会把隐式状态搞坏”
- Phase 3 和 Phase 4 才是“内部结构优化”
- Phase 5 属于在稳定基础上的识别增强

## 7. 每阶段的提交策略

建议每个阶段至少拆成独立提交，避免把“基线修复”和“模块重构”混在一起。

推荐提交粒度：

1. `docs: declare zsh as the only supported runtime`
2. `test: split functional tests from shell linting`
3. `runtime: simplify bootstrap and doctor for zsh-only execution`
4. `refactor: reduce dynamic state in analysis and verify flows`
5. `refactor: split project-context renderers`
6. `refactor: split profile candidate and facts helpers`
7. `feat: improve shell cli detection and verification hints`

## 8. 验收清单

全部重构完成后，应满足以下结果：

1. 运行时基线
   - 文档只声明 `zsh`
   - `doctor` 只检查 `zsh` 基线
   - bootstrap 不再维护 bash 回退路径
2. 测试链路
   - `run_tests.sh` 稳定通过
   - `run_extended_tests.sh` 行为稳定且语义清晰
   - CI 不再错误地对 zsh 脚本跑 shellcheck
3. 代码结构
   - 核心热点文件被拆分
   - `eval` 使用面缩小
   - 动态状态映射集中管理
4. 仓库分析质量
   - inspect/verify/status/metadata 共享 schema
   - 本仓库自身的 shell CLI 识别结果更完整

## 9. 风险与回滚策略

主要风险：

1. 拆分热点文件时引入隐式状态回归
2. bootstrap 改动导致入口脚本在某些环境下无法 re-exec 到 zsh
3. verify/status/report 输出字段变化影响现有脚本消费者

回滚策略：

1. Phase 0 和 Phase 1 独立提交，出现问题可直接回退，不影响内部重构
2. Phase 3 拆分文件时保持导出函数名不变，必要时通过兼容 shim 过渡
3. 对 `inspect --format env`、`verify --report-format env` 的字段变更必须先保持兼容，再逐步清理

## 10. 建议的下一步

如果从当前工作区继续推进，建议先做两个最小闭环：

1. 完成 Phase 0
   把 README、doctor、bootstrap、测试入口全部统一到 zsh
2. 完成 Phase 1
   把 `run_extended_tests` 和 shellcheck 冲突拆开，让测试基线重新可信

在这两个闭环完成前，不建议继续做大规模模块拆分。
