# Instructions

This repository is a playground project to play around with Swift on Embedded Platforms.

## Running

The build can be run by running `build.sh`.
If required, changes to this file can be made.

## Code Style

No strict code style is defined.
However `swift-format` is used to format and lint the code.

1. `make format` can re-format the code
2. `make lint` will lint the code

You should not submit changes before reformatting the code and making sure it passes the linter.
Finding a trivial workaround for a broken linter rule must be preferred over adding ignore comments to the code.
If no such workaround is found, a comment should be added explaining why the ignore is justified.

## Documentation

All `public` API must be documented with DocC style comments in the Code.
Appropriate warnings and notes about special behavior must be included in the documentation.
If a method/function uses complex math, the math should be briefly explained in the documentation.
If deemed useful, small code snippets should be included in the documentation to showcase API usage.