class nagios::nrpe::ntp ($server = $nagios::params::server) inherits nagios::params {
  require nagios::nrpe::config
  include nagios::nrpe::service

  # This should be factored out when we need a second eventhandler
  file { "/usr/lib/nagios/eventhandlers":
    ensure  => directory,
    recurse => true,
    owner   => root,
    group   => root,
    mode    => 755,
    before => File["resync_ntp.sh"],
  }

  file { "resync_ntp.sh":
    path   => "/usr/lib/nagios/eventhandlers/resync_ntp.sh",
    source => "puppet:///modules/nagios/resync_ntp.sh",
    owner  => root,
    group  => root,
    mode   => "0755",
    ensure => present,
    before => File_line["resync_ntp"],
  }
  
  #add nagios to sudoers so it can stop/start ntp
  file_line { "ntp_sudoers":
		line => "nagios ALL=(ALL) NOPASSWD: /etc/init.d/ntp stop, /etc/init.d/ntp start, /usr/sbin/ntpd -q",
		path => "/etc/sudoers",
		ensure => present,
		before => File_line["resync_ntp"],
}
  
  file_line { "check_time_sync":
    line   => "command[check_time_sync]=/usr/lib/nagios/plugins/check_ntp_time -H $server -w 0.5 -c 100",
    path   => "/etc/nagios/nrpe_local.cfg",
    match  => "command\[check_time_sync\]",
    ensure => present,
    notify => Service[nrpe],
  }
  
  file_line { "resync_ntp":
		line   => "command[resync_ntp]=/usr/lib/nagios/eventhandlers/resync_ntp.sh",
		path   => "/etc/nagios/nrpe_local.cfg",
		ensure => present,
    notify => Service[nrpe],
	}
	
	@@nagios_service { "check_time_sync_${hostname}":
    check_command       => "check_nrpe_1arg!check_mem",
    use                 => "generic-service",
    host_name           => $hostname,
    target              => "/etc/nagios3/conf.d/puppet/service_${fqdn}.cfg",
    service_description => "${hostname}_check_time_sync",
    tag                 => "${environment}",
    event_handler				=> "resync_ntp",
  }
  
  @basic_server::motd::register { 'NTP Check and Restart scrpit': }
}