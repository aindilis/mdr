package PerlLib::IE::MDR::DataRegion;

use PerlLib::IE::MDR::GeneralizedNode;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw /
	Node Region GNodes
      /
  ];

sub init {
  my ($s,%a) = @_;
  $s->Node($a{Node});
  $s->Region($a{Region} || [0,0,0]);
  $s->GNodes([]);
}

sub ID {
  my ($s,%a) = @_;
  return "[".join(",",($s->Node->ID,@{$s->Region}))."]";
}

sub Copy {
  my ($s,%a) = @_;
  $s->Node($a{DR}->Node);
  $s->Region($a{DR}->Region);
  print $s->ID."TADA\n" if $debug;
}

sub Covers {
  my ($s,%a) = @_;
  # $a{DR}
  # okay how do we implement this
}

sub RegionNotEmpty {
  my ($s,%a) = @_;
  return $s->Region->[2] > 0;
}

sub GeneralizedNodes {
  my ($s,%a) = @_;
  if (! scalar @{$s->GNodes}) {
    if ($s->RegionNotEmpty) {
      # now we need to pump out the 
      my $windowsize = $s->Region->[0];
      my $startlocation = $s->Region->[1];
      my $numgenlsnodes = $s->Region->[2] / $windowsize;
      for (my $i = 0; $i < $numgenlsnodes; ++$i) {
	my @set = $startlocation + $i * $windowsize .. $startlocation + ($i + 1) * $windowsize - 1;
	# print Dumper(\@set);
	my @nodes;
	foreach my $index (@set) {
	  push @nodes, $s->Node->Children->[$index];
	}
	my $gnode = PerlLib::IE::MDR::GeneralizedNode->new
	  (Nodes => \@nodes);
	push @{$s->GNodes}, $gnode;
      }
    }
  }
  return $s->GNodes;
}

1;
