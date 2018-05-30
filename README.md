# Wineskin Engine Builder

[![Build Status](https://travis-ci.org/WineskinCommunity/WineskinEngineBuilder.svg?branch=master)](https://travis-ci.org/WineskinCommunity/WineskinEngineBuilder)

Tool for automating the creation of Wineskin Engines.

### Quick Start
 
Install p7zip with Homebrew

```
$ brew install p7zip
```

Checkout the source:

```
$ git clone https://github.com/WineskinCommunity/WineskinEngineBuilder.git
$ cd WineskinEngineBuilder
```

Show usage:

```
$ swift run wsenginebuild --help
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

## WineskinEngines

This is a macOS app with some of the same functionality as the command line tool.

```
$ carthage update --cache-builds --platform mac
```

```
$ xcodebuild -project WineskinEngines.xcodeproj -scheme WineskinEngines build
```

## Engine List

`engines.json`

Example Engine:

```swift
{
	"engines":
	[
		{
			"name": "WS9Wine3.0.1",
			"description": "Wine Stable 3.0.1",
			"author": "WineHQ Official",
			"homepage": "https://dl.winehq.org/wine-builds/macosx/download.html",
			"sources":
			[
				{
					"url": "https://dl.winehq.org/wine-builds/macosx/pool/portable-winehq-stable-3.0.1-osx64.tar.gz",
					"sha256": "07429ae28be5ad811027ed15a9b58a6bbc5fb55a3cd2c4c803ed72d5c67a59aa",
					"arch": ["32", "64"],
					"type": "portable-winehq"
				},
				{
					"url": "https://dl.winehq.org/wine-builds/macosx/pool/portable-winehq-stable-3.0.1-osx.tar.gz",
					"sha256": "cc74c62868db89305a7bae02d72d053ff02f839e205657a62d8fc1a661198a20",
					"arch": ["32"],
					"type": "portable-winehq"
				},
				{
					"url": "https://dl.winehq.org/wine/source/3.0/wine-3.0.1.tar.xz",
					"sha256": "bad00d7ddac6652795a2ed52ce02a544ff4e891499b29ac71d28d20b8e1d26f3",
					"type": "source"
				}
			]
		}
	]
}
```

### Reference

* [https://github.com/marnovo/WINE-tools](https://github.com/marnovo/WINE-tools)

### License

[MPL 2.0](https://www.mozilla.org/en-US/MPL/2.0/)