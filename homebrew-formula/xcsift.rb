class Xcsift < Formula
  desc "Swift tool to parse xcodebuild output for coding agents"
  homepage "https://github.com/ldomaradzki/xcsift"
  url "https://github.com/ldomaradzki/xcsift/archive/v1.0.3.tar.gz"
  sha256 "144708a3ddef33e56e0125e01205499ad4dbf6390c0eff2a3d5b4b6868d903e9"
  license "MIT"
  head "https://github.com/ldomaradzki/xcsift.git", branch: "master"

  depends_on xcode: ["12.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/xcsift"
  end

  test do
    # Test version flag (version is hardcoded in source, not from git tag)
    assert_match /\d+\.\d+\.\d+/, shell_output("#{bin}/xcsift --version")
    
    # Test help flag
    assert_match "A Swift tool to parse xcodebuild output", shell_output("#{bin}/xcsift --help")
    
    # Test with sample input
    sample_input = "Build succeeded"
    output = pipe_output("#{bin}/xcsift", sample_input)
    assert_match "status", output
    assert_match "summary", output
  end
end