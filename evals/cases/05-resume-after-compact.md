# 用例：compact 后恢复 + worktree 校验
**测试维度**：auto-execute.md 恢复流程

## 准备
- 项目根存在 `.claude/active-plan.md`，含 `worktree: /path/A`，有未勾选步骤
- 当前会话工作目录 = `/path/A`

## 输入
（compact 后第一条消息）
```
继续
```

## 期望行为（worktree 匹配）
- [ ] 输出恢复提示："`检测到未完成计划：{任务}，创建于 {ts}，N/M 步已完成，即将从步骤 X 继续`"
- [ ] 等待伙伴确认后再执行

## 期望行为（worktree 不匹配场景）
- 当前 pwd = `/path/B` 时，先输出："`此计划属于 /path/A，当前位于 /path/B...`" 让伙伴选切换 / 在此继续 / 忽略

## 期望行为（旧版无 worktree 字段）
- 字段缺失时视作匹配通过，按正常恢复流程走（向后兼容）

## 反例（出现即 fail）
- 不读 active-plan.md 直接当新会话
- worktree 不匹配仍直接执行
- 旧版计划文件被当作错误拒绝
