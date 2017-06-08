package Junos::Config::Parser;

use strict;
use warnings;
use utf8;

use Data::Dumper;
use DateTime::Format::Strptime;

use Log::Log4perl   qw(:nowarn);

use Readonly;

Readonly our $TAG => __PACKAGE__;

sub new {
    my $type    = shift @_;
    my %opts    = @_;

    my $class = ref($type) || $type || __PACKAGE__;
    my $self = {};
    bless $self, $class;

    $self->{'_filename'} = $opts{'filename'} if defined $opts{'filename'};

    return $self;
}

sub _parse_section {
    my $self    = shift @_;
    my $name    = shift @_;
    my $lines   = shift @_;

    my $logger = Log::Log4perl->get_logger($TAG);
    $logger->debug("NAME: ${name}");
    my %details = ();
    while(defined(my $l = shift @{$lines})) {
        $logger->debug("[$name] L IS '${l}'");
        if ($l =~ /^.*Last changed: (.*)/) {
            my $p = DateTime::Format::Strptime->new(
                'pattern' => "%Y-%m-%d %H:%M:%S %Z",
            );
            my $dt = $p->parse_datetime($1);
            if ($dt) {
                $details{'last_changed'} = $dt->epoch();
            }
        }
        elsif ($l =~ /^\s*([\w\-\/]+);$/) {
            $logger->debug("[$name] no value details{$1} = 1");
            $details{$1} = 1;
        }
        elsif ($l =~ /^\s*(.+)\s+([^\{\}]+);$/) {
            $logger->debug("[$name] Details{$1} = $2");
            $details{$1} = $2;
        }
        elsif ($l =~ /^\s*(.+)\s+\{\s*$/) {
            my $key = $1;
            $logger->debug("KEY: '${key}'");
            my @key_fields = split(/\s+/, $key);
            my $section_name = $key;
            my $subsection_name;
            if (scalar(@key_fields) > 1) {
                $section_name = $key_fields[0];
                $subsection_name = $key_fields[1];
            }

            if ($subsection_name) {
                $logger->debug("[$name] PREPARE SUBSECTION ($subsection_name)");
                my %subsec = $self->_parse_section($subsection_name, $lines);
                $logger->debug("[$name] $section_name - SUBSECTION: ${subsection_name} = " . Dumper(\%subsec));
                $logger->debug("[$name] " . Dumper(\%details));
                if (defined($details{$section_name}) and not ref($details{$section_name})) {
                    my $orig_val = $details{$section_name};
                    $logger->debug("1. Trying to fix a thing");
                    $details{$section_name} = {$orig_val => 1};
                }

                $details{$section_name}->{$subsection_name} = \%subsec;
            }
            else {
#                $logger->debug(Dumper(\@lines));
                $logger->debug("PREPARE SECTION $section_name");
                my %section = $self->_parse_section($section_name, $lines);
                $logger->debug("[$name] Section{$section_name} = " . Dumper(\%section));
                $details{$section_name} = \%section;
            }
        }
        elsif ($l =~ /^\s*\}\s*$/) {
            $logger->debug("[$name] BREAK!? ($l)");
            # break
            last;
        }
    }

    return %details;
}

sub parse {
    my $self    = shift @_;

    my $filename = $self->{'_filename'};

    my $logger = Log::Log4perl->get_logger($TAG);
    my $fh;
    unless (open($fh, "<", $filename)) {
        $logger->error("Unable to open ${filename} for reading: $!");
        return;
    }

    my $buf;
    read($fh, $buf, -s $filename);
    close($fh);

    my @lines = split("\n", $buf);
    my %details = $self->_parse_section('', \@lines);

    $logger->debug("PARSE FILE");
    return %details;
}



1;
