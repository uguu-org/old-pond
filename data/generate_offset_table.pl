#!/usr/bin/perl -w

use strict;
use constant PI => 3.14159265358979323846264338327950288419716939937510;
use constant DIRECTION_COUNT => 16;
use constant X_VELOCITY => 100;
use constant Y_VELOCITY => 50;

print "movement_offsets =\n{\n";
for(my $i = 0; $i < DIRECTION_COUNT; $i++)
{
   my $a = $i * 2.0 * PI / DIRECTION_COUNT;
   print "\t{", int(X_VELOCITY * sin($a)),
         ", ", int(-Y_VELOCITY * cos($a)),
         "},\t-- $i\n";
}
print "}\n";
