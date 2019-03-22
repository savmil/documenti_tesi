use ::failure::Error;
use ::std::collections::BTreeMap;
use ::std::fmt;
use ::std::ops::Index;
use ::std::ops::IndexMut;
use super::Bitstream;
use super::DeviceDefinition;
use super::FrameAddress;
use super::FromWord;
use super::Opcode;
use super::Packet;
use super::RegisterAddress;
use super::Word;
use super::frame_address::BlockType;
use super::frame_address::DeviceHalf;
use super::registers;

#[derive(Constructor, From)]
pub struct Frame([Word; 101]);

impl Frame {
    pub fn from_words<T>(iter: T) -> Result<Self, Error>
    where
        T: Iterator<Item=Word>
    {
        let mut frame = Self::default();
        for (idx, word) in iter.enumerate() {
            if idx > 101 {
                return Err(format_err!("Too many words to create a frame"));
            }
            frame[idx] = word;
        }
        Ok(frame)
    }
}

impl Default for Frame {
    fn default() -> Self {
        Frame([0u32; 101])
    }
}

impl<I> Index<I> for Frame
where
    [Word]: Index<I>
{
    type Output = <[Word] as Index<I>>::Output;
    fn index(&self, idx: I) -> &Self::Output {
        <[Word] as Index<I>>::index(&self.0, idx)
    }
}

impl<I> IndexMut<I> for Frame
where
    [Word]: IndexMut<I>
{
    fn index_mut(&mut self, idx: I) -> &mut Self::Output {
        <[Word] as IndexMut<I>>::index_mut(&mut self.0, idx)
    }
}

impl fmt::Debug for Frame {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        writeln!(f, "")?;
        for (row, payload_line) in self.0.chunks(4).enumerate() {
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
}

#[derive(Debug)]
pub struct Configuration {
    device: DeviceDefinition,
    frames: BTreeMap<FrameAddress, Frame>,
}

impl Configuration {
    pub fn from_bitstream_for_device(bitstream: &Bitstream, device_def: &DeviceDefinition) -> Result<Self, Error>
    {
        let mut cmd_reg = registers::CommandRegister::default();
        let mut far_reg = registers::FrameAddressRegister::default();
        let mut mask_reg = registers::MaskRegister::default();
        let mut ctl1_reg = registers::ControlRegister1::default();

        let mut next_frame_write_address = FrameAddress::default();
        let mut last_register_address = RegisterAddress::default();
        let mut load_far_on_next_fdri = false;
        let mut idcode_matched = false;
        let mut config_frames = BTreeMap::<FrameAddress, Frame>::new();
        for packet in bitstream.iter() {
            match packet {
                Packet::Type1{
                    opcode: _,
                    address,
                    payload: _,
                } => last_register_address = *address,
                _ => (),
            }

            match packet {
                Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::IDCODE,
                    payload,
                } => {
                    let idcode = registers::IdCodeRegister::from_word(payload[0])?;
                    idcode_matched = idcode == device_def.idcode;
                    if !idcode_matched {
                        return Err(format_err!("Bitstream has wrong IDCODE expected={:x} actual={:x}", device_def.idcode, idcode));
                    }
                },
                Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::CTL1,
                    payload,
                } => {
                    ctl1_reg = registers::ControlRegister1::from_word(payload[0] & mask_reg.value)?
                },
                Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::MASK,
                    payload,
                } => {
                    mask_reg = registers::MaskRegister::from_word(payload[0])?;
                    },
                Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::CMD,
                    payload,
                } => {
                    cmd_reg = registers::CommandRegister::from_word(payload[0])?;
                    if cmd_reg.command == registers::Command::WriteConfigData {
                        load_far_on_next_fdri = true;
                    }
                },
                Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::FAR,
                    payload,
                } => {
                    far_reg = registers::FrameAddressRegister::from_word(payload[0])?;

                    // Per UG470, the last command written to CMD is re-executed
                    // each time FAR is written. In PERFRAMECRC bitstreams, FAR
                    // is loaded once to start the write and then each frame is
                    // sent individually to FDRI. FAR is also written after each
                    // FDRI to mark progress. These latter writes to FAR do not
                    // appear to alter the auto-incremented frame address. This
                    // difference in behavior seems to be controlled by an
                    // undocumented bit in CTRL1 that inhibits CMD re-execution
                    // during writes to FAR.
                    if !ctl1_reg.inhibit_cmd_reexec_on_far_write && cmd_reg.command == registers::Command::WriteConfigData {
                        load_far_on_next_fdri = true;
                    }
                },
                Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::FDRI,
                    payload,
                } if idcode_matched => {
                    if load_far_on_next_fdri {
                        next_frame_write_address = far_reg;
                        load_far_on_next_fdri = false;
                    }

                    let mut frame_address_iter = device_def.config_mem_layout.iter();
                    let mut frame_address_iter = frame_address_iter.skip_past(&next_frame_write_address);

                    let mut frame_chunk_iter = payload.chunks(101);
                    loop {
                        let current_address = next_frame_write_address;

                        let frame_chunk = match frame_chunk_iter.next() {
                            Some(x) => x,
                            None => break
                        };

                        let mut frame_words = [0u32; 101];
                        frame_words.copy_from_slice(frame_chunk);
                        config_frames.insert(current_address, Frame(frame_words));
                        debug!("Wrote {:p}", current_address);

                        next_frame_write_address = match frame_address_iter.next() {
                            Some(x) if !current_address.in_same_row(&x) => {
                                debug!("Skipping row switch padding");
                                frame_chunk_iter.next();
                                frame_chunk_iter.next();
                                x
                            },
                            Some(x) => x,
                            None => {
                                debug!("Skipping row switch padding at end of config mem");
                                frame_chunk_iter.next();
                                frame_chunk_iter.next();
                                current_address
                            },
                        };
                    }
                },
                Packet::Type2{
                    opcode: Opcode::Write,
                    payload,
                } if idcode_matched && last_register_address == RegisterAddress::FDRI => {
                    if load_far_on_next_fdri {
                        next_frame_write_address = far_reg;
                        load_far_on_next_fdri = false;
                    }

                    let mut frame_address_iter = device_def.config_mem_layout.iter();
                    let mut frame_address_iter = frame_address_iter.skip_past(&next_frame_write_address);

                    let mut frame_chunk_iter = payload.chunks(101);
                    loop {
                        let current_address = next_frame_write_address;

                        let frame_chunk = match frame_chunk_iter.next() {
                            Some(x) => x,
                            None => break
                        };

                        let mut frame_words = [0u32; 101];
                        frame_words.copy_from_slice(frame_chunk);
                        config_frames.insert(current_address, Frame(frame_words));

                        next_frame_write_address = match frame_address_iter.next() {
                            Some(x) if !current_address.in_same_row(&x) => {
                                debug!("Skipping row switch padding");
                                frame_chunk_iter.next();
                                frame_chunk_iter.next();
                                x
                            },
                            Some(x) => x,
                            None => {
                                debug!("Skipping row switch padding at end of config mem");
                                frame_chunk_iter.next();
                                frame_chunk_iter.next();
                                current_address
                            },
                        };
                    }

                    next_frame_write_address = frame_address_iter.next().unwrap_or_default();
                },
                Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::LOUT,
                    payload,
                } => {
                    debug!("LOUT {:p}", FrameAddress::from_word(payload[0])?);
                },
                _ => continue,
            }
        }

        Ok(Configuration{
            device: device_def.clone(),
            frames: config_frames,
        })
    }

    pub fn set_frame(&mut self, address: &FrameAddress, frame: Frame) -> Result<(), Error>
    {
        if !self.device.config_mem_layout.contains(address) {
            return Err(format_err!("Attempt to set frame address that does not exist in target device"));
        }

        self.frames.insert(*address, frame);
        Ok(())
    }
}

impl Into<Bitstream> for Configuration {
    fn into(self) -> Bitstream {
        let mut packets = Vec::new();

        packets.push(Packet::nop());

        packets.push(Packet::from(registers::WatchdogTimerRegister{
            timer_user_mon: false,
            timer_cfg_mon: false,
            timer_val: 0.into(),
        }));
        packets.push(Packet::from(registers::WarmBootStartAddressRegister{
            rs: 0.into(),
            rs_ts_b: false,
            start_addr: 0.into(),
        }));
        packets.push(Packet::from(registers::CommandRegister{
            command: registers::Command::Null,
        }));
        packets.push(Packet::nop());

        packets.push(Packet::from(registers::CommandRegister{
            command: registers::Command::ResetCrc,
        }));
        packets.push(Packet::nop());
        packets.push(Packet::nop());

        packets.push(Packet::from(registers::ConfigurationOptionsRegister0{
            pwrdwn_stat: false,
            done_pipe: true,
            drive_done: false,
            single: false,
            oscfsel: 0.into(),
            ssclksrc_jtag: false,
            ssclksrc_user: false,
            done_cycle: registers::StartupPhaseKeep::Phase3,
            match_cycle: registers::StartupPhaseNoWait::NoWait,
            lock_cycle: registers::StartupPhaseNoWait::NoWait,
            gts_cycle: registers::StartupPhaseTracksDone::Phase5,
            gwe_cycle: registers::StartupPhaseTracksDone::Phase6,
        }));
        packets.push(Packet::from(registers::ConfigurationOptionsRegister1{
            persist_deassert_at_desync: false,
            rb_crc_action: registers::RbCrcAction::Continue,
            rb_crc_no_pin: false,
            rb_crc_en: false,
            bpi_first_read_cycle: 0.into(),
            bpi_page_size: registers::BpiPageSize::OneBytePerWord,
        }));
        packets.push(Packet::from(self.device.idcode));
        packets.push(Packet::from(registers::CommandRegister{
            command: registers::Command::Switch,
        }));
        packets.push(Packet::nop());

        packets.push(Packet::from(registers::MaskRegister{
            value: 0x401,
        }));
        packets.push(Packet::from(registers::ControlRegister0{
            efuse_key: false,
            icap_select:false,
            over_temp_power_down: false,
            config_fallback: true,
            glutmask_b: true,
            farsrc: false,
            dec: false,
            writes_disabled: false,
            reads_disabled: false,
            persist: false,
            gts_usr_b: true,
        }));
        packets.push(Packet::from(registers::MaskRegister{
            value: 0x0,
        }));
        packets.push(Packet::from(registers::ControlRegister1{
            inhibit_cmd_reexec_on_far_write: false,
        }));
        packets.append(&mut vec![Packet::nop(); 8]);

        // Frames can be grouped into a single write where the address is
        // autoincremented for each frame. Doing so requires that there are no
        // gaps in the frame addresses we wish to write.
        let mut frame_address_iter = None;
        let mut fdri_payload = Vec::<Word>::new();
        let mut last_address: Option<FrameAddress> = None;
        for (addr, frame) in self.frames.iter() {
            frame_address_iter = match frame_address_iter {
                None => {
                    packets.push(Packet::from(*addr));
                    packets.push(Packet::from(registers::CommandRegister{
                        command: registers::Command::WriteConfigData,
                    }));
                    packets.push(Packet::nop());

                    Some(self.device.config_mem_layout.iter().skip_past(addr))
                },
                Some(mut x) => {
                    let next_addr_in_device = x.next().expect("Write past last address in device");

                    // Was the last frame written the end of a row? `addr`
                    // doesn't tell us as the frame data to be written may have
                    // a gap. Instead, look at the next address in the device's
                    // address space.
                    match last_address {
                        Some(x) if !x.in_same_row(&next_addr_in_device) => {
                            // Include 2 frames of zero-filled padding at the end of a row.
                            fdri_payload.extend_from_slice(&[0u32; 202]);
                        },
                        _ => (),
                    }

                    // If the next address to write is _not_ the next address in
                    // the device, a new FDRI write needs to be started.
                    if next_addr_in_device != *addr {
                        // Small payloads can fit in a Type1 packet but larger
                        // payloads need a combination of a zero-length Type1 to
                        // set the register address and a Type2 to carry the
                        // actual data.
                        if fdri_payload.len() > 2048 {
                            packets.push(Packet::Type1{
                                opcode: Opcode::Write,
                                address: RegisterAddress::FDRI,
                                payload: fdri_payload,
                            });
                            fdri_payload = Vec::new();
                        } else {
                            packets.push(Packet::Type1{
                                opcode: Opcode::Write,
                                address: RegisterAddress::FDRI,
                                payload: Vec::new(),
                            });
                            packets.push(Packet::Type2{
                                opcode: Opcode::Write,
                                payload: fdri_payload,
                            });
                            fdri_payload = Vec::new();
                        }
                        packets.push(Packet::from(*addr));
                        packets.push(Packet::nop());

                        Some(x.skip_past(addr))
                    } else {
                        Some(x)
                    }
                }
            };
            fdri_payload.extend_from_slice(&frame.0);
            last_address = Some(*addr);
        }

        if let (Some(mut iter), Some(last)) = (frame_address_iter, last_address) {
            match iter.next() {
                Some(ref next) if last.in_same_row(next) => (),
                _ => {
                    // Include 2 frames of zero-filled padding at the end of a row.
                    fdri_payload.extend_from_slice(&[0u32; 202]);
                }
            }

        }

        if !fdri_payload.is_empty() {
            // Small payloads can fit in a Type1 packet but larger
            // payloads need a combination of a zero-length Type1 to
            // set the register address and a Type2 to carry the
            // actual data.
            if fdri_payload.len() < 2048 {
                packets.push(Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::FDRI,
                    payload: fdri_payload,
                });
            } else {
                packets.push(Packet::Type1{
                    opcode: Opcode::Write,
                    address: RegisterAddress::FDRI,
                    payload: Vec::new(),
                });
                packets.push(Packet::Type2{
                    opcode: Opcode::Write,
                    payload: fdri_payload,
                });
            }
        }

        packets.push(Packet::nop());
        packets.push(Packet::nop());

        packets.push(Packet::from(registers::CommandRegister{
            command: registers::Command::PulseGrestore,
        }));
        packets.push(Packet::nop());

        packets.push(Packet::from(registers::CommandRegister{
            command: registers::Command::LastFrame,
        }));
        packets.append(&mut vec![Packet::nop(); 100]);

        packets.push(Packet::from(registers::CommandRegister{
            command: registers::Command::Start,
        }));
        packets.push(Packet::nop());

        packets.push(Packet::from(registers::FrameAddressRegister{
            block_type: BlockType::Unknown,
            device_half: DeviceHalf::Top,
            row: 31.into(),
            column: 0u16.into(),
            minor: 0.into(),
        }));
        packets.push(Packet::from(registers::MaskRegister{
            value: 0x501,
        }));
        packets.push(Packet::from(registers::ControlRegister0{
            efuse_key: false,
            icap_select:false,
            over_temp_power_down: false,
            config_fallback: true,
            glutmask_b: true,
            farsrc: false,
            dec: false,
            writes_disabled: false,
            reads_disabled: false,
            persist: false,
            gts_usr_b: true,
        }));
        packets.push(Packet::nop());
        packets.push(Packet::nop());

        packets.push(Packet::from(registers::CommandRegister{
            command: registers::Command::Desync,
        }));
        packets.append(&mut vec![Packet::nop(); 400]);

        Bitstream{ packets }
    }
}