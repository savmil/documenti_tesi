use ::failure::Error;
use ::packed_struct::prelude::*;
use ::serde::Deserialize;
use ::serde::Deserializer;
use ::serde::Serialize;
use ::serde::Serializer;
use ::serde::de::Error as SerdeError;
use ::serde::de::Unexpected;
use ::std::fmt;
use ::std::str::FromStr;

#[derive(Clone, Copy, Debug, Default, PartialEq, PackedStruct)]
#[packed_struct(size_bytes="4", bit_numbering="lsb0", endian="msb")]
pub struct IdCode {
    #[packed_field(bits="0")]
    pub _reserved: ReservedOnes<packed_bits::Bits1>,

    #[packed_field(bits="11:1")]
    pub manufacturer_id: Integer<u16, packed_bits::Bits11>,

    #[packed_field(bits="16:12")]
    pub device: Integer<u8, packed_bits::Bits5>,

    #[packed_field(bits="20:17")]
    pub subfamily: Integer<u8, packed_bits::Bits4>,

    #[packed_field(bits="27:21")]
    pub family: Integer<u8, packed_bits::Bits7>,

    #[packed_field(bits="31:28")]
    pub version: Integer<u8, packed_bits::Bits4>,
}

impl fmt::LowerHex for IdCode {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", ::hex::encode(self.pack()))
    }
}

impl FromStr for IdCode {
    type Err = Error;

    fn from_str(src: &str) -> Result<Self, Self::Err> {
        let bytes = ::hex::decode(src)?;
        Ok(IdCode::unpack_from_slice(bytes.as_slice())?)
    }
}

impl Serialize for IdCode {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where S: Serializer
    {
        serializer.serialize_str(&format!("{:x}", self))
    }
}

impl<'de> Deserialize<'de> for IdCode {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>
    {
        let value_string = String::deserialize(deserializer)?;
        match Self::from_str(value_string.as_str()) {
            Ok(value) => Ok(value),
            Err(_) => Err(D::Error::invalid_value(Unexpected::Str(value_string.as_str()), &"Device IDCODE in hexadecimal"))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn idcode_from_str() {
        let idcode = IdCode::from_str("0362c093").expect("IdCode failed to parse");
        assert_eq!(*idcode.manufacturer_id, 0x49);
        assert_eq!(*idcode.family, 0x1B);
        assert_eq!(*idcode.subfamily, 0x1);
        assert_eq!(*idcode.device, 0x0C);
        assert_eq!(*idcode.version, 0);
    }

    #[test]
    fn idcode_serialization() {
        use ::serde_test::{Token, assert_tokens};

        let idcode = IdCode {
            manufacturer_id: 0x49.into(),
            family: 0x1B.into(),
            subfamily: 0x1.into(),
            device: 0x0C.into(),
            version: 0.into(),
            .. IdCode::default()
        };

        assert_tokens(&idcode, &[Token::String("0362c093")])
    }
}