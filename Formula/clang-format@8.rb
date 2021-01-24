# Taken from https://gist.github.com/farzadshbfn/ed4d07a1212dfa8c23d7f64655cda7de

class ClangFormatAT8 < Formula
  desc "Formatting tool for C/C++/Java/JavaScript/Objective-C/Protobuf"
  homepage "https://releases.llvm.org/8.0.0/tools/clang/docs/ClangFormat.html"
  version "8.0.0"

  if MacOS.version >= :sierra
    url "https://releases.llvm.org/8.0.0/llvm-8.0.0.src.tar.xz"
    sha256 "8872be1b12c61450cacc82b3d153eab02be2546ef34fa3580ed14137bb26224c"
  else
    url "http://releases.llvm.org/8.0.0/llvm-8.0.0.src.tar.xz"
    sha256 "8872be1b12c61450cacc82b3d153eab02be2546ef34fa3580ed14137bb26224c"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "subversion" => :build

  resource "clang" do
    if MacOS.version >= :sierra
      url "https://releases.llvm.org/8.0.0/cfe-8.0.0.src.tar.xz"
      sha256 "084c115aab0084e63b23eee8c233abb6739c399e29966eaeccfc6e088e0b736b"
    else
      url "http://releases.llvm.org/8.0.0/cfe-8.0.0.src.tar.xz"
      sha256 "084c115aab0084e63b23eee8c233abb6739c399e29966eaeccfc6e088e0b736b"
    end
  end

  resource "libcxx" do
    url "https://releases.llvm.org/8.0.0/libcxx-8.0.0.src.tar.xz"
    sha256 "c2902675e7c84324fb2c1e45489220f250ede016cc3117186785d9dc291f9de2"
  end

  def install
    (buildpath/"projects/libcxx").install resource("libcxx")
    (buildpath/"tools/clang").install resource("clang")

    mkdir "build" do
      args = std_cmake_args
      args << "-DCMAKE_OSX_SYSROOT=/" unless MacOS::Xcode.installed?
      args << "-DLLVM_ENABLE_LIBCXX=ON"
      args << ".."
      system "cmake", "-G", "Ninja", *args
      system "ninja", "clang-format"
      bin.install "bin/clang-format"
    end
    bin.install "tools/clang/tools/clang-format/git-clang-format"
    (share/"clang").install Dir["tools/clang/tools/clang-format/clang-format*"]
  end

  test do
    # NB: below C code is messily formatted on purpose.
    (testpath/"test.c").write <<~EOS
      int         main(char *args) { \n   \t printf("hello"); }
    EOS

    assert_equal "int main(char *args) { printf(\"hello\"); }\n",
        shell_output("#{bin}/clang-format -style=Google test.c")

    # below code is messily formatted on purpose.
    (testpath/"test2.h").write <<~EOS
      #import  "package/file.h"
      @interface SomePlugin   : NSObject  < ParentPlugin >
      @end
    EOS

    # NOTE! different formatting depending on version
    # clang-format 5.x
    #     @interface SomePlugin : NSObject<ParentPlugin>
    # clang-format 6.x, 7.x
    #     @interface SomePlugin : NSObject <ParentPlugin>
    assert_equal "#import \"package/file.h\"\n@interface SomePlugin : NSObject <ParentPlugin>\n@end\n",
        shell_output("#{bin}/clang-format -style=Google test2.h")
  end
end
