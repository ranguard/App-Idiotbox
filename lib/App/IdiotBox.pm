package App::IdiotBox;

use Web::Simple __PACKAGE__;
use Method::Signatures::Simple;

dispatch {
  sub (/) { $self->show_front_page },
  subdispatch sub (/*/...) {
    my $bucket = $self->buckets->get({ slug => $_[1] });
    [
      sub (/) {
        $self->show_bucket($bucket)
      },
      sub (/*) {
        $self->show_video($bucket->videos->get({ slug => $_[1] });
      }
    ]
  }
};

method show_front_page {
  my $ann = $self->recent_announcements;
  $self->html_response(
    front_page => [
      '#announcement-list' => {
        -repeat => {
          data => $ann->map(sub { +{
            '#fill-bucket-name' => { -replace_content => $_->bucket->name },
            '#fill-bucket-link' => {
              -set_attribute => { name => 'href', value => '/'.$_->slug.'/' }
            },
            '#fill-new-videos' => $_->videos->count,
            '#fill-total-videos' => $_->bucket->videos->count,
          } })
        }
      }
    ]
  );
}

method html_response ($template_name, $selectors) {
  my $io = $self->_zoom_for($template_name => $selectors)->as_io;
  return [ 200, [ 'Content-Type' => 'text/html' ], $io ]
}

method _layout_zoom {
  $self->{layout_zoom} ||= HTML::Zoom->from_filename(
    $self->_teamplate_filename_for('layout')
  )
}

method _zoom_for ($template_name, $selectors) {
  ($self->{zoom_for_template}{$template_name} ||= do {
    my @body;
    HTML::Zoom->from_filename(
                  $self->_template_filename_for($template_name);
                )
              ->with_selectors(
                '#main-content' => { -capture_events_into => \@body }
                )
              ->to_bit_bucket;
    my @all = $self->_layout_zoom->with_selectors(
      '#main-content' => {
        -replace_content_events => \@body
      }
    )->to_event_array;
    HTML::Zoom->from_events(\@all)
  })->with_selectors(@$selectors)
}

1;
