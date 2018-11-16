# Return an array of interfaces which have IPv6 disabled
require 'puppet'
Facter.add(:ipv6_disabled) do
    setcode do
        ipv6_disabled = []
        $all_ifaces = (Facter.value(:networking)['interfaces'].keys + ['all']).sort
        $all_ifaces.each do |interface|
            $disabled = Facter::Util::Resolution.exec("cat /proc/sys/net/ipv6/conf/#{interface}/disable_ipv6")
           if $disabled == '1'
               ipv6_disabled.push(interface)
               Facter.debug("Interface '#{interface}' has IPv6 disabled")
           else
               Facter.debug("Interface '#{interface}' has IPv6 enabled")
           end
        end

        ipv6_disabled
    end
end
