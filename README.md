# homebrew-ghosterm

Ghosterm 的 Homebrew tap。目前只有 **dev 滚动渠道**一个 cask：`ghosterm-dev`。

## 装

```bash
brew tap hanxi/ghosterm
brew trust hanxi/homebrew-ghosterm   # Homebrew 7 起，第三方 tap 要先显式信任
brew install --cask ghosterm-dev
```

## 先说清楚：这条路**不**解决 Gatekeeper

装完首次打开**照样会被拦**。Homebrew 会**自己**给下载物贴 `com.apple.quarantine`——
`Library/Homebrew/extend/os/mac/cask/quarantine.rb` 直接调 CoreFoundation 的
LSQuarantine，agent 写 `Homebrew Cask`，Homebrew 7 里没有关掉它的开关或环境变量。
本机（macOS 26）实测：

```console
$ xattr -l /Applications/Ghosterm.app
com.apple.quarantine: 0381;…;;<uuid>      ← Homebrew 贴的
$ spctl -a -t execute /Applications/Ghosterm.app
... rejected                                ← ad-hoc 签名、未公证
```

**决定拦不拦的是「标记在不在」，不是标记里的 flag 值。** 同一个 ad-hoc 签名的探针包
分别贴浏览器风格 `0081;…;Safari;…` 与 Homebrew 风格 `0381;…;;…`：LaunchServices 两侧
都记 `launched with launchInQuarantine == true, so not starting the application`（进程
被 spawn 出来但挂住不执行），syspolicyd 两侧都报 `GatekeeperPolicyScanError -67018
Code did not match any currently allowed policy` 并弹框；不贴标记的那一份照常执行。

放行一次即可（之后不再问），两条都实测有效：

- 系统设置 → 隐私与安全性 → 底部「仍要打开」；或
- `xattr -dr com.apple.quarantine /Applications/Ghosterm.app`

所以走 brew 买到的是**一条命令装 + 一条命令升级 + 显式的架构/系统下限守卫**，
不是「双击直接开」。要完全不弹窗只有两条路：主仓库拿到 Developer ID 并公证，
或者用不贴标记的取包方式（下面那一节）。

### 想要「不贴标记」：`curl` + `ditto`

`curl` 不属于会贴标记的下载代理，实测 zip 与解出来的 `.app` 都只有
`com.apple.provenance`，首次打开不触发 Gatekeeper 评估。代价：**这一步绕过的只是
首次弹窗，不是校验**——字节对不对全看下面那三行 `shasum`。

```bash
base=https://github.com/hanxi/ghosterm/releases/download/dev
mkdir ghosterm && cd ghosterm
curl -fsSL -O "$base/Ghosterm-0.1.0-dev-arm64.zip" -O "$base/SHA256SUMS"
shasum -a 256 -c SHA256SUMS --ignore-missing
ditto -x -k Ghosterm-0.1.0-dev-arm64.zip /Applications
```

## 升级

```bash
brew upgrade --cask --greedy ghosterm-dev
```

`version :latest` 的 cask 默认**不进** `brew outdated`（Homebrew 认为「最新」无从比较），
所以要 `--greedy`；不想每次带参数就设 `export HOMEBREW_UPGRADE_GREEDY=1`。
升级前请先退出正在跑的 Ghosterm。

实测：dev 资产没重打时它会说 `Not upgrading ghosterm-dev, the downloaded artifact has
not changed` 而不是重装一次——`sha256 :no_check` 下没有可比对的校验和，它判的是
「下载物变没变」，不是字节对不对。主仓库推了新包之后这条命令才会真重下并覆盖
`/Applications/Ghosterm.app`。

## `sha256 :no_check`：这条路的代价，说清楚

cask **不校验字节**。原因是 dev 渠道的物理事实：滚动 tag `dev` 每轮被强删重建，
每轮 ad-hoc 签名的 cdhash 都不同——钉不住、也不该钉一个校验和。

这不是「反正没人看」的偷懒，是**有意划清的边界**：等拿到 Developer ID 证书 + 公证、
出**不可变的版本化资产**之后，这里必须切回真实 `sha256`（`version` 也从 `:latest` 换成
真版本号）。在那之前，谁把 `:no_check` 改成一个钉死的 sha，ghosterm 主仓库的闸门会当场红
（`scripts/check-dev-cask.sh`，牙见 `scripts/mutation-check-package-mac.sh` 的 A10）。

想要逐字节确认，另外取一份来对（`SHA256SUMS` 按文件名校验，几个文件要在同一个目录里）：

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
不会给你一个跑不起来的包。（Intel 与 macOS < 26 的报错路径**未在实机上验过**，
本机只验到 `brew info --cask` 能把这两条下限正确读出来。）

## 本机验证记录（留证据，不口头保证）

Homebrew 7.0.10 / macOS 26，2026-10-27：

- `brew style --cask hanxi/ghosterm/ghosterm-dev` → 绿（1 file inspected, no offenses）
- `brew audit --cask --strict` → 绿，`:no_check` 在个人 tap 上**没有**报警
- `brew info --cask` → 正确读出 `Required: arm64 architecture, macOS >= 26`
- `brew install --cask` → 装成，但**装完的 app 带 `com.apple.quarantine`（`0381;…`）**，
  见上面「不解决 Gatekeeper」那一节
- `brew uninstall --cask ghosterm-dev` → 干净（`/Applications/Ghosterm.app` 与 Caskroom 都没剩）

## 维护

URL 里的资产名带版本号（`Ghosterm-<version>-arm64.zip`）。**主仓库 bump 版本号时必须同步
改这里那一行**，否则用户侧 `brew install --cask` 404。这个漂移不会靠人记住：主仓库每次
dev 出包都会取本仓库的 `Casks/ghosterm-dev.rb` 与本轮资产名逐字对拍，对不上就让 dev 轨红
（见 `.github/workflows/dev-build.yml` 的「对拍 Homebrew cask ↔ 本轮资产」一步）。

上游与装机口径：`docs/how-to/dev-build.md`（ghosterm 主仓库）。
