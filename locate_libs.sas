/*!
* Sets filerefs amd librefs for macro and format libraries.
* @author Karl Wallendszus
* @created 2023-05-22
*/
*******************************************************************************;

*******************************************************************************;
* Macros
*******************************************************************************;

/**
* Sets up a macro library reference.
*
* @param lib_name	Name of macro library
* @param basedir	Base directory in which the macro library resides.
* @param subdir		Subdirectory of the base directory in which the macro 
*					library resides.
*/
%macro setmacrolib ( lib_name=, basedir=, subdir= );

	%let filrf=&lib_name.;
	%let rc=%sysfunc(filename(filrf, &basedir.&subdir.));
	%if &rc ne 0 %then %put %sysfunc(sysmsg());

%mend setmacrolib;

*******************************************************************************;
* Main code
*******************************************************************************;

* Macro libraries;
%setmacrolib(lib_name=ardmacro, basedir=&sasbaseard., 
	subdir=%str(\macros\source)); 

* Make AUTOCALL macro libraries available;
options mautosource sasautos = ( ardmacro sasautos );

/*
* Make the format libraries available;
options fmtsearch = ( comfmt );
*/
