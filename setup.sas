/*!
* Sets up ARD-Generator SAS Programs.
* @author Karl Wallendszus
* @created 2022-03-17
*/
*******************************************************************************;

* options mlogic mprint symbolgen;
options nomlogic nomprint nosymbolgen;
options noxwait;

*******************************************************************************;
* Macros
*******************************************************************************;

/**
* Check if the version file exists, and if it doesn't, raise an error.
*/
%macro verexist;

	%if %sysfunc(fileexist('version.txt')) %then %do;  
		%put NOTE: The version file version.txt was found.;
	%end;
	%else %do;
		%put ERROR: The required version file version.txt does not exist.;
	%end;

%mend verexist;

*******************************************************************************;
* Main code
*******************************************************************************;

* Set base directory for the project;
x 'setbasedir.cmd';
x 'copy setbase_stem.sas + sasbaseard.sas setbase.sas /b';
%include 'setbase.sas';
%put NOTE: sasbaseard = &sasbaseard.;

* Copy setbase.sas to wherever else in the tree it is needed;
x 'copy setbase.sas .\programs';
x 'copy setbase.sas .\macros\test';

* Check for presence of the version file;
%verexist;

* Set up templates;
/*
x 'cd templates';
%include '*.sas';
*/
