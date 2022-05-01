# linux_disable_ipv6

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with linux_disable_ipv6](#setup)
    * [What linux_disable_ipv6 affects](#what-linux_disable_ipv6-affects)
    * [Beginning with linux_disable_ipv6](#beginning-with-linux_disable_ipv6)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)

## Description

The linux_disable_ipv6 module disables IPv6 for Linux systems, following operating system vendor recommendations.

## Setup

### What linux_disable_ipv6 affects

Depending on the operating system and version, the module may affect networking, kernel configuration and bootloader configuration.

Using this module may cause issues with software which requires IPv6, such as SSH Xforwarding.

Configuration changes:

* Creates kernel parameter configuration file `/etc/sysctl.d/ipv6.conf`
* Load kernel parameters from file with `sysctl -p`
* Updates initramfs with `dracut -f`
* Updates flags for IPv6 transports in `/etc/netconfig`
* Updates `NETWORKING_IPV6` option in `/etc/sysconfig/network`
* Removes IPv6 loopback address from `/etc/hosts`

### Beginning with linux_disable_ipv6

To disable IPv6, include the class: `include linux_disable_ipv6`.

## Usage

By default, the module will disable IPv6 for whole system.

Depending on your operating system, disabling IPv6 for specific interfaces may be supported.

Supply a list of interface names to the `interfaces` parameter:

```puppet
class { 'linux_disable_ipv6':
  interfaces => ['lo', 'eth0'],
}
```

It's also possible to enable IPv6, by setting the `disable_ipv6` to `false`:

```puppet
class { 'linux_disable_ipv6':
  disable_ipv6 => false,
}
```

## Reference

### linux_disable_ipv6 class parameters

| Parameter   | Type  | Default | Description |
|-------------|-------|---------|-------------|
| `disable_ipv6` | `Boolean` | `true`    | Set this to either disable or enable IPv6 |
| `interfaces`   | `Array[String]` | `['all']` | Disable IPv6 for these interfaces. If not supported, this parameter is ignored. If it contains the value `all`, other interface names will be ignored. |

## Limitations

For a list of supported operating systems, see [metadata.json](metadata.json).
