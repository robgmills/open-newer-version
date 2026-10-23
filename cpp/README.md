This is my first real C++ project, so please bare with me :P .

This directory contains the C++ part of this extension. If you don't know how to
code or compile C++, and just want to update the Ruby code, feel free to ignore
it and just focus on the SketchUp Ruby extension.

# Set Up Guide

1. Open the Visual Studio solution (ConvertVersion.sln).

2. Open properties of the ConvertVersion project (right click > Properties).

3. Make sure _All Configurations_ is selected in the Configurations drop down.

4. Update _Configuration Properties > C/C++ > Include Directories_ to to refer
to where the
[SketchUp SDK](https://extensions.sketchup.com/en/developer_center/sketchup_sdk)
headers are located on your machine.

5. Update _Configuration Properties > Linker > Additional Library
Directories_ to refer to where the SketchUp SDK binaries are located on your
machine.

6. Update _Configuration Properties > Build Events > Post-Build Events > Command
line_ to refer to where the Sketchup SDK binaries are on your machine.

# Use updated program in SketchUp Ruby Extension

After building a new ConvertVersion.exe, copy it into src/bin/ to make it a part
of the Ruby extension (yeah, this could be scripted but let's do one thing at a
time). Also copy the most recent SketchUpAPI.dll and
SketchUpCommonPreferences.dll to this directory.

# macOS Build Notes

This extension also supports a macOS converter binary. You must build a native
macOS CLI using the SketchUp SDK for macOS and copy it into the extension.

Prerequisites:
- SketchUp SDK for macOS (download from SketchUp developer resources)
- Xcode command line tools (for clang++)

Example build steps (adjust paths to your SDK install):

  export SKETCHUP_SDK_MAC="/path/to/SketchUpSDK"
  clang++ -std=c++11 \
    -I "$SKETCHUP_SDK_MAC/SketchUpAPI.framework/Headers" \
    -F "$SKETCHUP_SDK_MAC" \
    -framework SketchUpAPI \
    -o ConvertVersion-mac \
    main.cpp

Then copy the binary into the extension and make it executable:

  cp ConvertVersion-mac ../src/ene_open_newer_version/bin/ConvertVersion-mac
  chmod +x ../src/ene_open_newer_version/bin/ConvertVersion-mac
