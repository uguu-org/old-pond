#!/usr/bin/perl -w
# Generate table of sample rate multipliers for adjusting pitch by some
# number of semitones.
#
# Normally we would generate this table with only multipliers greater than
# one (i.e. only raise pitch), but actually the pitch of the original sound
# is too high -- Tenacity's "change pitch" tool estimates the starting pitch
# to be at D7 (2400Hz).  Thus we start with negative exponents such that the
# first few entries will cause the pitch to be lowered.
#
# To compensate for Lua's 1-based indices, the generated range starts at -11.
# This is so that the table indices match the number of semitones steps away
# from C3 (e.g. rate_multiplier[12] == C4).

print "rate_multiplier =\n{\n";
for(my $i = -11; $i <= 12; $i++)
{
   print "\t", 2 ** ($i / 12.0), ",\n";
}
print "}\n";
