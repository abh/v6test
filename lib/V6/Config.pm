package V6::Config;
use strict;
use warnings;
use JSON::XS;
use File::Slurp qw(read_file);
use Moose;
use MooseX::Singleton;
use File::HomeDir;


my $json = JSON::XS->new->relaxed(1);

sub base_url {
    my $self = shift;
    my $host = shift;
    my $url  = $self->_base_url;
    return $url unless $host;
    $url =~ s/www/$host/;
    return $url;
}

has '_base_url' =>
    ( is      => 'rw',
      isa     => 'Str',
      lazy    => 1,
      default => sub { $_[0]->_config_hash()->{base_url} },
    );

has 'base_domain' => 
    ( is      => 'rw',
      isa     => 'Str',
      lazy    => 1,
      default => sub { $_[0]->_config_hash()->{base_domain} 
                       || Mojo::URL->new($_[0]->base_url)->host();
                     },
    );

has 'beanstalk_server' =>
    ( is      => 'rw',
      isa     => 'Str',
      lazy    => 1,
      default => sub { $_[0]->_config_hash()->{beanstalk_server} || '127.0.0.1' },
    );

has 'mongodb_config' =>
    ( is      => 'rw',
      isa     => 'HashRef',
      lazy    => 1,
      auto_deref => 1, 
      default => sub { my $h = $_[0]->_config_hash()->{mongodb_config};
                       $h ? $h : { host => 'localhost', port => 27017 };
                   },
    );

has 'google_analytics' =>
    ( is      => 'rw',
      isa     => 'Str',
      lazy    => 1,
      default => sub { $_[0]->_config_hash()->{google_analytics} || '' },
    );

has 'test_image_domain' =>
    ( is      => 'rw',
      isa     => 'Str',
      lazy    => 1,
      default => sub { $_[0]->_config_hash()->{test_image_domain} || 'v6test.develooper.com' },
    );

has 'proxy_mode' =>
    ( is      => 'rw',
      isa     => 'Bool',
      lazy    => 1,
      default => sub { $_[0]->_config_hash()->{proxy_mode} || 0 },
    );

has 'rpx_api_key' =>
    ( is      => 'rw',
      isa     => 'Str',
      lazy    => 1,
      default => sub { $_[0]->_config_hash()->{rpx_api_key} || 0 },
    );

has 'cdn_url' =>
    ( is      => 'rw',
      isa     => 'Str',
      lazy    => 1,
      # http://ajax.googleapis.com/ajax/
      default => sub { $_[0]->_config_hash()->{cdn_url} || 'http://st.pimg.net/cdn/' },
    );


has '_config_hash' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_config_hash',

    # for testing
    writer  => '_set_config_hash',
    clearer => '_clear_config_hash',
);

has '_config_file' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_config_file',

    # for testing
    clearer => '_clear_config_file',
);

sub _build_config_hash {
    my ($self, $app) = @_;

    my $file = $self->_config_file;
    my $data = $json->decode(scalar read_file($file));

    return $data;
}

has '_home_dir' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { File::HomeDir->my_home() },
    writer  => '_set_home_dir',
);

sub _build_config_file {
    my $self = shift;

    if ($ENV{V6_CONFIG}) {
        die "Nonexistent config file in V6_CONFIG env: $ENV{V6_CONFIG}"
          unless -f $ENV{V6_CONFIG};
        return $ENV{V6_CONFIG};
    }

    my @looked;

    my @dirs = ('/etc/v6test');
    $> and push @dirs, $self->_home_dir() . "/$_" for qw(.v6test etc);

    for my $dir (@dirs) {
        my $file = $dir . '/v6test.conf';
        return $file if -f $file;
        push @looked, $file;
    }

    die "Could not find a v6test.conf configuration file (@looked)\n";
}

__PACKAGE__->meta()->make_immutable();
no Moose;

1;
