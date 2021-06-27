# nimview C / CPP example

Is using a "minimal precompiled html ui" and doesn't use npm.
Uses "nake" to compile library and to compile C/C++ code.

Requires to have gcc available in PATH.

Usage:
- nake libs: This will compile Dlls / so files to use Nimview as library, for example
to use it from Visual Studio
- nake cpp: Compiles C++ Example
- nae c: Compiles C Example

Before using the VS project file, you need to run "nake libs". 
As Webview doesn't support clang or MSVC yet, you need to use a DLL of Nimview
when using Visual Studio.