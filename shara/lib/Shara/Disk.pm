package Shara::Disk;
use Mojo::Base 'Mojolicious::Controller';

 use Mojolicious::Static;
 
use 5.014;
use utf8;

use Encode 'from_to';

use HTML::Entities qw(decode_entities);
use Mojo::Util;
use MP3::Tag;

sub base_dir {
	return 'C:/Users/megatron/Desktop/au/';
}



sub read_dir {
	my $self = shift;
	my $dir  = shift;
	
	opendir(my $dh, $dir) || die "can't open dir";
	my @dir_data = grep {!($_ ~~ ['.','..'])} readdir($dh);
	closedir $dh;

	my (@dirs, @files);
	for (@dir_data) {
		if (-d $dir . $_) {
			push @dirs, Encode::decode('cp1251',$_);
		} else {
			push @files, Encode::decode('cp1251',$_);
		}
	}
		
	return (\@dirs, \@files);

}

sub get {
	my $self = shift;
	#die 123;
	
	my $base_dir = $self->base_dir;
	my $path = $self->stash('path');
	if ($path) {
		$path = decode_entities($path);
		$path = Encode::encode('cp1251', $path);
	}

	if (-f $base_dir . $path) {
		my $static = Mojolicious::Static->new(paths=>[$base_dir]);
		if ($path =~ /\.(mp3|ogg)$/i) {
			my $fname = $path;
			$fname =~ s/^.*?([^\\\/]+)$/$1/;
			$self->res->headers->content_disposition(qq[attatchment; filename="$fname"]);
		}

	    $static->serve($self, $path);
	    return $self->rendered;
	}
	
	my $dir = $base_dir . $path;
	return $self->render_not_found unless -d $dir;

	my ($dirs, $files) = $self->read_dir($dir);
	
	$self->stash(dirs	=> $dirs);
	$self->stash(files 	=> $files);
	
	if ($self->param('tar')) {
		use Archive::Tar;
		
	}	
	
	if (@$files) {
		if (my @images = grep {/\.(jpg|png)$/i} @$files) {
			for my $check_name (qw(folder front cover album top)) {
				for my $img (@images) {
					my $i = lc $img;
					$i =~ s/\.(jpg|png)$//;
					if ($i eq $check_name) {
						$self->stash(cover => $img);
						#die $img;
						last;
					}
				}
			}
			$self->stash(cover => $images[0]) unless $self->stash('cover');
		}
		my @tracks;
		my @others;
		for (@$files) {
			if (/\.(mp3|ogg)$/i) {
				my $format = lc $1;
				my $title = $_;
				$title =~ s/\.mp3$//;
				if ($title =~ /^\d{1,2}\s*-\s*/) {
					$title =~ s/^\d{1,2}\s*-\s*//;
				} elsif ($title =~ /^\d{1,2}\.\s+/) {
					$title =~ s/^\d{1,2}\.\s+//;
				}
				my $mp3 = MP3::Tag->new($dir.'/'.$_);
				my ($title2, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo();
				push @tracks, {
					$format	=> '/d/'. $path.'/'.$_,
					title 	=> ($artist && 0 ? "$artist - " : '') . $title2 || $title,
					artist	=> $artist,
					cover	=> $self->stash ('cover'),
					file	=> $_,
				};
			} else {
				push @others, $_;
			}
		}
		$self->stash(
			tracks => \@tracks,
			others => \@others,
		);
	}
}


1;
