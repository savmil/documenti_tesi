use ::byteorder::BigEndian;
use ::byteorder::ReadBytesExt;
use ::byteorder::WriteBytesExt;
use ::failure::Error;
use ::failure::ResultExt;
use ::from_bytes::BufReadFromBytesExt;
use ::from_bytes::FromBytes;
use ::from_bytes::ToBytes;
use ::packed_struct::prelude::*;
use ::packed_struct::debug_fmt::PackedStructDebug;
use ::std::fmt;
use ::std::io::prelude::*;
use super::FromWord;
use super::ToWord;
use super::Register;
use super::Word;

#[derive(Debug, Display, Clone, Copy, PartialEq, PrimitiveEnum)]
pub enum Opcode {
    NOP = 0b00,
    Read = 0b01,
    Write = 0b10,
}
impl Default for Opcode {
    fn default() -> Self {
        Opcode::NOP
    }
}

#[derive(Debug, Display, Clone, Copy, PartialEq, PrimitiveEnum)]
#[allow(non_camel_case_types)]
pub enum RegisterAddress {
    CRC = 0b00000,
    FAR = 0b00001,
    FDRI = 0b00010,
    FDRO = 0b00011,
    CMD = 0b00100,
    CTL0 = 0b00101,
    MASK = 0b00110,
    STAT = 0b00111,
    LOUT = 0b01000,
    COR0 = 0b01001,
    MFWR = 0b01010,
    CBC = 0b01011,
    IDCODE = 0b01100,
    AXSS = 0b01101,
    COR1 = 0b01110,
    WBSTAR = 0b10000,
    TIMER = 0b10001,
    UNKNOWN_1 = 0b10011,
    BOOTSTS = 0b10110,
    CTL1 = 0b11000,
    BSPI = 0b11111,
}
impl Default for RegisterAddress {
    fn default() -> Self {
        RegisterAddress::CRC
    }
}

#[derive(Debug, Clone, Copy, PartialEq, PrimitiveEnum)]
enum PacketType {
    Type0 = 0b000,
    Type1 = 0b001,
    Type2 = 0b010,
}
impl Default for PacketType {
    fn default() -> Self {
        PacketType::Type0
    }
}

#[derive(PackedStruct, Default, Debug, PartialEq)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct Type0Header {
    #[packed_field(bits="31:29", ty="enum")]
    packet_type: PacketType,

    #[packed_field(bits="28:0")]
    _reserved: ReservedZeroes<packed_bits::Bits29>,
}

#[derive(PackedStruct, Default, Debug, PartialEq)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct Type1Header {
    #[packed_field(bits="31:29", ty="enum")]
    packet_type: PacketType,

    #[packed_field(bits="28:27", ty="enum")]
    opcode: Opcode,

    #[packed_field(bits="26:18")]
    _address_reserved: ReservedZeroes<packed_bits::Bits9>,

    #[packed_field(bits="17:13", ty="enum")]
    address: RegisterAddress,

    #[packed_field(bits="12:11")]
    _reserved: ReservedZeroes<packed_bits::Bits2>,

    #[packed_field(bits="10:0")]
    word_count: Integer<u16, packed_bits::Bits11>,
}

#[derive(PackedStruct, Default, Debug, PartialEq)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct Type2Header {
    #[packed_field(bits="31:29", ty="enum")]
    packet_type: PacketType,

    #[packed_field(bits="28:27", ty="enum")]
    opcode: Opcode,

    #[packed_field(bits="26:0")]
    word_count: Integer<u32, packed_bits::Bits27>,
}


#[derive(Debug, Clone)]
pub enum Packet {
    Type0,
    Type1 {
        opcode: Opcode,
        address: RegisterAddress,
        payload: Vec<Word>,
    },
    Type2 {
        opcode: Opcode,
        payload: Vec<Word>,
    },
}

impl Packet {
    pub fn nop() -> Self {
        Packet::Type1{
            opcode: Opcode::NOP,
            address: RegisterAddress::CRC,
            payload: Vec::new(),
        }
    }
}

impl<T> From<T> for Packet
where
    T: ToWord + Register
{
    fn from(reg: T) -> Self {
        Packet::Type1{
            opcode: Opcode::Write,
            address: reg.register_address(),
            payload: vec![reg.to_word()],
        }
    }
}

fn write_reg_value<T>(f: &mut fmt::Formatter, payload: &Vec<Word>) -> fmt::Result
where
    T: FromWord + PackedStructDebug
{
    match T::from_word(payload[0]) {
        Ok(x) => {
            writeln!(f, "")?;
            x.fmt_fields(f)
        },
        Err(_) => {
            error!("Register decoding failed");
            write_payload(f, payload)
        },
    }
}

fn write_payload(f: &mut fmt::Formatter, payload: &Vec<Word>) -> fmt::Result
{
    for (row, payload_line) in payload.chunks(4).enumerate() {
        write!(f, "{:04x}:    ", row * 4)?;
        for (col, payload_word) in payload_line.iter().enumerate() {
            write!(f, "{:08x}{}", payload_word,
                match col+1 {
                    n if n == payload_line.len() => "",
                    _ => " ",
                }
            )?;
        }
        writeln!(f, "")?;
    }
    Ok(())    
}

impl fmt::Display for Packet {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match *self {
            Packet::Type0 => writeln!(f, "[Type0]"),
            Packet::Type1 { opcode, address, ref payload } => {
                match opcode {
                    Opcode::NOP => writeln!(f, "[Type1 NOP]"),
                    _ => {
                        writeln!(f, "[Type1 {}({}) {}]", opcode, payload.len(), address)?;
                        match address {
                            RegisterAddress::CRC => write_reg_value::<super::registers::CrcRegister>(f, payload),
                            RegisterAddress::FAR => write_reg_value::<super::registers::FrameAddressRegister>(f, payload),
                            RegisterAddress::CMD => write_reg_value::<super::registers::CommandRegister>(f, payload),
                            RegisterAddress::CTL0 => write_reg_value::<super::registers::ControlRegister0>(f, payload),
                            RegisterAddress::STAT => write_reg_value::<super::registers::StatusRegister>(f, payload),
                            RegisterAddress::LOUT => write_reg_value::<super::registers::LoutRegister>(f, payload),
                            RegisterAddress::COR0 => write_reg_value::<super::registers::ConfigurationOptionsRegister0>(f, payload),
                            RegisterAddress::CBC => write_reg_value::<super::registers::CbcRegister>(f, payload),
                            RegisterAddress::IDCODE => write_reg_value::<super::registers::IdCodeRegister>(f, payload),
                            RegisterAddress::COR1 => write_reg_value::<super::registers::ConfigurationOptionsRegister1>(f, payload),
                            RegisterAddress::WBSTAR => write_reg_value::<super::registers::WarmBootStartAddressRegister>(f, payload),
                            RegisterAddress::TIMER => write_reg_value::<super::registers::WatchdogTimerRegister>(f, payload),
                            RegisterAddress::BOOTSTS => write_reg_value::<super::registers::BootHistoryStatusRegister>(f, payload),
                            RegisterAddress::CTL1 => write_reg_value::<super::registers::ControlRegister1>(f, payload),
                            RegisterAddress::BSPI => write_reg_value::<super::registers::BpiSpiConfigurationOptionsRegister>(f, payload),
                            _ => write_payload(f, payload),
                        }
                    }
                }
            },
            Packet::Type2 { opcode, ref payload } => {
                writeln!(f, "[Type2 {}({})", opcode, payload.len())?;
                write_payload(f, payload)
            }
        }
    }
}

impl FromBytes for Packet {
    fn from_bytes(bytes: &mut BufRead) -> Result<Self, Error> {
        let mut header_bytes = [0u8; 4];
        bytes.read_exact(&mut header_bytes).context(format!("Unable to read {}::Packet header bytes", module_path!()))?;

        // Assume Type0 to start as it only exposes the packet type field. Once
        // the actual packet type is known, use that type's header.
        match Type0Header::unpack(&header_bytes).context(format!("Unexpected packet type: {:#?}", header_bytes))?.packet_type {
            PacketType::Type0 => Ok(Packet::Type0),
            PacketType::Type1 => {
                let header = Type1Header::unpack(&header_bytes)
                    .context(format!("Failed to unpack 0x{} as {}::Packet::Type1", ::hex::encode(header_bytes), module_path!()))?;

                let mut payload = vec![0u32; *header.word_count as usize];
                bytes.read_u32_into::<BigEndian>(&mut payload)?;

                Ok(Packet::Type1 {
                    opcode: header.opcode,
                    address: header.address,
                    payload: payload,
                })
            },
            PacketType::Type2 => {
                let header = Type2Header::unpack(&header_bytes)
                                        .context(format!("Failed to unpack 0x{} as {}::Packet::Type2", ::hex::encode(header_bytes), module_path!()))?;

                let mut payload = vec![0u32; *header.word_count as usize];
                bytes.read_u32_into::<BigEndian>(&mut payload)?;

                Ok(Packet::Type2 {
                    opcode: header.opcode,
                    payload: payload,
                })
            },
        }
    }
}

impl ToBytes for Packet {
    fn to_bytes(&self, writer: &mut Write) -> Result<(), Error> {
        match *self {
            Packet::Type0 => Type0Header{
                    packet_type: PacketType::Type0,
                    ..Type0Header::default()
                }.to_bytes(writer),
            Packet::Type1 { opcode, address, ref payload } => {
                if payload.len() > (1usize << 11) - 1 {
                    return Err(format_err!("Payload too large for Type 1 packet"));
                }

                Type1Header{
                    packet_type: PacketType::Type1,
                    opcode,
                    address,
                    word_count: (payload.len() as u16).into(),
                    ..Type1Header::default()
                }.to_bytes(writer)?;
                for word in payload.iter() {
                    writer.write_u32::<BigEndian>(*word)?
                }
                Ok(())
            },
            Packet::Type2 { opcode, ref payload } => {
                if payload.len() > (1usize << 27) - 1 {
                    return Err(format_err!("Payload too large for Type 2 packet"));
                }

                Type2Header{
                    packet_type: PacketType::Type2,
                    opcode,
                    word_count: (payload.len() as u32).into(),
                    ..Type2Header::default()
                }.to_bytes(writer)?;
                for word in payload.iter() {
                    writer.write_u32::<BigEndian>(*word)?
                }
                Ok(())
            }
        }
    }
}

#[derive(Debug)]
pub struct Bitstream {
    pub packets: Vec<Packet>,
}

impl Bitstream {
    const BIT_WIDTH_DETECTION_PATTERN: [u8; 20] = [
        0xFF, 0xFF, 0xFF, 0xFF,
        0x00, 0x00, 0x00, 0xBB,
        0x11, 0x22, 0x00, 0x44,
        0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF,
    ];

    const SYNC_WORD: [u8; 4] = [0xAA, 0x99, 0x55, 0x66];

    /// Returns an iterator over the packets contained in the bitstream.
    pub fn iter(&self) -> ::std::slice::Iter<Packet> {
        self.packets.iter()
    }
}

impl fmt::Display for Bitstream {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        writeln!(f, "Packets: {}", self.packets.len())?;
        for packet in self.packets.iter() {
            packet.fmt(f)?;
        }
        Ok(())
    }
}

impl FromBytes for Bitstream {
    fn from_bytes(mut bytes: &mut BufRead) -> Result<Self, Error> {
        if !bytes.skip_until_match(&Self::SYNC_WORD).context("xc7 sync word not found")? {
            return Err(format_err!("Sync word not found"))
        }

        let mut packets: Vec<Packet> = Vec::new();
        loop {
            if bytes.fill_buf()?.len() == 0 {
                break;
            }

            packets.push(Packet::from_bytes(bytes).context("Failed to read packet from bitstream")?);
        }

        Ok(Bitstream{packets: packets})
    }
}

impl ToBytes for Bitstream {
    fn to_bytes(&self, writer: &mut Write) -> Result<(), Error> {
        writer.write_all(&Self::BIT_WIDTH_DETECTION_PATTERN).context("I/O error while writing bitstream bit width detection pattern")?;
        writer.write_all(&Self::SYNC_WORD).context("I/O error while writing bitstream sync word")?;
        for packet in self.packets.iter() {
            packet.to_bytes(writer)?
        }
        Ok(())
    }
}