use Term::ANSIColor; use Term::ANSIColor ':constants';

sub clear{ #removes blank '' values from a set
	my @input = @{$_[0]};
	my @set;
  	foreach (@input){ unless( $_ eq '' ){ push(@set,$_) } }
	return @set;
}

sub slim{ #removes duplicate occurances of an element
	my @input = @{$_[0]};
    if( $#input <= 0 ){ return @input }
    for $i (0..$#input-1){
      for $j ($i+1..$#input){ if( $input[$i] eq $input[$j] ){ $input[$j] = '' } }
    }
	return clear(\@input);
}

sub isElement{
	my ($element,$set) = @_; my @set = @$set;
  	foreach (@set){ if( $element eq $_ ){ return 1 } }
	return 0;
}

sub addElement{
	my ($e,$set) = @_; my @set = @{$set};
  	push(@set,$e);
	return slim(\@set);
}

sub deleteElement{
	my ($e,$set) = @_; my @set = @$set;
	foreach (@set){ if( $e eq $_ ){ $_ = '' } }
	return clear(\@set);
}

sub union{
	my ($a,$b) = @_; my @A = clear(\@$a); my @B = clear(\@$b);
  	push(@A,@B);
	return slim(\@A);
}

sub intersect{ #interset will take in SETS and return SETS.  This will require that the arrays it takes in are already slim()med.
  my @input = @{$_[0]};
	my @set;
    for $i (0..$#input-1){
      for $j ($i+1..$#input){ if( $input[$i] eq $input[$j] ){ push(@set,$input[$j]) } }
    }
	return slim(\@set);
}

sub isSubset{ #if @B doesn't exist, this returns 0 as desired
	my ($a,$b) = @_; my @A = clear(\@$a); my @B = clear(\@$b);
   if( union(\@A,\@B)==@B ){ return 1 }
   return 0
}

sub minus{
	my ($a,$b) = @_; my @A = clear(\@$a); my @B = clear(\@$b);
	foreach( @A ){ if(isElement($_,\@B)){ $_ = '' } }
	return clear(\@A);
}

sub setin{
	my $input = 'temp'; my @set;
	print "Input your set now. Press <RETURN> after each element, and when you are finished:\n";
	while( $input ne '' ){
		chomp( $input = <STDIN> );
		push( @set, $input );
	}
	print "\n";
	return slim(\@set);
}

sub displayStr{ #no color for saving files
  my @input = @{$_[0]};
	my $first = shift @input;
	my $toprint;
    $toprint.= "{ ";
    $toprint.= $first; foreach( @input ){ $toprint.= ", $_" }
    $toprint.= " }";
}

1;
