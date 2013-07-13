package Shara;
use Mojo::Base 'Mojolicious';


use constant SECRET => '$Xv_e&5[#';

sub startup {
	my $self = shift;
	
	$self->plugin('Config');
	$self->secret(SECRET);
	$self->sessions->cookie_name('s');
	$self->sessions->default_expiration(0);

	# Router
	my $r0 = $self->routes;
	my $r = $r0->under(sub{
		if (!$_[0]->session->{auth}){
			return $_[0]->redirect_to('/');
		}
		return 1;
	});
	
	my $signin = $r0->under(sub{
		if ($_[0]->session->{auth}){
			return $_[0]->redirect_to('/d/');
		}
		return 1;
	});
	

	$r->get('/d/')->to('disk#get');
	$r->get('/d/*path')->to('disk#get');
	
	$signin->get('/')->to('signin#signin');
	$signin->get('/signin')->via(qw/GET POST/)->to('signin#signin');
}

1;
