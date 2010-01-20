package App::IdiotBox::DataSet;

use strict;
use warnings FATAL => 'all';
use Scalar::Util qw(blessed);

use base qw(DBIx::Data::Collection::Set);

sub _inflate {
  my ($self, $raw) = @_;
  my %new;
  foreach my $k (keys %$raw) {
    my @parts = split /\./, $k;
    my $final = pop @parts;
    @parts or ($new{$k} = $raw->{$k}, next);
    my $targ = \%new;
    $targ = $targ->{$_}||={} for @parts;
    $targ->{$final} = $raw->{$k};
  }
  $self->_class->{inflate}->($self, \%new);
}

sub _deflate {
  my ($self, $obj) = @_;
  $self->_class->{deflate}->($self, $obj)
}

sub _merge { die "no" }

1;
