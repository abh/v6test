package V6::Controller::Counter;

use strict;
use warnings;

use base 'V6::Controller';
use JSON::XS qw();

my $json;

sub _json {
    return $json if $json;
    $json = JSON::XS->new;
    $json->ascii(1);
    $json->pretty(1); # should be devel mode only
    $json->convert_blessed(1);
    return $json;
}

sub json {
    my $self = shift;
    my $rv = { ok => 1 };

    my $params = $self->req->params->to_hash;
    use Data::Dumper qw(Dumper);

    my $data = { map { $_ => $params->{$_} } grep { m/^ipv\d+/ } keys %$params };

    $data->{'user-agent'} = $self->req->headers->user_agent;
    $data->{'referrer'}   = $self->req->headers->header('referer');
    $data->{'remote_ip'}  = $self->tx->remote_address;
    $data->{'site'}       = $params->{site} if $params->{site};
    $data->{'time'}       = time;

    warn Dumper(\$data); # , \$self);

    my $callback = $self->req->param('callback');
    my $js = _json->encode($rv);

    if ($callback) {
        $callback =~ s/[^a-zA-Z0-9\.\_\[\]]//g;
        $self->res->headers->content_type('text/javascript');
        return $self->render_text("$callback($js)");
    }
    $self->res->headers->content_type('application/json');
    return $self->render_text($js);
}

1;
