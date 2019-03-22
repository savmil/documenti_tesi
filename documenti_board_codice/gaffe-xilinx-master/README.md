# gaffe-xilinx

Rust library for parsing and manipulating Xilinx bitstream formats.

[![Build Status](https://travis-ci.org/gaffe-logic/gaffe-xilinx.svg?branch=master)](https://travis-ci.org/gaffe-logic/gaffe-xilinx)
[![](http://meritbadge.herokuapp.com/gaffe-xilinx)](https://crates.io/crates/gaffe-xilinx)

## xc7-tool Usage

xc7-tool is a multi-tool for manipulating 7-Series bitstreams. If you are mainly interested in looking at the contents of a bitstream, you'll likely find `xc7-tool packets` and `xc7-tool config_mem_frames` useful.  Commands and their options are documented via --help.

Note that subcommands that parse a bitstream to a configuration will require a device description file.  This is a YAML file containing a serialized DeviceDescription.  None are currently included in this repo. One can be generated from a debug bitstream with `xc7-tool device_description`.  The logic design inside the bitstream doesn't matter. The only requirements are that it be built with Vivado's BITSTREAM.GENERAL.DEBUGBITSTREAM property set to YES.

## Library Usage

### Cargo.toml
```
[dependencies]
gaffe-xilinx = "0.1"
```

### Include the library
```
extern crate gaffe-xilinx;
```

### Example of parsing a 7-Series bitstream into configuration memory frames
```
use gaffe_xilinx::from_bytes::FromBytes;
use ::gaffe-xilinx::xc7 as xc7;

let mut device_file = std::fs::File::open(device_file)?;
let device_description : ::xc7::DeviceDefinition = ::serde_yaml::from_reader(device_file)?;

let mut bitstream = std::io::BufReader::new(std::fs::File::open(bitstream)?);
let bitstream = ::xc7::Bitstream::from_bytes(&mut bitstream)?;

let configuration = ::xc7::Configuration::from_bitstream_for_device(&bitstream, &device_description)?;
println!("{:#?}", configuration)
```

## Supported device families

Current development is focused on 7-series (Spartan7, Artix7, Kintex7). Virtex2 and later families all use a similar bitstream format and configuration protocol. If you are interested in looking at these other families, please join ##openfpga (yes, two #s) on Freenode IRC and let us know.
