package App::IdiotBox;

use Web::Simple __PACKAGE__;
use Method::Signatures::Simple;
use FindBin;
use HTML::Zoom;

{
  package App::IdiotBox::Announcement;

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
}

default_config(
  template_dir => $FindBin::Bin.'/../share/html'
);

dispatch {
  sub (/) { $self->show_front_page },
  subdispatch sub (/*/...) {
    my $bucket = $self->buckets->get({ slug => $_[1] });
    [
      sub (/) {
        $self->show_bucket($bucket)
      },
      sub (/*) {
        $self->show_video($bucket->videos->get({ slug => $_[1] }));
      }
    ]
  }
};

method recent_announcements { $self->{recent_announcements} }

method show_front_page {
  my $ann = $self->recent_announcements;
  $self->html_response(
    front_page => [
      '#announcement-list' => [
        -repeat_content => {
          repeat_for => $ann->map(sub { [
            '.fill-bucket-name' => [
              -replace_content => { replace_with => $_->bucket->name }
            ],
            '.fill-bucket-link' => [
              -set_attribute => { name => 'href', value => $_->bucket->slug.'/' }
            ],
            '.fill-new-videos' => [
              -replace_content => { replace_with => $_->video_count }
            ],
            '.fill-total-videos' => [
              -replace_content => { replace_with => $_->bucket->video_count }
            ],
          ] })->as_stream
        }
      ]
    ]
  );
}

method show_bucket ($bucket) {
  $self->html_response(bucket => [
    '.fill-bucket-name' => [
      -replace_content => { replace_with => $bucket->name }
    ],
    '#video-list' => [
      -repeat_content => {
        repeat_for => $bucket->videos->map(sub { [
          '.fill-video-name' => [
            -replace_content => { replace_with => $_->name }
          ],
          '.fill-video-author' => [
            -replace_content => { replace_with => $_->author }
          ],
          '.fill-video-link' => [
            -set_attribute => {
              name => 'href', value => $_->slug.'/'
            }
          ],
        ] })->as_stream
      }
    ]
  ]);
}

method show_video ($video) {
  $self->html_response(video => [
    '.fill-video-name' => [
      -replace_content => { replace_with => $video->name }
    ],
    '.fill-author-name' => [
      -replace_content => { replace_with => $video->author }
    ],
    '.fill-bucket-link' => [
      -set_attribute => { name => 'href', value => '../' }
    ],
    '.fill-bucket-name' => [
      -replace_content => { replace_with => $video->bucket->name }
    ],
    '.fill-video-details' => [
      -replace_content => { replace_with => $video->details }
    ]
  ]);
}

method html_response ($template_name, $selectors) {
  my $io = $self->_zoom_for($template_name => $selectors)->as_readable_fh;
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
              ->with_selectors(
                  '#main-content' => [
                    -capture_events => { into => \@body }
                  ]
                )
              ->run;
    $self->_layout_zoom->with_selectors(
      '#main-content' => [
        -replace_content_events => { replace_with => \@body }
      ]
    )->to_zoom;
  })->with_selectors($selectors)
}

1;
