#!/bin/bash
# ==============================================
# 🇯🇵 Japan Trip Itinerary — GitHub Pages Deploy
# ==============================================
# 把这个脚本和 japan_v8_nandaimon.html 放在同一个文件夹
# 然后运行: bash deploy_to_github.sh
# ==============================================

set -e

REPO_NAME="japan-trip-2025"
HTML_FILE="japan_v8_nandaimon.html"

echo "🇯🇵 Japan Trip — GitHub Pages 部署脚本"
echo "========================================"

# 1. 检查 gh CLI
if ! command -v gh &> /dev/null; then
  echo "❌ 需要先安装 GitHub CLI (gh)"
  echo ""
  echo "Mac:     brew install gh"
  echo "Windows: winget install GitHub.cli"
  echo "Linux:   https://cli.github.com"
  exit 1
fi

# 2. 检查 HTML 文件
if [ ! -f "$HTML_FILE" ]; then
  echo "❌ 找不到 $HTML_FILE，请确认文件在同一目录"
  exit 1
fi

echo "✅ 检查完成，开始部署..."
echo ""

# 3. 登录 GitHub（如果未登录）
if ! gh auth status &> /dev/null; then
  echo "🔑 请登录 GitHub..."
  gh auth login
fi

GH_USER=$(gh api user --jq '.login')
echo "👤 GitHub 用户：$GH_USER"

# 4. 创建临时部署目录
DEPLOY_DIR=$(mktemp -d)
cp "$HTML_FILE" "$DEPLOY_DIR/index.html"

# 5. 创建 GitHub Repo（如果不存在则新建）
echo "📁 创建 GitHub repository: $REPO_NAME"
if gh repo view "$GH_USER/$REPO_NAME" &> /dev/null; then
  echo "   Repository 已存在，继续更新..."
else
  gh repo create "$REPO_NAME" --public --description "🇯🇵 Japan Family Trip 2025 - Osaka Kyoto Nagoya"
  echo "   ✅ Repository 创建成功！"
fi

# 6. 初始化 git 并推送
cd "$DEPLOY_DIR"
git init -q
git checkout -b main
git add index.html
git config user.email "deploy@japan-trip.local"
git config user.name "Japan Trip Deploy"
git commit -q -m "🇯🇵 Japan trip itinerary - $(date '+%Y-%m-%d %H:%M')"

REPO_URL="https://github.com/$GH_USER/$REPO_NAME.git"
git remote add origin "$REPO_URL"
git push -f origin main
echo "✅ 代码推送成功！"

# 7. 开启 GitHub Pages
echo "🌐 开启 GitHub Pages..."
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/$GH_USER/$REPO_NAME/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/" \
  2>/dev/null || \
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$GH_USER/$REPO_NAME/pages" \
  -f "source[branch]=main" \
  -f "source[path]=/" \
  2>/dev/null || true

# 8. 完成
echo ""
echo "========================================"
echo "🎉 部署完成！"
echo ""
echo "🌐 你的行程网址（约1分钟后生效）："
echo "   👉 https://$GH_USER.github.io/$REPO_NAME"
echo ""
echo "📌 GitHub 仓库："
echo "   👉 https://github.com/$GH_USER/$REPO_NAME"
echo "========================================"

# 清理临时目录
cd - > /dev/null
rm -rf "$DEPLOY_DIR"
