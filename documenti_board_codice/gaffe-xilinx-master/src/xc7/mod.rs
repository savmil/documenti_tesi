mod bitstream;
mod configuration;
mod device;
pub mod frame_address;
mod idcode;
pub mod registers;

pub type Word = u32;
pub use self::bitstream::Bitstream;
pub use self::bitstream::Packet;
pub use self::bitstream::RegisterAddress;
pub use self::bitstream::Opcode;
pub use self::configuration::Configuration;
pub use self::configuration::Frame;
pub use self::device::DeviceDefinition;
pub use self::frame_address::FrameAddress;
pub use self::idcode::IdCode;
pub use self::registers::Register;

use ::byteorder::BigEndian;
use ::byteorder::ReadBytesExt;
use ::byteorder::WriteBytesExt;
use ::failure::Error;
use ::failure::ResultExt;
use ::packed_struct::PackedStruct;

pub trait FromWord: PackedStruct<[u8; 4]> {
    fn from_word(word: Word) -> Result<Self, Error> {
        let mut bytes = [0u8; 4];
        (&mut bytes as &mut [u8]).write_u32::<BigEndian>(word).context("Converting u32 to [u8;4]")?;
        Ok(Self::unpack(&bytes).context("Failure to unpack struct from xc7 word")?)
    }
}

impl<T: PackedStruct<[u8; 4]>> FromWord for T {}

pub trait ToWord: PackedStruct<[u8; 4]> {
    fn to_word(&self) -> Word {
        (&self.pack() as &[u8]).read_u32::<BigEndian>().expect("Packing 32-bit register")
    }
}

impl<T: PackedStruct<[u8; 4]>> ToWord for T {}