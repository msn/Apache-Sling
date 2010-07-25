use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::Sling',
    VERSION_FROM      => 'lib/Apache/Sling.pm', # finds $VERSION
    PREREQ_PM         => {Net::LDAP => 0.34, Text::CSV => 1.17}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache/Sling.pm', # retrieve abstract from module
       AUTHOR         => 'D. D. Parry <perl@ddp.me.uk>') : ()),
);
