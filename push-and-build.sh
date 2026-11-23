#!/bin/bash
# 推送到 GitHub 并用 macOS runner 出 ipa
set -e
cd "$(dirname "$0")"

TOKEN="$GH_TOKEN"
if [ -z "$TOKEN" ]; then
  for f in "./gh-token.txt" "../gh-token.txt" "/c/Users/hp/Downloads/gh-token.txt"; do
    if [ -f "$f" ]; then TOKEN=$(tr -d ' \r\n' < "$f"); echo "从 $f 读取 token"; break; fi
  done
fi
[ -z "$TOKEN" ] && { echo "没有 token：把 token 写进 gh-token.txt"; exit 1; }
case "$TOKEN" in
  ghp_*|github_pat_*) ;;
  *) echo "gh-token.txt 里不是有效 token（应以 ghp_ 或 github_pat_ 开头），当前内容前 4 位：$(printf %s "$TOKEN" | cut -c1-4)"; exit 1 ;;
esac


REPO="oz-ios"
[ -n "$1" ] && REPO="$1"
API="https://api.github.com"

OWNER=$(curl -sS -H "Authorization: token $TOKEN" "$API/user" | sed -n 's/.*"login": "\([^"]*\)".*/\1/p' | head -1)
[ -z "$OWNER" ] && { echo "token 无效"; exit 1; }
echo "账号：$OWNER　仓库：$REPO"

BODY="{\"name\":\"$REPO\",\"private\":true}"
curl -sS -H "Authorization: token $TOKEN" "$API/user/repos" -d "$BODY" >/dev/null 2>&1 || true

[ -d .git ] || git init -q
git add -A
git -c user.email=oz@local -c user.name=oz commit -qm "oz ios build" || true
git remote remove origin 2>/dev/null || true
git remote add origin "https://x-access-token:$TOKEN@github.com/$OWNER/$REPO.git"
git push -f -u origin HEAD:main

sleep 2
curl -sS -X POST -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github+json" \
  "$API/repos/$OWNER/$REPO/actions/workflows/ios.yml/dispatches" -d "{\"ref\":\"main\"}" >/dev/null
echo
echo "已触发：https://github.com/$OWNER/$REPO/actions"
echo "跑完在 Artifacts 下载 oz-unsigned-ipa"
