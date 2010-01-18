use strict;
use warnings FATAL => 'all';
use Test::More;

use App::IdiotBox;
use Data::Perl::Collection::Set;
use Scalar::Util qw(weaken);

my $idiotbox = App::IdiotBox->new({
 config => { template_dir => 'share/html' }
});

my $bucket = bless({
  slug => 'lpw2009',
  name => 'London Perl Workshop 2009',
}, 'App::IdiotBox::Bucket');

my %vid;

$bucket->{videos} = Data::Perl::Collection::Set->new(
    members => [ map {
      my $o = bless(
        { %$_, bucket => $bucket, details => ''  },
        'App::IdiotBox::Video'
      );
      weaken($o->{bucket});
      $vid{$o->{slug}} = $o
    }
      { name => 'The M Word', slug => 'm-word', author => 'davorg' },
      { name => 'Dreamcasting', slug => 'dream', author => 'mst' },
  ]
);

sub slurp_html {
  my $string;
  my $fh = $_[0]->[-1];
  while (defined (my $chunk = $fh->getline)) {
    $string .= $chunk;
  }
  $string;
} 

my $bucket_result = $idiotbox->show_bucket($bucket);

my $html = slurp_html($bucket_result);

warn $html;

warn "\n\n------\n\n";

my $video_result = $idiotbox->show_video($vid{dream});

$html = slurp_html($video_result);

warn $html;

pass;

done_testing;
