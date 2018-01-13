package PerlLib::IE::MDR::GeneralizedNode;

use Data::Dumper;
use String::Similarity qw (similarity);

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw /
	Nodes
      /
  ];

sub init {
  my ($s,%a) = @_;
  $s->Nodes($a{Nodes});
}

sub TagString {
  my ($s,%a) = @_;
  # return the tag string of a generalized node
  return join(" ", (map {$_->TagString} @{$s->Nodes}));
}

sub EditDistance {
  my ($s,%a) = @_;
  return 1.0 - similarity($s->TagString,$a{GeneralizedNode}->TagString);
}

sub ExtractRecords {
  my ($s,%a) = @_;
  # now we iterate over the nodes and print out their contents
  my @records;
  foreach my $node (@{$s->Nodes}) {
    push @records, $node->ExtractRecords;
  }
  return \@records;
}

sub FindRecords {
  my ($s,%a) = @_;
  my $numnodes = scalar @{$s->Nodes};
  if ($numnodes == 1) {
    return $s->FindRecords1;
  } elsif ($numnodes > 1) {
    return $s->FindRecordsN;
  }
}

sub FindRecords1 {
  my ($s,%a) = @_;
  my @records;
  my $node = $s->Nodes->[0];
  # if all children nodes of $s are similar
  if ($node->AllChildrenAreSimilar and
      # and $s is not a data table row then
      $node->Tag ne "tr") {
    # each child node of $s is a data record
    push @records, @{$node->ExtractRecords};
  } else {
    # else $s is a record
    push @records, $s->ExtractRecords;
  }
  return \@records;
}

sub FindRecordsN {
  my ($s,%a) = @_;
  my @records;
  # if the children nodes of each node in G are similar and each node
  # also has the same number of children then
  # the corresponding children nodes of node in G
  # form a non-contiguous object description
  # else G itself is a data record
  return \@records;
}

1;
