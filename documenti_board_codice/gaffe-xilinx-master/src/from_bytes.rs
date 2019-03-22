//! Traits and helpers for reading/writing binary formats to objects.

use ::failure::Error;
use ::failure::ResultExt;
use ::std::io::prelude::*;
use ::packed_struct::PackedStructSlice;

/// `FromBytes` indicates that the type can be directly translated from a
/// byte-oriented format. This is primarily used for types that represent
/// structures used in a wire format.
pub trait FromBytes: Sized {
    /// Read an instance of this type from the reader.
    ///
    /// If successful, an instance of this type is returned and the reader now
    /// points to the byte immediately following the returned object. If an
    /// error occurs, the error is returned and reader is left in an
    /// indeterminate state.
    fn from_bytes(reader: &mut BufRead) -> Result<Self, Error>;
}

impl<T> FromBytes for T
where
    T: PackedStructSlice
{
    fn from_bytes(reader: &mut BufRead) -> Result<Self, Error> {
        let mut packed_bytes = vec![0u8; Self::packed_bytes()];
        reader.read_exact(&mut packed_bytes)?;
        Ok(Self::unpack_from_slice(&packed_bytes).context("parse error")?)
    }
}

/// `ToBytes` indicates that the type can be directly translated to a
/// byte-oriented format. This is primarily used for types that represent
/// structures used in a wire format.
pub trait ToBytes: Sized {
    /// Write an instance of this type to the writer.
    ///
    /// If an error occurs, the error is returned and writer is left in an
    /// indeterminate state.
    fn to_bytes(&self, writer: &mut Write) -> Result<(), Error>;
}

impl<T> ToBytes for T
where
    T: PackedStructSlice
{
    fn to_bytes(&self, writer: &mut Write) -> Result<(), Error>
    {
        let mut packed_bytes = vec![0u8; Self::packed_bytes()];
        self.pack_to_slice(&mut packed_bytes).context("Error packing struct")?;
        Ok(writer.write_all(&packed_bytes).context("I/O error while writing packed struct as bytes")?)
    }
}

/// Extension to `std::io::BufRead` providing convenience methods for operations
/// commonly used when reading binary formats.
pub trait BufReadFromBytesExt: BufRead {
    /// Consume bytes from this reader until `pattern` has been consumed.
    ///
    /// If `pattern` is found, true is returned and the reader has been
    /// advanced to the byte immediately following the last byte of `pattern`.
    /// Otherwise, returns false and the reader is at EOF.
    /// 
    /// # Errors
    /// 
    /// This function will ignore all instances of [`ErrorKind::Interrupted`] and
    /// will otherwise return any errors returned by [`BufRead::fill_buf`].
    /// 
    /// [`BufRead::fill_buf`]: trait.BufRead.html#method.fill_buf
    /// [`ErrorKind::Interrupted`]: enum.ErrorKind.html#variant.Interrupted
    /// 
    fn skip_until_match(&mut self, pattern: &[u8]) -> Result<bool, Error>
    {
        loop {
            let (done, used) = {
                let available = match self.fill_buf() {
                    Ok(n) => n,
                    Err(ref e) if e.kind() == ::std::io::ErrorKind::Interrupted => continue,
                    Err(e) => return Err(e.into())
                };
                
                match ::twoway::find_bytes(available, pattern) {
                    Some(index) => (true, index + pattern.len()),
                    None => (false, available.len() - pattern.len())
                }
            };
            self.consume(used);
            if done || used == 0 {
                return Ok(done);
            }
        }
    }
}

impl<T: BufRead> BufReadFromBytesExt for T {}