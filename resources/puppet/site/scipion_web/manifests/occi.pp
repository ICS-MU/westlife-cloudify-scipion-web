class scipion_web::occi {
  contain scipion_web::occi::repo
  contain scipion_web::occi::install
  contain scipion_web::occi::config

  Class['scipion_web::occi::repo']
    -> Class['scipion_web::occi::install']
    -> Class['scipion_web::occi::config']

  Class['apt::update']
    -> Class['scipion_web::occi::install']
}
