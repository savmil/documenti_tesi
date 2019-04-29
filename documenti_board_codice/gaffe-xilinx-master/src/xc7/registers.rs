use ::packed_struct::prelude::*;
use super::RegisterAddress;

pub trait Register {
    fn register_address(&self) -> RegisterAddress;
}

#[derive(Debug, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct CrcRegister{
    #[packed_field(bits="31:0")]
    pub crc: u32,
}

impl Register for CrcRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::CRC
    }
}

pub use super::frame_address::FrameAddress as FrameAddressRegister;

impl Register for FrameAddressRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::FAR
    }
}

#[derive(Debug, Clone, Copy, PartialEq, PrimitiveEnum, SmartDefault)]
pub enum Command {
    #[default]
    Null = 0b00000,
    WriteConfigData = 0b00001,
    MultipleFrameWrite = 0b00010,
    LastFrame = 0b00011,
    ReadConfigData = 0b00100,
    Start = 0b00101,
    ResetCapture = 0b00110,
    ResetCrc = 0b00111,
    AssertGhigh = 0b01000,
    Switch = 0b01001,
    PulseGrestore = 0b01010,
    Shutdown = 0b01011,
    PulseGcapture = 0b01100,
    Desync = 0b01101,
    InternalProg = 0b01111,
    CrcCalculate = 0b10000,
    ReloadWatchdog = 0b10001,
    BspiRead = 0b10010,
    FallEdge = 0b10011,
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct CommandRegister {
    #[packed_field(bits="4:0", ty="enum")]
    pub command: Command,
}

impl Register for CommandRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::CMD
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct ControlRegister0 {
    #[packed_field(bits="31")]
    pub efuse_key: bool,

    #[packed_field(bits="30")]
    pub icap_select: bool,

    #[packed_field(bits="12")]
    pub over_temp_power_down: bool,

    #[packed_field(bits="10")]
    pub config_fallback: bool,

    #[packed_field(bits="8")]
    pub glutmask_b: bool,

    #[packed_field(bits="7")]
    pub farsrc: bool,

    #[packed_field(bits="6")]
    pub dec: bool,

    /// When set, both reads and writes are disabled when encrypted bitstreams are used.
    #[packed_field(bits="5")]
    pub writes_disabled: bool,

    #[packed_field(bits="4")]
    pub reads_disabled: bool,

    #[packed_field(bits="3")]
    pub persist: bool,

    #[packed_field(bits="0")]
    pub gts_usr_b: bool
}

impl Register for ControlRegister0 {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::CTL0
    }
}

#[derive(Debug, Clone, Copy, PrimitiveEnum, SmartDefault)]
#[allow(non_camel_case_types)]
pub enum BusWidth {
    #[default]
    x1 = 0b00,
    x8 = 0b01,
    x16 = 0b10,
    x32 = 0b11,
}

#[derive(Debug, Clone, Copy, PrimitiveEnum, SmartDefault)]
pub enum StartupPhaseStatus {
    #[default]
    Phase0 = 0b000,
    Phase1 = 0b001,
    Phase2 = 0b011,
    Phase3 = 0b010,
    Phase4 = 0b110,
    Phase5 = 0b111,
    Phase6 = 0b101,
    Phase7 = 0b100,
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct StatusRegister {
    #[packed_field(bits="26:25", ty="enum")]
    pub bus_width: BusWidth,

    #[packed_field(bits="20:18", ty="enum")]
    pub startup_state: StartupPhaseStatus,

    #[packed_field(bits="16")]
    pub dec_error: bool,

    #[packed_field(bits="15")]
    pub id_error: bool,

    #[packed_field(bits="14")]
    pub done: bool,

    #[packed_field(bits="13")]
    pub release_done: bool,

    #[packed_field(bits="12")]
    pub init_b: bool,

    #[packed_field(bits="11")]
    pub init_complete: bool,

    #[packed_field(bits="10:8")]
    pub mode: Integer<u8, packed_bits::Bits3>,

    #[packed_field(bits="7")]
    pub ghigh_b: bool,

    #[packed_field(bits="6")]
    pub gwe: bool,

    #[packed_field(bits="5")]
    pub gts_cfg_b: bool,

    #[packed_field(bits="4")]
    pub eos: bool,

    #[packed_field(bits="3")]
    pub dci_match: bool,

    #[packed_field(bits="2")]
    pub mmcm_lock: bool,

    #[packed_field(bits="1")]
    pub part_secured: bool,

    #[packed_field(bits="0")]
    pub crc_error: bool,
}

impl Register for StatusRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::STAT
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct LoutRegister{
    #[packed_field(bits="31:0")]
    pub value: u32,
}

impl Register for LoutRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::LOUT
    }
}

#[derive(Debug, Clone, Copy, PrimitiveEnum, SmartDefault)]
pub enum StartupPhaseKeep {
    #[default]
    Phase0 = 0b000,
    Phase1 = 0b001,
    Phase2 = 0b010,
    Phase3 = 0b011,
    Phase4 = 0b100,
    Phase5 = 0b101,
    Phase6 = 0b110,
    Keep = 0b111,
}

#[derive(Debug, Clone, Copy, PrimitiveEnum, SmartDefault)]
pub enum StartupPhaseNoWait {
    #[default]
    Phase0 = 0b000,
    Phase1 = 0b001,
    Phase2 = 0b010,
    Phase3 = 0b011,
    Phase4 = 0b100,
    Phase5 = 0b101,
    Phase6 = 0b110,
    NoWait = 0b111,
}

#[derive(Debug, Clone, Copy, PrimitiveEnum, SmartDefault)]
pub enum StartupPhaseTracksDone {
    #[default]
    Phase1 = 0b000,
    Phase2 = 0b001,
    Phase3 = 0b010,
    Phase4 = 0b011,
    Phase5 = 0b100,
    Phase6 = 0b101,
    TracksDone = 0b110,
    Keep = 0b111,
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct ConfigurationOptionsRegister0 {
    #[packed_field(bits="27")]
    pub pwrdwn_stat: bool,

    #[packed_field(bits="25")]
    pub done_pipe: bool,

    #[packed_field(bits="24")]
    pub drive_done: bool,

    #[packed_field(bits="23")]
    pub single: bool,

    #[packed_field(bits="22:17")]
    pub oscfsel: Integer<u8, packed_bits::Bits6>,

    /// Use JTAG clock during startup-sequence.  When set, ssclksrc_user is ignored.
    #[packed_field(bits="16")]
    pub ssclksrc_jtag: bool,

    /// Use user clock during startup-sequence.  When both this and
    /// ssclksrc_jtag are unset, CCLK is used.
    #[packed_field(bits="15")]
    pub ssclksrc_user: bool,

    #[packed_field(bits="14:12", ty="enum")]
    pub done_cycle: StartupPhaseKeep,

    #[packed_field(bits="11:9", ty="enum")]
    pub match_cycle: StartupPhaseNoWait,

    #[packed_field(bits="8:6", ty="enum")]
    pub lock_cycle: StartupPhaseNoWait,

    #[packed_field(bits="5:3", ty="enum")]
    pub gts_cycle: StartupPhaseTracksDone,

    #[packed_field(bits="2:0", ty="enum")]
    pub gwe_cycle: StartupPhaseTracksDone,
}

impl Register for ConfigurationOptionsRegister0 {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::COR0
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct CbcRegister{
    #[packed_field(bits="31:0")]
    pub value: u32,
}

impl Register for CbcRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::CBC
    }
}

pub use super::IdCode as IdCodeRegister;

impl Register for IdCodeRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::IDCODE
    }
}

#[derive(Debug, Clone, Copy, PrimitiveEnum, SmartDefault)]
pub enum RbCrcAction {
    #[default]
    Continue = 0b00,
    Halt = 0b01,
    CorrectAndContinue = 0b10,
    CorrectAndHalt = 0b11,
}

#[derive(Debug, Clone, Copy, PrimitiveEnum, SmartDefault)]
pub enum BpiPageSize {
    #[default]
    OneBytePerWord = 0b00,
    FourBytesPerWord = 0b01,
    EightBytesPerWord = 0b10,
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct ConfigurationOptionsRegister1 {
    #[packed_field(bits="17")]
    pub persist_deassert_at_desync: bool,

    #[packed_field(bits="16:15", ty="enum")]
    pub rb_crc_action: RbCrcAction,

    #[packed_field(bits="9")]
    pub rb_crc_no_pin: bool,

    #[packed_field(bits="8")]
    pub rb_crc_en: bool,

    /// First read cycle is register value plus one.
    #[packed_field(bits="3:2")]
    pub bpi_first_read_cycle: Integer<u8, packed_bits::Bits2>,

    #[packed_field(bits="1:0", ty="enum")]
    pub bpi_page_size: BpiPageSize,
}

impl Register for ConfigurationOptionsRegister1 {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::COR1
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct WarmBootStartAddressRegister {
    #[packed_field(bits="31:30")]
    pub rs: Integer<u8, packed_bits::Bits2>,

    #[packed_field(bits="29")]
    pub rs_ts_b: bool,

    #[packed_field(bits="28:0")]
    pub start_addr: Integer<u32, packed_bits::Bits29>,
}

impl Register for WarmBootStartAddressRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::WBSTAR
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct WatchdogTimerRegister {
    #[packed_field(bits="31")]
    pub timer_user_mon: bool,

    #[packed_field(bits="30")]
    pub timer_cfg_mon: bool,

    #[packed_field(bits="29:0")]
    pub timer_val: Integer<u32, packed_bits::Bits30>,
}

impl Register for WatchdogTimerRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::TIMER
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct BootHistoryStatusRegister {
    #[packed_field(bits="15")]
    pub hmac_error_1: bool,

    #[packed_field(bits="14")]
    pub wrap_error_1: bool,
    
    #[packed_field(bits="13")]
    pub crc_error_1: bool,
    
    #[packed_field(bits="12")]
    pub id_error_1: bool,
    
    #[packed_field(bits="11")]
    pub wto_error_1: bool,
    
    #[packed_field(bits="10")]
    pub iprog_1: bool,
    
    #[packed_field(bits="9")]
    pub fallback_1: bool,
    
    #[packed_field(bits="8")]
    pub valid_1: bool,
    
    #[packed_field(bits="7")]
    pub hmac_error_0: bool,
    
    #[packed_field(bits="6")]
    pub wrap_error_0: bool,
    
    #[packed_field(bits="5")]
    pub crc_error_0: bool,
    
    #[packed_field(bits="4")]
    pub id_error_0: bool,
    
    #[packed_field(bits="3")]
    pub wto_error_0: bool,
    
    #[packed_field(bits="2")]
    pub iprog_0: bool,
    
    #[packed_field(bits="1")]
    pub fallback_0: bool,
    
    #[packed_field(bits="0")]
    pub valid_0: bool,
}

impl Register for BootHistoryStatusRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::BOOTSTS
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct ControlRegister1{
    #[packed_field(bits="21")]
    pub inhibit_cmd_reexec_on_far_write: bool,
}

impl Register for ControlRegister1 {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::CTL1
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct BpiSpiConfigurationOptionsRegister{
    #[packed_field(bits="31:0")]
    pub value: u32,
}

impl Register for BpiSpiConfigurationOptionsRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::BSPI
    }
}

#[derive(Debug, Default, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct MaskRegister{
    #[packed_field(bits="31:0")]
    pub value: u32,
}

impl Register for MaskRegister {
    fn register_address(&self) -> RegisterAddress {
        RegisterAddress::MASK
    }
}