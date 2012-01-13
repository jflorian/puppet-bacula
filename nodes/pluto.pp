node pluto {
  include role::server

  ssh::allowgroup { "developers": }
  ssh::allowgroup { "prosvc": }
  ssh::allowgroup { "builder": }

  sudo::allowgroup { "builder": }

  # The deploy user is used for the automated deployment of documentation.
  # see https://github.com/puppetlabs/puppet-docs/blob/master/config/deploy.rb
  # for the Rest of the Story (TM)
  ssh::allowgroup { "www-data": }
  Account::User <| tag == deploy |>
  Ssh_authorized_key <| tag == deploy |>

  # (#11435) jenkins user for QA/release automation
  Account::User <| tag == 'jenkins' |>
  Ssh_authorized_key <| tag == 'jenkins' |>
  ssh::allowgroup { "jenkins": }

  cron { "sync /opt/enterprise to tbdriver":
    minute  => '*/10',
    user    => root,
    command => '/usr/bin/setlock -nx /var/run/_opt_enterprise_sync.lock /usr/local/bin/_opt_enterprise_sync.sh';
  }

  file { "/usr/local/bin/_opt_enterprise_sync.sh":
    owner  => root,
    group  => root,
    mode   => 750,
    source => "puppet:///modules/puppetlabs/_opt_enterprise_sync.sh";
  }

  apache::vhost { $fqdn:
      port    => 80,
      docroot => '/opt/enterprise'
  }

  # Permissions corrections.
  file {
    "/opt/enterprise":
      owner   => root,
      group   => enterprise,
      mode    => 0664,
      recurse => true;
    "/opt/puppet":
      ensure  => directory,
      owner   => root,
      group   => www-data,
      mode    => 0664,
      recurse => true;
    "/opt/puppet/nightly":
      ensure  => directory,
      owner   => root,
      group   => www-data,
      mode    => 0664;
    "/opt/tools":
      ensure  => directory,
      owner   => root,
      group   => developers,
      mode    => 664,
      recurse => true;
    "/opt/archive-enterprise":
      owner   => root,
      group   => enterprise,
      mode    => 0664,
      recurse => true;
  }

  class { 'freight':
    freight_vhost_name      => 'freight.puppetlabs.lan',
    freight_docroot         => '/opt/enterprise/repos/debian',
    freight_gpgkey          => 'pluto@puppetlabs.lan',
    freight_group           => 'enterprise',
    freight_libdir          => '/opt/tools/freight',
    freight_manage_docroot  => true,
    freight_manage_libdir   => true,
    freight_manage_vhost    => true,
  }
}
