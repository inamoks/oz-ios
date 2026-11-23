# 怎么给 GitHub token

## 一、造一个（1 分钟）

1. 打开 https://github.com/settings/tokens
2. Tokens (classic) -> Generate new token (classic) -> 输密码
3. Note 填 oz-build，Expiration 选 7 days
4. 勾两个 scope：
   - repo（建私有仓库、推代码）
   - workflow（触发 Actions）
5. Generate token，复制 ghp_ 开头那串（只显示一次）

> fine-grained token 也可以：Repository access 选 All repositories，Permissions 里 Contents / Workflows / Administration 给 Read and write。

## 二、怎么给我

### 方式 A：写文件（推荐，不进聊天记录）

在 Downloads 目录新建 gh-token.txt，里面只放一行 token：

    ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxx

完整路径：C:/Users/hp/Downloads/gh-token.txt

放好回我一句「放好了」，我读文件跑构建，全程不打印 token。

### 方式 B：直接贴在对话里

能用，但聊天记录会留着，用完记得去 GitHub 删掉。

## 三、我拿到后做什么

    bash ios-app/push-and-build.sh oz-ios

1. 查 token 归属账号
2. 建私有仓库 oz-ios（不公开）
3. 推 ios-app 全部源码
4. 触发 ios.yml，macOS runner 编译
5. 5~10 分钟后 Artifacts 里是 oz-unsigned.ipa

## 四、安全

- token 等于账号操作权限，用完就删：https://github.com/settings/tokens -> Delete
- 仓库建成私有；构建日志不含 token
- 免费账号私有仓库 2000 分钟/月 Actions 额度，一次构建 5-10 分钟

## 五、不想给 token 的网页路径

1. https://github.com/new，仓库名 oz-ios，选 Private，Create
2. 解压 oz-ios-src.zip，把 ios-app 里全部文件（含隐藏的 .github 目录）拖进 Add file -> Upload files
3. Commit
4. Actions -> 左侧 build-ios-ipa -> Run workflow
5. 跑完页面底部 Artifacts 下载 oz-unsigned-ipa
