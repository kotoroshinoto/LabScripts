#how to define jobs for resolving file dependencies
#steps separated by ':' imply nothing about linkage, assume no link unless otherwise specified
#steps separated by '-' imply that JOBL is parent of JOBR
#STEP1-STEP2-STEP3

#can provide explicit parent-list by putting parent steps into square brackets and separating with ','
#parent step name must have been defined previously in a left-to-right manner
#examples:
#STEP1:STEP2[STEP1]-STEP3 or 
#STEP1:STEP2:STEP3[STEP1,STEP2] or 
#STEP1:STEP2[STEP1]:STEP3[STEP2] (equivalent to STEP1-STEP2-STEP3)

#multiple steps that are the children of a previous step can be combined into a parenthesis and separated by ','
#all subsequent linking should be done either inside the parenthesis or by separating with : and continuing definitions
#examples: 
#STEP1-(STEP2,STEP3) <- both steps 2 and 3 are children of step1 but have no relation to each other 
#STEP1-(STEP2_1-STEP2_2,STEP3_1-STEP3_2) <- STEP2_1 and STEP3_1 are children of STEP1, each has its own child
#STEP1-(STEP2,STEP3):STEP4[STEP3]
#STEP1:(STEP2,STEP3)[STEP1]:STEP4[STEP3] <-implies that both STEP2 and STEP3 are dependent on STEP1 and that STEP4 follows STEP3
#STEP1:(STEP2,STEP3-STEP4)[STEP1]  <- same as immediately previous example

#if assuming steps, pipeline steps can refer to assumed steps as their parents
#these definitions will be read left-to-right, any unresolvable situation will result in an error
#with these rules it should not be possible, but just in case: NO CIRCULAR DEPENDENCIES 
#obvious the above rules imply that step names cannot contain any of these: -()[]:

#TODO implement the above system
#for now going with '-'
sub parsePipelineDERP{
	my $string=shift;
	$string=PipelineUtil::trim($string);
	my @parents=@_;#=uniq @_;
	#print STDERR  "parsing: $string\n";
	#if(scalar(@parents)){print STDERR  "\tparents: @parents\n";}
	my @added_Vertices;#store them to return them
	my ($openparenpos,$closeparenpos,$paren_err)=getParenthesisPositions($string);
	my $parensub="";
	if($paren_err){die "INVALID FORMAT (parentheses error)\n";}
	if($openparenpos==0 && $closeparenpos>-1){
		$parensub=substr($string,$openparenpos+1,$closeparenpos-$openparenpos-1);
		my $rest=substr($string,$closeparenpos+1);
		my $parentstr;
		#my @parents;
		#print STDERR  "balanced parenthesis found from $openparenpos to $closeparenpos; contained: $parensub\n";
		if(charAt($rest,0) eq '['){
			my $end=index($rest,']');
			if($end != -1){
				$parentstr=substr($rest,1,$end-1);
				$rest=substr($rest,$end+1);
				push (@parents,split(',',$parentstr));
				#@parents=uniq @parents;
				#print "\tusing parents: @parents\n";
			}
		}
		if(charAt($rest,0) eq '-'){die "FORMAT ERROR (dash following parentheses)\n"};
		if(charAt($rest,0) eq ':'){$rest=substr($rest,1)};
		#print STDERR  "rest: $rest\n";
		my @commasplit=splitCommaNotInParens($parensub);
		for my $item (@commasplit){
			if(scalar(@parents)){
				push (@added_Vertices,parsePipeline($item,@parents));
			} else {
				push (@added_Vertices,parsePipeline($item));
			}
		}
		if(defined($rest) && length ($rest)){push (@added_Vertices,parsePipeline($rest));}
	} else {
		my $parentstr="";
		my $namestr="";
		#my $commapos=index($string,',');
		my $colonpos=index($string,':');
		my $dashpos=index($string,'-');
		#print STDERR "colonpos: $colonpos\n";
		#print STDERR "dashpos: $dashpos\n";
		if($colonpos == 0){die "INVALID FORMAT (colon at start of parse)\n";}
		if($dashpos == 0){die "INVALID FORMAT (dash at start of parse)\n";}
		if ($colonpos > 0 && ($colonpos < $dashpos || $dashpos <=0  ) ){
			$namestr=substr($string,0,$colonpos);#012
			my $rest=substr($string,$colonpos+1);
			#ADD
			parseBracketsDERP($namestr,\$namestr,\@parents);
			addStep($namestr,@parents);
			push(@added_Vertices,$namestr);
			#print STDERR  ("COLON SEPARATOR -> namestr: $namestr\n");
			push(@added_Vertices,parsePipeline($rest));
		} elsif ($dashpos > 0 && ( $dashpos < $colonpos || $colonpos <=0 ) ){
			$namestr=substr($string,0,$dashpos);#012
			my $rest=substr($string,$dashpos+1);
			#print "parents before: @parents\n";
			parseBracketsDERP($namestr,\$namestr,\@parents);
			#print "parents after: @parents\n";
			#ADD
			addStep($namestr,@parents);
			push(@added_Vertices,$namestr);
			#print STDERR ("DASH SEPARATOR -> namestr: $namestr\n");
			push(@added_Vertices,parsePipeline($rest,$namestr));
		} else {
			#print STDERR "string: $string\n";
			parseBracketsDERP($string,\$namestr,\@parents);
			#$namestr=$string;
			if($namestr ne ""){
				#ADD
				addStep($namestr,@parents);
				push(@added_Vertices,$namestr);
			}
			#print STDERR "namestr: $namestr\n";
		}
	}
	return @added_Vertices;
}

sub parseBracketsDERP{
	my $string=shift;
	my $namestr=shift;
	my $parents=shift;
	my $start=index($string,'[');
	my $end=index($string,']');
	my $parentstr;
	
	if($start > 0){
		if($end > 0){
			#print STDERR "string: $string\n";
			$parentstr=substr($string,$start+1,$end-$start-1);
			#print STDERR "parentstr: $parentstr\n";
			${$namestr}=substr($string,0,$start);
			#print STDERR "namestr: ${$namestr}\n";
			push (@{$parents},split(',',$parentstr));
		} else {
			die "INVALID FORMAT (unpaired '[')\n";
		}
	} elsif($end > 0) {
		die "INVALID FORMAT (unpaired ']')\n";
	} else {
		${$namestr}=$string;
	}
}
sub splitCommaNotInParens{
	my @splitresult;
	my $string=shift;
	#print STDERR "splitting: $string\n";
	my $parenlayer=0;
	my $char;
	my $badformat=0;
	my $word="";
	for(my $i=0;$i<length($string) && !$badformat;++$i){
		$char=charAt($string,$i);
		if($char eq '('){
			++$parenlayer;
		}elsif($char eq ')'){
			--$parenlayer;
			if($parenlayer==-1){$badformat=1;}
		}
		if($char eq ',' && $parenlayer == 0){
			push (@splitresult,$word);
			$word="";
		}else {
			$word.=$char;
		}
	}
	push (@splitresult,$word);
	if($badformat){
		die("INVALID FORMAT (parentheses error)\n");
	}
	return @splitresult;
}
sub getParenthesisPositions{
	my $string=shift;
	my (@positions)=(-1,-1,0);
	my $parenfound=0;
	my $parenlayer=0;
	my $char;
	my $badformat=0;
	my $done=0;
	for(my $i=0;$i<length($string) && !$done;++$i){
		$char=charAt($string,$i);
		if($char eq '('){
			if(!$parenfound){$positions[0]=$i;}
			$parenfound=1;
			++$parenlayer;
		}elsif($char eq ')'){
			if(!$parenfound){$badformat=1;$done=1;}
			--$parenlayer;
			if($parenlayer==-1){$badformat=1;$done=1;}
			if($parenfound && $parenlayer==0){$positions[1]=$i;$done=1;}
		}
	}
	if($badformat){
		@positions=(-1,-1,1)#no values and indicate error
	}
	return @positions;
}