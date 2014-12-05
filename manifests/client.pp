# == Class: nagios::client
#
# Checks if a host needs to be rebooted as a result of updates.  The script checks for /var/run/reboot-required and
# raises a warning if present. It never raises a critical in order to minimise unnecessary emails etc.
#
# === Variables
#
# [*nagios_service*]
#   This is the generic service it will implement. This is set from nagios::params. This should be set by heira in the
#   future.
#
# === Authors
#
# Ben Field <justin.miller@concreteplatform.com
class nagios::client {
  # Gonna take in a nagios_parent variable as an override
  include nagios::params

  $nagios_service = $::nagios::params::nagios_servicef

  if $::nagios_parent != "" {
    $parent = $::nagios_parent
  } else {
    $parent = $xenhost
  }

  # The not hugely neat way, need to refactor this:

  if $parent != "" {
    @@nagios_host { $hostname:
      target          => "/etc/nagios3/conf.d/puppet/host_${fqdn}.cfg",
      ensure          => present,
      address         => $ipaddress_eth0,
      use             => "generic-host",
      alias           => $hostname,
      tag             => "${environment}",
      parents         => "${parent}",
      icon_image      => "base/linux40.png",
      statusmap_image => "base/linux40.gd2",
    }
  } else {
    @@nagios_host { $hostname:
      target          => "/etc/nagios3/conf.d/puppet/host_${fqdn}.cfg",
      ensure          => present,
      address         => $ipaddress_eth0,
      use             => "generic-host",
      alias           => $hostname,
      tag             => "${environment}",
      icon_image      => "base/linux40.png",
      statusmap_image => "base/linux40.gd2",
    }
  }

  @@nagios_service { "check_ping_${hostname}":
    target              => "/etc/nagios3/conf.d/puppet/service_${fqdn}.cfg",
    check_command       => "check_ping!100.0,20%!500.0,60%",
    use                 => "${nagios_service}",
    host_name           => "$hostname",
    service_description => "${hostname}_check_ping",
    require             => nagios_host[$hostname],
    tag                 => "${environment}",
  }

  @motd::register { 'Nagios Ping Check': }

}
