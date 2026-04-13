#!/bin/bash
# /prism 一键安装脚本
# 用法：bash install.sh

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills/prism"
RULES_DIR="$CLAUDE_DIR/rules"

echo ""
echo "▶ 安装 /prism skill..."

mkdir -p "$SKILLS_DIR"
cp "$REPO_DIR/SKILL.md" "$SKILLS_DIR/SKILL.md"
echo "  ✓ ~/.claude/skills/prism/SKILL.md"

echo ""
echo "▶ 安装配套规则..."

mkdir -p "$RULES_DIR"
cp "$REPO_DIR/rules/auto-execute.md" "$RULES_DIR/auto-execute.md"
echo "  ✓ ~/.claude/rules/auto-execute.md"

echo ""
echo "▶ 可选规则：assertive-partner.md（让 CC 在所有对话中主动反驳）"

if [ -f "$RULES_DIR/assertive-partner.md" ]; then
  echo "  ℹ 已存在 assertive-partner.md，跳过（不覆盖）"
else
  read -r -p "  是否安装？[y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    cp "$REPO_DIR/rules/assertive-partner.md" "$RULES_DIR/assertive-partner.md"
    echo "  ✓ ~/.claude/rules/assertive-partner.md"
  else
    echo "  跳过。需要时手动 cp rules/assertive-partner.md ~/.claude/rules/"
  fi
fi

echo ""
echo "▶ 检查 user-context.md..."

if [ -f "$RULES_DIR/user-context.md" ]; then
  echo "  ℹ 已存在 user-context.md，跳过（不覆盖）"
else
  echo "  ⚠ 未找到 ~/.claude/rules/user-context.md"
  echo "    可选：参考 docs/user-context.example.md 创建你自己的伙伴画像"
  echo "    让 Phase 3 的审查维度更贴合你的实际决策框架"
fi

echo ""
echo "✅ 安装完成！"
echo ""
echo "   在 Claude Code 中输入 /prism <任务描述> 即可使用"
echo "   详细说明：docs/manual.html"
echo ""
