# Wineskin Engine Builder

Tool for automating the creation of Wineskin Engines.

### Quick Start

```
$ git clone https://github.com/WineskinCommunity/WineskinEngineBuilder.git
$ cd WineskinEngineBuilder
$ swift run wsenginebuild
```

### Running Tests

```
$ swift test
```

#### Generate Xcode Project

This will auto-generate an Xcodeproj file for the `wsenginebuild` command line tool. Do not edit it because it is auto-generated and in the `.gitignore`.

```
$ swift package generate-xcodeproj
$ open wsenginebuild.xcodeproj
```

#### Release

This will build a statically linked `wsenginebuild` command line binary suitable for redistribution.

```
$ swift build --configuration release --static-swift-stdlib
```

### Engine List

`engines.json`

### Reference

* [https://github.com/marnovo/WINE-tools](https://github.com/marnovo/WINE-tools)

### License

GPLv3