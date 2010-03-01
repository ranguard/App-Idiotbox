package App::IdiotBox;

use Web::Simple __PACKAGE__;
use Method::Signatures::Simple;
use FindBin;
use HTML::Zoom;
use HTML::Zoom::FilterBuilder::Template;

{
  package App::IdiotBox::Announcement;

  sub id { shift->{id} }
  sub made_at { shift->{made_at} } 
  sub bucket { shift->{bucket} } 
  sub video_count { shift->{video_count} } 

  package App::IdiotBox::Bucket;

  sub slug { shift->{slug} }
  sub name { shift->{name} }
  sub video_count {
    exists $_[0]->{video_count}
      ? $_[0]->{video_count}
      : $_[0]->{videos}->count
  }
  sub videos { shift->{videos} }

  package App::IdiotBox::Video;

  sub slug { shift->{slug} }
  sub name { shift->{name} }
  sub author { shift->{author} }
  sub details { shift->{details} }
  sub bucket { shift->{bucket} }
  sub file_name {
    (my $s = join(' ', @{+shift}{qw(author name)})) =~ s/ /-/g;
    $s;
  }
  sub url_path {
    join('/', $_[0]->bucket->slug, $_[0]->slug);
  }
}

default_config(
  template_dir => 'share/html',
  store => 'SQLite',
  db_file => 'var/lib/idiotbox.db',
  base_url => 'http://localhost:3000/',
  base_dir => do { use FindBin; $FindBin::Bin },
);

sub BUILD {
  my $self = shift;
  my $store;
  ($store = $self->config->{store}) =~ /^(\w+)$/
    or die "Store config should be just a name, got ${store} instead";
  my $store_class = "App::IdiotBox::Store::${store}";
  eval "require ${store_class}; 1"
    or die "Couldn't load ${store} store: $@";
  $store_class->bind($self);
}
  
dispatch {
  sub (/) { $self->show_front_page },
  subdispatch sub (/*/...) {
    my $bucket = $self->buckets->get({ slug => $_[1] });
    [
      sub (/) {
        $self->show_bucket($bucket)
      },
      sub (/*/) {
        $self->show_video($bucket->videos->get({ slug => $_[1] }));
      }
    ]
  }
};

method recent_announcements { $self->{recent_announcements} }

method buckets { $self->{buckets} }

method show_front_page {
  my $ann = $self->recent_announcements;
  $self->html_response(
    front_page => sub {
      $_->select('#announcement-list')
        ->repeat_content($ann->map(sub {
            my $obj = $_;
            sub {
              $_->select('.bucket-name')->replace_content($obj->bucket->name)
                ->select('.bucket-link')->set_attribute({
                    name => 'href', value => $obj->bucket->slug.'/'
                  })
                ->select('.new-videos')->replace_content($obj->video_count)
                ->select('.total-videos')->replace_content(
                    $obj->bucket->video_count
                  )
            }
          }))
    }
  );
}

method show_bucket ($bucket) {
  $self->html_response(bucket => sub {
    $_->select('.bucket-name')->replace_content($bucket->name)
      ->select('#video-list')->repeat_content($bucket->videos->map(sub {
          my $video = $_;
          sub {
            $_->select('.video-name')->replace_content($video->name)
              ->select('.video-author')->replace_content($video->author)
              ->select('.video-link')->set_attribute(
                  { name => 'href', value => $video->slug.'/' }
                )
          }
        }))
  });
}

method show_video ($video) {
  $self->html_response(video => sub {
    my $video_url = 
      $self->base_url
      .join('/', $video->bucket->slug, $video->slug, $video->file_name.'.flv');

    $_->select('.video-name')->replace_content($video->name)
      ->select('.author-name')->replace_content($video->author)
      ->select('.bucket-link')->set_attribute(
          { name => 'href', value => '../' }
        )
      ->select('.bucket-name')->replace_content($video->bucket->name)
      ->select('.video-details')->replace_content($video->details)
      ->select('script')->template_text_raw({ video_url => $video_url });
  });
}

method html_response ($template_name, $selectors) {
  my $io = $self->_zoom_for($template_name => $selectors)->to_fh;
  return [ 200, [ 'Content-Type' => 'text/html' ], $io ]
}

method _template_filename_for ($name) {
  $self->{config}{template_dir}.'/'.$name.'.html';
}

method _layout_zoom {
  $self->{layout_zoom} ||= HTML::Zoom->from_file(
    $self->_template_filename_for('layout')
  )
}

method _zoom_for ($template_name, $selectors) {
  ($self->{zoom_for_template}{$template_name} ||= do {
    my @body;
    HTML::Zoom->from_file(
                  $self->_template_filename_for($template_name)
                )
              ->select('#main-content')->collect_content({ into => \@body })
              ->run;
    $self->_layout_zoom
         ->select('#main-content')->replace_content(\@body)
         ->memoize;
  })->apply($selectors);
}

method base_url {
  $self->{base_url} ||= do {
    (my $u = $self->config->{base_url}) =~ s/\/$//;
    "${u}/";
  }
}

method _run_cli {
  unless (@ARGV == 1 && $ARGV[0] eq 'import') {
    return $self->SUPER::_run_cli(@_);
  }
  $self->cli_import;
}

method _cli_usage {
  "To import data into your idiotbox install, chdir into a directory\n".
  "containing video files and run:\n".
  "\n".
  "  $0 import\n".
  "\n".
  $self->SUPER::_cli_usage(@_);
}

method cli_import {
  require App::IdiotBox::Importer;
  App::IdiotBox::Importer->run($self);
}

1;
