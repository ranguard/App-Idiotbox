package App::IdiotBox::Store::SQLite;

use strict;
use warnings FATAL => 'all';
use DBIx::Data::Store;
use DBIx::Data::Store::CRUD;
use App::IdiotBox::DataSet;
use Scalar::Util qw(weaken);

my (%BIND, %SQL);

%BIND = (
  recent_announcements => {
    class => {
      inflate => sub {
        my ($self, $obj) = @_;
        bless($obj, 'App::IdiotBox::Announcement');
        bless($obj->{bucket}, 'App::IdiotBox::Bucket');
        $obj;
      },
      deflate => sub {
        my ($self, $obj) = @_;
        my %raw = %$obj;
        delete $raw{bucket};
        \%raw;
      }
    },
    set_over => [ 'id' ],
  },
  buckets => {
    class => {
      inflate => sub {
        my ($self, $obj) = @_;
        bless($obj, 'App::IdiotBox::Bucket');
        weaken (my $weak = $obj);
        $obj->{videos} = _bind_set('bucket_videos',
          {
            raw_store => $self->_store->raw_store,
            implicit_arguments => { bucket_slug => $obj->{slug} },
          },
          {
            class => {
              inflate => sub {
                my ($self, $obj) = @_;
                bless($obj, 'App::IdiotBox::Video');
                weaken($obj->{bucket} = $weak);
                $obj;
              },
              deflate => sub {
                my ($self, $obj) = @_;
                my %raw = %$obj;
                delete $raw{bucket};
                \%raw;
              },
            }
          }
        );
        $obj;
      },
      deflate => sub {
        my ($self, $obj) = @_;
        my %raw = %$obj;
        delete $raw{videos};
        \%raw;
      }
    },
    set_over => [ 'slug' ],
  },
  bucket_videos => {
    set_over => [ 'slug' ]
  },
);

%SQL = (
  recent_announcements => {
    select_column_order => [ qw(
      id made_at video_count bucket.slug bucket.name bucket.video_count
    ) ],
    select_sql => q{
      SELECT
        announcement.id, announcement.made_at, COUNT(DISTINCT my_videos.slug),
        bucket.slug, bucket.name, COUNT(DISTINCT all_videos.slug)
      FROM
        announcements announcement
        JOIN buckets bucket
          ON bucket.slug = announcement.bucket_slug
        JOIN videos my_videos
          ON my_videos.announcement_id = announcement.id
        JOIN videos all_videos
          ON all_videos.bucket_slug = announcement.bucket_slug
        JOIN announcements all_announcements
          ON all_announcements.bucket_slug = announcement.bucket_slug
      GROUP BY
        announcement.made_at, bucket.slug, bucket.name
      HAVING
        announcement.made_at = MAX(all_announcements.made_at)
      ORDER BY
        announcement.made_at DESC
    },
  },
  buckets => {
    select_column_order => [ qw(slug name) ],
    select_single_sql => q{
      SELECT slug, name
      FROM buckets
      WHERE slug = ?
    },
    select_single_argument_order => [ 'slug' ],
  },
  bucket_videos => {
    select_column_order => [ qw(slug name author details) ],
    select_sql => q{
      SELECT slug, name, author, details
      FROM videos
      WHERE bucket_slug = ?
    },
    select_argument_order => [ 'bucket_slug' ],
    select_single_sql => q{
      SELECT slug, name, author, details
      FROM videos
      WHERE bucket_slug = ? AND slug = ?
    },
    select_single_argument_order => [ qw(bucket_slug slug) ],
  },
);

sub bind {
  my ($class, $idiotbox) = @_;
  bless({ idiotbox => $idiotbox }, $class)->_bind;
}

sub _new_db_store {
  DBIx::Data::Store->connect("dbi:SQLite:$_[1]");
}

sub _bind {
  my $self = shift;
  my $idiotbox = $self->{idiotbox};

  my $db_store = $self->_new_db_store($idiotbox->config->{db_file});

  foreach my $to_bind (qw(recent_announcements buckets)) {
    $idiotbox->{$to_bind} = _bind_set($to_bind, { raw_store => $db_store });
  }
  $idiotbox;
}

sub _bind_set {
  my ($type, $store_args, $set_args) = @_;
  my $store = DBIx::Data::Store::CRUD->new({
    %{$SQL{$type}},
    %{$store_args},
  });
  return App::IdiotBox::DataSet->new({
    %{$BIND{$type}},
    store => $store,
    %{$set_args||{}},
  });
}

1;
