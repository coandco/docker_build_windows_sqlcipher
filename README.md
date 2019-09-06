# docker_build_sqlcipher
Cross-compilation Docker script for building the Windows binary of sqlcipher

To build the Windows sqlcipher binary, run `./make-windows-sqlcipher.sh`.  The resulting `sqlcipher.exe` binary will be deposited in the current directory.

This script was adapted from the qTox cross-compilation build script, located at https://github.com/qTox/qTox/blob/51c5171ca395ca35c934e0357748e512d746f356/windows/cross-compile/build.sh
