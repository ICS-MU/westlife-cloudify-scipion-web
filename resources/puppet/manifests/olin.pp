$_ensure = $facts['cloudify_ctx_operation_name'] ? {
  delete  => absent,
  stop    => absent,
  default => present,
}

###

class { 'scipion_web':
  ensure => $_ensure,
}
