# homebrew-ghosterm

Ghosterm 的 Homebrew tap。目前只有 **dev 滚动渠道**一个 cask：`ghosterm-dev`。

## 装

```bash
brew trust hanxi/ghosterm   # Homebrew 7 起，第三方 tap 要先显式信任
brew tap hanxi/ghosterm
brew install --cask ghosterm-dev
```

装完**双击直接开**，不会遇到「Apple 无法检查是否含恶意软件」那一屏。

为什么：Gatekeeper 只看文件上的 `com.apple.quarantine` 标记，而那个标记是**下载工具**贴的——
浏览器、Mail、AirDrop 会贴，`curl` / `ditto` / Homebrew 不贴。Homebrew 用自己的 curl 封装取包，
所以这条路拿到的 `Ghosterm.app` 压根没有 quarantine 属性，Gatekeeper 连评估都不做。
包本身仍是 ad-hoc 签名、未公证（`spctl --assess` 判 rejected）——那只在**带标记**时才有意义。

包没变好，只是没被贴标记。

## 升级

```bash
brew upgrade --cask --greedy ghosterm-dev
```

`version :latest` 的 cask 默认**不进** `brew outdated`（Homebrew 认为「最新」无从比较），
所以要 `--greedy`；不想每次带参数就设 `export HOMEBREW_UPGRADE_GREEDY=1`。
升级前请先退出正在跑的 Ghosterm。

## `sha256 :no_check`：这条路的代价，说清楚

cask **不校验字节**。原因是 dev 渠道的物理事实：滚动 tag `dev` 每轮被强删重建，
每轮 ad-hoc 签名的 cdhash 都不同——钉不住、也不该钉一个校验和。

这不是「反正没人看」的偷懒，是**有意谎报的边界**：等拿到 Developer ID 证书 + 公证，
出**不可变的版本化资产**之后，这里必须切回真实 `sha256`（`version` 也从 `:latest` 换成真版本号）。
在那之前，谁把 `:no_check` 改成一个钉死的 sha，ghosterm 主仓库的闸门会当场红
（`scripts/check-dev-cask.sh`，牙见 `scripts/mutation-check-package-mac.sh` 的 A10）。

想要逐字节确认，另外取一份来对（`SHA256SUMS` 按文件名校验，三个文件要在同一个目录里）：

```bash
mkdir ghosterm-sums && cd ghosterm-sums
base=https://github.com/hanxi/ghosterm/releases/download/dev
curl -fsSL -O "$base/Ghosterm-0.1.0-dev-arm64.zip" -O "$base/SHA256SUMS" -O "$base/BUILD-INFO.txt"
shasum -a 256 -c SHA256SUMS
```

装好的那份里也带着一份 `Contents/Resources/BUILD-INFO.txt`，记着 commit、构建时刻、
架构、最低系统、签名档位——它就是「这个包是怎么来的」的答案，写的是实际值而不是配置值。

## 系统要求

只出 **arm64**（`GhosttyKit.xcframework` 当前只有 arm64 切片），最低 **macOS 26**
——这个下限是被内嵌的 Homebrew `libcrypto.3.dylib` 抬上去的，不是 app 自己的要求
（二进制自身 13.0）。两者都写在 cask 的 `depends_on` 上，不满足时 Homebrew 当场报错、
不会给你一个跑不起来的包。

## 维护

URL 里的资产名带版本号（`Ghosterm-<version>-arm64.zip`）。**主仓库 bump 版本号时必须同步
改这里那一行**，否则用户侧 `brew install --cask` 404。这个漂移不会靠人记住：主仓库每次
dev 出包都会取本仓库的 `Casks/ghosterm-dev.rb` 与本轮资产名逐字对拍，对不上就让 dev 轨红
（见 `.github/workflows/dev-build.yml` 的「对拍 Homebrew cask ↔ 本轮资产」一步）。

上游与装机口径：`docs/how-to/dev-build.md`。
