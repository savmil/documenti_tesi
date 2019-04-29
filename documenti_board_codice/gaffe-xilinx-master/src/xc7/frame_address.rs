use ::serde::Serialize;
use ::serde::Serializer;
use ::serde::Deserialize;
use ::serde::Deserializer;
use ::std::collections::BTreeSet;
use ::std::collections::btree_set;
use ::std::fmt;
use ::std::iter::FromIterator;
use ::std::ops::Add;

#[derive(Clone, Copy, Debug, Display, Deserialize, Serialize, Hash, PartialEq, Eq, PartialOrd, Ord, PrimitiveEnum)]
pub enum DeviceHalf {
    Top = 0,
    Bottom = 1,
}

impl Default for DeviceHalf {
    fn default() -> Self { DeviceHalf::Top }
}

#[derive(Clone, Copy, Debug, Display, Deserialize, Serialize, Hash, PartialEq, Eq, PartialOrd, Ord, PrimitiveEnum)]
#[allow(non_camel_case_types)]
pub enum BlockType {
    CLB_IO_CLK = 0b000,
    BLOCK_RAM = 0b001,
    CFG_CLB = 0b010,
    Reserved = 0b011,
    Unknown = 0b111,
}

impl Default for BlockType {
    fn default() -> Self { BlockType::CLB_IO_CLK }
}

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize, PackedStruct)]
#[packed_struct(size_bytes="4", endian="msb", bit_numbering="lsb0")]
pub struct FrameAddress {
    #[packed_field(bits="25:23", ty="enum")]
    pub block_type: BlockType,
    #[packed_field(bits="22", ty="enum")]
    pub device_half: DeviceHalf,
    #[packed_field(bits="21:17")]
    pub row: u8,
    #[packed_field(bits="16:7")]
    pub column: u16,
    #[packed_field(bits="6:0")]
    pub minor: u8,
}

impl FrameAddress {
    pub fn in_same_row(&self, other: &FrameAddress) -> bool {
        self.block_type == other.block_type && self.device_half == other.device_half && self.row == other.row
    }
}

impl Add<u8> for FrameAddress {
    type Output = Option<FrameAddress>;

    fn add(self, rhs: u8) -> Self::Output {
        if let Some(minor) = self.minor.checked_add(rhs) {
            Some(FrameAddress{minor: minor, .. self})
        } else {
            None
        }
    }
}

impl fmt::Pointer for FrameAddress {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{{{}, {}, {}, {}, {}}}", self.block_type, self.device_half, self.row, self.column, self.minor)
    }
}

#[cfg(test)]
mod tests_frame_address {
    use super::*;
    use ::xc7::FromWord;

    #[test]
    fn add() {
        let initial = FrameAddress::from_word(0u32).expect("FrameAddress from literal");
        match initial + 1 {
            None => panic!("FrameAddress{minor: 0} + 1 yielded no result"),
            Some(x) => assert_eq!(x.minor, 1),
        }
    }

    #[test]
    fn add_overflow_minor() {
        let initial = FrameAddress{minor: 254, ..FrameAddress::default() };
        assert_eq!(initial + 2, None);
    }

    #[test]
    fn in_same_row() {
        let row1 = FrameAddress{row: 1, ..FrameAddress::default()};
        let also_row1 = FrameAddress{row: 1, column:5, ..FrameAddress::default()};
        assert!(row1.in_same_row(&also_row1));

        let row2 = FrameAddress{row: 2, ..FrameAddress::default()};
        assert!(!row1.in_same_row(&row2));

        let other_half = FrameAddress{device_half: DeviceHalf::Bottom, row: 1, ..FrameAddress::default()};
        assert!(!row1.in_same_row(&other_half));

        let other_block_type = FrameAddress{block_type: BlockType::BLOCK_RAM, row: 1, ..FrameAddress::default()};
        assert!(!row1.in_same_row(&other_block_type));
    }

    #[test]
    fn fmt_pointer() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };
        assert_eq!("{BLOCK_RAM, Bottom, 2, 10, 7}", format!("{:p}", frame_addr));
    }
}

/// Frame address space is heavily fragmented due to the geographical addressing
/// scheme used.  In practice, minor address is the only field that is routinely
/// contiguous.  Using start+length format where the length applies only to the
/// minor address provides a compact range representation.
#[derive(Clone, Copy, Debug, Default, Deserialize, Serialize, PartialEq, Eq, PartialOrd, Ord)]
pub struct Range {
    pub start: FrameAddress,
    pub length: u8,
}

impl Range {
    pub fn contains(&self, addr: &FrameAddress) -> bool {
        return addr >= &self.start && addr <= &self.last();
    }

    /// Split off the first address from the range. Returns that address and the
    /// remaining range.
    pub fn first(self) -> (FrameAddress, Option<Range>) {
        if self.length == 1 {
            return (self.start, None)
        } else {
            return (self.start, Some(
                Range{
                    start: (self.start + 1).expect("minor address overflow while splitting off first from range"),
                    length: self.length - 1
                }))
        }
    }

    /// Returns the last valid address covered by this range.
    pub fn last(&self) -> FrameAddress {
        (self.start + (self.length - 1)).expect("minor address overflow while getting last address in range")
    }

    /// Returns an `iter` that yields each `FrameAddress` covered by this range.
    pub fn iter(&self) -> RangeIter {
        RangeIter{
            range: Some(*self)
        }
    }

    /// Extend the range to cover an additional `amount` addresses past the
    /// current range end. If extending by `amount` would overflow the minor
    /// field, None is returned.
    pub fn extend(&self, amount: u8) -> Option<Self> {
        if let Some(length) = self.length.checked_add(amount) {
            Some(Self{length: length, .. *self})
        } else {
            None
        }
    }

    /// Split the range into two ranges around `address`.
    ///
    /// Returns two ranges: `before` and `after`. `Before` is a range from
    /// [self.start, address) while `after` is a range from [address,
    /// self.last()]. If `address` is outside this range, the entire range will
    /// be returned as one of `before` or `after` depending on whether this range
    /// comes before `address` or after.
    pub fn split(self, address: &FrameAddress) -> (Option<Range>, Option<Range>) {
        if *address <= self.start {
            return (None, Some(self))
        } else if self.contains(address) {
            let before = Range{
                start: self.start,
                length: address.minor - self.start.minor
            };
            let after = Range{
                start: *address,
                length: self.last().minor - address.minor + 1,
            };
            return (Some(before), Some(after))
        } else {
            return (Some(self), None)
        }
    }
}

impl fmt::Display for Range {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{:p} - {:p}", self.start, self.last())
    }
}

#[cfg(test)]
mod tests_range {
    use super::*;

    #[test]
    fn contains_start_address() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 5,
        };

        assert!(range.contains(&frame_addr));
    }

    #[test]
    fn contains_address_in_range() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 5,
        };

        assert!(range.contains(&FrameAddress{minor: 9, ..frame_addr}));
    }

    #[test]
    fn contains_end_address() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 5,
        };

        assert!(range.contains(&FrameAddress{minor: 11, ..frame_addr}));
    }

    #[test]
    fn doesnt_contain_less_than() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 5,
        };

        assert!(!range.contains(&FrameAddress{minor: 6, ..frame_addr}));
    }

    #[test]
    fn doesnt_contain_greater_than() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 5,
        };

        assert!(!range.contains(&FrameAddress{minor: 12, ..frame_addr}));
    }

    #[test]
    fn first_with_single_address_range() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 1,
        };

        assert_eq!((frame_addr, None), range.first());
    }

    #[test]
    fn first_with_multi_address_range() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 9,
        };

        let (first, rest) = range.first();
        assert_eq!(frame_addr, first);
        assert_eq!(rest, Some(Range{ start: FrameAddress{ minor: 8, ..frame_addr}, length: 8}));
    }

    #[test]
    fn last() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 9,
        };

        assert_eq!(FrameAddress{ minor: 15, ..frame_addr}, range.last());
    }

    #[test]
    fn extend() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 9,
        };

        assert_eq!(Some(Range{ length: 11, ..range}), range.extend(2));
    }

    #[test]
    fn extend_past_minor_field_fails() {
        let frame_addr = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: frame_addr,
            length: 9,
        };

        assert_eq!(None, range.extend(247));
    }

    #[test]
    fn split() {
        let range_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: range_start,
            length: 9,
        };

        let split_point = FrameAddress{
            minor: 9,
            ..range_start
        };

        let (before, after) = range.split(&split_point);
        assert_eq!(before, Some(Range{start: range_start, length: 2}));
        assert_eq!(after, Some(Range{start: split_point, length: 7}));
    }

    #[test]
    fn split_less_than_start() {
        let range_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: range_start,
            length: 9,
        };

        let split_point = FrameAddress{
            minor: 6,
            ..range_start
        };

        let (before, after) = range.split(&split_point);
        assert_eq!(before, None);
        assert_eq!(after, Some(range));
    }

    #[test]
    fn split_greater_than_start() {
        let range_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: range_start,
            length: 9,
        };

        let split_point = FrameAddress{
            minor: 16,
            ..range_start
        };

        let (before, after) = range.split(&split_point);

        assert_eq!(before, Some(range));
        assert_eq!(after, None);
    }

    #[test]
    fn fmt_display() {
        let range_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: range_start,
            length: 9,
        };

        assert_eq!(format!("{:p} - {:p}", range_start, (range_start + 8).unwrap()), format!("{}", range));
    }
}

/// Iterator that yields each address in a Range
#[derive(Debug, Default)]
pub struct RangeIter
{
    range: Option<Range>,
}

impl Iterator for RangeIter
{
    type Item = FrameAddress;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(range) = self.range {
            let (first, rest) = range.first();
            self.range = rest;
            Some(first)
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests_range_iter {
    use super::*;

    #[test]
    fn next() {
        let range_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range = Range{
            start: range_start,
            length: 2,
        };

        let iter = range.iter();
        for (ii, addr) in iter.enumerate() {
            match ii {
                0...1 => assert_eq!(addr, (range_start + ii as u8).unwrap()),
                _ => panic!("Iterated over more items than expected"),
            }
        }
    }
}

/// Set over FrameAddresses implemented in terms of FrameAddressRanges.  Using
/// ranges allows much more compact expression compared to storing individual
/// FrameAddresses in a HashSet or similar.
#[derive(Debug, Clone, Default)]
pub struct Set {
    ranges: BTreeSet<Range>,
}

impl Set {
    pub fn contains(&self, addr: &FrameAddress) -> bool {
        self.ranges.iter().any(|x| x.contains(addr))
    }

    pub fn iter<'a>(&'a self) -> SetIter<btree_set::Iter<'a, Range>> {
        SetIter{ iter: self.ranges.iter(), range: None }
    }

    pub fn iter_ranges<'a>(&'a self) -> btree_set::Iter<'a, Range> {
        self.ranges.iter()
    }
}

impl fmt::Display for Set {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        for range in self.ranges.iter() {
            writeln!(f, "{}", range)?;
        }
        Ok(())
    }
}

impl FromIterator<FrameAddress> for Set
{
    fn from_iter<T>(iter: T) -> Self
    where
        T: IntoIterator<Item = FrameAddress>
    {
        let unique_addresses = iter.into_iter().collect::<BTreeSet<FrameAddress>>();
        let mut ranges = BTreeSet::<Range>::new();

        // Walk through the unique addresses and merge blocks of contiguous
        // addresses into Ranges.
        let mut cur_range = None;
        for addr in unique_addresses {
            cur_range = match cur_range {
                // No current range so start one.
                None => Some(Range{start: addr, length: 1}),
                // Next address in a contiguous block.  Extend the range.
                Some(range) if range.last() + 1 == Some(addr) => Some(range.extend(1).expect("range expansion failed")),
                // Non-contiguous address. Stash the current range and start a new one.
                Some(range) => {
                    ranges.insert(range);
                    Some(Range{start: addr, length: 1})
                }
            }
        }

        if let Some(range) = cur_range {
            ranges.insert(range);
        }

        Self{ranges: ranges}
    }
}

impl FromIterator<Range> for Set
{
    fn from_iter<T>(iter: T) -> Self
    where
        T: IntoIterator<Item = Range>
    {
        Self{ ranges: iter.into_iter().collect() }
    }
}

// Manually implement serde traits to remove "ranges" as a level in the
// serialized hierarchy.
impl Serialize for Set {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where S: Serializer
    {
        self.ranges.serialize(serializer)
    }
}

impl<'de> Deserialize<'de> for Set {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>
    {
        Ok(Self {
            ranges: BTreeSet::<Range>::deserialize(deserializer)?,
        })
    }
}

#[cfg(test)]
mod tests_set {
    use super::*;

    #[test]
    fn contains() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        assert!(set.contains(&FrameAddress{minor: 8, ..range1_start}));
    }

    #[test]
    fn doesnt_contain_less_than_start() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        assert!(!set.contains(&FrameAddress{minor: 5, ..range1_start}));
    }

    #[test]
    fn doesnt_contain_between_ranges() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        assert!(!set.contains(&FrameAddress{minor: 10, ..range1_start}));
        assert!(!set.contains(&FrameAddress{minor: 5, ..range2_start}));
    }

    #[test]
    fn doesnt_contain_after_end() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        assert!(!set.contains(&FrameAddress{minor: 10, ..range2_start}));
    }

    #[test]
    fn from_iter_frame_address() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let addrs = vec![
            range1_start,
            FrameAddress{minor: 8, ..range1_start},
            range2_start,
            FrameAddress{minor: 8, ..range2_start},
        ];

        let set = Set::from_iter(addrs);
        let mut set_ranges = set.iter_ranges();
        assert_eq!(set_ranges.next(), Some(&Range{ start: range1_start, length: 2}));
        assert_eq!(set_ranges.next(), Some(&Range{ start: range2_start, length: 2}));
    }
}

#[derive(Debug, Clone, Default)]
pub struct SetIter<'a, T>
where
    T: Iterator<Item = &'a Range>  + fmt::Debug + Clone
{
    iter: T,
    range: Option<Range>,
}

impl<'a, T> SetIter<'a, T>
where
    T: Iterator<Item = &'a Range>  + fmt::Debug + Clone
{
    /// Create a new iterator such that next() will return the next valid
    /// address after `address`.
    pub fn skip_past(self, address: &FrameAddress) -> Self {
        let mut skipped_past = self.clone();

        trace!("Skipping past {:p}", *address);
        loop {
            trace!("Top of skip loop: {:#?}", skipped_past.range);
            match skipped_past.range {
                Some(range) if *address < range.start => {
                    trace!("No skip");
                    return skipped_past
                },
                Some(range) if range.contains(address) => {
                    let (_, after) = range.split(address);
                    let (_, after) = after.expect("range containing address failed to split at that address").first();
                    skipped_past.range = after;
                    trace!("skipped in range, ended with: {:#?}", skipped_past.range);
                    return skipped_past
                },
                _ => {
                    if let Some(range) = skipped_past.iter.next() {
                        trace!("Pulled next range");
                        skipped_past.range = Some(*range);
                    } else {
                        trace!("End of iterator");
                        skipped_past.range = None;
                        return skipped_past
                    }
                },
            }
        }
    }
}

impl<'a, T> Iterator for SetIter<'a, T>
where
    T: Iterator<Item = &'a Range>  + fmt::Debug + Clone
{
    type Item = FrameAddress;

    fn next(&mut self) -> Option<Self::Item> {
        trace!("Before iterating: {:#?}", self.range);
        if let Some(range) = self.range {
            let (first, rest) = range.first();
            self.range = rest;
            return Some(first)
        } else if let Some(next_range) = self.iter.next() {
            let (first, rest) = next_range.first();
            self.range = rest;
            return Some(first)
        } else {
            None
        }
    }
}

#[cfg(test)]
mod tests_set_iter {
    use super::*;

    #[test]
    fn next() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);

        let iter = set.iter();
        for (ii, addr) in iter.enumerate() {
            match ii {
                0...1 => assert_eq!(addr, (range1_start + ii as u8).unwrap()),
                2...3 => assert_eq!(addr, (range2_start + (ii as u8 - 2)).unwrap()),
                _ => panic!("Iterated past expected ranges")
            }
        }
    }

    #[test]
    fn skip_past() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        for (ii, addr) in set.iter().skip_past(&range2_start).enumerate() {
            match ii {
                0 => assert_eq!(addr, (range2_start + 1).unwrap()),
                _ => panic!("Iterated past expected ranges")
            }
        }
    }

    #[test]
    fn skip_past_before_start() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        let iter = set.iter().skip_past(&FrameAddress{minor: 6, ..range1_start});
        for (ii, addr) in iter.enumerate() {
            match ii {
                0...1 => assert_eq!(addr, (range1_start + ii as u8).unwrap()),
                2...3 => assert_eq!(addr, (range2_start + (ii as u8 - 2)).unwrap()),
                _ => panic!("Iterated past expected ranges")
            }
        }
    }

    #[test]
    fn skip_past_between_ranges() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        let iter = set.iter().skip_past(&FrameAddress{minor: 10, ..range1_start});
        for (ii, addr) in iter.enumerate() {
            match ii {
                0...1 => assert_eq!(addr, (range2_start + ii as u8).unwrap()),
                _ => panic!("Iterated past expected ranges")
            }
        }
    }

    #[test]
    fn skip_past_after_end() {
        let range1_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 2,
            column: 10,
            minor: 7,
        };

        let range1 = Range{
            start: range1_start,
            length: 2,
        };

        let range2_start = FrameAddress{
            block_type: BlockType::BLOCK_RAM,
            device_half: DeviceHalf::Bottom,
            row: 3,
            column: 10,
            minor: 7,
        };

        let range2 = Range{
            start: range2_start,
            length: 2,
        };

        let set = Set::from_iter(vec![range1, range2]);
        let mut iter = set.iter().skip_past(&FrameAddress{minor: 10, ..range2_start});
        assert_eq!(iter.next(), None);
    }
}