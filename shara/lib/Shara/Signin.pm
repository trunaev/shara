package Shara::Signin;
use Mojo::Base 'Mojolicious::Controller';

use 5.014;
use utf8;


sub signin {
	my $self = shift;
	#die 13;
	#die $self->req->method;
	if ($self->req->method eq 'POST') {
		my $pass = $self->param('key');
		#die $pass;
		if ($pass eq $self->config('password')) {
			$self->session(auth => 1);
			return $self->redirect_to($self->param('back_to') || '/');
		}
	}
}


1;
