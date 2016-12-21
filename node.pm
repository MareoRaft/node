use nodeset;

package Node;

sub new{
  my $class = shift;
  my %options = @_; my @connectors = ();
  my $node = { CONNECTORS => \@connectors, %options };
  bless( $node, $class );
  return $node;
}

sub name{
  my $node = shift;
  return $node->{NAME}
}

sub connectorsRef{
  my $node = shift;
  return $node->{CONNECTORS}
}

sub connectors{
  my $node = shift;
  return @{$node->connectorsRef}
}

sub addConnectors{
  my $node = shift;
  my ($setref) = @_;
  @{$node->connectorsRef} = ::union( $node->connectorsRef, $setref );
  return 1
}

########
=pod
@nodes;

sub obj{
  my ($name) = @_;
  foreach( @nodes ){ if( $_->name eq $name ){ return $_ } }
  die "object does not exist"
}


@a = (0..9);
@b = (4..14);
$obj = Node->new(NAME=>'ralph',CONNECTORS=>\@a);
push(@nodes,$obj);
print $obj->name;
print "\n\n";
print $obj->connectors;
print "\n\n";
print $obj->connectorsRef;
print "\n\n";

#print obj('ralph');
#$node = obj('ralph');
#$node->addConnectors([777]);
obj('ralph')->addConnectors([777]);
print $obj->connectors;
print "\n\n";
=cut
1;
