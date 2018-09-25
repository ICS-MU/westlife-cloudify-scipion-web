class scipion_web::occi::repo {
  apt::source { 'cas':
    ensure   => $scipion_web::ensure,
    location => 'http://repository.egi.eu/sw/production/cas/1/current',
    release  => 'egi-igtf',
    repos    => 'core',
    key      => 'D12E922822BE64D50146188BC32D99C83CDBBC71',
  }

  apt::source { 'rocci.cli':
    ensure       => $scipion_web::ensure,
    location     => 'http://repository.egi.eu/community/software/rocci.cli/4.3.x/releases/ubuntu',
    release      => $facts['os']['distro']['codename'],
    architecture => $facts['os']['architecture'],
    repos        => 'main',
    key          => 'FD7011F31EBF9470B82FAFCDE2E992EB352D3E14',
  }
}
