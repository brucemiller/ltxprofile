#!/usr/bin/perl -w
use strict;
use warnings;
use YAML::Tiny;
use Data::Dumper;

my @choices = grep {defined} map {/^--([\w\-]+)=([\w\-.]+)$/ && ($1,$2);} @ARGV;

# Note that we are still building the full array of options that LaTeXML needs,
#  in order to then build an options hash; as we are trying to be backwards compat.
#  and manage e.g. --path=foo --path=bar or --pmml --nopmml --cmml
my @options = ();
my $defaults = {};
my $definitions = {};

# Parse options:
while (my ($k, $v) = splice(@choices,0,2)) {
  # Load if profile:
  if (($k eq 'profile') || ($k eq 'format')) {
    my $profile_spec = load_profile(name=>$v, defaults=>$defaults, definitions=>$definitions); 
    my $cfg_opts = $profile_spec->{cfg_opts};
    # Simply append to @options:
    @options = (@options, %$cfg_opts); }
  # Otherwise simple overwrite (for basic example):
  else { push @options, ($k,$v); } }

# Simple overwrite with defaults:
@options = (%$defaults, @options);

# Result:
my @printable = ();
while (my ($k, $v) = splice(@options,0,2)) {
  push @printable, [$k, $v]; }
print STDERR Dumper(\@printable);

# Definitions:
print STDERR Dumper($definitions);

### ------------------------------------------
### Profile logic:
sub load_profile {
  my (%options) = @_;
  my ($name, $defaults, $cfg_opts, $definitions) = map {$options{$_}} qw(name defaults cfg_opts definitions);
  # 0. Initialize a CFG_OPTS options hash local to this profile
  $cfg_opts = {} unless defined $cfg_opts;
  $definitions = {} unless defined $definitions;
  $defaults = {} unless defined $defaults;
  # 1. Load profile file and parse YAML definitions
  my $yaml = YAML::Tiny->read("lib/AltConfig/$name.ltxcfg");
  return [] unless $yaml && $yaml->[0];
  my $cfg = $yaml->[0];
  
  # 2. DFS descent into dependencies, go to 1. for each, passing in the current CFG_OPTS
  foreach my $dependency(@{($cfg->{dependencies} || [])}) {
    load_profile(name=>$dependency, defaults=>$defaults, cfg_opts=>$cfg_opts, definitions=>$definitions); }

  # 3. Process definitions. On collisions, merge definition hashes, overwriting key values where needed
  foreach my $processor(keys %{$cfg->{definitions} || {}}) {
    $definitions->{$processor} = {} unless defined $definitions->{$processor};
    my $defs_processor = $definitions->{$processor};
    foreach my $pk (keys %{$cfg->{definitions}->{$processor}}) {
      $defs_processor->{$pk} = $cfg->{definitions}->{$processor}->{$pk}; } }
  # 4. Process "requires". On collisions, overwrite values.
  foreach my $key (keys %{$cfg->{requires} || {}}) {
    $cfg_opts->{$key} = $cfg->{requires}->{$key}; }
  
  # 5. Suspend processing "defaults" by pushing them on a global DEFAULTS_OPTS
  foreach my $key (keys %{$cfg->{defaults} || {}}) {
    $defaults->{$key} = $cfg->{defaults}->{$key}; }
  
  # 6. Return the assembled CFG_OPTS
  return {cfg_opts => $cfg_opts, definitions => $definitions, defaults => $defaults};
}
