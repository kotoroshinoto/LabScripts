'''
Created on Mar 26, 2013

@author: mgooch
'''
import BiotoolsSettings
def replaceVars(instr,subjob,grouplbl,cumsuffix,prefix,prefix2=None):
    #TODO: fill in stub
    if instr is None:
        pass
    if subjob is None:
        pass
    if grouplbl is None:
        pass
    if cumsuffix is None:
        pass
    if prefix is None:
        pass
#    if(!defined($grouplbl)){die "replaceVars called without grouplbl variable\n";}
#    if(!defined($grouplbl)){die "replaceVars called without cumsuffix variable\n";}
#    my ($prefix,$prefix2);
#    $prefix=shift;
#    if(!defined($grouplbl)){die "replaceVars called without prefix variable\n";}
#    if(${$subjob}->{parent}->{isCrossJob}){
#        $prefix2=shift;
#        if(!defined($grouplbl)){die "replaceVars called on crossjob without prefix2 variable\n";}
#    }else {$prefix2="";}
#    my $search;
#    my $replace;
#    #replace custom variables
#    for my $var(keys(%{${$subjob}->{parent}->{vars}})){
#        $search=$var;
#        $replace=${$subjob}->{parent}->{vars}->{$var};
#        $search=~s/\$/\\\$/g;
#        #$replace=~s/\$/'\$'/g;
#        #print "replacing $search with $replace\n";
#        $str=~s/$search/$replace/g;
#    }
#    
#    #replace ADJPREFIX with $PREFIX$CUMSUFFIX - totally for convenience, can still use $CUMSUFFIX directly, for input files that need it
#    if(!defined($cumsuffix)){$cumsuffix="";}
#    if(!${$subjob}->{parent}->{clearsuffixes}){
#        $str=~s/\$ADJPREFIX/\$PREFIX\$CUMSUFFIX/g;
#    } else {
#        $str=~s/\$ADJPREFIX/\$PREFIX/g;
#    }
#    $str=~s/\$CUMSUFFIX/$cumsuffix/g;
#    my $suffix=${$subjob}->{parent}->{suffix};
#    #print "suffix: $suffix","\n";
#    $str=~s/\$SUFFIX/$suffix/g;
#    
#    #replace standard variables
#    for my $key(keys(%{SettingsLib::SettingsList})){
#        $search='\$'.$key;
#        $replace=${SettingsLib::SettingsList}{$key};
#        #print "search $search : replace $replace\n";
#        $str=~s/$search/$replace/g;
#    }
#    #replace remaining filename vars
#    
#    $str=~s/\$GROUPLBL/$grouplbl/g;
#    $str=~s/\$CUMSUFFIX/$cumsuffix/g;
#    $str=~s/\$PREFIX/$prefix/g;
#    if(${$subjob}->{parent}->{isCrossJob}){
#        $str=~s/\$PREFIX2/$prefix2/g;
#    }
#    return $str;
    return None


def templateDir():
    #return os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))),"jobtemplates")#get path to this script, get directory name, and go up one level, then append template dir name
    return BiotoolsSettings.getValue("SJM_TEMPLATE_DIR")