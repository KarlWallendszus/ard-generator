/*!
* Deletes all files from the work library.
* @author Karl Wallendszus
* @created 2024-03-08
*/
*******************************************************************************;

* Set base directory;
%include 'setbase.sas';

options label dtreset spool;
* options mlogic mprint symbolgen;
options nomlogic nomprint nosymbolgen;

*******************************************************************************;
* Macros
*******************************************************************************;

*******************************************************************************;
* Main code
*******************************************************************************;

* Empty the work library;
proc datasets library=work kill;
run;
quit;
