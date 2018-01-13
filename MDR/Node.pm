package PerlLib::IE::MDR::Node;

use PerlLib::IE::MDR::DataRegion;
use PerlLib::IE::MDR::GeneralizedNode;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw /

	ID Tag Parent Children Element TreeDepth DRs Distance Content Debug

      /
  ];

sub init {
  my ($s,%a) = @_;
  $s->Parent();
  $s->DRs({});
  $s->Children([]);
  $s->Distance({});
  $s->Element($a{Element});
  $s->Tag($s->Element->tag);
  $s->Debug($a{Debug} || 0);
  my $maxdepth = 1;
  foreach my $element ($a{Element}->content_list()) {
    my $ref = ref $element;
    my $node;
    if ($ref eq "HTML::Element") {
      my $node = PerlLib::IE::MDR::Node->new
	(Element => $element);
      $node->Parent($s);
      if ($maxdepth < $node->TreeDepth + 1) {
	$maxdepth = $node->TreeDepth + 1;
      }
      $s->AddChild
	(Child => $node);
    }
  }
  $s->TreeDepth($maxdepth);
}

sub IndentString {
  my ($s,%a) = @_;
  $a{Indent} |= "";
  my $res = $a{Indent}.($a{WithID} ? $s->ID." " : "").$s->Tag."\n";
  foreach my $child (@{$s->Children}) {
    $res .= $child->IndentString
      (
       Indent => $a{Indent}." ",
       WithID => $a{WithID},
      );
  }
  return $res;
}

sub TagString {
  my ($s,%a) = @_;
  # return the tag string of a node
  my $tagstring = $s->Tag;
  foreach my $child (@{$s->Children}) {
    $tagstring .= " ".$child->TagString;
  }
  return $tagstring;
}

sub AddChild {
  my ($s,%a) = @_;
  push @{$s->Children}, $a{Child};
}

sub MDR {
  my ($s,%a) = @_;
  # print $s->TagString."\n";
  if ($s->TreeDepth >= 3) {
    $s->CombComp
      (
       NodeList => \@{$s->Children},
       K => $a{K},
      );
    foreach my $childnode (@{$s->Children}) {
      $childnode->MDR
	(K => $a{K});
    }
  }
}

sub CombComp {
  my ($s,%a) = @_;
  my $length = scalar @{$a{NodeList}};
  for (my $startlocation = 0; $startlocation < $a{K}; ++$startlocation) {
    for (my $windowsize = $startlocation + 1; $windowsize <= $a{K}; ++$windowsize) {
      if (exists $a{NodeList}->[$startlocation + 2 * $windowsize - 1]) {
	my $St = $startlocation;
	for (my $k = $startlocation + $windowsize; $k < $length; $k += $windowsize) {
	  if (exists $a{NodeList}->[$k + $windowsize - 1]) {
	    my @set1 = $St .. ($k - 1);
	    my @set2 = $k .. ($k + $windowsize - 1);
	    my @nodes1;
	    my @nodes2;
	    foreach my $index (@set1) {
	      push @nodes1, $a{NodeList}->[$index];
	    }
	    foreach my $index (@set2) {
	      push @nodes2, $a{NodeList}->[$index];
	    }
	    my $gnode1 = PerlLib::IE::MDR::GeneralizedNode->new
	      (
	       Nodes => \@nodes1,
	      );
	    my $gnode2 = PerlLib::IE::MDR::GeneralizedNode->new
	      (
	       Nodes => \@nodes2,
	      );
	    $s->Distance->{$windowsize}->{$St} =
	      $gnode1->EditDistance(GeneralizedNode => $gnode2);

	    $St += $windowsize;
	  }
	}
      }
    }
  }
}

sub FindDRs {
  my ($s,%a) = @_;
  if ($s->TreeDepth >= 3) {
    print "FIND DRs: ".$s->ID."\n" if $s->Debug;
    $s->DRs($s->IdentDRs
	    (
	     Start => 0,
	     K => $a{K},
	     T => $a{T},
	    ));
    my $order = 0;
    foreach my $child (@{$s->Children}) {
      $child->FindDRs
	(
	 K => $a{K},
	 T => $a{T},
	);
      my $hash = $s->UnCoveredDRs
	(
	 Child => $child,
	 Order => $order,
	);
      foreach my $key (keys %$hash) {
	print "KEY\n".$key."\n" if $s->Debug;
	$s->DRs->{$key} = $hash->{$key};
      }
      ++$order;
    }
  }
}

sub IdentDRs {
  my ($s,%a) = @_;
  my $numchildren = scalar @{$s->Children};
  my $maxDR = PerlLib::IE::MDR::DataRegion->new(Node => $s);
  my $curDR = PerlLib::IE::MDR::DataRegion->new(Node => $s);
  for (my $windowsize = 1; $windowsize <= $a{K}; ++$windowsize) {
    for (my $f = $a{Start}; $f <= $windowsize; ++$f) {
      my $flag = 1;
      for (my $startlocation = $f; $startlocation < $numchildren; $startlocation += $windowsize) {
	if (exists $s->Distance->{$windowsize} and 
	    exists $s->Distance->{$windowsize}->{$startlocation}) {
	  print "WS:$windowsize\tSL:$startlocation\n" if $s->Debug;
	  if ($s->Distance->{$windowsize}->{$startlocation} <= $a{T}) { # obviously needs some attention
	    if ($flag) {
	      $curDR->Region([$windowsize,$startlocation,2*$windowsize]);
	      $flag = 0;
	    } else {
	      $curDR->Region->[2] += $windowsize;
	      print "YEAH\n" if $s->Debug;
	    }
	  } elsif (! $flag) {
	    last;		# exit inner loop
	  }
	} else {
	  print "Why isn't $windowsize x $startlocation covered?\n" if $s->Debug;
	}
      }
      if ($maxDR->Region->[2] < $curDR->Region->[2] and
	  ($maxDR->Region->[1] == 0 or $curDR->Region->[1] <= $maxDR->Region->[1])) {
	$maxDR->Copy(DR => $curDR);
      }
    }
  }
  my $retval = {};
  if ($maxDR->Region->[2] != 0) {
    if ($maxDR->Region->[1] + $maxDR->Region->[2] != $numchildren) {
      $retval = $s->IdentDRs(
			     Start => $maxDR->Region->[1] + $maxDR->Region->[2],
			     K => $a{K},
			     T => $a{T},
			    );
      print Dumper(["howdy",keys %$retval]) if $s->Debug;
    }
    $retval->{$maxDR->ID} = $maxDR;
  }
  return $retval;
}


sub UnCoveredDRs {
  my ($s,%a) = @_;
  foreach my $dr (values %{$s->DRs}) {
    if (defined $dr->Node->ID and defined $s->ID and $dr->Node->ID eq $s->ID) {
      if ($a{Order} >= $dr->Region->[1] and
	  $a{Order} < $dr->Region->[1] + $dr->Region->[2]) {
	# print "N".$s->ID."\tNULL\n";
	# print Dumper([$dr->Region->[1],$a{Order},$dr->Region->[1] + $dr->Region->[2] - 1]);
	return {};
      }
    }
  }
  return $a{Child}->DRs;
}

sub ExtractRecords {
  my ($s,%a) = @_;
  # now we iterate over the children and return their contents
  my @records;
  if (! scalar @{$s->Children}) {
    return $s->Element->content_list;
  } else {
    foreach my $child (@{$s->Children}) {
      push @records, $child->ExtractRecords;
    }
    return \@records;
  }
}

sub AllChildrenAreSimilar {
  my ($s,%a) = @_;
  my $numchildren = scalar @{$s->Children};
  for (my $i = 0; $i < $numchildren - 1; ++$i) {
    if ($s->Distance->{1}->{$i} >= 0.3) {
      return 0;
    }
  }
  return 1;
}

1;
