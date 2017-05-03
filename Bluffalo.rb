class Bluffalo < Formula
  desc "Generate fake classes for Swift"
  homepage ""

  head "https://github.com/Nordstrom/bluffalo.git", :shallow => false

  depends_on :xcode => ["8.0", :build]
  depends_on "sourcekitten"

  def install
    system "make", "prefix_install",  "PREFIX=#{prefix}", "TEMPORARY_FOLDER=#{buildpath}/Bluffalo.dst"
  end

end
