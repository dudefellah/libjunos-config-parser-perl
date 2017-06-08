use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Junos::Config::Parser',
    'VERSION'       => '0.1',
    'PREREQ_PM'     => {
        'Data::Dumper'                  => 0,
        'DateTime::Format::Strptime'    => 0,
        'Log::Log4perl'                 => 0,
        'Readonly'                      => 0,
        'Test::More'                    => 0,
    },
);
