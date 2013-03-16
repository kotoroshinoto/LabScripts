#!/usr/bin/env python
import sys
import os
import BiotoolsSettings
BiotoolsSettings.AssertPaths()
import DPyGetOpt
import pyswitch
class Usage(Exception):
    def __init__(self, msg, err=True):
        #msg is an error message to post before the usage info
        self.msg = msg
        self.exit_code=None
        if err == True:
            self.exit_code = 2
        else:
            self.exit_code = 0
def main(argv=None):
    if argv is None:
        argv = sys.argv
    try:
        #try to parse option arguments
        try:
            pass
        except DPyGetOpt.ArgumentError as DPyGetOptArgErr:
            pass
        except DPyGetOpt.Error as DPyGetOptErr:
            pass
        except DPyGetOpt.SpecificationError as DPyGetOptSpecErr:
            pass
        except DPyGetOpt.TerminationError as DPyGetOptTermErr:
            pass
        raise Usage("")
    except Usage as err:
        sys.stderr.write(err.msg)
        sys.stderr.write("for help use --help")
        return err.exit_code
        
if __name__ == "__main__":
    sys.exit(main())