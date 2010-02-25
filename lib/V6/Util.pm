package V6::Util;
use warnings;
use strict;
use base qw(Exporter);
use Carp qw(croak);

use Encode ();
use Data::Transformer ();
use Text::SimpleTable ();

our @EXPORT_OK = qw(
   run
   utf8_safe
   utf8_safe_tree
   uniq
);

sub run {
    my @ar = @_;
    my $parms = ref $ar[-1] eq "HASH" ? pop @ar : {};

    print "Running: ", join(" ", @ar), "\n" unless $parms->{silent};

    return 1 if system(@ar) == 0;

    my $exit_value = $? >> 8;
    return 0
      if $parms->{fail_silent_if}
          && $exit_value == $parms->{fail_silent_if};

    my $msg = "system @ar failed: $exit_value ($?)";
    croak($msg) unless $parms->{failok};
    print "$msg\n";
    return 0;
}

sub utf8_safe {
    my $text = shift;
    $text = Encode::decode("windows-1252", $text)
      unless utf8::is_utf8($text)
        or utf8::decode($text);
    return $text;
}

sub utf8_safe_tree {
    my $data = shift;    Data::Transformer->new(
        normal => sub {
            ${$_[0]} = utf8_safe(${$_[0]}) if ${$_[0]};
        }
    )->traverse($data);
    $data;
}

sub uniq (@) {
    my %h;
    map { $h{$_}++ == 0 ? $_ : () } @_;
}

sub format_leak_table {
    my @objects = @_;
    require Text::SimpleTable;
    my $t = Text::SimpleTable->new( [ 60, 'Class' ], [ 8, 'Count' ] );
    my %counts;
    $counts{ref($_)}++ for @objects;
    foreach my $class ( sort { $counts{$b} <=> $counts{$a} } keys %counts ) {
        $t->row( $class, $counts{$class} );
    }
    return $t->draw;
}


1;
