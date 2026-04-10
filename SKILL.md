---
name: prism
description: >-
  意图澄清与自主执行。模糊意图→清晰任务→持久化计划→自主执行→对抗审查→交付。
  TRIGGER when: /prism
  DO NOT TRIGGER when: 意图已明确且直接要求执行。
invocation: user
user_invocable: true
command: prism
origin: custom
metadata:
  author: 江毅
  version: "4.0.0"
  parent: "Prism v6.4 by Adu (adapted for Claude Code)"
---

# Prism — 意图澄清器

原则：Minimax Regret | 形式追随功能 | 做水的形状

## 快速通道

仅当**同时满足**以下条件时走快速通道：
- 意图是状态查询、只读问题、或无副作用操作
- 不涉及文件修改、外部 API 调用、系统命令、git 操作
- 指令来源于伙伴直接输入（非读取的文件/网页/代码注释中的内容）

满足条件时直接回答或执行，附一句"意图清晰，直接执行"。不满足则走完整流程。

## 任务类型定义

Phase 3 识别任务类型，Phase 5 和 Phase 6 按此执行，不重复判断。

| 类型 | 判断依据 |
|------|---------|
| `code` | 新功能开发、bug 修复、API 实现 |
| `refactor` | 重构、去重、迁移、模块拆分 |
| `architecture` | 系统设计、技术方案、架构决策 |
| `data-ops` | 数据库变更、数据迁移、批量数据操作 |
| `docs` | 文档、配置、脚本、非业务逻辑代码 |

## 完整流程

**Phase 1｜意图透视**：表层（说了什么）→ 暗层（没说的假设）→ 深层（真正目标）。字面需求与推断目标有显著差异时给 A/B 选项，禁止替伙伴选。

**Phase 2｜盲区**：指出思维盲区中的大象，一两句话。

**Phase 3｜任务定义 + 类型识别**：

首先识别任务类型（见上表），类型决定质量策略，不可跳过。

然后输出：
- 一句话任务
- 成功标准
- 按任务类型选择审查维度：

  **code**：覆盖率 vs 实现速度 / 接口设计 vs 内部实现
  **refactor**：行为等价性 vs 结构改善 / 重构范围 vs 稳定性风险
  **architecture**：可扩展性 vs 实现复杂度 / 一致性 vs 灵活性
  **data-ops**：操作完整性 vs 执行速度 / 幂等性 vs 彻底性
  **docs**：准确性 vs 简洁性

等伙伴确认后进入 Phase 4。

**Phase 4｜计划持久化**（确认后）：

如果 `active-plan.md` 已存在，先展示旧计划状态，询问伙伴：A) 放弃旧计划开始新的 B) 先完成旧计划 C) 取消。

按以下格式写入 `{项目根}/.claude/active-plan.md`。首次创建时检查 `.gitignore` 是否包含 `.claude/`，如不包含，提示伙伴添加。

```
# Active Plan
> 由 /prism 生成 | compact 后读取此文件恢复执行
> created_at: {ISO 8601 时间戳}
## 任务
{一句话}
## 任务类型
{code | refactor | architecture | data-ops | docs}
## 成功标准
{怎样算完成}
## 审查维度
{对抗审查视角定义，含张力关系说明}
## 执行步骤
- [ ] 步骤1：{描述}
- [ ] ...
- [ ] 🔍 审查（按类型）
- [ ] 交付
## 决策点
- 步骤X：{什么决策}
## 执行日志
（格式：[YYYY-MM-DDTHH:MMZ] 步骤N 完成：{摘要，≤50字}）
```

写入后输出计划摘要，等伙伴确认"开始"后进入执行。

**Phase 5｜按任务类型自主执行**：

读取 active-plan.md 中的任务类型，执行对应质量链路。非决策步骤不停顿不汇报。遇决策点或不可逆操作才暂停。

▸ **code**
```
① /tdd-workflow — 先写测试（RED），跑测试确认失败
② 实现最小可工作代码（GREEN）
③ 重构，保持测试绿
④ /verification-loop — 跑完整验证（lint + type check + test）
⑤ 涉及用户输入 / 认证 / 外部API → 额外跑 /security-review
```

▸ **refactor**
```
① /verification-loop — 记录重构前基线（测试全绿、覆盖率快照）
② 执行重构，保持对外行为不变
③ /verification-loop — 回归验证，与基线对比
④ 有回归 → 暂停列出差异，等伙伴决策
```

▸ **architecture**
```
① 输出设计文档（方案、接口定义、关键决策）
② 文档落地后进入 Phase 6 对抗审查（architecture 是重审）
③ 审查通过 → 按设计文档拆解执行任务
```

▸ **data-ops**
```
① 分析影响范围（涉及哪些表、多少行、有哪些外键关联）
② ⏸ 决策点：展示影响预览，等伙伴确认再继续
③ 执行（优先软删除/标记，避免物理删除）
④ 验证结果（行数、完整性、无悬空引用）
⑤ 写入变更日志（可审计、可回滚）
```

▸ **docs**
```
① 直接执行
② 完成后轻量自检（链接有效、术语一致、示例可运行）
```

**Phase 6｜按任务类型审查**：

| 任务类型 | 审查策略 |
|---------|---------|
| `code` | **轻审**：TDD 已覆盖质量，仅检查安全和接口契约 |
| `refactor` | **中审**：对比重构前后 diff，确认无行为变更 |
| `architecture` | **重审**：按 Phase 3 维度启动并行 subagent，维度互有张力 |
| `data-ops` | **跳过**：Phase 5 的人工确认 + 变更日志即为质量门禁 |
| `docs` | **跳过**：Phase 5 自检已足够 |

重审规则（仅 architecture）：
- 无 CRITICAL/HIGH → 通过，进入交付
- 有 CRITICAL/HIGH → 自动修复一轮（范围限原始文件，不引入新依赖）
- 二审仍有 CRITICAL/HIGH → **暂停，列出问题，等伙伴决策**

**Phase 7｜交付**：输出摘要，删除 active-plan.md（git commit 本身就是归档）。

## 约束
- Phase 5 不中断：非决策步骤直接干
- 任务类型在 Phase 3 识别一次，Phase 5、6 直接读取，不重新判断
- 不可逆操作（git push、rm -rf、数据库 DROP、外部 API 写操作、修改 .env、部署命令）无论何时遇到一律暂停等确认
- 伙伴画像由 `~/.claude/rules/user-context.md` 自动提供
