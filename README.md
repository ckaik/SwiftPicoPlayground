# SwiftPicoPlayground

This is my personal playground for working with the Raspberry Pi Pico and Embedded Swift.

For one, I'm interested in learning how to work with embedded systems for some personal projects, and as an iOS developer using Swift for this purpose is appealing.
In addition, this allows me to get into Swift/C interop and properly bridging C APIs for Swift users. I want to explore possibilites for Swifty APIs for embedded development and to see how well Swift can be used here.

The project uses the [CPicoSDK](https://github.com/gonzalolarralde/CPicoSDK) package, which provides Swift bindings to the Raspberry Pi Pico SDK for C/C++, simplifying the process of getting set up and running Swift code on the Pico compared to the examples provided in the Swift Embedded repo.

## My Setup

I'm running this on a Mac in VS Code. I'm using a Raspberry Pi Pico 2W and the official Raspberry Pi Debug Probe for flashing and debugging. However the the code should work on any Pico board with only minor adjustments thanks to the CPicoSDK.

## Networking Overview

- **HTTP Server** (`Sources/MongooseKit/HTTP/`): A lightweight wrapper around Mongoose HTTP primitives for handling simple request/response flows on-device.
- **MQTT Client** (`Sources/MongooseKit/MQTT/`): A client-focused API for connecting to an MQTT broker, subscribing to topics, and handling reconnect behavior for basic IoT messaging scenarios.
- **JSON Decoder** (`Sources/MongooseKit/Utilities/MGJSONDecoder.swift`): A small utility layer that helps decode Mongoose JSON values into Swift-friendly types used by the networking components.

## Getting Started

After cloning, initialise the Mongoose submodule:

```bash
git submodule update --init
```

## License

This project is licensed under the [MIT License](LICENSE) for repository-owned code.

This repository also includes third-party software with separate license terms, including Mongoose (via a git submodule at `third_party/mongoose/`, dual-licensed GPL-2.0-only or commercial). See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for details and distribution obligations.

For GPL distribution workflows, a copy of GPLv2 is included at [COPYING.GPL-2.0](COPYING.GPL-2.0).
