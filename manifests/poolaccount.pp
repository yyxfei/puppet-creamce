class creamce::poolaccount inherits creamce::params {

  require creamce::yumrepos
  
  define pooluser ($uid, $groups, $gridmapdir, $homedir="/home", $shell="/bin/bash") {
  
    user { "${title}":
      ensure     => "present",
      uid        => $uid,
      comment    => "mapped user for ${groups[0]}",
      gid        => "${groups[0]}",
      groups     => $groups,
      home       => "${homedir}/${title}",
      managehome => true,
      shell      => "${shell}"
    }
    
    file { "${gridmapdir}/${title}":
      ensure     => file,
      owner      => "root",
      group      => "root",
      mode       => 0644,
      content    => "",
      require    => [ File["${gridmapdir}"], User["${title}"] ]
    }

  }
  
  package { "cleanup-grid-accounts":
    ensure     => "present",
  }
  
  package { "lcg-expiregridmapdir":
    ensure => present
  }
  
  group { "edguser":
    gid    => 152,
  }
  
  file { "${gridmap_dir}":
    ensure   => directory,
    owner    => "root",
    group    => "edguser",
    mode     => 0770,
    require  => Group["edguser"],
  }
  
  $group_table = build_group_definitions($voenv)
  create_resources(group, $group_table)
  
  $user_table = build_user_definitions($voenv, $gridmap_dir, $default_pool_size)
  create_resources(pooluser, $user_table)
  
  file { "/etc/cleanup-grid-accounts.conf":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    require  => Package["cleanup-grid-accounts"],
    content  => template("creamce/cleanup-grid-accounts.conf.erb")
  }
  
  file  { "/etc/cron.d/cleanup-grid-accounts":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    content  => "${cga_cron_sched} root /usr/sbin/cleanup-grid-accounts.sh -v -F >> ${cga_logfile} 2>&1\n",
    require  => Package["cleanup-grid-accounts"],
  }
  
  $cga_logrotate = "${cga_logfile} {
    compress
    daily
    rotate 30
    missingok
}
"

  file { "/etc/logrotate.d/cleanup-grid-accounts":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    content  => "${cga_logrotate}",
    require  => File["/etc/cron.d/cleanup-grid-accounts"],
  }
  
  file { "/etc/cron.deny":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    content  => template("creamce/cron_deny.erb")
  }
  
  file { "/etc/at.deny":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    content  => template("creamce/at_deny.erb")
  }
  
  #################################################################################################
  # https://twiki.cern.ch/twiki/bin/view/LCG/YaimGuide400
  #################################################################################################


  file  { "/etc/cron.d/lcg-expiregridmapdir":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    content  => "${gridmap_cron_sched} root /usr/sbin/lcg-expiregridmapdir.pl -e 240 -v >> /var/log/lcg-expiregridmapdir.log 2>&1\n",
    require  => Package["lcg-expiregridmapdir"],
  }
  
  $groupmap_table = build_groupmap($voenv)
  
  file { "${groupmap_file}":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    content  => template("creamce/groupmapfile.erb"),
  }
  
  $gridmap_table = build_gridmap($voenv, $default_pool_size)
  
  file { "${gridmap_file}":
    ensure   => file,
    owner    => "root",
    group    => "root",
    mode     => 0644,
    content  => template("creamce/gridmapfile.erb"),
  }

}
