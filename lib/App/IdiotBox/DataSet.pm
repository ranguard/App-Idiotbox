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
  my $fat_raw = $self->_class->{deflate}->($self, $obj);
  $self->_splat($fat_raw)
}

sub _splat {
  my ($self, $fat) = @_;
  my %raw;
  foreach my $key (keys %$fat) {
    my $v = $fat->{$key};
    $v = { %$v } if blessed($v);
    if (ref($v) eq 'HASH') {
      #my $splat = $self->_splat($v);
      my $splat = $v;
      @raw{map "${key}.$_", keys %$splat} = values %$splat;
    } else {
      $raw{$key} = $v;
    }
  }
  \%raw
}

sub _merge {
  my ($self, $new, $to_merge) = @_;
#require Carp; warn Carp::longmess; warn $new; warn $to_merge;
  @{$new}{keys %$to_merge} = values %$to_merge;
  return
}

1;
