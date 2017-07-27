class Bluffalo < Formula
  desc "Allows you to do real mocking and stubbing in Swift."
  homepage "https://github.com/Nordstrom/bluffalo"
  url "https://github.com/Nordstrom/bluffalo/archive/1.1.tar.gz"
  sha256 "6adbf998ac21e05bdb3dbf01cd35b03de8cc5f1b71df5933a9d9deb1a2e11745"
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
