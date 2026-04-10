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
  version: "4.1.0"
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

## 可调度的质量 Skills

Phase 3 按任务特征判断需要激活哪些 skill，Phase 5 执行，Phase 6 从中推导审查力度。

| Skill | 激活条件 |
|-------|---------|
| `tdd-workflow` | 写新功能、修 bug、重构、加 API、新建组件 |
| `verification-loop` | 任何代码变更完成后、PR 前、重构后 |
| `security-review` | 涉及认证/授权、用户输入、外部 API、密钥、支付、敏感数据 |
| `database-migrations` | 建表/改表、加减字段或索引、数据迁移/回填 |
| `e2e-testing` | 涉及关键用户流程、需要验收级别测试 |

## 完整流程

**Phase 1｜意图透视**：表层（说了什么）→ 暗层（没说的假设）→ 深层（真正目标）。字面需求与推断目标有显著差异时给 A/B 选项，禁止替伙伴选。

**Phase 2｜盲区**：指出思维盲区中的大象，一两句话。

**Phase 3｜任务定义 + 质量 Skill 选择**：

根据任务特征，对照上方「可调度的质量 Skills」表，勾选本次需要激活的 skill 组合（可多选）。选择逻辑：只要任务涉及某个 skill 的激活条件，就选中它，不强行归类。

然后输出：
- 一句话任务
- 成功标准
- **质量 Skill 组合**：列出选中的 skill 及理由
- **审查维度**（2-4 个，互有张力）：根据选中的 skill 组合推导，而非预设模板

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
## 质量 Skill 组合
{选中的 skill 列表，如：tdd-workflow, verification-loop, security-review}
## 成功标准
{怎样算完成}
## 审查维度
{对抗审查视角定义，含张力关系说明}
## 执行步骤
- [ ] 步骤1：{描述}
- [ ] ...
- [ ] 🔍 审查
- [ ] 交付
## 决策点
- 步骤X：{什么决策}
## 执行日志
（格式：[YYYY-MM-DDTHH:MMZ] 步骤N 完成：{摘要，≤50字}）
```

写入后输出计划摘要，等伙伴确认"开始"后进入执行。

**Phase 5｜按质量 Skill 组合自主执行**：

读取 active-plan.md 中的「质量 Skill 组合」，按以下顺序依次执行各 skill。非决策步骤不停顿不汇报。遇决策点或不可逆操作才暂停。

**执行顺序规则：**

```
database-migrations（如有）→ tdd-workflow → 实现 → verification-loop → security-review（如有）→ e2e-testing（如有）
```

各 skill 的执行要点：

▸ **tdd-workflow**（如选中）
先写测试（RED）→ 跑测试确认失败 → 实现最小可工作代码（GREEN）→ 重构保持测试绿

▸ **verification-loop**（每次代码变更后必跑）
build → lint → type check → test，任一失败立即停下修复，不继续后续步骤

▸ **security-review**（如选中）
按 security-review skill 的检查清单逐项核对，发现 CRITICAL 问题暂停等伙伴决策

▸ **database-migrations**（如选中）
⏸ 先展示影响预览（涉及哪些表、行数、外键），等伙伴确认 → 执行 → 验证完整性 → 写变更日志

▸ **e2e-testing**（如选中）
在实现完成、verification-loop 通过后，补充关键用户流程的 E2E 测试

**Phase 6｜按质量 Skill 组合推导审查力度**：

从选中的 skill 组合判断：
- 选了 `tdd-workflow` → 代码质量已有测试保障，Phase 6 **轻审**（仅检查接口契约和安全边界）
- 未选 `tdd-workflow`（纯设计/架构任务）→ Phase 6 **重审**（按 Phase 3 审查维度启动并行 subagent）
- 选了 `database-migrations` → Phase 6 **跳过**（Phase 5 的人工确认 + 变更日志已是质量门禁）

重审规则（无 tdd-workflow 时）：
- 无 CRITICAL/HIGH → 通过，进入交付
- 有 CRITICAL/HIGH → 自动修复一轮（范围限原始文件，不引入新依赖）
- 二审仍有 CRITICAL/HIGH → **暂停，列出问题，等伙伴决策**

**Phase 7｜交付**：输出摘要，删除 active-plan.md（git commit 本身就是归档）。

## 约束
- Phase 5 不中断：非决策步骤直接干
- 质量 Skill 组合在 Phase 3 选定一次，Phase 5、6 直接读取，不重新判断
- 不可逆操作（git push、rm -rf、数据库 DROP、外部 API 写操作、修改 .env、部署命令）无论何时遇到一律暂停等确认
- 伙伴画像由 `~/.claude/rules/user-context.md` 自动提供
