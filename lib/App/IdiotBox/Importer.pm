package App::IdiotBox::Importer;

use strict;
use warnings FATAL => 'all';
use Cwd;
use IO::All;
use ExtUtils::MakeMaker qw(prompt);
use File::Spec::Functions qw(catfile catdir);
use POSIX qw(strftime);

sub log_info (&) { print $_[0]->(), "\n"; }

sub run {
  my ($class, $ib) = @_;
  my @buckets = $ib->buckets->flatten;
  my %bucket_by_slug;
  log_info { "Available buckets to import into:" };
  foreach my $idx (0 .. $#buckets) {
    my $bucket = $buckets[$idx];
    $bucket_by_slug{$bucket->slug} = $bucket;
    log_info { "(${idx}) ${\$bucket->slug} : ${\$bucket->name}" };
  }

  my $bucket;
    
  CHOOSE: {
    my $choice = prompt("Which bucket to import into (by number or slug) ?");
    if ($choice =~ /^\d+$/) {
      $bucket = $buckets[$choice];
    } else {
      $bucket = $bucket_by_slug{$choice};
    }
    unless ($bucket) {
      log_info {
         "No bucket for ${choice} - valid options are 0 to ${\$#buckets}"
         ." or slug (e.g. ${\$buckets[0]->slug})"
       };
       redo CHOOSE;
    }
  }

  my $ann = $ib->recent_announcements->add(bless({
    bucket => $bucket,
    made_at => strftime("%Y-%m-%d %H:%M:%S",localtime),
  }, 'App::IdiotBox::Announcement'));

  log_info { "Created new announcement, id ".$ann->id };

  my $video_files = $class->video_files_from_dir(my $source_dir = cwd);

  my %videos;

  foreach my $video_file (keys %{$video_files}) {

    log_info { "Processing file ${video_file}" };
    my @parts = split(/[- ]+/, $video_file);
    my @options;
    foreach my $idx (1 .. $#parts) {
      my @opt = @{$options[$idx] = [
        join(' ', @parts[0..$idx-1]),
        join(' ', @parts[$idx..$#parts]),
      ]};
      log_info { "(${idx}) ".join(' / ', @opt) };
    }
    my $info;
    CHOICE: {
      my $choice = prompt(
        'What author is this for (enter number for pre-selected combination) ?',
        2
      );
      if ($choice =~ /^\d+$/) {
        @{$info}{qw(author name)} = @{$options[$choice] || redo CHOICE};
      } else {
        $info->{author} = $choice;
      }
    }
    $info->{name} = prompt('What is the name of this talk?', $info->{name});
    (my $slug = lc $info->{name}) =~ s/ /-/g;
    $info->{slug} = prompt('What is the slug for this talk?', $slug);
    $info->{bucket} = $bucket;
    $info->{announcement} = $ann;
    $videos{$video_file} = bless($info, 'App::IdiotBox::Video');
  }
  foreach my $video_file (keys %videos) {
    my $video = $videos{$video_file};
    my $target_dir = catdir($ib->config->{base_dir}, $video->url_path);
    io($target_dir)->mkpath;
    log_info { "Copying video files to ${target_dir}"};
    foreach my $ext (@{$video_files->{$video_file}}) {
      no warnings 'void';
      io(catfile($target_dir, "${\$video->file_name}.${ext}"))
        < io(catfile($source_dir, "${video_file}.${ext}"));
    }
  }
  
  $bucket->videos->add($_) for values %videos;
}

sub video_files_from_dir {
  my ($class, $dir) = @_;
  my %videos;
  foreach my $file (io($dir)->all_files) {
    $file->filename =~ /^([^\.]+)\.([^\.]+)$/ or next;
    push(@{$videos{$1}||=[]}, $2);
  }
  \%videos;
}

1;
