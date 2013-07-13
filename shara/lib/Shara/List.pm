package Shara::List;
use Mojo::Base 'Mojolicious::Controller';

 use Mojolicious::Static;
 
use 5.014;
use utf8;
use Encode;
 #use locale;
 #use POSIX qw(locale_h);
 
 use Text::Iconv;
 use Encode 'from_to';
use Mojo::Util;

sub read_dir {
	my $self = shift;
	my $dir  = shift;
	
	
	opendir(my $dh, $dir) || die "can't open dir";
	#binmode($dh, ':utf8');
	my @dir_data = grep {!($_ ~~ ['.','..'])} readdir($dh);
	#@dir_data = sort map {Encode::decode('cp1251', $_)} @dir_data;
	
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

# This action will render a template
sub list {
	my $self = shift;
	
	my $base_dir = 'C:/Users/megatron/Desktop/au/';
	my $dir = $base_dir;
	if (my $pref = $self->stash('dir')) {
		$dir .= Encode::encode('cp1251', $pref);
	}

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
				my $title = $_;
				$title =~ s/\.mp3$//;
				if ($title =~ /^\d{1,2}\s*-\s*/) {
					$title =~ s/^\d{1,2}\s*-\s*//;
				} elsif ($title =~ /^\d{1,2}\.\s+/) {
					$title =~ s/^\d{1,2}\.\s+//;
				}
				push @tracks, {
					file 	=> $_,
					title 	=> $title,
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

# This action will render a template
sub file {
	my $self = shift;
	use  HTML::Entities qw(decode_entities);
	
	my $base_dir = 'C:/Users/megatron/Desktop/au/';
	my $file = decode_entities($self->stash('file')) or die 'no file';
	#$file = $base_dir . $file;
	#die 'no file ' . $file unless -f $file;
	#die $file;
	
	my $static = Mojolicious::Static->new(paths=>[$base_dir]);
	my $fname = $file;
	$fname =~ s/^.*?([^\\\/]+)$/$1/;
	$self->res->headers->content_disposition(qq[attatchment; filename="$fname"]);
	
    # Send
    $static->serve($self, $file);
    $self->rendered;
}



1;
