#!/usr/bin/env perl

use node;
use nodeset;
use POSIX;
use Term::ANSIColor; use Term::ANSIColor ':constants';

my @nodes; #stores objects
my $graphtype = 'graph'; #'graph' for regular graph, 'directed graph' for directed graph.
my $filename;
my $historynum = -1; #history will start at 0 and go up
my $dt = 1;
my @positions; my @previouspositions;#will be integrated into nodes

sub trim{ my ($i) = @_; $i =~ s/^\s+|\s+$//g; $i }

sub input{ my $i = <STDIN>; trim($i) }

sub promptInput{ print "$filename \$ "; print GREEN; my $input = input(); print RESET; $input }
sub promptInputOrange{ print "$filename \$ "; print "\033[38;5;208m"; my $input = input(); print RESET; $input }

sub inputArray{
	my @array;
	while(1){
		my $i = promptInputOrange(); #print "\$i is BEGIN",$i,"END";
		if( $i eq '' ){ return slim(\@array) }
		push(@array,$i);
	}
}

##########################################################################################

sub readFile{
	my ($inname) = @_; $inname =~ s/\.txt$//i;
	open( IN, "$inname.txt" ) or die $!;
		local $/ = undef;
		my $data = <IN>;
	close( IN );
	return trim($data)
}

sub isEqual{
	my ($name1,$name2) = @_; if( !defined $name1 || !defined $name2 ){ return 0 }
	my $data1 = readFile($name1);
	my $data2 = readFile($name2);
	if( $data1 eq $data2 ){ return 1 }
	return 0
}

sub saveDataTo{
	my ($outname) = @_; $outname =~ s/\.txt$//i; my $out;
	open( OUT, ">$outname.txt" ) or die "Couldn't make that file $!";
		foreach( @nodes ){ $out .= "Node $_ points to: ".displayStr(\@$_)."\n\n" }
		print OUT trim($out);
	close( OUT );
	return 1;
}

sub saveData{
	my ($inname) = @_;
	if( defined $filename && !defined $inname ){
		print "Would you like to save as ", BOLD $filename, RESET "?  Any previous versions of $filename would be overwritten.\n";
		my $i = promptInput();
		if( $i =~ /^y/ ){
			saveDataTo($filename) or die "Could not save file.";
			print "Successfully saved as ", BOLD "$filename.txt", RESET "!\n";
			return 1;
		}
	}
	if( !defined $inname ){
		print "Please type the name that you would like to save your file as.  Do NOT include the extension.\n";
		$inname = promptInput()
	}
	$inname =~ s/\.txt$//i;
	saveDataTo($inname) or die "Could not save file.";
	$filename = $inname;
	print "Successfully saved as $filename.txt!\n";
	return 1;
}

sub isDataDifferentThan{
  my ($comparefilename) = @_;
	saveDataTo('.historycompare') or die "Failed to save data compare file.";
	if( isEqual('.historycompare',$comparefilename) ){ return 0 }
	return 1
}

sub saveHistory{ #now has the built in feature that it only saves if a change has been made
  if( $historynum==-1 || isDataDifferentThan(".history$historynum") ){
    ++$historynum;
    saveDataTo(".history$historynum") or die "Failed to save history.";
    return 1
  }
  return 0
}

##########################################################################################

sub obj{
  my ($name) = @_;
  foreach( @nodes ){ if( $_->name eq $name ){ return $_ } }
  die "object does not exist"
}

sub addNewNodeObject{
  my ($name) = @_;
  push( @nodes, Node->new(NAME=>$name) );
}

sub nameExists{
  my ($name) = @_;
  foreach( @nodes ){ if( $_->name eq $name ){ return 1 } }
  return 0
}

sub addNodeObject{
  my ($name) = @_;
  if( !nameExists($name) ){ addNewNodeObject($name) }
}

sub addNodeWithConnectionsPM{
  my ($name,$connectos = shift; my @connectors = @_;
  if( isElement($name,\@nodes) ){ return 0 }
  push(@nodes,$name);
  push( @node, Node->new(NAME=>$name,CONNECTORS=>\@connectors) );
}

sub addConnection{
	my ($a,$b) = @_; #print "\$a is $a and \$b is $b\n";
	@nodes = addElement($a,\@nodes); @nodes = addElement($b,\@nodes); #print "\n";	foreach( @nodes ){ print "Node $_ END\n" }
	@$a = addElement($b,\@$a);
	if( $graphtype eq 'graph' ){ @$b = addElement($a,\@$b) }
	return 1;
}

sub addConnections{
  my ($name,$connectorsref) = @_;
	obj($name)->addConnectors($connectorsref)
  foreach( @{$connectorsref} ){ addNodeObject($_->name) }
  if( $graphtype eq 'graph' ){
    foreach( @$connectorsref ){ obj($_)->addConnectors([$name]) }
  }
}

sub completeConnections{
  foreach( @nodes ){
    my $node = $_;
    foreach( $node->connectors ){
      obj($_)->addConnectors( [$node->name] )
    }
  }
}

sub addNodeNamed{
	my ($name) = @_;
	addNodeObject($name);
	print "What would you like ", RED, $name, RESET, " to be connected to? (Press ", CYAN, "RETURN", RESET, " after each entry, and when finished)\n";
	my @connectors = inputArray();
	addConnections($name,\@connectors);
}

sub addNode{
	my ($name) = @_;
	if( !defined $name ){ print "Enter node's name:\n"; $name = promptInputOrange() }
	addNodeNamed($name);
	if( isDataDifferentThan(".history$historynum") ){ print "Successfully added information.\n" and return 1 }
	print "Information already exists.\n" and return 0
}

sub deleteNodeNamed{
	my $node = shift @_;
	if( !isElement($node,\@nodes) ){ return 0 }
	foreach( @$node ){ @$_ = deleteElement($node,\@$_) }
	@nodes = deleteElement($node,\@nodes);
	@$node = ();
	return 1
}

sub deleteNode{
	my $node = shift @_;
	if( !defined $node ){ print "Enter node's name:\n"; $node = promptInputOrange(); }
	if( deleteNodeNamed($node) ){ print "Successfully deleted node.\n" and return 1 }
	print "No such node to delete.\n" and return 0
}

sub deleteAllNodes{
	foreach( @nodes ){ @$_ = () }
	@nodes = ();
}

sub neighbors{ #i have decided to make neighbors(@set) disclude the elements of @set itself
	my @neighbors;
	foreach( @_ ){ @neighbors = union(\@neighbors,\@$_) }
	return minus(\@neighbors,\@_);
}

sub family{ #family is like neighbors, but it INCLUDES the input set.
	my @neighbors = @_;
	foreach( @_ ){ @neighbors = union(\@neighbors,\@$_) }
	return @neighbors;
}

sub connectedGraph{ #print "input is ",@_," and family is ",family(@_)," and lengthleft is ",length(@_)," and lengthright is ",length(family(@_)),"\n";
	my @input = @_;
	if( intersect(\@input,\@nodes)==() ){ return }
	my @family = family(@input);
	if( $#input == $#family ){ return @input }
	return connectedGraph(@family);
}

sub level{
	my ($level,$node) = @_; my @current = ($node);
	if( $level < 0 ){ return }
	if( $level==0 ){ return @current }
	while(1){
#	print "level is ",2-$level,"\n";
#	print "current is "; display \@current; print "\n";
#	print "neighbors of current is "; display [neighbors(@current)]; print "\n";
#	print "\n\n";
		#everything gets promoted
		if( $level==1 ){ return neighbors(@current) }
		@current = family(@current);
		--$level;
	}
}

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

sub viewData{ #print "\$#nodes is $#nodes\n";
	my ($input) = @_;
	unless( $input eq '' ){
		if( isElement($input,\@nodes) ){
			print "\nNode ",RED $input,RESET " points to: "; display(\@$input); print "\n\n"; return 1
		}
		print "$input is not a node.\n"; return 1
	}
	if( $#nodes==-1 ){ print "There is no data currently.\n"; return 1 }
	print "\n";
	foreach( @nodes ){ print "Node ",RED $_,RESET " points to: "; display(\@$_); print "\n\n" }
	return 1;
}

sub changeGraphType(){
	$graphtype = otherType();
	if( $graphtype eq 'graph' ){
		print "Successfully switched from ", BOLD "directed", RESET " graph mode to ", BOLD "graph", RESET " mode.  From now on, all connections you create will point both ways.  Would you like to also convert all previously made directed connections to regular connections?\n";
		my $i = promptInput(); if( $i =~ /^y/ ){ completeConnections() }
	}
	elsif( $graphtype eq 'directed graph' ){ print "Successfully switched from ", BOLD "graph", RESET " mode to ", BOLD "directed", RESET " graph mode.  From now on, all connections you create will point one way.\n"; }
	else{ die "Impossible graph type." }
}

sub help{
	my $twidth = `tput cols`; #if( $toprintwidth>$twidth ){ warn "STRING TOO LONG" }
	print "\n";
	print ' 'x(($twidth-141)*50/100); #the following string is 141 characters long:
	print CYAN, "add", RESET, " nodes or connections  |  ", CYAN, "delete", RESET, " nodes or connections  |  ", CYAN, "view", RESET, " data  |  ", CYAN, "find", RESET, " nodes connected to...  |  ", CYAN, "change", RESET, " from ", BOLD $graphtype, RESET " to ",otherType(),"\n";
	print "\n";
	print ' 'x(($twidth-62)*50/100); #the following string is 62 characters long:
	print CYAN, "undo", RESET, "  |  ", CYAN, "redo", RESET, "  |  ", CYAN, "save", RESET, " data  |  ", CYAN, "load", RESET, " data from a file  |  ", CYAN, "quit", RESET, "\n";
	print "\n";
}

##########################################################################################

sub loadDataFrom{ #in order for this to work, the user should not put commas in their node names (or })
	my $inname = shift @_;
	my $data = readFile($inname);
	while( $data =~ /^Node (.+?) points to: { ((?:[^,}]+, )*[^}]*) }/gm ){
		my $node = $1; my @connections = split(/, /,$2); #print "\$node is $node\n";
		addConnections($node,\@connections);
	}
	return 1;
}

sub loadData{
	my $inname = shift @_;
	if( $#nodes > -1 ){
		print "Would you like to ", CYAN "discard", RESET " the current data, or ", CYAN "merge", RESET " the data together?\n";
		my $i = promptInput(); if( $i =~ /^[do]/ ){ deleteAllNodes() }
	}
	if( !defined $inname ){
		print "Please type the name of the file you would like to load.  Do NOT include the extension.\n";
		$inname = promptInput();
	}
	if( $#nodes==-1 ){ $filename = $inname }
	loadDataFrom($inname) or die "Could not load file.";
	print "Successfully loaded data from $inname.txt!\n";
	return 1;
}

sub undoData{
	if( $historynum==0 ){ print "Nothing left to undo.\n"; return 0 }
	deleteAllNodes();
	--$historynum; loadDataFrom(".history$historynum") or die "failed load"; print "Successfully undid last change.\n";
	return 1;
}

sub redoData{ #print "\$historynum is $historynum\n";
	my $nextnum = $historynum+1;
	if( `ls -A | grep .history$nextnum.txt` eq '' ){ print "Nothing to redo.\n"; return 0 }
	deleteAllNodes();
	++$historynum; #print "\$historynum is $historynum\n";
	loadDataFrom(".history$historynum") or die "failed load"; print "Successfully redid last change.\n";
	return 1;
}

sub deleteHistory{ system('rm .history* 2>/dev/null') }

sub otherType{
	if( $graphtype eq 'graph' ){ return 'directed graph' }
	elsif( $graphtype eq 'directed graph' ){ return 'graph' }
	else{ die "bad graph type" }
}

sub quit{ #print "\$#nodes is $#nodes";
	if( $#nodes>-1 && isDataDifferentThan($filename) ){
		print "There have been changes to your graph.  Would you like to save before quitting?\n";
		my $i = promptInput(); if( $i =~ /^[ys]/ ){ saveData() }
	}
	deleteHistory();
	exit 0;
}

##########################################################################################
=pod
sub evaluate{ #not working!
	my $str = eval($_[0]);
	print $str;
}

sub isGuyToRight{
	my $node = shift; my @level = @_; if( !isElement($node,\@level) ){ warn "not in level"; return 0 }
	for my $i (0..$#level){
		if( $node eq $level[$i] && $i < $#level ){ return 1 }
	}
	return 0
}

sub isGuyToLeft{
	my $node = shift; my @level = @_; if( !isElement($node,\@level) ){ warn "not in level"; return 0 }
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
	my $tree = shift; my @positions = @_; my $c=0;
	for my $i (0..maxLevel($tree)){
		my @level = level($i,$tree);
		my $p=0;
		for my $j (0..$#level){
			while( $p < leftPos($positions[$c],$level[$j]) ){ print ' ' and ++$p }
			print $level[$j];
			++$c;
			$p += length($level[$j]);
		}
		print "\n";
	}
}

sub direction{ # 1 if left of center, -1 if right of center
	my $position = shift; my $center = (`tput cols`)/2;
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

sub findData{ #user cannot have parenthesis () in nodes for multiple search
	my $search = shift @_;
	if( !defined $search ){ print "Input your search keywords:\n"; $search = promptInput() }
	#            (        $1                 )($2 )
#	$search =~ s/((?:(?:^|\(|\)|&&|\|\|)\s*)+)(.+?)(?=\(|\)|&&|\|\||$)/$1connectedGraph(trim($2))/g;
	#$M = $i =~ s/((?:(?:^|\(|\)|[ )]and |[ )]or )\s*)+)(.+?)(?=\(|\)| and[ (]| or[ (]|$)/$1trim($2)/g;

	#if( !isElement($search,\@nodes) ){ print "$search is not a node.\n"; return 1 }

	print "\nThe nodes connected to ", RED, $search, RESET, " are "; display [connectedGraph($search)]; print "\n\n";

	for( my $i=0; $i<=5; ++$i ){
		print "level $i is "; display [level($i,$search)]; print "\n\n\n";
	}

	print "\n the maxlevel of $search is ", maxLevel($search), "\n\n";
	print "\n the level of popcorn in $search is ", levelOfNodeInTree('popcorn',$search), "\n\n";

	print "\nneighbors in tree of $search are \n";
	display [neighborsInTree('popcorn',$search)];

	print "\nstartingPositions of $search are \n"; my @sp = startingPositions($search);
	display \@sp;

	print "\nand now the tree...\n"; @sp = (4, 4, 24, 84, 84, 84, 4, 24, 44, 64, 84, 104);
	printTreeWithPositions($search,@sp);

	animateTree($search);



}
=cut
##########################################################################################

print "Welcome to ", BOLD, "node.pl", RESET, "!!  Type ", CYAN "help", RESET " at any time to view your options.\n";
foreach( @ARGV ){ loadDataFrom($_) } if( $#ARGV==0 ){ $filename=$ARGV[0] }
deleteHistory(); saveHistory();
while(1){
	my $i; my $c; my $input = promptInput(); if( $input =~ /^\w+/ ){ $i = $& } if( $input =~ /^\w+\s+(.+)/ ){ $c = $1 }
	if( $i =~ /^h/ ){ help() }
 	elsif( $i =~ /^[an]/ ){ addNode($c); saveHistory() }
	elsif( $i =~ /^d/ ){ deleteNode($c); saveHistory() }
	elsif( $i =~ /^v/ ){ viewData($c) }
#	elsif( $i =~ /^[fk]/ ){ findData($c) }
	elsif( $i =~ /^[ct]/ ){ changeGraphType(); saveHistory() }
	elsif( $i =~ /^s/ ){ saveData($c) }
	elsif( $i =~ /^[lo]/ ){ loadData($c); saveHistory() }
	elsif( $i =~ /^[uz]/ ){ undoData() }
	elsif( $i =~ /^[ry]/ ){ redoData() }
	elsif( $i =~ /^[qe]/ ){ quit() }
#	elsif( $i =~ /^eval/ ){ evaluate($c) }
	else{}
}

