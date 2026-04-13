# /prism

> 让 Claude Code 在动手之前先想清楚的意图澄清器。
>
> **核心理念**：先讨论清楚再动手，比干完了再返工节省十倍时间。

---

## Before / After

同一句模糊指令 `做一个用户管理后台`，对比：

**Vanilla Claude Code**
> 好的，我来帮你做。我打算用 React + Express，先建一个 users 表... *(开始建文件)*

**装了 /prism**
> Phase 1 透视到三种可能：A) 内部运维用、几十人规模 B) 多租户 SaaS、要鉴权隔离 C) 给现有 App 加个 admin 入口。三者技术选型差异很大。
> Phase 2 盲区：你提到的"管理"是只 CRUD，还是含审批/审计/权限矩阵？后者会让数据模型完全不同。
> 请选 A/B/C 并说明权限模型，再进入计划。

差别不在功能，在**做之前先确认在做什么**——避免做完才发现方向错了。

## 这是什么

`/prism` 是一个 [Claude Code](https://claude.ai/code) slash command（skill），在你给 AI 布置任务之前，强制做一次**意图透视**——确认你真正想要的是什么，而不是字面上说的是什么，然后生成一份结构化执行计划持久化到文件，支持跨 session 恢复。

**解决三个痛点：**

| 痛点 | /prism 的解法 |
|------|-------------|
| AI 误解意图，方向跑偏，做完了才发现 | Phase 1-3：意图透视 + 任务定义，执行前对齐 |
| 长任务被 compact 截断，丢失上下文 | Phase 4：计划持久化到 `active-plan.md`，自动恢复 |
| AI 自作主张执行不可逆操作 | Phase 5：决策点暂停，危险操作强制确认 |

## 快速安装

```bash
git clone https://github.com/JimMir45/claude-prism.git
cd claude-prism
bash install.sh
```

安装后在 Claude Code 中直接使用：

```
/prism 我要做一个 XXX
```

## 文件说明

```
├── SKILL.md                       # skill 主文件 → 安装到 ~/.claude/skills/prism/
├── rules/
│   ├── auto-execute.md            # 必装配套规则 → 安装到 ~/.claude/rules/
│   └── assertive-partner.md       # 可选常驻规则：让 CC 在所有对话中主动反驳
├── evals/
│   ├── README.md                  # 行为回归测试集说明
│   └── cases/                     # 5 个核心用例（改 SKILL.md 后跑一遍）
├── docs/
│   ├── manual.html                # 完整使用手册（含三个真实示例）
│   └── user-context.example.md    # 伙伴画像模板（可选）
└── install.sh                     # 一键安装脚本
```

## 工作原理

```
Phase 1  意图透视     → 表层 / 暗层 / 深层三层挖掘，有歧义给 A/B 选项
Phase 2  盲区提示     → 一两句话指出你可能没想到的问题
Phase 3  任务定义     → 一句话目标 + 成功标准 + 互有张力的审查维度（等你确认）
Phase 4  计划持久化   → 写入 .claude/active-plan.md（等你说"开始"）
Phase 5  自主执行     → 不中断，完成更新日志，遇决策点或危险操作才暂停
Phase 6  对抗审查     → 复杂任务完成后并行 subagent 多视角检查
Phase 7  交付         → 输出摘要，删除 active-plan.md
```

内置**快速通道**：只读查询和无副作用操作直接回答，不走完整流程。

## 配套规则说明

`rules/auto-execute.md` 是必装的配套规则，单独安装 skill 文件无法获得以下能力：

- **Compact 后自动恢复**：新对话开始时检测到未完成计划，提示从断点继续
- **执行中不随意中断**：完成一步直接进下一步，不停下来汇报
- **危险操作白名单**：`git push`、`rm -rf`、数据库 DROP 等，无论计划里有没有标注，一律暂停等确认

## 示例

三个典型场景的完整对话：
- **架构规划**：意图透视识别出"整理文档"背后是"验证假设"
- **功能开发**：A/B 歧义澄清，"加向量召回"到底是并联还是替换
- **数据去重**：盲区识别救场，主动提醒不可逆操作风险，先给预览再动刀

详见 [`docs/manual.html`](docs/manual.html)。

## 可选：让 CC 在所有对话中主动反驳

`/prism` 只在显式调用时生效。如果你想要 CC 在**所有**对话里都具备「看到坑就喊一声」的能力（不限于 /prism 内），把 `rules/assertive-partner.md` 装到 `~/.claude/rules/` 即可。

它定义了 staff engineer 的常驻人设、4 项评估义务、speak-up 触发原则、按场景的 5 级阈值校准、以及硬边界（只反驳技术、不干涉业务/范围/流程）。与 /prism 共享同一套判据，不冲突。

## 改了 SKILL.md 怎么验证没退化

跑 `evals/cases/` 下的 5 个用例，详见 [`evals/README.md`](evals/README.md)。每个用例是一段输入 + 期望行为，人工对照评分。任一 fail 即视为回归。

---

*基于 Prism v6.4 by Adu 适配 Claude Code。*
