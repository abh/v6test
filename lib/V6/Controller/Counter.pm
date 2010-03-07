package V6::Controller::Counter;

use strict;
use warnings;

use base 'V6::Controller';
use JSON::XS qw();
use V6::Beanstalk;

my $beanstalk = V6::Beanstalk->new;
$beanstalk->use('v6-results');

my $json;

sub _json {
    return $json if $json;
    $json = JSON::XS->new;
    $json->ascii(1);
    $json->pretty(1); # should be devel mode only
    $json->convert_blessed(1);
    return $json;
}

sub index {
    return shift->redirect('/');
}

sub _count {
    my ($self, $data) = @_;
    eval { $beanstalk->put({ttr => 10}, $data) };
    if (my $err = $@) {
        $self->log->warn($err);
        return 0;
    }
    return 1;
}

sub _remote_ip {
    my $self = shift;
    if ($self->app->config->proxy_mode) {
        my $xff = $self->req->headers->header('X-Forwarded-For') || '';
        return (split /, /, $xff)[0];
    }
    return $self->tx->remote_address;
}

sub ip {
    my $self = shift;
    my $rand = my $js = _json->encode({ip => $self->_remote_ip});
    $self->res->headers->header('Cache-Control', 'private,max-age=0');
    $self->res->headers->header('Vary', '*');
    $self->res->headers->content_type('application/json');
    return $self->render_text($js);
}

sub json {
    my $self = shift;

    my $params = $self->req->params->to_hash;
    use Data::Dumper qw(Dumper);

    my $host = $self->req->headers->host || '';
    $host =~ s/:\d+$//;

    my $data = { map { $_ => $params->{$_} } grep { m/^ipv\d+/ } keys %$params };
    $data->{'user-agent'} = $self->req->headers->user_agent;
    $data->{'referrer'}   = $self->req->headers->header('referer');
    $data->{'remote_ip'}  = $self->_remote_ip;
    $data->{'site'}       = $params->{site} if $params->{site};
    $data->{'time'}       = time;
    $data->{'v6uq'}       = $params->{v6uq};
    $data->{'version'}    = $params->{version};
    $data->{'host'}       = $host;

    warn Dumper(\$data); # , \$self);

    my $rv = $self->_count($data);

    my $callback = $self->req->param('callback');
    my $js = _json->encode({ ok => $rv });

    if ($callback) {
        $callback =~ s/[^a-zA-Z0-9\.\_\[\]]//g;
        $self->res->headers->content_type('text/javascript');
        return $self->render_text("$callback($js)");
    }
    $self->res->headers->content_type('application/json');
    return $self->render_text($js);
}

1;
