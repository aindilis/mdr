package PerlLib::IE::MDR;

use PerlLib::IE::MDR::Node;

use Data::Dumper;
use HTML::TreeBuilder;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [
   qw /
	MaxTagNodes
	HTMLTree
	NodeTree
	Nodes
	Debug
	Results
      /

  ];

sub init {
  my ($self,%args) = @_;
  print "This is the correct one!\n";
  $self->Debug($args{Debug} || 0);
  $self->Nodes({});
  $self->GenerateTree
    (File => $args{File},
     Contents => $args{Contents});
}

sub GenerateTree {
  my ($self,%args) = @_;
  $self->HTMLTree(HTML::TreeBuilder->new); # empty tree
  if ($args{File}) {
    $self->HTMLTree->parse_file($args{File});
  } elsif ($args{Contents}) {
    $self->HTMLTree->parse($args{Contents});
  }
  $self->HTMLTree->elementify;

  # take the elements and map them into nodes here
  $self->NodeTree
    (PerlLib::IE::MDR::Node->new
     (
      Element => $self->HTMLTree,
      ID => 0,
     ));

  # label the tree
  $self->LabelTree
    (
     Node => $self->NodeTree,
     ID => 0,
    );

  # do stuff
  print $self->NodeTree->IndentString
    (WithID => 1)."\n" if $self->Debug;
  my $k = 5;
  $self->NodeTree->MDR
    (
     K => $k,
    );
  $self->NodeTree->FindDRs
    (
     T => 0.3,
     K => $k,
    );

  # $self->PrintNodeContents;

  $self->Results
    ($self->ExtractRecords
     (
      Silent => $args{Silent},
     ));

  # $self->ExtractRecordsFromDRs;

  # cleanup
  $self->HTMLTree->delete;
}

sub LabelTree {
  my ($self,%args) = @_;
  $args{Node}->ID($a{ID});
  $self->Nodes->{$args{ID}} = $a{Node};
  $offset = $args{ID} + 1;
  foreach my $child (@{$args{Node}->Children}) {
    $offset = $self->LabelTree
      (
       ID => $offset,
       Node => $child,
      );
  }
  return $offset;
}

sub PrintNodeContents {
  my ($self,%args) = @_;
  foreach my $node (sort {$args->ID <=> $b->ID} values %{$self->Nodes}) {
    my $parent = $node->Parent;
    my $parentid = "";
    if (defined $parent) {
      $parentid = $parent->ID;
    }
    print "N".$node->ID."\tP$parentid\n";
    print join("\n",map {"\t".$_} keys %{$node->DRs})."\n";
  }
}

sub ExtractRecords {
  my ($self,%args) = @_;
  print "RESULTS\n" unless $args{Silent};
  my @all;
  foreach my $dr (values %{$self->NodeTree->DRs}) {
    # take the data regions and extract the information from them
    print $dr->ID."\n";
    # now pull the generalized nodes from the data region
    my @records;
    foreach my $gnode (@{$dr->GeneralizedNodes}) {
      push @records, $gnode->ExtractRecords;
    }
    print Dumper(\@records) unless $args{Silent};
    push @all, \@records;
  }
  return \@all;
}

sub ExtractRecordsFromDRs {
  my ($self,%args) = @_;
  print "RESULTS\n" unless $args{Silent};
  my @all;
  foreach my $dr (values %{$self->NodeTree->DRs}) {
    # take the data regions and extract the information from them
    print $dr->ID."\n";
    # now pull the generalized nodes from the data region
    my @records;
    foreach my $gnode (@{$dr->GeneralizedNodes}) {
      push @records, $gnode->FindRecords1;
    }
    print Dumper(\@records) unless $args{Silent};
    push @all, \@records;
  }
  return \@all;
}

1;
