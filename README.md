## imageoptimizer-brunch
Optimize PNG and JPG images on --optimize with [brunch](http://brunch.io).
It either uses [jpegtran](http://jpegclub.org/jpegtran/) and [optipng](http://optipng.sourceforge.net/) or [node-smushit](https://github.com/colorhook/node-smushit) to get the best out of your images in your /public folder.

## Installation

You can install jpegtran and optipng with [homebrew](http://mxcl.github.com/homebrew/)
```shell
brew install optipng jpeg
```

## Config
```coffeescript
  imageoptimizer:
    smushit: false # if false it use jpegtran and optipng, if set to true it will use smushit
    path: 'images' # your image path within your public folder
```

## Usage
Add `"imageoptimizer-brunch": "0.0.1"` to `package.json` of your brunch app.

Pick a plugin version that corresponds to your minor (y) brunch version.

If you want to use git version of plugin, add
`"imageoptimizer-brunch": "git+ssh://git@github.com:digitalhero/brunch-imageoptimizer.git"`.