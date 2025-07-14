Reticulum Network Stack <img align="right" src="https://static.pepy.tech/personalized-badge/rns?period=month&units=international_system&left_color=grey&right_color=blue&left_text=Installs/month" style="padding-left:10px"/><a href="https://github.com/markqvist/Reticulum/actions/workflows/build.yml"><img align="right" src="https://github.com/markqvist/Reticulum/actions/workflows/build.yml/badge.svg"/></a>
==========

<p align="center"><img width="200" src="https://raw.githubusercontent.com/markqvist/Reticulum/master/docs/source/graphics/rns_logo_512.png"></p>

Reticulum is the cryptography-based networking stack for building local and wide-area
networks with readily available hardware. It can operate even with very high latency
and extremely low bandwidth. Reticulum allows you to build wide-area networks
with off-the-shelf tools, and offers end-to-end encryption and connectivity,
initiator anonymity, autoconfiguring cryptographically backed multi-hop
transport, efficient addressing, unforgeable delivery acknowledgements and
more.

The vision of Reticulum is to allow anyone to be their own network operator,
and to make it cheap and easy to cover vast areas with a myriad of independent,
inter-connectable and autonomous networks. Reticulum **is not** *one* network.
It is **a tool** for building *thousands of networks*. Networks without
kill-switches, surveillance, censorship and control. Networks that can freely
interoperate, associate and disassociate with each other, and require no
central oversight. Networks for human beings. *Networks for the people*.

Reticulum is a complete networking stack, and does not rely on IP or higher
layers, but it is possible to use IP as the underlying carrier for Reticulum.
It is therefore trivial to tunnel Reticulum over the Internet or private IP
networks.

Having no dependencies on traditional networking stacks frees up overhead that
has been used to implement a networking stack built directly on cryptographic
principles, allowing resilience and stable functionality, even in open and
trustless networks.

No kernel modules or drivers are required. Reticulum runs completely in
userland, and can run on practically any system that runs Python 3.

## Read The Manual
The full documentation for Reticulum is available at [markqvist.github.io/Reticulum/manual/](https://markqvist.github.io/Reticulum/manual/).

You can also download the [Reticulum manual as a PDF](https://github.com/markqvist/Reticulum/raw/master/docs/Reticulum%20Manual.pdf) or [as an e-book in EPUB format](https://github.com/markqvist/Reticulum/raw/master/docs/Reticulum%20Manual.epub).

For more info, see [reticulum.network](https://reticulum.network/) and [the FAQ section of the wiki](https://github.com/markqvist/Reticulum/wiki/Frequently-Asked-Questions).

## Notable Features
- Coordination-less globally unique addressing and identification
- Fully self-configuring multi-hop routing over heterogeneous carriers
- Flexible scalability over heterogeneous topologies
  - Reticulum can carry data over any mixture of physical mediums and topologies
  - Low-bandwidth networks can co-exist and interoperate with large, high-bandwidth networks
- Initiator anonymity, communicate without revealing your identity
  - Reticulum does not include source addresses on any packets
- Asymmetric X25519 encryption and Ed25519 signatures as a basis for all communication
  - The foundational Reticulum Identity Keys are 512-bit Elliptic Curve keysets
- Forward Secrecy is available for all communication types, both for single packets and over links
- Reticulum uses the following format for encrypted tokens:
  - Ephemeral per-packet and link keys and derived from an ECDH key exchange on Curve25519
  - AES-256 in CBC mode with PKCS7 padding
  - HMAC using SHA256 for authentication
  - IVs are generated through os.urandom()
- Unforgeable packet delivery confirmations
- Flexible and extensible interface system
  - Reticulum includes a large variety of built-in interface types
  - Ability to load and utilise custom user- or community-supplied interface types
  - Easily create your own custom interfaces for communicating over anything
- Authentication and virtual network segmentation on all supported interface types
- An intuitive and easy-to-use API
  - Simpler and easier to use than sockets APIs, but more powerful
  - Makes building distributed and decentralised applications much simpler
- Reliable and efficient transfer of arbitrary amounts of data
  - Reticulum can handle a few bytes of data or files of many gigabytes
  - Sequencing, compression, transfer coordination and checksumming are automatic
  - The API is very easy to use, and provides transfer progress
- Lightweight, flexible and expandable Request/Response mechanism
- Efficient link establishment
  - Total cost of setting up an encrypted and verified link is only 3 packets, totalling 297 bytes
  - Low cost of keeping links open at only 0.44 bits per second
- Reliable sequential delivery with Channel and Buffer mechanisms

## Roadmap
While Reticulum is already a fully featured and functional networking stack,
many improvements and additions are actively being worked on, and planned for the future.

To learn more about the direction and future of Reticulum, please see the [Development Roadmap](./Roadmap.md).

## Examples of Reticulum Applications
If you want to quickly get an idea of what Reticulum can do, take a look at the
following resources.

- You can use the [rnsh](https://github.com/acehoss/rnsh) program to establish remote shell sessions over Reticulum.
- [LXMF](https://github.com/markqvist/lxmf) is a distributed, delay and disruption tolerant message transfer protocol built on Reticulum
- The [LXST](https://github.com/markqvist/lxst) protocol and framework provides real-time audio and signals transport over Reticulum. It includes primitives and utilities for building voice-based applications and hardware devices, such as the `rnphone` program, that can be used to build hardware telephones.
- For an off-grid, encrypted and resilient mesh communications platform, see [Nomad Network](https://github.com/markqvist/NomadNet)
- The Android, Linux, macOS and Windows app [Sideband](https://github.com/markqvist/Sideband) has a graphical interface and many advanced features, such as file transfers, image and voice messages, real-time voice calls, a distributed telemetry system, mapping capabilities and full plugin extensibility.
- [MeshChat](https://github.com/liamcottle/reticulum-meshchat) is a user-friendly LXMF client with a web-based interface, that also supports image and voice messages, as well as file transfers. It also includes a built-in page browser for browsing Nomad Network nodes.

## Where can Reticulum be used?
Over practically any medium that can support at least a half-duplex channel
with greater throughput than 5 bits per second, and an MTU of 500 bytes. Data radios,
modems, LoRa radios, serial lines, AX.25 TNCs, amateur radio digital modes,
WiFi and Ethernet devices, free-space optical links, and similar systems are
all examples of the types of physical devices Reticulum can use.

An open-source LoRa-based interface called
[RNode](https://markqvist.github.io/Reticulum/manual/hardware.html#rnode) has
been designed specifically for use with Reticulum. It is possible to build
yourself, or it can be purchased as a complete transceiver that just needs a
USB connection to the host.

Reticulum can also be encapsulated over existing IP networks, so there's
nothing stopping you from using it over wired Ethernet, your local WiFi network
or the Internet, where it'll work just as well. In fact, one of the strengths
of Reticulum is how easily it allows you to connect different mediums into a
self-configuring, resilient and encrypted mesh, using any available mixture of
available infrastructure.

As an example, it's possible to set up a Raspberry Pi connected to both a LoRa
radio, a packet radio TNC and a WiFi network. Once the interfaces are
configured, Reticulum will take care of the rest, and any device on the WiFi
network can communicate with nodes on the LoRa and packet radio sides of the
network, and vice versa.

## How do I get started?
The best way to get started with the Reticulum Network Stack depends on what
you want to do. For full details and examples, have a look at the 
[Getting Started Fast](https://markqvist.github.io/Reticulum/manual/gettingstartedfast.html) 
section of the [Reticulum Manual](https://markqvist.github.io/Reticulum/manual/).

To simply install Reticulum and related utilities on your system, the easiest way is via `pip`.
You can then start any program that uses Reticulum, or start Reticulum as a system service with
[the rnsd utility](https://markqvist.github.io/Reticulum/manual/using.html#the-rnsd-utility).

```bash
pip install rns
```

If you are using an operating system that blocks normal user package installation via `pip`,
you can return `pip` to normal behaviour by editing the `~/.config/pip/pip.conf` file,
and adding the following directive in the `[global]` section:

```text
[global]
break-system-packages = true
```

Alternatively, you can use the `pipx` tool to install Reticulum in an isolated environment:

```bash
pipx install rns
```

When first started, Reticulum will create a default configuration file,
providing basic connectivity to other Reticulum peers that might be locally
reachable. The default config file contains a few examples, and references for
creating a more complex configuration.

If you have an old version of `pip` on your system, you may need to upgrade it first with `pip install pip --upgrade`. If you no not already have `pip` installed, you can install it using the package manager of your system with `sudo apt install python3-pip` or similar.

For more detailed examples on how to expand communication over many mediums such 
as packet radio or LoRa, serial ports, or over fast IP links and the Internet using 
the UDP and TCP interfaces, take a look at the [Supported Interfaces](https://markqvist.github.io/Reticulum/manual/interfaces.html) 
section of the [Reticulum Manual](https://markqvist.github.io/Reticulum/manual/).

## Included Utilities
Reticulum includes a range of useful utilities for managing your networks, 
viewing status and information, and other tasks. You can read more about these 
programs in the [Included Utility Programs](https://markqvist.github.io/Reticulum/manual/using.html#included-utility-programs) 
section of the [Reticulum Manual](https://markqvist.github.io/Reticulum/manual/).

- The system daemon `rnsd` for running Reticulum as an always-available service
- An interface status utility called `rnstatus`, that displays information about interfaces
- The path lookup and management tool `rnpath` letting you view and modify path tables
- A diagnostics tool called `rnprobe` for checking connectivity to destinations
- A simple file transfer program called `rncp` making it easy to transfer files between systems
- The identity management and encryption utility `rnid` let's you manage Identities and encrypt/decrypt files
- The remote command execution program `rnx` let's you run commands and
  programs and retrieve output from remote systems

All tools, including `rnx` and `rncp`, work reliably and well even over very
low-bandwidth links like LoRa or Packet Radio. For full-featured remote shells
over Reticulum, also have a look at the [rnsh](https://github.com/acehoss/rnsh)
program.

## Supported interface types and devices

Reticulum implements a range of generalised interface types that covers most of
the communications hardware that Reticulum can run over. If your hardware is
not supported, it's [simple to implement a custom interface module](https://markqvist.github.io/Reticulum/manual/interfaces.html#custom-interfaces).

Pull requests for custom interfaces are gratefully accepted, provided they are
generally useful and well-tested in real-world usage.

Currently, the following built-in interfaces are supported:

- Any Ethernet device
- LoRa using [RNode](https://unsigned.io/rnode/)
- Packet Radio TNCs (with or without AX.25)
- KISS-compatible hardware and software modems
- Any device with a serial port
- TCP over IP networks
- UDP over IP networks
- External programs via stdio or pipes
- Custom hardware via stdio or pipes

## Performance
Reticulum targets a *very* wide usable performance envelope, but prioritises
functionality and performance on low-bandwidth mediums. The goal is to
provide a dynamic performance envelope from 250 bits per second, to 1 gigabit
per second on normal hardware.

Currently, the usable performance envelope is approximately 150 bits per second
to 40 megabits per second, with physical mediums faster than that not being
saturated. Performance beyond the current level is intended for future
upgrades, but not highly prioritised at this point in time.

## Current Status
All core protocol features are implemented and functioning, but additions will
probably occur as real-world use is explored and understood. The API and wire-format
can be considered stable.

## Dependencies
The installation of the default `rns` package requires the dependencies listed
below. Almost all systems and distributions have readily available packages for
these dependencies, and when the `rns` package is installed with `pip`, they
will be downloaded and installed as well.

- [PyCA/cryptography](https://github.com/pyca/cryptography)
- [pyserial](https://github.com/pyserial/pyserial)

On more unusual systems, and in some rare cases, it might not be possible to
install or even compile one or more of the above modules. In such situations,
you can use the `rnspure` package instead, which require no external
dependencies for installation. Please note that the contents of the `rns` and
`rnspure` packages are *identical*. The only difference is that the `rnspure`
package lists no dependencies required for installation.

No matter how Reticulum is installed and started, it will load external
dependencies only if they are *needed* and *available*. If for example you want
to use Reticulum on a system that cannot support
[pyserial](https://github.com/pyserial/pyserial), it is perfectly possible to
do so using the `rnspure` package, but Reticulum will not be able to use
serial-based interfaces. All other available modules will still be loaded when
needed.

**Please Note!** If you use the `rnspure` package to run Reticulum on systems
that do not support [PyCA/cryptography](https://github.com/pyca/cryptography),
it is important that you read and understand the [Cryptographic
Primitives](#cryptographic-primitives) section of this document.

## Public Testnet
If you just want to get started experimenting without building any physical
networks, you are welcome to join the RNS Development Testnet.

The testnet is just that, an informal network for testing and experimenting.
It will be up most of the time, and anyone can join, but it also means that
there's no guarantees for service availability.

It probably goes without saying, but *don't use the testnet entry-points as 
hardcoded or default interfaces in any applications you ship to users*. When
shipping applications, the best practice is to provide your own default
connectivity solutions, if needed and applicable, or in most cases, simply
leave it up to the user which networks to connect to, and how.

The testnet runs the very latest version of Reticulum (often even a short while
before it is publicly released). Sometimes experimental versions of Reticulum
might be deployed to nodes on the testnet, which means strange behaviour might
occur. If none of that scares you, you can join the testnet via either TCP or
I2P. Just add one of the following interfaces to your Reticulum configuration
file:

```
# TCP/IP interface to the RNS Amsterdam Hub
  [[RNS Testnet Amsterdam]]
    type = TCPClientInterface
    enabled = yes
    target_host = amsterdam.connect.reticulum.network
    target_port = 4965

# TCP/IP interface to the BetweenTheBorders Hub (community-provided)
  [[RNS Testnet BetweenTheBorders]]
    type = TCPClientInterface
    enabled = yes
    target_host = reticulum.betweentheborders.com
    target_port = 4242

# Interface to Testnet I2P Hub
  [[RNS Testnet I2P Hub]]
    type = I2PInterface
    enabled = yes
    peers = g3br23bvx3lq5uddcsjii74xgmn6y5q325ovrkq2zw2wbzbqgbuq.b32.i2p
```

The testnet also contains a number of [Nomad Network](https://github.com/markqvist/nomadnet) nodes, and LXMF propagation nodes.

## Support Reticulum
You can help support the continued development of open, free and private communications systems by donating via one of the following channels:

- Monero:
  ```
  84FpY1QbxHcgdseePYNmhTHcrgMX4nFfBYtz2GKYToqHVVhJp8Eaw1Z1EedRnKD19b3B8NiLCGVxzKV17UMmmeEsCrPyA5w
  ```
- Bitcoin
  ```
  bc1p4a6axuvl7n9hpapfj8sv5reqj8kz6uxa67d5en70vzrttj0fmcusgxsfk5
  ```
- Ethereum
  ```
  0xae89F3B94fC4AD6563F0864a55F9a697a90261ff
  ```
- Liberapay: https://liberapay.com/Reticulum/

- Ko-Fi: https://ko-fi.com/markqvist

## Cryptographic Primitives
Reticulum uses a simple suite of efficient, strong and well-tested cryptographic
primitives, with widely available implementations that can be used both on
general-purpose CPUs and on microcontrollers.

One of the primary considerations for choosing this particular set of primitives is
that they can be implemented *safely* with relatively few pitfalls, on practically
all current computing platforms.

The primitives listed here **are authoritative**. Anything claiming to be Reticulum,
but not using these exact primitives **is not** Reticulum, and possibly an
intentionally compromised or weakened clone. The utilised primitives are:

- Reticulum Identity Keys are 512-bit Curve25519 keysets
  - A 256-bit Ed25519 key for signatures
  - A 256-bit X22519 key for ECDH key exchanges
- HKDF for key derivation
- Encrypted tokens are based on the [Fernet spec](https://github.com/fernet/spec/)
  - Ephemeral keys derived from an ECDH key exchange on Curve25519
  - HMAC using SHA256 for message authentication
  - IVs must be generated through `os.urandom()` or better
  - AES-256 in CBC mode with PKCS7 padding
  - No Fernet version and timestamp metadata fields
- SHA-256
- SHA-512

In the default installation configuration, the `X25519`, `Ed25519`,
and `AES-256-CBC` primitives are provided by [OpenSSL](https://www.openssl.org/)
(via the [PyCA/cryptography](https://github.com/pyca/cryptography) package).
The hashing functions `SHA-256` and `SHA-512` are provided by the standard
Python [hashlib](https://docs.python.org/3/library/hashlib.html). The `HKDF`,
`HMAC`, `Token` primitives, and the `PKCS7` padding function are always
provided by the following internal implementations:

- [HKDF.py](RNS/Cryptography/HKDF.py)
- [HMAC.py](RNS/Cryptography/HMAC.py)
- [Token.py](RNS/Cryptography/Token.py)
- [PKCS7.py](RNS/Cryptography/PKCS7.py)


Reticulum also includes a complete implementation of all necessary primitives
in pure Python. If OpenSSL and PyCA are not available on the system when
Reticulum is started, Reticulum will instead use the internal pure-python
primitives. A trivial consequence of this is performance, with the OpenSSL
backend being *much* faster. The most important consequence however, is the
potential loss of security by using primitives that has not seen the same
amount of scrutiny, testing and review as those from OpenSSL.

Please note that by default, installing Reticulum will **require** OpenSSL and
PyCA to also be automatically installed if not already available. It is only
possible to use the pure-python primitives if this requirement is specifically
overridden by the user, for example by installing the `rnspure` package instead
of the normal `rns` package, or by running directly from local source-code.

If you want to use the internal pure-python primitives, it is **highly
advisable** that you have a good understanding of the risks that this pose, and
make an informed decision on whether those risks are acceptable to you.

Reticulum is relatively young software, and should be considered as such. While
it has been built with cryptography best-practices very foremost in mind, it
_has not_ been externally security audited, and there could very well be
privacy or security breaking bugs. If you want to help out, or help sponsor an
audit, please do get in touch.

## Acknowledgements & Credits
Reticulum can only exist because of the mountain of Open Source work it was
built on top of, the contributions of everyone involved, and everyone that has
supported the project through the years. To everyone who has helped, thank you
so much.

A number of other modules and projects are either part of, or used by
Reticulum. Sincere thanks to the authors and contributors of the following
projects:

- [PyCA/cryptography](https://github.com/pyca/cryptography), *BSD License*
- [Pure-25519](https://github.com/warner/python-pure25519) by [Brian Warner](https://github.com/warner), *MIT License*
- [Pysha2](https://github.com/thomdixon/pysha2) by [Thom Dixon](https://github.com/thomdixon), *MIT License*
- [Python AES-128](https://github.com/orgurar/python-aes) by [Or Gur Arie](https://github.com/orgurar), *MIT License*
- [Python AES-256](https://github.com/boppreh/aes) by [BoppreH](https://github.com/boppreh), *MIT License*
- [Curve25519.py](https://gist.github.com/nickovs/cc3c22d15f239a2640c185035c06f8a3#file-curve25519-py) by [Nicko van Someren](https://gist.github.com/nickovs), *Public Domain*
- [I2Plib](https://github.com/l-n-s/i2plib) by [Viktor Villainov](https://github.com/l-n-s)
- [PySerial](https://github.com/pyserial/pyserial) by Chris Liechti, *BSD License*
- [Configobj](https://github.com/DiffSK/configobj) by Michael Foord, Nicola Larosa, Rob Dennis & Eli Courtwright, *BSD License*
- [ifaddr](https://github.com/pydron/ifaddr) by Stefan C. Mueller, *MIT License*
- [Umsgpack.py](https://github.com/vsergeev/u-msgpack-python) by [Ivan A. Sergeev](https://github.com/vsergeev)
- [Python](https://www.python.org)
