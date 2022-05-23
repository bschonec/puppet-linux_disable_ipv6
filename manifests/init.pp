# @summary
#   The linux_disable_ipv6 module disables IPv6 for Linux systems, following operating system vendor recommendations.
#
# @example Basic usage
#   include linux_disable_ipv6
#
# @param disable_ipv6
#   Disables or enables IPv6.
#
# @param interfaces
#   Specifies interfaces for which to disable IPv6, where supported.
#
# @see https://access.redhat.com/solutions/8709
#   Red Hat Solution - How do I disable or enable the IPv6 protocol in Red Hat Enterprise Linux?
#
class linux_disable_ipv6 (
  Boolean $disable_ipv6 = true,
  Array[String] $interfaces = ['all'],
) {
  case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['release']['major'] {
        '7', '8': {
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

          # Install the libtirpc package.
          package {'libtirpc':
            ensure => installed,
            before => [
                File_line['netconfig-udp6'],
                File_line['netconfig-tcp6'],
              ]
          }

          # Only runs after notify
          exec { 'sysctl -p':
            command     => 'cat /etc/sysctl.d/*.conf | sysctl -p -',
            path        => '/sbin:/bin:/usr/sbin:/usr/bin',
            refreshonly => true,
            notify      => Exec['dracut -f'],
          }

          # Only runs after notify
          exec { 'dracut -f':
            command     =>  'dracut -f',
            path        =>  '/sbin:/bin:/usr/sbin:/usr/bin',
            refreshonly =>  true,
          }

          # Create sysctl configuration file and notify Exec['sysctl -p']
          $disable_ipv6_num = Integer($disable_ipv6)
          file { 'ipv6.conf':
            ensure  => file,
            content => template('linux_disable_ipv6/sysctl.d_ipv6.conf.erb'),
            group   => 'root',
            mode    => '0644',
            owner   => 'root',
            path    => '/etc/sysctl.d/ipv6.conf',
            notify  => Exec['sysctl -p'],
          }

          # Update /etc/netconfig to prevent rpc* messages: https://access.redhat.com/solutions/2963091
          if $disable_ipv6 {
            $netconfig = '-'
          } else {
            $netconfig = 'v'
          }
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

          # Update /etc/sysconfig/network
          file_line { 'sysconfig':
            line  => "NETWORKING_IPV6=${bool2str($disable_ipv6, 'no', 'yes')}",
            match => '^NETWORKING_IPV6=',
            path  => '/etc/sysconfig/network',
          }

          # Update hosts file with localhost entry
          if ($disable_ipv6 and ( lo in $interfaces or 'all' in $interfaces)) {
            $hosts_ensure = 'absent'
            $hosts_match_for_absence = true
          } else {
            $hosts_ensure = 'present'
            $hosts_match_for_absence = false
          }
          file_line { 'hosts':
            ensure            => $hosts_ensure,
            path              => '/etc/hosts',
            match             => '^::1',
            line              => '::1         localhost localhost.localdomain localhost6 localhost6.localdomain6',
            match_for_absence => $hosts_match_for_absence,
          }

        }
        default: {
          fail("linux_disable_ipv6 supports RedHat like systems with major release of 7/8 and you have ${facts['os']['release']['full']}")
        }
      }
    }
    default: {
      fail("linux_disable_ipv6 supports osfamily RedHat. Detected osfamily is ${facts['os']['family']}")
    }
  }
}
