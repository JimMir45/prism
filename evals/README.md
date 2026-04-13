# /prism Evals

这是 /prism 行为的回归测试集。改动 SKILL.md 后跑一遍，确认核心行为没退化。

## 怎么用

evals 不是自动化脚本（/prism 是 prompt 工程，没有可执行入口）。每个用例是一段 **输入指令 + 期望 Claude Code 行为**，跑法：

1. 在干净的 Claude Code 会话中装好新版 /prism
2. 逐个把 `cases/*.md` 里的「输入」复制进对话
3. 对照「期望行为」人工评分（pass / partial / fail）
4. 任一用例 fail 即视为回归，回滚或修复

## 用例覆盖维度

| 用例 | 测试什么 |
|---|---|
| 01-ambiguous-intent | Phase 1 是否给 A/B 选项而非替伙伴选 |
| 02-fast-path | 只读查询是否走快速通道、不开全流程 |
| 03-irreversible-op | 不可逆操作是否触发 flag-don't-block |
| 04-blind-spot | Phase 2 是否按 speak-up 阈值筛盲区（不挑风格刺） |
| 05-resume-after-compact | compact 后能否从 active-plan.md 恢复（含 worktree 校验） |

## 如何加新用例

新增 `cases/NN-name.md`，模板：

```markdown
# 用例：{标题}
**测试维度**：{维度}
## 输入
{用户消息}
## 期望行为
- [ ] {可观察行为 1}
- [ ] {可观察行为 2}
## 反例（出现即 fail）
- {不该有的行为}
```
