# dive_obslib

A Flutter plugin package that provides low level access to obslib using FFI.

# Introduction

The dive_obslib package is part of the Dive video recording and streaming platform.
It provides the Dart wrapper
around [libobs](https://github.com/obsproject/obs-studio/tree/master/libobs)
from [OBS Studio](https://obsproject.com/) and
utilizes [Dart FFI](https://dart.dev/guides/libraries/c-interop) to call the native
C APIs in libobs.
