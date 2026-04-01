# Parabricks WDL

This is a repository of WDL workflow files for popular Parabricks tools.

## Table of Contents

- [Quick Start](#quick-start)
- [Full Tutorial](#full-tutorial)
  - [Install Sprocket](#install-sprocket)
  - [Run the tests](#run-the-tests)
- [Future Work](#future-work)

## Quick Start 

```
# Clone the repo and cd into directory 
git clone https://github.com/clara-parabricks-workflows/Parabricks-WDL-Workflows.git
cd parabricks-wdl

# Install Sprocket
curl https://sh.rustup.rs -sSf | sh
cargo install sprocket --locked

# Download all the test data 
make 

# Run the full test suite  
sprocket dev test
```

## Full Tutorial 

### Install Sprocket 

Install [Rust](https://rust-lang.org/) using [rustup](https://rustup.rs/). This will also install [Cargo](https://doc.rust-lang.org/cargo/), the Rust package manager 

```
curl https://sh.rustup.rs -sSf | sh
```

Install [Sprocket](https://sprocket.bio/) using Cargo 

```
cargo install sprocket --locked
```

Hint: If OpenSSL issues arise, then users may need to run `sudo apt install libssl-dev`

### Download the test data 

To download all the test data run: 

```
make
```

To download data just for one test, just append the directory name: 

```
make fq2bam
```

### Run the tests 

This repo uses the Sprocket unit testing framework. See the [documentation](https://sprocket.bio/subcommands/test.html) for more information. 

To run the full test suite use: 

```
sprocket dev test
```

To run a specific test specify the root directory with `-w` and provide the directory name. See the `fq2bam` example below: 

```
sprocket dev test -w . fq2bam
```

## Future Work 

* Update test data to use shared files when possible (Ex. All germline use the same reference)
* Set defaults for common params (memory, num_cpus, qc_metrics=true, etc.) to reduce clutter 
* Split base_url and file_url in data download scripts. See `starfusion/tests/download_data.sh`. 