cask "ghosterm-dev" do
  version :latest
  sha256 :no_check

  url "https://github.com/hanxi/ghosterm/releases/download/dev/Ghosterm-0.1.0-dev-arm64.zip"
  name "Ghosterm (dev channel)"
  desc "Libghostty 驱动的多端终端（dev 滚动渠道，未公证）"
  homepage "https://github.com/hanxi/ghosterm"

  depends_on arch: :arm64
  depends_on macos: :tahoe

  app "Ghosterm.app"

  uninstall quit: "dev.ghosterm.mac"
end
