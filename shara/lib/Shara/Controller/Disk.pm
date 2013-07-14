package Shara::Controller::Disk;
use Mojo::Base 'Mojolicious::Controller';

 use Mojolicious::Static;
 
use 5.014;
use utf8;

use Encode 'from_to';
use Encode;
require Encode::Detect;
  
use HTML::Entities qw(decode_entities);
use Mojo::Util;
use MP3::Tag;
use MP3::Info;

sub base_dir {
	return 'C:/Users/megatron/Music/';
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
	@dirs = sort @dirs;
	@files = sort @files;
		
	return (\@dirs, \@files);

}

sub get {
	my $self = shift;
	#die 123;
	
	my $base_dir = $self->base_dir;
	my $path = $self->stash('path');
	my $path_orig = $path;
	if ($path) {
		#die $path;
		eval {
			$path = decode('cp1251', $path);
		};
		#$path = decode('cp1251', $path);
		#die $path;
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
	$self->stash->{subdirs} //= [];
	if ($path) {
		my @parts = grep {$_} split /\//, $path;
		if (@parts > 1) {
			my ($dirs, $files) = $self->read_dir($base_dir . $parts[0]. '/');
			$self->stash->{subdirs} //= [];
			$self->stash->{subdirs}->[0] = $dirs if @$dirs > 1;
			#use Data::Dumper;
			#die Dumper $dirs;
			#die Dumper $self->stash->{subdirs};
		}		
	}

	my ($dirs, $files) = $self->read_dir($dir);
	
	$self->stash(dirs	=> $dirs);
	$self->stash(files 	=> $files);
	
	if (@$files) {
		if (my @images = grep {/\.(jpe?g|png|gif)$/i} @$files) {
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
		#my $dir = Encode::encode('cp1251', $path);
		for my $f (@$files) {
			if ($f =~ /\.(mp3|ogg)$/i) {
				my $format = lc $1;
				my $title = $_;
				$title =~ s/\.mp3$//;
				if ($title =~ /^\d{1,2}\s*-\s*/) {
					$title =~ s/^\d{1,2}\s*-\s*//;
				} elsif ($title =~ /^\d{1,2}\.\s+/) {
					$title =~ s/^\d{1,2}\.\s+//;
				}

				my $mp3_path = $dir;
				eval { 
					#	$mp3_path .= $_;
						$mp3_path .= Encode::encode('cp1251', $f);
				};
				die $mp3_path . ' - ' . $@ if $@;
				my $mp3 = new MP3::Tag($mp3_path);
				my ($title2, $track, $artist, $album, $comment, $year, $genre) = $mp3->autoinfo();
				#my $_mp3 = get_mp3tag($mp3_path);				
				#my $title2 = $mp3
				#use Data::Dumper;
				#die Dumper $_mp3;
				my $num = $track;
				if ($num) {
					if ($num =~ /^(\d+)\/\d+$/) {
						$num = $1;
					}
					$num = int $num if ($num =~ /^\d+$/);
				}
				my $file = '/d/'. $path_orig.$f;
				#die $file;
				$title = $title2 || $title;
				#die $title;
				eval {$title = decode('cp1251', $title)};
				eval {$artist = decode('cp1251', $artist)};
				my $cover = $self->stash('cover');
				# $cover = '/d/'. $path_orig. $cover if $cover;
				
				push @tracks, {
					$format	=> $file,
					title 	=> $title,
					artist	=> $artist,
					cover	=> $cover,
					file	=> $f,
					track	=> $num,
				};
			} else {
				push @others, $f;
			}
		}
		$self->stash(
			tracks => \@tracks,
			others => \@others,
		);
	}
}


1;
