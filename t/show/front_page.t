use strict;
use warnings FATAL => 'all';
use Test::More;

use App::IdiotBox;
use Data::Perl::Collection::Set;

BEGIN { $INC{"App/IdiotBox/Store/Test.pm"} = __FILE__ }

sub App::IdiotBox::Store::Test::bind {}

my $idiotbox = App::IdiotBox->new({
  config => {
    store => 'Test'
  }
});

my $ann = do {
  my ($lpw, $opw) = map bless($_, 'App::IdiotBox::Bucket'),
    { slug => 'lpw2009',
      name => 'London Perl Workshop 2009',
      video_count => 18 },
    { slug => 'opw2010',
      name => 'Perl Oasis 2010',
      video_count => 6 };
  my @ann = map bless($_, 'App::IdiotBox::Announcement'),
    {
      made_at => '2010-01-21 01:00:00',
      bucket => $opw,
      video_count => 3 },
    {
      made_at => '2010-01-01 14:00:00',
      bucket => $lpw,
      video_count => 5 };
  Data::Perl::Collection::Set->new(members => [ @ann ]);
};

$idiotbox->{recent_announcements} = $ann;

use Devel::Dwarn;

#Dwarn

my $front = $idiotbox->show_front_page;

my $html = do {
  my $string;
  my $fh = $front->[-1];
  while (defined (my $chunk = $fh->getline)) {
    $string .= $chunk;
  }
  $string;
};

warn $html;

pass;

done_testing;

#my %test;

#HTML::Zoom->from_string($html)
#          ->with_selectors({
#              '.announcement' => [
#                -sub_selectors => {
#                  selectors => [
                    
     
