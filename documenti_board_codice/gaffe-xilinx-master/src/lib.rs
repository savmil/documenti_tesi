extern crate byteorder;
#[macro_use]
extern crate derive_more;
#[macro_use]
extern crate failure;
extern crate hex;
#[macro_use]
extern crate log;
extern crate packed_struct;
#[macro_use]
extern crate packed_struct_codegen;
extern crate serde;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate smart_default;
extern crate strum;
#[macro_use]
extern crate strum_macros;
extern crate twoway;

#[cfg(test)]
extern crate serde_test;

pub mod from_bytes;
pub mod xc7;