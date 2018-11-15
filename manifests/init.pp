# @summary
#   The linux_disable_ipv6 module disables IPv6 for Linux systems, following operating system vendor recommendations.
#
# @example Basic usage
#   include linux_disable_ipv6
#
# @param disable_ipv6
#   Disables IPv6 or reverts the effects of the module.
#
# @param interfaces
#   Specifies interfaces for which to disable IPv6, where supported.
#
# @see https://access.redhat.com/solutions/8709
#   Red Hat Solution - How do I disable or enable the IPv6 protocol in Red Hat Enterprise Linux?
#
class linux_disable_ipv6 (
  Boolean $disable_ipv6 = true,
  Array[String] $interfaces = ['all']
) {
  if $disable_ipv6 {
    $ensure = 'file'
    $netconfig = '-'
  } else {
    $ensure = 'absent'
    $netconfig = 'v'
  }

  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['release']['major'] {
        '7': {

          # Following the second method, using sysctl

          # Validation
          if $disable_ipv6 and $interfaces == [] {
            fail("No interfaces specified. You probably want 'all'")
          }

          $all_ifaces = ($facts['networking']['interfaces'].keys + ['all']).sort
          $ifaces = $interfaces.sort
          $bad_ifaces = $ifaces - $all_ifaces
          if $bad_ifaces != [] {
            fail("Specified interfaces do not exist on host: ${bad_ifaces}")
          }

          # Only runs after notify
          exec { 'sysctl -p':
            command     =>  'cat /etc/sysctl.d/*.conf | sysctl -p -',
            path        =>  '/sbin:/bin:/usr/sbin:/usr/bin',
            refreshonly =>  true,
            notify => Exec['dracut -f'],
          }

          # Only runs after notify
          exec { 'dracut -f':
            command =>  "dracut -f",
            path =>  '/sbin:/bin:/usr/sbin:/usr/bin',
            refreshonly =>  true,
          }

          # Create sysctl configuration file and notify Exec['sysctl -p']
          file { 'ipv6.conf':
            ensure  => $ensure,
            content => template('linux_disable_ipv6/sysctl.d_ipv6.conf.erb'),
            group   => 'root',
            mode    => '0644',
            owner   => 'root',
            path    => '/etc/sysctl.d/ipv6.conf',
            notify  => Exec['sysctl -p'],
          }

          # Update /etc/netconfig to prevent rpc* messages: https://access.redhat.com/solutions/2963091
          file_line { 'netconfig-udp6':
            line  => "udp6       tpi_clts      ${netconfig}     inet6    udp     -       -",
            match => '^udp6',
            path  => '/etc/netconfig',
          }
          file_line { 'netconfig-tcp6':
            line  => "tcp6       tpi_cots_ord  ${netconfig}     inet6    tcp     -       -",
            match => '^tcp6',
            path  => '/etc/netconfig',
          }

        }
        default: {
          fail("linux_disable_ipv6 supports RedHat like systems with major release of 7 and you have ${facts['os']['release']['full']}")
        }
      }
    }
    default: {
      fail("linux_disable_ipv6 supports osfamily RedHat. Detected osfamily is ${facts['os']['family']}")
    }
  }
}
