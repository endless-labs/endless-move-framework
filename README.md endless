---
id: Endless-framework
title: Endless Framework
---

## The Endless Framework

The Endless Framework defines the standard actions that can be performed on-chain
both by the Endless VM---through the various prologue/epilogue functions---and by
users of the blockchain---through the allowed set of transactions. This
directory contains different directories that hold the source Move
modules and transaction scripts, along with a framework for generation of
documentation, ABIs, and error information from the Move source
files. See the [Layout](#layout) section for a more detailed overview of the structure.

## Documentation

Each of the main components of the Endless Framework and contributing guidelines are documented separately. See them by version below:

* *Endless tokens* - endless-move/framework/endless-token/doc/overview.md
* *Endless framework* - endless-move/framework/endless-framework/doc/overview.md
* *Endless stdlib* - endless-move/framework/endless-stdlib/doc/overview.md
* *Move stdlib* - endless-move/framework/move-stdlib/doc/overview.md

Follow our [contributing guidelines](CONTRIBUTING.md) and basic coding standards for the Endless Framework.

## Compilation and Generation

The documents above were created by the Move documentation generator for Endless. It is available as part of the Endless CLI. To see its options, run:
```shell
endless move document --help
```

The documentation process is also integrated into the framework building process and will be automatically triggered like other derived artifacts, via `cached-packages` or explicit release building.

## Running Move tests

To test our Move code while developing the Endless Framework, run `cargo test` inside this directory:

```
cargo test
```

(Alternatively, run `cargo test -p endless-framework` from anywhere.)

To skip the Move prover tests, run:

```
cargo test -- --skip prover
```

To filter and run only the tests in specific packages (e.g., `endless_stdlib`), run:

```
cargo test -- endless_stdlib --skip prover
```

(See tests in `tests/move_unit_test.rs` to determine which filter to use; e.g., to run the tests in `endless_framework` you must filter by `move_framework`.)

Sometimes, Rust runs out of stack memory in dev build mode.  You can address this by either:
1. Adjusting the stack size

```
export RUST_MIN_STACK=4297152
```

2. Compiling in release mode

```
cargo test --release -- --skip prover
```

## Layout
The overall structure of the Endless Framework is as follows:

```
├── endless-framework                                 # Sources, testing and generated documentation for Endless framework component
├── endless-token                                 # Sources, testing and generated documentation for Endless token component
├── endless-stdlib                                 # Sources, testing and generated documentation for Endless stdlib component
├── move-stdlib                                 # Sources, testing and generated documentation for Move stdlib component
├── cached-packages                                 # Tooling to generate SDK from mvoe sources.
├── src                                     # Compilation and generation of information from Move source files in the Endless Framework. Not designed to be used as a Rust library
├── releases                                    # Move release bundles
└── tests
```
