# == Define: nagios::nrpe::blockdevice::inodes
#
# This will take a drive reference as the name, and use it to create a diskspace
# check. The warning level for io load will be 15% and 5% for critical
#
# Note: It will set the name of the check to reference sysvol not xvda for
# cleanness in the nagios server
#
# === Parameters
#
# [*namevar*]
#   This will provide the drive reference (ie xvda from xen machines).
#
# === Variables
#
# [*nagios_service*]
#   This is the generic service it will implement. This is set from
#   nagios::params. This should be set by heira in the future.
#
# === Examples
#
#   nagios::nrpe::blockdevice::inodes { 'xvda':
#   }
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com
define nagios::nrpe::blockdevice::inodes {
  include nagios::params

  $nagios_service = $::nagios::params::nagios_service

  include base::params

  $monitoring_environment = $::base::params::monitoring_environment

  file_line { "check_${name}_inodes":
    ensure => present,
    line   => "command[check_${name}_inodes]=/usr/lib/nagios/plugins/check_disk -E -W 15% -K 5% -R /dev/${name}*",
    path   => '/etc/nagios/nrpe_local.cfg',
    match  => "command\[check_${name}_inodes\]",
    notify => Service['nrpe'],
  }

  # For neatness :

  if $name == 'xvda' {
    $drive = 'sysvol'
  } else {
    $drive = $name
  }

  @@nagios_service { "check_${drive}_inodes_${::hostname}":
    check_command       => "check_nrpe_1arg!check_${name}_inodes",
    use                 => $nagios_service,
    host_name           => $::hostname,
    target              => "/etc/nagios3/conf.d/puppet/service_${::fqdn}.cfg",
    service_description => "${::hostname}_check_${drive}_inodes",
    tag                 => $monitoring_environment,
  }

  @motd::register { "Nagios Inodes Check ${name}": }

}
