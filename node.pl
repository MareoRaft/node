#!/usr/bin/env perl
use strict;
use Data::Dumper;
use node;
use nodeset;
use POSIX;
use Term::ANSIColor; use Term::ANSIColor ':constants';

my @nodes; #stores objects
my $graphtype = 'graph'; #'graph' for regular graph, 'directed graph' for directed graph.

my %colors =
( 'on black' =>  {
                'strawberry'  => { 'name' => "\x1b[38;5;162m",  'nameinput' => "\x1b[35m",        'command' => "\x1b[38;5;27m",     'commandinput' => "\x1b[38;5;33m" },
                'natural'     => { 'name' => "\x1b[38;5;28m",   'nameinput' => "\x1b[38;5;24m",   'command' => "\x1b[38;5;243m",    'commandinput' => "\x1b[38;5;94m" },
                'invertedn'   => { 'name' => "\x1b[38;5;28;7m", 'nameinput' => "\x1b[38;5;24;7m", 'command' => "\x1b[38;5;243;7m",  'commandinput' => "\x1b[38;5;94;7m" },
                'original'    => { 'name' => "\x1b[38;5;142m",  'nameinput' => "\x1b[38;5;208m",  'command' => "\x1b[38;5;38m",     'commandinput' => "\x1b[38;5;32m" }
                },
  'on white' =>  {
                'strawberry'  => { 'name' => "\x1b[38;5;162m",  'nameinput' => "\x1b[35m",        'command' => "\x1b[38;5;19m",     'commandinput' => "\x1b[38;5;26m" },
                'natural'     => { 'name' => "\x1b[38;5;22m",   'nameinput' => "\x1b[38;5;24m",   'command' => "\x1b[38;5;238m",    'commandinput' => "\x1b[38;5;94m" },
                'invertedn'   => { 'name' => "\x1b[38;5;28;7m", 'nameinput' => "\x1b[38;5;24;7m", 'command' => "\x1b[38;5;238;7m",  'commandinput' => "\x1b[38;5;94;7m" },
                'original'    => { 'name' => "\x1b[38;5;100m",  'nameinput' => "\x1b[38;5;166m",  'command' => "\x1b[38;5;31m",     'commandinput' => "\x1b[38;5;25m" }
                }
);
my %color = %{$colors{'on black'}{'natural'}};
#184 for a bright yellow #142 muted yellow
#148 for a light yellow-green #208 very nice orange
#38 light blue with green tint #19 purple
#32 very nice blue #26 very nice slightly darker blue
my $boldC = "\x1b[1m";
my $resetC = "\x1b[0m";

my $delimiterand = 'and';
my $delimiteror = 'or';
my $filename = '';
my $historynum = -1; #history will start at 0 and go up
my $dt = 1;
#my @positions; my @previouspositions;#will be integrated into nodes

############################# BASIC INPUTS AND OUTPUTS ###################################

sub max{ if( $_[0] > $_[1] ){ return $_[0] } return $_[1] }
sub min{ if( $_[0] < $_[1] ){ return $_[0] } return $_[1] }

sub trim{ my ($i) = @_; $i =~ s/^\s+|\s+$//g; $i }

sub input{ my $i = <STDIN>; trim($i) }
sub inputName{ print $color{'nameinput'}; my $i = <STDIN>; print ${resetC}; trim($i) }

sub promptInput{ print "$filename \$ "; print $color{'commandinput'}; my $input = input(); print ${resetC}; $input }
sub promptInputName{ print "$filename \$ "; print $color{'nameinput'}; my $input = input(); print ${resetC}; $input }

sub inputArray{
	my @array;
	while(1){
		my $i = promptInputName(); #print "\$i is BEGIN",$i,"END";
		if( $i eq '' ){ return slim(\@array) }
		push(@array,$i);
	}
}

sub lengthC{
	my ($str) = @_;
	$str =~ s/(?:\x1b|\033)\[[^m]*m//g; $str =~ s/\n//g; #it is your choice if you want newlines in the length
	length($str);
}

sub printp{ #printpercent
	my ($percentnum,$toprint,$fixedlength) = @_; #fixed length is optional, and can be used to make a centered block instead of each line centered.
	$toprint =~ s/[^\S\n]+(?=\n)//g; # (nonnewline) whitespace before a newline is unnecessary and can cause trouble
	if( $toprint =~ s/^\n+// ){ print $& } #print the leading newlines
	my $trailingnewlines = ( $toprint =~ s/\n+$// )? $&: '';

	$toprint = trim($toprint); #get rid of leading and trailing whitespace
	my $toprintwidth = (defined $fixedlength)? $fixedlength: lengthC($toprint);
	my $twidth = `tput cols`; if( $toprintwidth>$twidth ){ warn "\$toprintwidth TOO LONG" }
	print ' ' x (($twidth-$toprintwidth)*$percentnum/100); #'c' x n     will automatically round n down if it is not an integer
  print $toprint.$trailingnewlines;
}

sub printc{ #printcentered
	my ($toprint,$fixedlength) = @_;
	printp(50,$toprint,$fixedlength);
}

sub display{
  my @input = @{$_[0]};
	my $first = shift @input;
	print "{ ";
	print "$color{'name'}$first"; foreach( @input ){ print "${resetC}, $color{'name'}$_" } print ${resetC};
	print " }";
}

############################## READ / SAVE FILES #########################################

sub strip{ my($i) = @_; $$i =~ s/\.txt$//i }

sub append{ my ($i) = @_; strip($i); $$i .= '.txt' }

sub readFile{
	my ($inname,$outref) = @_; append(\$inname);
	open( IN, "$inname" ) or return 0;
		local $/ = undef;
		my $data = <IN>;
		$$outref = trim($data);
	close( IN );
	return 1
}

sub isEqual{
	my ($name1,$name2) = @_; if( !defined $name1 || !defined $name2 ){ return 0 } #print "going to compare $name1 to $name2";
	my $data1; readFile($name1,\$data1); #print "DATA1 is\n:$data1";
	my $data2; readFile($name2,\$data2); #print "DATA2 is\n:$data2";
	if( $data1 eq $data2 ){ return 1 }
	return 0
}

sub saveDataTo{
	my ($outname) = @_; append(\$outname); my $out;
	open( OUT, ">$outname" ) or die "Couldn't make ${boldC}$outname${resetC}. $!";
		foreach( @nodes ){ $out .= "Node ".$_->name." points to: ".displayStr($_->connectorsRef)."\n\n" }
		print OUT trim($out);
	close( OUT );
	return 1;
}

sub saveData{
	my ($inname) = @_;
	if( $filename ne '' && !defined $inname ){
		print "Would you like to save as ${boldC}$filename${resetC}?  Any previous versions of $filename would be overwritten.\n";
		my $i = promptInput();
		if( $i =~ /^y/ ){ $inname = $filename }
	}
	elsif( !defined $inname ){
		print "Please type the name that you would like to save your file as.  Do not include the extension.\n";
		$inname = promptInput()
	}
	saveDataTo($inname) or die "Could not save file.";
	$filename = $inname; strip(\$filename);
	print "Successfully saved as ${boldC}$filename.txt${resetC}!\n";
	return 1;
}

sub isDataDifferentThan{
  my ($comparefilename) = @_;
  if( !defined $comparefilename ){ return 1 }
	saveDataTo('.historycompare') or die "Failed to save data compare file.";
	if( isEqual('.historycompare',$comparefilename) ){ return 0 }
	return 1
}

sub saveHistory{ #now has the built in feature that it only saves if a change has been made
  if( $historynum==-1 || isDataDifferentThan(".history$historynum") ){ #print "CHANGEDETECTED\n";
    ++$historynum;
    saveDataTo(".history$historynum") or die "Failed to save history.";
    return 1
  }
  return 0
}

sub saveSettings{
	open( OUT, ">.settings.txt" ) or die "Couldn't make settings file $!";
    print OUT "\$graphtype = '$graphtype';\n";
    print OUT "\$delimiterand = '$delimiterand';\n";
    print OUT "\$delimiteror = '$delimiteror';\n";
    my $color = Data::Dumper->Dump( [\%color], ['*color'] ); $color =~ s/'/"/g; $color =~ s/\[/\\x1b\[/g;
    print OUT $color, "\n";
	close( OUT );
}

################################ ADDING / DELETING NODES #################################

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

sub addDirectedConnections{ #this function no longer makes nodes for the toarray.  That is done in addNodeNamed
  my ($fromref,$toref) = @_; #these are names
  foreach( @$fromref ){
    my $name = $_;
    addNodeObject($name);
    obj($name)->addConnectors($toref);
  }
}

sub addNodeNamed{
	my ($name) = @_;
	print "What would you like $color{'name'}$name${resetC} to be connected to? (Press $color{'command'}RETURN${resetC} after each entry, and when finished)\n";
	my @connectors = inputArray();
	addDirectedConnections([$name],\@connectors);
	if( $graphtype eq 'graph' ){ addDirectedConnections(\@connectors,[$name]) }
	else{ foreach (@connectors){ addNodeObject($_) } }
}

sub addNode{
	my ($name) = @_;
	if( !defined $name ){ print "Enter node's name:\n"; $name = promptInputName() }
	addNodeNamed($name);
	if( isDataDifferentThan(".history$historynum") ){ print "Successfully added information.\n"; return 1 }
	print "Information already exists.\n"; return 0
}

sub completeConnections{
  foreach( @nodes ){
    my $node = $_;
    foreach( $node->connectors ){
      obj($_)->addConnectors([$node->name])
    }
  }
}

sub deleteNodeNamed{
	my ($name) = @_;
	if( !nameExists($name) ){ return 0 }
	foreach( @nodes ){ @{$_->connectorsRef} = deleteElement($name,$_->connectorsRef) }
	@nodes = deleteElement(obj($name),\@nodes);
}

sub deleteNode{
  my ($name) = @_;
  if( !defined $name ){ print "Enter node's name:\n"; $name = promptInputName() }
  deleteNodeNamed($name);
  if( isDataDifferentThan(".history$historynum") ){ print "Successfully deleted node.\n"; return 1 }
  print "No such node to delete.\n"; return 0
}

sub deleteConnectionFromTo{
  my ($fromname,$toname) = @_;
  @{obj($fromname)->connectorsRef} = deleteElement($toname,obj($fromname)->connectorsRef);
}

sub deleteConnection{
  my ($fromtostring) = @_; my $fromname = ''; my $toname = '';
  if( $fromtostring =~ /^(?:to\s+(.*))|(?:(?:from\s+)?(.*?)(?=(?:\s+to|\s*$))(?:\s+to\s+)?(.*))/i ){
    $fromname = $2;
    $toname = $1.$3;
  }
  if( $fromname eq '' ){ print ' ' x max(0,length($filename)+2-5), "from: "; $fromname = inputName() } #print "$fromname is $fromname\n";
  if( $toname eq '' ){ print ' ' x max(2,length($filename)+2-3), "to: "; $toname = inputName() } #print "$toname is $toname\n";
  if( nameExists($fromname) && nameExists($toname) ){ deleteConnectionFromTo($fromname,$toname) }
  if( isDataDifferentThan(".history$historynum") ){ print "Successfully deleted connection.\n"; return 1 }
  print "No such connection to delete.\n"; return 0
}

sub deleteNodeOrConnection{
	my ($name) = @_;
	if( defined $name ){ deleteNode($name); return 1 }
	print "Would you like to delete a $color{'command'}node${resetC}, or a $color{'command'}connection${resetC}?\n";
  my $i = promptInput();
  if( $i =~ /^c/i ){ deleteConnection(); return 1 }
  deleteNode(); return 1;
}

sub deleteAllNodes{
  foreach( @nodes ){ $_ = '' } #necessary?  efficient?
	@nodes = ();
}

############################## MORE MAIN USER FUNCTIONS ##################################

sub viewData{ #print "\$#nodes is $#nodes\n";
	my ($name) = @_;
	unless( $name eq '' ){
		if( nameExists($name) ){
			print "\nNode $color{'name'}$name,${resetC} points to: "; display(obj($name)->connectorsRef); print "\n\n"; return 1
		}
		print "$name is not a node.\n"; return 1
	}
	if( $#nodes==-1 ){ print "There is no data currently.\n"; return 1 }
	print "\n";
	foreach( @nodes ){ print "Node $color{'name'}",$_->name,"${resetC} points to: "; display($_->connectorsRef); print "\n\n" }
	return 1;
}

sub otherType{
	if( $graphtype eq 'graph' ){ return 'directed graph' }
	elsif( $graphtype eq 'directed graph' ){ return 'graph' }
}

sub changeGraphType(){
	$graphtype = otherType();
	if( $graphtype eq 'graph' ){
		print "Successfully switched from ${boldC}directed${resetC} graph mode to ${boldC}graph${resetC} mode.  From now on, all connections you create will point both ways.  Would you like to convert all directed connections to regular connections?\n";
		my $i = promptInput(); if( $i =~ /^y/ ){ completeConnections(); print "Successfully completed connections.\n" }
	}
	elsif( $graphtype eq 'directed graph' ){
	  print "Successfully switched from ${boldC}graph${resetC} mode to ${boldC}directed${resetC} graph mode.  From now on, all connections you create will point one way.\n"
	}
}

sub color{
  my $choice; my $background;
  print "Color scheme choices are $color{'command'}strawberry$resetC, $color{'command'}natural$resetC, $color{'command'}inverted natural$resetC, and $color{'command'}original$resetC.  You can also $color{'command'}create your own$resetC.\n";
  my $i = promptInput();
  if( $i =~ /^s/i ){ $choice = 'strawberry' }
  elsif( $i =~ /^o/i ){ $choice = 'original' }
  elsif( $i =~ /^n/i ){ $choice = 'natural' }
  elsif( $i =~ /^i/i ){ $choice = 'invertedn' }
  elsif( $i =~ /^c/i ){



  }
  else{ $choice = 'natural' }
  print "Is your terminal background $color{'command'}light$resetC, or $color{'command'}dark?$resetC\n";
  $i = promptInput();
  if( $i =~ /^[lw]/i ){ $background = 'on white' }
  elsif( $i =~ /^[db]/i ){ $background = 'on black' }
  else{ $background = 'on black' }
  %color = %{$colors{$background}{$choice}} or print "Could not set $choice $background.\n" and return 0;
  print "$color{'commandinput'}Successfully$resetC $color{'name'}converted$resetC to $color{'command'}$choice$resetC $color{'nameinput'}$background$resetC!\n" and return 1
}

sub delimiter{
  print ' ' x max(0,length($filename)+2-14), "and delimiter: "; $delimiterand = inputName();
  print ' ' x max(1,length($filename)+2-13), "or delimiter: "; $delimiteror = inputName();
}

sub help{
	print "\n";
	printc "$color{'command'}add${resetC} nodes or connections  |  $color{'command'}delete${resetC} nodes or connections  |  $color{'command'}view${resetC} data  |  $color{'command'}find${resetC} nodes connected to...  |  $color{'command'}change${resetC} from ${boldC}$graphtype${resetC} to ".otherType()."\n";
	print "\n";
	printc "$color{'command'}undo${resetC}  |  $color{'command'}redo${resetC}  |  $color{'command'}save${resetC} data  |  $color{'command'}load${resetC} data from a file  |  $color{'command'}more${resetC}  |  $color{'command'}quit${resetC}\n";
	print "\n";
}

sub more{
	print "\n";
  my $toprint = "Each command can be abbreviated by using its first letter.  Moreover, words after a command will be taken as input.  For example, $color{'command'}a Andrew${resetC} will add a node named ${boldC}Andrew${resetC}. $color{'command'}dc from a to b${resetC} will delete the connection from ${boldC}a${resetC} to ${boldC}b${resetC}.\n\n\n$color{'command'}find${resetC} is capable of taking in expressions such as $color{'command'}find Mohith and ( python or perl )${resetC}, which would find all nodes which are connected to both ${boldC}Mohith${resetC} and one of the two ${boldC}p${resetC} keywords.  You can type $color{'command'}delimiter${resetC} to change the ${boldC}and${resetC}s and ${boldC}or${resetC}s to ${boldC}&&${resetC}s and ${boldC}||${resetC}s.\n\n\nThe $color{'command'}color${resetC} scheme can be changed too.\n\n\nColors, delimiters, and the graph type are settings which remain even after quitting and relaunching ${boldC}node.pl${resetC}.";
	my $desiredlength = (`tput cols`)/2;
	while( $toprint =~ s/^\n*(?:(?:(?:\x1b|\033)\[[^m]*m)*.){1,$desiredlength}// ){
		my $match = $&; $match =~ s/\n//; #delete one newline if present
	  printc ($match,$desiredlength); print "\n";
	}
	print "\n";
}

sub deleteHistory{ system('rm .history* 2>/dev/null') }

sub quit{ #print "in quit:\$filename is $filename\n";
	if( $#nodes>-1 && isDataDifferentThan($filename) ){
		print "There have been changes to your graph.  Would you like to save before quitting?\n";
		my $i = promptInput(); if( $i =~ /^[ys]/ ){ saveData() }
	}
}

############################## LOADING DATA / UNDO / REDO ################################

sub loadSettings{
	my $settings; readFile('.settings',\$settings); #print "settingsare:\n$settings\n\n";
  eval $settings;
	return 1;
}

sub loadData{
	my ($inname,$silence) = @_;
	if( !defined $inname ){
		print "Please type the name of the file you would like to load.  Do NOT include the extension.\n";
		$inname = promptInput();
	}
	append(\$inname);
	my $data; readFile($inname,\$data) or print "${boldC}$inname${resetC} does not exist in this directory.\n" and return 0;
	if( $data =~ /^\s*$/ ){ print "${boldC}$inname${resetC} is blank.\n"; return 0 }
	elsif( $data !~ /^Node (.+?) points to: { ((?:[^,}]+, )*[^}]*) }/m ){ print "The information in ${boldC}$inname${resetC} is not in correct node format.\n"; return 0 }
  else{
	  if( $#nodes > -1 && $silence ne 'silent' ){
	  	print "Would you like to $color{'command'}discard${resetC} the current data, or $color{'command'}merge${resetC} the data together?\n";
	  	my $i = promptInput(); if( $i =~ /^[do]/ ){ deleteAllNodes(); $filename = $inname; strip(\$filename) }
  	}
  	elsif( $#nodes==-1 ){ $filename = $inname; strip(\$filename) }
	  while( $data =~ /^Node (.+?) points to: { ((?:[^,}]+, )*[^}]*) }/gm ){
	  	my $name = $1; my @connections = split(/, /,$2); #print "\$node is $node\n"; #print "start: "; print @connections; print " end.\n\n";
  		addDirectedConnections([$name],\@connections);
  	}
   	print "Successfully loaded data from ${boldC}$inname${resetC}!\n"; return 1
  }
}

sub undoData{
	if( $historynum==0 ){ print "Nothing left to undo.\n"; return 0 }
	deleteAllNodes(); #replace with a check that the file exists before deleing (write it into loadData as option 'overwrite')
	--$historynum; loadData(".history$historynum",'silent') or die "failed load"; print "Successfully undid last change.\n";
	return 1;
}

sub redoData{ #print "\$historynum is $historynum\n";
	my $nextnum = $historynum+1;
	if( `ls -A | grep .history$nextnum.txt` eq '' ){ print "Nothing to redo.\n"; return 0 }
	deleteAllNodes();
	++$historynum; loadData(".history$historynum",'silent') or die "failed load"; print "Successfully redid last change.\n";
	return 1;
}

################################ ADVANCED FIND FEATURES ##################################

sub nodeNames{
  my @names;
  foreach( @nodes ){ push(@names,$_->name) }
  return @names
}

sub neighbors{ #i have decided to make neighbors(@set) disclude the elements of @set itself. Assumed good input of actual node names
  my ($currentref) = @_;
	my @neighbors;
	foreach( @$currentref ){ @neighbors = union(\@neighbors,obj($_)->connectorsRef) }
	return minus(\@neighbors,$currentref);
}

sub family{ #family is like neighbors, but it INCLUDES the input set.
  my ($currentref) = @_;
	my @neighbors = @_;
	foreach( @$currentref ){ @neighbors = union(\@neighbors,obj($_)->connectorsRef) }
	return union(\@neighbors,$currentref);
}

sub connectedGraph{ #print "input is ",@_," and family is ",family(@_)," and lengthleft is ",length(@_)," and lengthright is ",length(family(@_)),"\n";
	my ($currentref) = @_;
	if( intersect($currentref,[nodeNames])==() ){ warn "no such node names"; return 0 }
	my @family = family($currentref);
	if( $#$currentref == $#family ){ return $currentref }
	return connectedGraph(\@family);
}

sub level{
	my ($level,$node) = @_; my @current = ($node);
	if( $level < 0 ){ return }
	if( $level==0 ){ return @current }
	while(1){
#	print "level is ",2-$level,"\n";
#	print "current is "; display \@current; print "\n";
#	print "neighbors of current is "; display([neighbors(@current)]); print "\n";
#	print "\n\n";
		#everything gets promoted
		if( $level==1 ){ return neighbors(@current) }
		@current = family(@current);
		--$level;
	}
}

sub findData{ #user cannot have parenthesis () in nodes for multiple search
	my ($search) = @_;
	if( !defined $search ){ print "Input your search keywords:\n"; $search = promptInput() }
	#            (        $1                 )($2 )
#	$search =~ s/((?:(?:^|\(|\)|&&|\|\|)\s*)+)(.+?)(?=\(|\)|&&|\|\||$)/$1connectedGraph(trim($2))/g;
	#$M = $i =~ s/((?:(?:^|\(|\)|[ )]and |[ )]or )\s*)+)(.+?)(?=\(|\)| and[ (]| or[ (]|$)/$1trim($2)/g;

	#if( !isElement($search,\@nodes) ){ print "$search is not a node.\n"; return 1 }

	print "\nThe nodes connected to $color{'name'}$search, ${resetC} are "; display([connectedGraph($search)]); print "\n\n";

	for( my $i=0; $i<=5; ++$i ){
		print "level $i is "; display([level($i,$search)]); print "\n\n\n";
	}

	print "\n the maxlevel of $search is ", maxLevel($search), "\n\n";
	print "\n the level of popcorn in $search is ", levelOfNodeInTree('popcorn',$search), "\n\n";

	print "\nneighbors in tree of $search are \n";
	display([neighborsInTree('popcorn',$search)]);

	print "\nstartingPositions of $search are \n"; my @sp = startingPositions($search);
	display \@sp;

	print "\nand now the tree...\n"; @sp = (4, 4, 24, 84, 84, 84, 4, 24, 44, 64, 84, 104);
	printTreeWithPositions($search,@sp);

	animateTree($search);



}

########################################## MAIN ##########################################

loadSettings();
#system("clear"); setting to act like "less" by default
print "Welcome to ${boldC}node.pl${resetC}!!  Type $color{'command'}help${resetC} at any time to view your options.\n";
foreach( @ARGV ){ loadData($_,'silent') } if( $#ARGV > 0 ){ $filename = '' }
deleteHistory(); saveHistory();
while(1){
	my $i; my $c; my $input = promptInput(); if( $input =~ /^\w+/ ){ $i = $& } if( $input =~ /^\w+\s+(.+)/ ){ $c = $1 }
	if( $i =~ /^h/i ){ help() }
 	elsif( $i =~ /^[an]/i ){ addNode($c); saveHistory() }
	elsif( $i =~ /^delim/i ){ delimiter($c); saveSettings() }
	elsif( $i =~ /^dc/i ){ deleteConnection($c); saveHistory() }
	elsif( $i =~ /^d/i ){ deleteNodeOrConnection($c); saveHistory() }
	elsif( $i =~ /^v/i ){ viewData($c) }
#	elsif( $i =~ /^[fk]/i ){ findData($c) }
	elsif( $i =~ /^co/i ){ color($c); saveSettings() }
	elsif( $i =~ /^[ct]/i ){ changeGraphType(); saveHistory(); saveSettings() }
	elsif( $i =~ /^s/i ){ saveData($c) }
	elsif( $i =~ /^[lo]/i ){ loadData($c); saveHistory() }
	elsif( $i =~ /^[uz]/i ){ undoData() }
	elsif( $i =~ /^[ry]/i ){ redoData() }
	elsif( $i =~ /^m/i ){ more() }
	elsif( $i =~ /^[qe]/i ){ quit(); deleteHistory(); exit 0 }
#	elsif( $i =~ /^eval/i ){ evaluate($c) }
	else{}
}
