class Bluffalo < Formula
  desc "Allows you to do real mocking and stubbing in Swift."
  homepage "https://github.com/Nordstrom/bluffalo"
  url "https://github.com/PeqNP/bluffalo/archive/1.1.tar.gz"
  sha256 "8f00d8d6f4034cc424c93d7fc24f194b51c74be6922160f0c4e1374a3ded081f"
  head "https://github.com/Nordstrom/bluffalo.git", :shallow => false

  depends_on :xcode => ["8.0", :build]
  depends_on "sourcekitten"

  def install
    system "make", "prefix_install", "PREFIX=#{prefix}", "TEMPORARY_FOLDER=#{buildpath}/Bluffalo.dst"
  end

  test do
    system "#{bin}/bluffalo", "-?"
  end
end
