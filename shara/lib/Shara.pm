package Shara;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('list#list');
  $r->get('/d/')->to('list#list');
  $r->get('/d/*dir')->to('list#list');
  $r->get('/file/*file')->to('list#file');
  $r->get('/xspf/*dir')->to('list#xspf');
}

1;
