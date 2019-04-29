#[macro_use]
extern crate failure;
extern crate gaffe_xilinx;
extern crate log;
extern crate env_logger;
extern crate serde_yaml;
#[macro_use]
extern crate structopt;

use failure::Error;
use gaffe_xilinx::from_bytes::FromBytes;
use gaffe_xilinx::from_bytes::ToBytes;
use gaffe_xilinx::xc7 as xc7;
use gaffe_xilinx::xc7::FromWord;
use std::io::prelude::*;
use std::iter::FromIterator;
use std::path::PathBuf;
use structopt::StructOpt;

#[derive(Debug, StructOpt)]
#[structopt(name="xc7-tool")]
struct Xc7Tool {
    /// Pass many times for more log output
    ///
    /// By default, it'll only report errors. Passing `-v` one time also prints
    /// warnings, `-vv` enables info logging, `-vvv` debug, and `-vvvv` trace.
    #[structopt(long = "verbosity", short = "v", parse(from_occurrences))]
    verbosity: u8,

    #[structopt(subcommand)]
    cmd: Command
}

#[derive(Debug, StructOpt)]
enum Command {
    /// List configuration packets contained in a bitstream
    #[structopt(name = "packets")]
    Packets {
        #[structopt(parse(from_os_str))]
        bitstream: PathBuf
    },

    /// Parse a bitstream, serialize it back to bytes, and compare the two
    #[structopt(name = "packets_round_trip")]
    PacketRoundTrip {
        #[structopt(parse(from_os_str))]
        input: PathBuf,

        #[structopt(parse(from_os_str))]
        output: PathBuf
    },

    /// Prints the Device ID that is written to the IDCODE register
    #[structopt(name = "idcode")]
    GetIdcode {
        #[structopt(parse(from_os_str))]
        bitstream: PathBuf,

        /// Output the IDCODE as a 32-bit hex value. Default is to print a
        /// parsed form.
        #[structopt(name = "hex", short = "h")]
        hex_output: bool,
    },

    /// Gather valid configuration memory address ranges from a debug bitstream
    #[structopt(name = "config_mem_layout")]
    ConfigMemLayout {
        /// Bitstream generated with BITSTREAM.GENERAL.DEBUGBITSTREAM set to YES
        #[structopt(parse(from_os_str))]
        bitstream: PathBuf,
    },

    /// Create minimal device description from a debug bitstream
    #[structopt(name = "device_description")]
    DeviceDescription {
        /// Write device description to `output`.  Default is to standard output.
        #[structopt(name = "output", short = "o", parse(from_os_str))]
        output_file: Option<PathBuf>,

        /// Device's name (e.g. xc7a50t)
        device_name: String,

        /// Bitstream generated with BITSTREAM.GENERAL.DEBUGBITSTREAM set to YES
        #[structopt(parse(from_os_str))]
        bitstream: PathBuf,
    },

    /// Dump configuration memory frames written by a bitstream
    #[structopt(name = "config_mem_frames")]
    ConfigMemFrames {
        /// Path to a device description file
        #[structopt(name = "device", short = "d", parse(from_os_str))]
        device_file: PathBuf,

        #[structopt(parse(from_os_str))]
        bitstream: PathBuf,
    },

    /// Parse a bitstream to configuration frames, serialize it back to bytes, and compare the two.
    #[structopt(name = "config_round_trip")]
    ConfigRoundTrip{
        /// Path to a device description file
        #[structopt(name = "device", short = "d", parse(from_os_str))]
        device_file: PathBuf,

        #[structopt(parse(from_os_str))]
        input: PathBuf,

        #[structopt(parse(from_os_str))]
        output: PathBuf
    },

    /// Generate a new bitstream by replacing individual frames of an existing bitstream.
    #[structopt(name = "patch")]
    Patch{
        /// Path to a device description file
        #[structopt(name = "device", short = "d", parse(from_os_str))]
        device_file: PathBuf,

        /// Bitstream to which frame replacements are applied
        #[structopt(parse(from_os_str))]
        source: PathBuf,

        /// File containing a list of frame replacements in the form of "<frame_address> <word1> ... <word101>"
        #[structopt(parse(from_os_str))]
        patch: PathBuf,

        /// Path to which patched bitstream is written
        #[structopt(parse(from_os_str))]
        destination: PathBuf
    },

}

fn idcodes(bitstream: &::xc7::Bitstream) -> Vec<::xc7::IdCode> {
    bitstream.iter().filter_map(
        |x| {
            match x {
                ::xc7::Packet::Type1{
                    opcode: ::xc7::Opcode::Write,
                    address: ::xc7::RegisterAddress::IDCODE,
                    payload
                } => Some(::xc7::IdCode::from_word(payload[0]).unwrap()),
                _ => None,
            }
        }
    ).collect::<Vec<::xc7::IdCode>>()
}

fn frame_addresses(bitstream: &::xc7::Bitstream) -> Vec<::xc7::FrameAddress> {
    // In a debug bitstream, each frame is written to FDRI individually.
    // After a frame is written, the address of that frame is written to
    // LOUT as an external progress indicator. Scan through the
    // bitstream and collect all the frame addresses written to LOUT.
    let mut frame_addresses = Vec::<::xc7::FrameAddress>::new();
    let mut fdri_has_been_written = false;
    for packet in bitstream.iter() {
        match packet {
            ::xc7::Packet::Type1{
                opcode: ::xc7::Opcode::Write,
                address: ::xc7::RegisterAddress::FDRI,
                payload: _
            } => fdri_has_been_written = true,
            ::xc7::Packet::Type1{
                opcode: ::xc7::Opcode::Write,
                address: ::xc7::RegisterAddress::LOUT,
                payload
            } if fdri_has_been_written => frame_addresses.push(::xc7::FrameAddress::from_word(payload[0]).unwrap()),
            _ => continue,
        }
    }
    frame_addresses
}

fn main() -> Result<(), Error> {
    let opts = Xc7Tool::from_args();

    let level_filter = {
        match opts.verbosity {
            0 => log::Level::Error,
            1 => log::Level::Warn,
            2 => log::Level::Info,
            3 => log::Level::Debug,
            _ => log::Level::Trace,
        }.to_level_filter()
    };

    env_logger::Builder::new()
        .filter(Some(module_path!()), level_filter)
        .filter(Some(&env!("CARGO_PKG_NAME").replace("-", "_")), level_filter)
        .init();

    match opts.cmd {
        Command::Packets{ bitstream } => {
            let mut bitstream = std::io::BufReader::new(std::fs::File::open(bitstream)?);
            let bitstream = ::xc7::Bitstream::from_bytes(&mut bitstream)?;
            println!("{}", bitstream)
        },
        Command::PacketRoundTrip{ input, output } => {
            let orig_bytes = ::std::fs::read(input)?;
            let mut orig_bitstream = ::std::io::Cursor::new(&orig_bytes);
            let orig_bitstream = ::xc7::Bitstream::from_bytes(&mut orig_bitstream)?;

            let mut out_file = ::std::fs::File::create(output)?;
            orig_bitstream.to_bytes(&mut out_file)?;
        },
        Command::GetIdcode{ bitstream, hex_output } => {
            let mut bitstream = std::io::BufReader::new(std::fs::File::open(bitstream)?);
            let bitstream = ::xc7::Bitstream::from_bytes(&mut bitstream)?;

            for idcode in idcodes(&bitstream) {
                if hex_output {
                    println!("{:x}", idcode);
                } else {
                    println!("{}", idcode);
                }
            }
        },
        Command::ConfigMemLayout{ bitstream } => {
            let mut bitstream = std::io::BufReader::new(std::fs::File::open(bitstream)?);
            let bitstream = ::xc7::Bitstream::from_bytes(&mut bitstream)?;
            let frame_addresses = frame_addresses(&bitstream);

            if frame_addresses.is_empty() {
                return Err(format_err!("Bitstream does not appear to be a debug bitstream: contains no LOUT writes"))
            } else {
                let config_mem_layout = ::xc7::frame_address::Set::from_iter(frame_addresses);
                println!("{}", config_mem_layout)
            }
        },
        Command::DeviceDescription{ output_file, device_name, bitstream } => {
            let mut bitstream = std::io::BufReader::new(std::fs::File::open(bitstream)?);
            let bitstream = ::xc7::Bitstream::from_bytes(&mut bitstream)?;

            let idcodes = idcodes(&bitstream);
            match idcodes.len() {
                0 => return Err(format_err!("Bitstream is missing an IDCODE")),
                1 => (),
                _ => return Err(format_err!("Bitstream contains more than one IDCODE")),
            }

            let frame_addresses = frame_addresses(&bitstream);
            if frame_addresses.is_empty() {
                return Err(format_err!("Bitstream does not appear to be a debug bitstream: contains no LOUT writes"))
            }

            let device_def = ::xc7::DeviceDefinition{
                name: device_name,
                idcode: idcodes[0],
                config_mem_layout: ::xc7::frame_address::Set::from_iter(frame_addresses),
            };

            match output_file {
                Some(path) => ::serde_yaml::to_writer(::std::fs::File::create(path)?, &device_def)?,
                None => println!("{}", ::serde_yaml::to_string(&device_def)?)
            }
        },
        Command::ConfigMemFrames{ device_file, bitstream } => {
            let mut device_file = std::fs::File::open(device_file)?;
            let device_description : ::xc7::DeviceDefinition = ::serde_yaml::from_reader(device_file)?;

            let mut bitstream = std::io::BufReader::new(std::fs::File::open(bitstream)?);
            let bitstream = ::xc7::Bitstream::from_bytes(&mut bitstream)?;

            let configuration = ::xc7::Configuration::from_bitstream_for_device(&bitstream, &device_description)?;
            
        },
        Command::ConfigRoundTrip{ device_file, input, output } => {
            let mut device_file = std::fs::File::open(device_file)?;
            let device_description : ::xc7::DeviceDefinition = ::serde_yaml::from_reader(device_file)?;

            let mut bitstream = std::io::BufReader::new(std::fs::File::open(input)?);
            let bitstream = ::xc7::Bitstream::from_bytes(&mut bitstream)?;

            let configuration = ::xc7::Configuration::from_bitstream_for_device(&bitstream, &device_description)?;

            let repacked_bitstream: ::xc7::Bitstream = configuration.into();
            let mut out_file = ::std::fs::File::create(output)?;
            repacked_bitstream.to_bytes(&mut out_file)?;
        }
        Command::Patch{ device_file, source, patch, destination } => {
            let mut device_file = std::fs::File::open(device_file)?;
            let device_description : ::xc7::DeviceDefinition = ::serde_yaml::from_reader(device_file)?;
            
            let mut source = std::io::BufReader::new(std::fs::File::open(source)?);
            let source = ::xc7::Bitstream::from_bytes(&mut source)?;
            let mut configuration = ::xc7::Configuration::from_bitstream_for_device(&source, &device_description)?;

            let mut patch_file = std::fs::File::open(patch)?;
            let patch_file = std::io::BufReader::new(patch_file);

            for line in patch_file.lines() {
                if let Ok(line) = line {
println!("{}",line);
                    let tokens = line.split_whitespace().collect::<Vec<&str>>();
                    let (address, words) = tokens.split_first().expect("Patch file must contain lines of \"<frame_address> <word1> .. <word101>\"");
		      
                    let address = u32::from_str_radix(address, 16)?;
                    let address = ::xc7::FrameAddress::from_word(address)?;
		
                    let words = words.iter().map(|x| u32::from_str_radix(x, 16).expect("Frame words must be in hexidecimal without a prefix"));
                    let frame = ::xc7::Frame::from_words(words)?;

                    configuration.set_frame(&address, frame)?;
                }
            }
	   
            let repacked_bitstream: ::xc7::Bitstream = configuration.into();
            let mut destination = ::std::fs::File::create(destination)?;
            repacked_bitstream.to_bytes(&mut destination)?;
        }
    }
    Ok(())
}
