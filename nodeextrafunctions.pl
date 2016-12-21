sub maxLevel{ #returns 0 if $tree is not a node
	my ($tree) = @_; my $maxlevel;
		while( level($maxlevel,$tree)!=() ){ ++$maxlevel }
	return $maxlevel-1;
}

sub levelOfNodeInTree{
	my ($node,$tree) = @_;
	my $maxlevel = maxLevel($tree);
	for( my $i=0; $i<=$maxlevel; ++$i ){
		my @level = level($i,$tree);
		if( isElement($node,\@level) ){ return $i }
	}
	return -1;
}

sub neighborsInTree{ #finds what $node is connected to in tree of $tree
	my ($node,$tree) = @_; my $levelofnode = levelOfNodeInTree($node,$tree);
	my @beforelevel = level($levelofnode-1,$tree);
	my @afterlevel = level($levelofnode+1,$tree);
	return intersect( union(\@beforelevel,\@afterlevel), neighbors($node) );
}

sub evaluate{ #not working!
	my $str = eval($_[0]);
	print $str;
}

sub isGuyToRight{
	my ($node) = @_; my @level = @_; if( !isElement($node,\@level) ){ warn "not in level"; return 0 }
	for my $i (0..$#level){
		if( $node eq $level[$i] && $i < $#level ){ return 1 }
	}
	return 0
}

sub isGuyToLeft{
	my ($node) = @_; my @level = @_; if( !isElement($node,\@level) ){ warn "not in level"; return 0 }
	for my $i (0..$#level){
		if( $node eq $level[$i] && $i > 0 ){ return 1 }
	}
	return 0
}

sub startingPositions{
	my ($tree) = @_; my @positions;
	for my $i (0..maxLevel($tree)){
		my @level = level($i,$tree);
		my @poss = ();
		for my $j (0..$#level){
			my $previouslength = 0; if( $j>0 ){ $previouslength = length($level[$j-1]) }
			#print "push( @poss, ceil($poss[$j-1] + $previouslength/2 + 1 + length($level[$j])/2) );\n";
			#print "push( @poss, ceil($poss[$j-1] + ",$previouslength/2," + 1 + ",length($level[$j])/2,") );\n\n";
			push( @poss, $poss[$j-1] + $previouslength/2 + 1 + length($level[$j])/2 );
		}
		push(@positions,@poss);
	}
	return @positions;
}

sub leftPos{
	my ($position,$name) = @_;
	return $position - length($name)/2
}

sub printTreeWithPositions{
	my ($tree) = @_; my @positions = @_; my $c=0;
	for my $i (0..maxLevel($tree)){
		my @level = level($i,$tree);
		my $p=0;
		for my $j (0..$#level){
			while( $p < leftPos($positions[$c],$level[$j]) ){ print ' '; ++$p }
			print $level[$j];
			++$c;
			$p += length($level[$j]);
		}
		print "\n";
	}
}

sub direction{ # 1 if left of center, -1 if right of center
	my ($position) = @_; my $center = (`tput cols`)/2;
	if( $position < $center ){ return 1 }
	if( $position > $center ){ return -1 }
	if( $position == $center ){ return 0 }
	die "big issue";
}

sub findNodeInTree{
	my ($node,$tree) = @_; my $c=0;
	for my $i (0..maxLevel($tree)){ #this giant loop updates all the positions once
	my @level = level($i,$tree);
		foreach( @level ){
			if( $_ eq $node ){ return $c }
			++$c;
		}
	}
	die "no node"
}

sub animateTree{
	my ($tree) = @_; #my $maxlevel = maxLevel($tree);
	#for my $i (0..$maxlevel){ foreach( level($i,$tree) ){
	my @positions = startingPositions($tree);
	printTreeWithPositions($tree,@positions);
	my @previouspositions = @positions;
	my @connectedgraph = connectedGraph($tree); #just for pastvel array. this is temporary until we introduce a better method
#	for my $i (0..$#connectedgraph){
	my @pastvelocities = (0) x $#connectedgraph;

	for (0..5){
				my $c = 0;
				for my $i (0..maxLevel($tree)){ #this giant loop updates all the positions once
					my @level = level($i,$tree);
					foreach( @level ){
						#consider node $_
						my $me = $_;
						#assign a force towards center, which is less in the middle
						my $force += 3*direction($positions[$c]);
						#$foreach neighbor in tree, assign a rubber band force
						foreach( neighborsInTree($me,$tree) ){
							$force += $positions[findNodeInTree($_,$tree)] - $positions[$c]
						}
						#now convert the force to an accel, then
						my $v = ($pastvelocities[$c] + $force)*0.7;
						#prevent overlaps
						if( $v > 0 && isGuyToRight($me,@level) ){ $v = 0 }
						if( $v < 0 && isGuyToLeft($me,@level) ){ $v = 0 }
						$pastvelocities[$c] = $v;
						my $positionchange = $v*$dt; #$dt is change of time in seconds
						$positions[$c] = $previouspositions[$c] + $positionchange;
						#compare each guy with the next one to see if they overlapped.  If so, take the average and unoverlap
						#nvm, we took care of that
						++$c;
				}}
	sleep(1);
	print '-' x 20, "\n";
	printTreeWithPositions($tree,@positions);
	}
	return 1
}

