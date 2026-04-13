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
  version: "4.2.0"
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

## 透视的四项评估标准

Phase 1/2 透视意图与盲区时，对照以下标准检视伙伴方案与你自己的方案：

1. **根因（Root cause）**：是修真问题，还是给症状贴膏药？
2. **正确性（Correctness）**：边界、并发、长期演化下还成立吗？
3. **简单性（Simplicity）**：有更简单等效的做法吗？
4. **风险（Risk）**：会不会引入 bug、安全洞、维护债？

**何时开口（speak-up 触发原则）**：
> 当「后果严重性 × 你对该问题的置信度」**大于**「事后修复的可逆成本」时，必须说出来。
> 反之（风格偏好、边际收益、平等替代方案）保持安静。

这是 Phase 1（A/B 选项触发条件）与 Phase 2（盲区判定）的统一判据，避免无差别挑刺，也避免明知是坑而沉默。

## 完整流程

**Phase 1｜意图透视**：表层（说了什么）→ 暗层（没说的假设）→ 深层（真正目标）。用四项评估标准检视伙伴方案，字面需求与推断目标有显著差异、或方案在某项标准下明显劣于替代时，给 A/B 选项，禁止替伙伴选。

**Phase 2｜盲区**：按 speak-up 触发原则筛选——只指出"严重性×置信度"高过"可逆成本"的大象，**最多 2 条**。每条一两句话，配一个具体替代。

示例（"给登录接口加限流，每分钟 10 次"）：
- ✅ 限流维度（按 IP / 按用户 / 按设备）选错会让防护形同虚设——建议先确认攻击模型再定维度
- ❌ "建议给函数加注释"（风格类，应过滤掉）

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
> worktree: {当前项目绝对路径，用于多 worktree 并发校验}
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

> **向后兼容**：旧版（无 `worktree` 字段）的 active-plan.md 仍可读，恢复时若缺字段视作匹配通过。

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

**不可逆操作的 flag-don't-block 协议**：

遇到不可逆操作时，按以下格式一次说清，不阻塞、不长篇大论：

```
⏸ 即将执行：{操作 + 具体后果，一句话}
建议：{替代或更安全做法}
继续 / 改用建议 / 取消？
```

伙伴回"继续"后执行，且**不再就同一操作重复 flag**。仅当后果是「数据丢失 / 安全泄露 / 生产事故」级别时，才允许追加一次确认（含明确不可逆后果描述），之后无论回应一律服从。

**Phase 6｜按质量 Skill 组合推导审查力度**：

从选中的 skill 组合判断：
- 选了 `tdd-workflow` → 代码质量已有测试保障，Phase 6 **轻审**（仅检查接口契约和安全边界）
- 未选 `tdd-workflow`（纯设计/架构任务）→ Phase 6 **重审**（按 Phase 3 审查维度启动并行 subagent）
- 选了 `database-migrations` → Phase 6 **跳过**（Phase 5 的人工确认 + 变更日志已是质量门禁）

重审规则（无 tdd-workflow 时）：
- 无 CRITICAL/HIGH → 通过，进入交付
- 有 CRITICAL/HIGH → 自动修复一轮，**修复必须满足以下边界**：
  - diff ≤ 50 行
  - 不新增文件、不新增依赖
  - 不修改测试
  - 仅限审查指出的原始文件
  超出任一边界 → 立即暂停，列出问题与建议方案，等伙伴决策
- 二审仍有 CRITICAL/HIGH → **暂停，列出问题，等伙伴决策**

**Phase 7｜交付**：输出摘要，删除 active-plan.md（git commit 本身就是归档）。

## 约束
- Phase 5 不中断：非决策步骤直接干
- 质量 Skill 组合在 Phase 3 选定一次，Phase 5、6 直接读取，不重新判断
- 不可逆操作（git push、rm -rf、数据库 DROP、外部 API 写操作、修改 .env、部署命令）无论何时遇到一律按 flag-don't-block 协议暂停
- 伙伴画像由 `~/.claude/rules/user-context.md` 自动提供
- 想常态化"主动反驳"能力（不仅在 /prism 内），可选装 `rules/assertive-partner.md`
