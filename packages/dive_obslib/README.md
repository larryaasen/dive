# dive_obslib

A Flutter plugin package that provides low level access to obslib using FFI.

[![pub package](https://img.shields.io/pub/v/dive_obslib.svg)](https://pub.dev/packages/dive_obslib)
<a href="https://www.buymeacoffee.com/larryaasen">
  <img alt="Gift me a coffee" src="https://img.shields.io/badge/Donate-Gift%20Me%20A%20Coffee-yellow.svg">
</a>

# Introduction

The dive_obslib package is part of the [Dive](https://pub.dev/packages/dive) video recording and streaming platform.
It provides the Dart wrapper
around [libobs](https://github.com/obsproject/obs-studio/tree/master/libobs)
from [OBS Studio](https://obsproject.com/) and
utilizes [Dart FFI](https://dart.dev/guides/libraries/c-interop) to call the native
C APIs in libobs.

This package is designed to be used by the
[dive](https://pub.dev/packages/dive) package, and can also be used
separately.
