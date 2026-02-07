# SwiftPicoPlayground

This is my personal playground for working with the Raspberry Pi Pico and Embedded Swift.

For one, I'm interested in learning how to work with embedded systems for some personal projects, and as an iOS developer using Swift for this purpose is appealing.
In addition, this allows me to get into Swift/C interop and properly bridging C APIs for Swift users. I want to explore possibilites for Swifty APIs for embedded development and to see how well Swift can be used here.

The project uses the [CPicoSDK](https://github.com/gonzalolarralde/CPicoSDK) package, which provides Swift bindings to the Raspberry Pi Pico SDK for C/C++, simplifying the process of getting set up and running Swift code on the Pico compared to the examples provided in the Swift Embedded repo.

## My Setup

I'm running this on a Mac in VS Code. I'm using a Raspberry Pi Pico 2W and the official Raspberry Pi Debug Probe for flashing and debugging. However the the code should work on any Pico board with only minor adjustments thanks to the CPicoSDK.

## License

This project is licensed under the [MIT License](LICENSE).
