# ====== Build arguments ====== #

# === NOTE ABOUT GO === #
# Everything related to Go is handled in the override file docker-bake.override.json
# This makes it easier to update the Go version and checksums via the `dda run update go` command.
# The override file is automatically loaded by docker buildx bake and updates some
# Go-specific variables (go_versions, go_checksums_amd64, go_checksums_arm64) which are then
# merged into the final args below.

variable "versions" {
  type = map(string)
  default = {
    PY3_VERSION         = "3.12.6"
    CONDA_VERSION       = "4.9.2-7"
    BAZELISK_VERSION    = "1.28.1"
    TEST_BAZEL_VERSION  = "8.5.1" # Version of Bazel to test that Bazelisk properly bootstraps Bazel, will also be preinstalled into the final image
    DDA_VERSION         = "v0.31.0"
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
    DD_OCTO_STS_VERSION    = "v1.9.3"
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
    CONDA_SHA256             = "91d5aa5f732b5e02002a371196a2607f839bab166970ea06e6ecc602cb446848"
    BAZELISK_SHA256          = "22e7d3a188699982f661cf4687137ee52d1f24fec1ec893d91a6c4d791a75de8"
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
    CONDA_SHA256             = "ea7d631e558f687e0574857def38d2c8855776a92b0cf56cf5285bede54715d9"
    BAZELISK_SHA256          = "8ded44b58a0d9425a4178af26cf17693feac3b87bdcfef0a2a0898fcd1afc9f2"
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
    go_versions, # Defined in docker-bake.override.json
    checksums_common,
    architecture_defs_amd64,
    checksums_amd64,
    go_checksums_amd64, # Defined in docker-bake.override.json
    misc_args_amd64,
  )
}

// ARM64 architecture specific arguments
variable "args_arm64" {
  type = map(string)
  default = merge(
    versions,
    go_versions, # Defined in docker-bake.override.json
    checksums_common,
    architecture_defs_arm64,
    checksums_arm64,
    go_checksums_arm64, # Defined in docker-bake.override.json
    misc_args_arm64,
  )
}

# ====== Helpers ====== #
// Should not be needed as it is a builtin, but the LSP complains otherwise
variable "BAKE_LOCAL_PLATFORM" {
  type = string
  default = "$BAKE_LOCAL_PLATFORM"
}

function "get_arch" {
  params = []
  result = split("/", "${BAKE_LOCAL_PLATFORM}")[1]
}

variable "registry_name" {
  type = string
  default = "registry.ddbuild.io/ci"
}

variable "repo_name" {
  type = string
  default = "datadog-agent-buildimages"
}

# ====== Caching details ====== #
variable "CI" {
  type = string
  // Will pull in the env var if it is defined in CI environments (GitLab CI sets this to "true")
  default = ""
}

variable CI_COMMIT_BRANCH {
  type = string
  // Will pull in the env var if it is defined, but otherwise will be empty
  default = ""
  validation {
    condition     = CI_COMMIT_BRANCH != "" || CI == ""
    error_message = "CI_COMMIT_BRANCH must be set and not empty in CI environment"
  }
}

variable "default_branch_name" {
  type = string
  default = "main"
}

variable "build_branch_name" {
  type = string
  default = sanitize("${CI_COMMIT_BRANCH}")
}

variable "cache_key_main" {
  type = string
  default = "cache-${default_branch_name}-${get_arch()}"
}

variable "cache_key_branch" {
  type = string
  default = "cache-${build_branch_name}-${get_arch()}"
}

variable "linux_cache_details_main" {
  type = string
  default = "type=registry,ref=${registry_name}/${repo_name}/linux:${cache_key_main}"
}

variable "linux_cache_details_branch" {
  type = string
  default = "type=registry,ref=${registry_name}/${repo_name}/linux:${cache_key_branch}"
}

# ====== Local build targets ====== #
# Fake target containing settings common for local build targets
target "_fake_linux-local" {
  dockerfile = "linux/Dockerfile"
  context    = "./"
  cache-from = [linux_cache_details_main]
  tags       = ["${repo_name}/linux:latest"]
  # Outside CI, use GITLAB_TOKEN from env var
  secret     = ["type=env,id=gitlab-token,env=GITLAB_TOKEN"]
}

// AMD64 architecture
target "linux-amd64" {
  inherits = ["_fake_linux-local"]
  platforms  = ["linux/amd64"]
  args       = args_amd64
}

// ARM64 architecture
target "linux-arm64" {
  inherits = ["_fake_linux-local"]
  platforms  = ["linux/arm64"]
  args       = args_arm64
}

# ====== CI build targets ====== #
// CI build targets (contain extra info for tagging, caching, etc.)

variable "CI_COMMIT_SHORT_SHA" {
  type = string
  // Use the gitlab-provided env var - if it is not set, will be empty
  default = ""
  validation {
    condition     = strlen(CI_COMMIT_SHORT_SHA) == 8 || CI == ""
    error_message = "CI_COMMIT_SHORT_SHA must be 8 characters long in CI environment"
  }
}

variable "CI_PIPELINE_ID" {
  type = string
  // Use the gitlab-provided env var - if it is not set, will be empty
  default = ""
  validation {
    condition     = CI_PIPELINE_ID != "" || CI == ""
    error_message = "CI_PIPELINE_ID must be set in CI environment"
  }
}

variable "linux-image-tag" {
  type = string
  default = "v${CI_PIPELINE_ID}-${CI_COMMIT_SHORT_SHA}-${get_arch()}"
}

# Fake target containing settings common for CI build targets
target "_fake_linux-ci" {
  # In CI, use CI_JOB_TOKEN as GITLAB_TOKEN
  secret     = ["type=env,id=gitlab-token,env=CI_JOB_TOKEN"]
  cache-from = [linux_cache_details_branch, linux_cache_details_main]
  cache-to   = [linux_cache_details_branch]
  tags       = ["${registry_name}/${repo_name}/linux:${linux-image-tag}"]
  output     = ["type=docker,dest=./linux-${linux-image-tag}.tar"]
}

target "linux-amd64-ci" {
  inherits = ["linux-amd64", "_fake_linux-ci"]
}

target "linux-amd64-ci_test_only" {
  inherits = ["linux-amd64-ci"]
  tags     = ["${registry_name}/${repo_name}/linux_test_only:${linux-image-tag}"]
  output   = ["type=docker,dest=./linux_test_only-${linux-image-tag}.tar"]
}

target "linux-arm64-ci" {
  inherits = ["linux-arm64", "_fake_linux-ci"]
}

target "linux-arm64-ci_test_only" {
  inherits = ["linux-arm64-ci"]
    # Override the tags and output from the linux-ci target to change the image name
  tags     = ["${registry_name}/${repo_name}/linux_test_only:${linux-image-tag}"]
  output   = ["type=docker,dest=./linux_test_only-${linux-image-tag}.tar"]
}

// Default group - automatically builds the target for the current architecture
group "default" {
  targets = ["linux-${get_arch()}"]
}
