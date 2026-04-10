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
  version: "3.0.0"
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

## 完整流程

**Phase 1｜意图透视**：表层（说了什么）→ 暗层（没说的假设）→ 深层（真正目标）。字面需求与推断目标有显著差异时给 A/B 选项，禁止替伙伴选。

**Phase 2｜盲区**：指出思维盲区中的大象，一两句话。

**Phase 3｜任务定义**：一句话任务 + 成功标准 + 执行路径 + 2-4 个互有张力的审查维度（由 CC 主动提出并解释张力关系）。等伙伴确认。

与 planner agent 的分工：Prism 负责"做什么"（意图澄清），planner 负责"怎么做"（工程分解）。复杂任务的执行计划可调用 planner agent 生成。

**Phase 4｜计划持久化**（确认后）：

如果 `active-plan.md` 已存在，先展示旧计划状态，询问伙伴：A) 放弃旧计划开始新的 B) 先完成旧计划 C) 取消。

按以下固定格式写入 `{项目根}/.claude/active-plan.md`。首次创建时检查 `.gitignore` 是否包含 `.claude/`，如不包含，提示伙伴添加。

```
# Active Plan
> 由 /prism 生成 | compact 后读取此文件恢复执行
> created_at: {ISO 8601 时间戳}
## 任务
{一句话}
## 成功标准
{怎样算完成}
## 审查维度
{对抗审查视角定义，含张力关系说明}
## 审查触发条件
{是否需要审查：步骤 >= 3 或涉及多文件修改时触发，否则跳过直接交付}
## 执行步骤
- [ ] 步骤1：{描述}
- [ ] ...
- [ ] 🔍 对抗审查（如需）
- [ ] 交付
## 决策点
- 步骤X：{什么决策}
## 执行日志
（格式：[YYYY-MM-DDTHH:MMZ] 步骤N 完成：{摘要，≤50字}）
```

写入后输出计划摘要，等伙伴确认"开始"后进入执行。

**Phase 5｜自主执行**：按计划逐步执行，用 TodoWrite 跟踪步骤进度。每完成一步更新 active-plan.md 执行日志。非决策步骤不停顿不汇报。遇决策点才暂停。

**Phase 6｜对抗审查**（仅在计划标记"需要审查"时触发）：

按 Phase 3 定义的审查维度启动并行 subagent 审查。维度互有张力。
- 无 CRITICAL/HIGH → 通过，进入交付
- 有 CRITICAL/HIGH → 自动修复一轮（修复范围限于计划原始涉及的文件，不引入新依赖，不创建计划外新文件）
- 二审仍有 CRITICAL/HIGH → **暂停，列出问题，等伙伴决策**，不再自动修复

**Phase 7｜交付**：输出摘要，删除 active-plan.md（git commit 本身就是归档）。

## 约束
- Phase 5 不中断：非决策步骤直接干
- 审查维度必须互有张力
- 伙伴画像由 `~/.claude/rules/user-context.md` 自动提供
