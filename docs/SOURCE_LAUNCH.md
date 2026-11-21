# Launch from a source checkout

| Platform | Launch the last build, or build it on first use | Rebuild after edits and launch |
| --- | --- | --- |
| Linux x86_64 | `Start-DeskPort.sh` | `Build-and-Start-DeskPort.sh` |
| Windows x64 | `Start-DeskPort.cmd` | `Build-and-Start-DeskPort.cmd` |

Open the script from the checkout in your file manager. On Linux, choose **Run**
if asked, or run `./Start-DeskPort.sh` from a terminal if your file manager opens
scripts as text. Quit any running DeskPort instance before trying a new build.
DeskPort otherwise brings the running instance to the foreground.

Linux builds use Bash, Git, Python 3 and [Nix with flakes enabled](BUILD_WORKFLOW.md).
If this checkout already has an executable `build/deskport` launcher, the Linux
starter uses it. A local `build/rebuild-deskport` script can rebuild that binary
when using a system toolchain. This lets a configured development machine reuse
its existing toolchain and runtime dependencies.

Windows compilation uses the [maintained cross-build](BUILD_WINDOWS.md) in an
x64 WSL distribution with Git, Python 3 and `nix-shell` available in the login
shell. Use a Windows checkout with Unix line endings so WSL can run the build
scripts. For example, `git clone --config core.autocrlf=false --recurse-submodules
<repository-url>` from Windows. After building, the launcher copies the portable
payload to `%LOCALAPPDATA%\DeskPortSource` and starts the native `DeskPort.exe`.
The exe uses the normal Windows settings profile. The launcher needs WSL for
compilation only. The first build may take time to fetch and compile dependencies.

If you need a Windows host service or virtual display driver, follow the
[Windows installation and hosting guide](WINDOWS_DISPLAY_SERVICE.md). The
launcher runs the app from source build outputs and does not install those
system components.
