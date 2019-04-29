use super::IdCode;
use super::frame_address;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceDefinition {
    pub name: String,
    pub idcode: IdCode,

    pub config_mem_layout: frame_address::Set,
}