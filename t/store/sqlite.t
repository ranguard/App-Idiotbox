use strict;
use warnings FATAL => 'all';

use App::IdiotBox::Store::SQLite;

use Devel::Dwarn;

my $ib = {};

App::IdiotBox::Store::SQLite->bind($ib);

#Dwarn [ $ib->{recent_announcements}->flatten ];
my $bucket = DwarnS $ib->{buckets}->get({ slug => 'opw2010'});

#Dwarn [ $bucket->{videos}->flatten ];

Dwarn $bucket->{videos}->get({ slug => 'troll-god-mountain' });
