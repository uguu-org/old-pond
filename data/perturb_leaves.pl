#!/usr/bin/perl -w
# Apply perturbations to cloned leaf elements, for use with creating
# swaying animations.
#
# perl {frame_index} < world.svg > perturbed_world.svg


use strict;
use Digest::MD5 qw(md5);
use XML::LibXML;

use constant PI => 3.14159265358979323846264338327950288419716939937510;

# Total number of frames.
use constant FRAME_COUNT => 8;

# Maximum displacement distance in pixels.
#
# Because the displacement oscillates between [-1,1], the maximum distance
# moved will actually be double of this number.
use constant MAX_DISTANCE => 0.9;

# Apply changes to layers matching this pattern.
use constant LAYER_PATTERN => "^world - tree leaves.*";

# Find the starting coordinate of each path and index them by ID.
# This is used to determine the coordinates for the source of the cloned
# objects.
sub collect_paths($$)
{
   my ($dom, $path_table) = @_;

   foreach my $path ($dom->getElementsByTagName("path"))
   {
      my $d = eval('$path->{"d"}');
      if( defined($d) &&
          $d =~ /^\s*[mM]\s*(-?\d+(?:\.\d*))[ ,](-?\d+(?:\.\d*))\s+/ )
      {
         $$path_table{$path->{"id"}} = [$1, $2];
      }
   }
}

# Apply perturbations.
sub recursive_apply($$$);
sub recursive_apply($$$)
{
   my ($node, $path_table, $frame_index) = @_;

   # Only apply to clone elements with matrix transformations.
   if( $node->nodeName eq "use" )
   {
      my $origin = eval('$node->{"xlink:href"}');
      if( defined($origin) && $origin =~ /^#(.*)$/ && exists $$path_table{$1} )
      {
         my $ox = $$path_table{$1}[0];
         my $oy = $$path_table{$1}[1];
         my $transform = eval('$node->{"transform"}');
         if( defined($transform) &&
             $transform =~ /^matrix\(([^,]+)[, ]([^,]+)[, ]([^,]+)[, ]
                                     ([^,]+)[, ]([^,]+)[, ]([^,]+)\)$/x )
         {
            my ($a, $b, $c, $d, $e, $f) = ($1, $2, $3, $4, $5, $6);

            # Compute position of this clone.
            my $tx = $a * $ox + $c * $oy + $e;
            my $ty = $b * $ox + $d * $oy + $f;

            # Set shift direction based on absolute position of clone,
            # such that leaves that are near each other will sway in the
            # same direction.
            my $direction = 2 * PI * sin($tx * 0.03 * cos(PI / 3) +
                                         $ty * 0.04 * sin(PI / 3));

            # Set shift phase based on hash of node ID.  This makes it
            # random yet deterministic.
            my @hash_bytes = unpack "C*", md5($node->{"id"});
            my $phase = ($hash_bytes[0] + $frame_index) % FRAME_COUNT;

            # Apply shift.
            #
            # Here we are using sine function for oscillating magnitude.
            # A different function to try would be:
            #  (4 * abs(0.5 - $phase / FRAME_COUNT) - 1) * MAX_DISTANCE
            #
            # The result is roughly the same.
            my $amplitude =
               sin($phase * 2.0 * PI / FRAME_COUNT) * MAX_DISTANCE;

            $e += $amplitude * cos($direction);
            $f += $amplitude * sin($direction);

            # Rewrite transformation matrix.
            $node->{"transform"} = "matrix($a,$b,$c,$d,$e,$f)";
         }
      }
   }

   # Recursively apply to child.
   foreach my $child ($node->childNodes())
   {
      recursive_apply($child, $path_table, $frame_index);
   }
}


if( $#ARGV < 0 )
{
   die "$0 {frame_index}\n";
}
my $frame = shift @ARGV;
unless( $frame =~ /^\d+$/ && $frame >= 0 && $frame < FRAME_COUNT )
{
   die "Bad frame index $frame\n";
}

# Load XML from stdin or last argument.
my $dom = XML::LibXML->load_xml(huge => 1, string => join "", <ARGV>);

# Collect source coordinates for clone templates.
my %paths = ();
collect_paths($dom, \%paths);

# Iterate through all group nodes.
my $layer_pattern = LAYER_PATTERN;
$layer_pattern = qr/$layer_pattern/;
foreach my $group ($dom->getElementsByTagName("g"))
{
   if( defined $group->{"inkscape:groupmode"} &&
       defined $group->{"inkscape:label"} &&
       $group->{"inkscape:groupmode"} eq "layer" &&
       $group->{"inkscape:label"} =~ $layer_pattern )
   {
      recursive_apply($group, \%paths, $frame);
   }
}

# Output updated XML.
print $dom->toString(), "\n";
