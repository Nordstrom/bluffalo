class Bluffalo < Formula
  desc "Allows you to do real mocking and stubbing in Swift."
  homepage "https://github.com/Nordstrom/bluffalo"
  url "https://github.com/Nordstrom/bluffalo/archive/1.1.tar.gz"
  sha256 "68c4cc308382dfd73b52a67203b17e2dddc7f0b930066d198f74f861f6608730"
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
