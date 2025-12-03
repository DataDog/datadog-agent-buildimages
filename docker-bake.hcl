variable "versions" {
  type = map(string)
  default = {
    GO_VERSION          = "1.24.9"
    MSGO_PATCH          = "1" // Patch version of the Microsoft Go distribution
    PY3_VERSION         = "3.12.6"
    CONDA_VERSION       = "4.9.2-7"
    BAZELISK_VERSION    = "1.27.0"
    DDA_VERSION         = "v0.29.0"
    CMAKE_VERSION       = "3.30.2"
    CTNG_VERSION        = "1.26.0"
    RUST_VERSION        = "1.91.0"
    RVM_VERSION         = "1.29.12"
    RUSTUP_VERSION      = "1.26.0"
    BUNDLER_VERSION     = "2.4.20"
    VAULT_VERSION       = "1.17.2"
    DATADOG_CI_VERSION  = "3.9.0"
    PROTOBUF_VERSION    = "29.3"
    AWSCLI_VERSION      = "2.27.30"
    DPKG_ARMHF_VERSION  = "1.18.4"
    DATADOG_PACKAGES_VERSION = "bb430d549b551c0aeb466f3f38470971dabdef2c"
    PULUMI_VERSION         = "3.207.0"
  }
}
// NOTE: Glibc versions are different for amd64 and arm64 and thus are defined in the architecture_defs variables

variable "checksums_common" {
  type = map(string)
  default = {
    DPKG_ARMHF_SHA256  = "19f332e26d40ee45c976ff9ef1a3409792c1f303acff714deea3b43bb689dc41"
    RVM_SHA256         = "fea24461e98d41528d6e28684aa4c216dbe903869bc3fcdb3493b6518fae2e7e"
    PULUMI_SHA256      = "1fe472a5915b416299df9a1b490e7e6d573d3c9f41c662ff4322a79bf4bf0550"
  }
}

variable "checksums_amd64" {
  type = map(string)
  default = {
    GO_SHA256                = "5b7899591c2dd6e9da1809fde4a2fad842c45d3f6b9deb235ba82216e31e34a6"
    MSGO_SHA256              = "1d54fded463be66d6ccfd95379de86f11fa9da7686ed3cfc05d59e87d9248f50"
    CONDA_SHA256             = "91d5aa5f732b5e02002a371196a2607f839bab166970ea06e6ecc602cb446848"
    BAZELISK_SHA256          = "e1508323f347ad1465a887bc5d2bfb91cffc232d11e8e997b623227c6b32fb76"
    CMAKE_SHA256_AMD64       = "33f5a7680578481ce0403dc5a814afae613f2f6f88d632a3bda0f7ff5f4dedfc"
    CMAKE_SHA256_ARM64       = "8a6636e72a6ddfe50e0087472bff688f337df48b00a7728b12d7b70b5b459fc5"
    RUSTUP_SHA256            = "0b2f6c8f85a3d02fde2efc0ced4657869d73fccfce59defb4e8d29233116e6db"
    VAULT_SHA256             = "a0c0449e640c8be5dcf7b7b093d5884f6a85406dbb86bbad0ea06becad5aaab8"
    DATADOG_CI_SHA256        = "1b62407af5d4e99827a6903a0e893a17cadf94d1da42e86a76fb5f2b44b2a1e5"
    PROTOBUF_SHA256          = "3e866620c5be27664f3d2fa2d656b5f3e09b5152b42f1bedbf427b333e90021a"
    AWSCLI_SHA256            = "2bda389190cf1509584e1bcfb6c9ffe4343ffb1804cf8a9cd96ed874870f7f94"
  }
}

variable "checksums_arm64" {
  type = map(string)
  default = {
    GO_SHA256                = "9aa1243d51d41e2f93e895c89c0a2daf7166768c4a4c3ac79db81029d295a540"
    MSGO_SHA256              = "62cbf3028a86e5fa75032c7ce6249cc002aa7ea70151789c9e25b34c64f4e329"
    CONDA_SHA256             = "ea7d631e558f687e0574857def38d2c8855776a92b0cf56cf5285bede54715d9"
    BAZELISK_SHA256          = "bb608519a440d45d10304eb684a73a2b6bb7699c5b0e5434361661b25f113a5d"
    CMAKE_SHA256_AMD64       = "33f5a7680578481ce0403dc5a814afae613f2f6f88d632a3bda0f7ff5f4dedfc"
    CMAKE_SHA256_ARM64       = "8a6636e72a6ddfe50e0087472bff688f337df48b00a7728b12d7b70b5b459fc5"
    RUSTUP_SHA256            = "673e336c81c65e6b16dcdede33f4cc9ed0f08bde1dbe7a935f113605292dc800"
    VAULT_SHA256             = "1cdfd33e218ef145dbc3d71ac4164b89e453ff81b780ed178274bc1ba070e6e9"
    DATADOG_CI_SHA256        = "abb2ef649b3407496fbcf9b634a4b1dbe5f6d5141e273d7fdf272a3e4bc3de4d"
    PROTOBUF_SHA256          = "6427349140e01f06e049e707a58709a4f221ae73ab9a0425bc4a00c8d0e1ab32"
    AWSCLI_SHA256            = "cdb480c2f6e1ff2bb0ac234da4ee121c7864d58b2aeddec0e5449a66dc1efc2c"
  }
}

variable "architecture_defs_amd64" {
  type = map(string)
  default = {
    DATADOG_CI_ARCH      = "x64"
    ARCH                 = "x86_64"
    CTNG_ARCH            = "x86_64"
    CTNG_CROSS_ARCH      = "aarch64"
    AWSCLI_ARCH          = "x86_64"
    RUSTUP_ARCH          = "x86_64"
    GO_ARCH              = "amd64"
    CONDA_ARCH           = "x86_64"
    BAZELISK_ARCH        = "amd64"
    VAULT_ARCH           = "amd64"
    PROTOBUF_ARCH        = "x86_64"
    GLIBC_VERSION        = "2.17"
    CROSS_GLIBC_VERSION  = "2.23"
  }
}

variable "architecture_defs_arm64" {
  type = map(string)
  default = {
    DATADOG_CI_ARCH      = "arm64"
    ARCH                 = "aarch64"
    CTNG_ARCH            = "aarch64"
    CTNG_CROSS_ARCH      = "x86_64"
    AWSCLI_ARCH          = "aarch64"
    RUSTUP_ARCH          = "aarch64"
    GO_ARCH              = "arm64"
    CONDA_ARCH           = "aarch64"
    BAZELISK_ARCH        = "arm64"
    VAULT_ARCH           = "arm64"
    PROTOBUF_ARCH        = "aarch_64"
    GLIBC_VERSION        = "2.23"
    CROSS_GLIBC_VERSION  = "2.17"
  }
}

variable "misc_args_amd64" {
  type = map(string)
  default = {
    ADDITIONAL_PACKAGE  = "libc6-dev-i386"
  }
}

variable "misc_args_arm64" {
  type = map(string)
  default = {
  }
}

// AMD64 architecture specific arguments
variable "args_amd64" {
  type = map(string)
  default = merge(
    versions,
    checksums_common,
    architecture_defs_amd64,
    checksums_amd64,
    misc_args_amd64,
  )
}

// ARM64 architecture specific arguments
variable "args_arm64" {
  type = map(string)
  default = merge(
    versions,
    checksums_common,
    architecture_defs_arm64,
    checksums_arm64,
    misc_args_arm64,
  )
}

// Target for AMD64 architecture
target "linux-amd64" {
  dockerfile = "linux/Dockerfile"
  context    = "./"
  platforms  = ["linux/amd64"]
  args       = args_amd64
  tags       = ["datadog/agent-buildimages-linux:amd64"]
}

// Target for ARM64 architecture
target "linux-arm64" {
  dockerfile = "linux/Dockerfile"
  context    = "./"
  platforms  = ["linux/arm64"]
  args       = args_arm64
  tags       = ["datadog/agent-buildimages-linux:arm64"]
}

// Group to build both architectures
group "linux" {
  targets = ["linux-amd64", "linux-arm64"]
}

// Default group
group "default" {
  targets = ["linux"]
}
