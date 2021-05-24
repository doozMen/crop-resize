![crop](Media/crop_header.jpg)

Base on https://github.com/eneko/crop

# crop & scale
 
## Install cloned

```
git clone https://github.com/doozMen/crop
```

A command line tool to **scale and crop images maintaining aspect ratio**.

After cloning lib 
```
$ swift run crop-scale crop dir Media --width 1920 --height 1080
```

Reduce memory footprint
```
$ swift run crop-scale scale dir Media 
```


## Usage
Output after running `swift run crop-scale --help`

```
USAGE: crop-resize [--verbose <verbose>] <subcommand>

OPTIONS:
--verbose <verbose>     (default: false)
-h, --help              Show help information.

SUBCOMMANDS:
crop
scale
memory-footprint

See 'crop-resize help <subcommand>' for detailed help.
```


## Installation on System

Currently only supports building from source. You will need to understand git.

```
cd <#developer directry#>
git clone https://github.com/doozMen/crop-scale
cd crop-scale
# brew install make
make
```