/*!
* Imports SAS V5 transport files and converts them to SAS datasets.
* @author Karl Wallendszus
* @created 2023-07-21
*/
*******************************************************************************;

* Set base directory;
%include 'setbase.sas';

* Set working directory;
%let workdir = &sasbaseard.\programs;
x "cd &workdir.";

* Set library and path names;
libname adam "&sasbaseard.\data\adam" inencoding="wlatin1" filelockwait=5;
%let dirxpt = &sasbaseard.\data\adam\xpt;

* Set date/time macro variables;
%include "&sasbaseard./setprogdt.sas";

options label dtreset spool;
* options mlogic mprint symbolgen;
options nomlogic nomprint nosymbolgen;

*******************************************************************************;
* Macros
*******************************************************************************;

/**
* Finds all files with the given extension within the directory that is passed 
* to the macro, including any subdirectories, and writes their paths to a
* dataset.
* Adpated from https://documentation.sas.com/?docsetId=mcrolref&docsetTarget=n0js70lrkxo6uvn1fl4a5aafnlgt.htm&docsetVersion=9.4&locale=en
*
* @param dir		Name of directory to search.
* @param ext		File extension to search for.
* @param dsout		Output dataset.
*/
%macro list_files ( dir, ext, dsout );

	* Declare macro variables;
	%local filrf rc did memcnt name i;

	* Set fileref and open directory;
	%let rc = %sysfunc(filename(filrf, &dir.));
	%let did = %sysfunc(dopen(&filrf.));      

	* Check that the directory can be opened;
 	%if &did. eq 0 %then %do;
		%put ERROR: Directory &dir. cannot be opened or does not exist;
		%return;
	%end;

	* Create output dataset;
	data &dsout.;
		length dir $132 filename $80;
		stop;
	run;

	* Loop through files in the directory;
	%do i = 1 %to %sysfunc(dnum(&did));   

		* Get filename;
 		%let name = %qsysfunc(dread(&did., &i.));

		* Check extension;
		%if %qupcase(%qscan(&name., -1, .)) = %upcase(&ext.) %then %do;
			* Extension matches;
        	%put &dir.\&name.;
			proc sql;
				insert into &dsout.
					( dir, filename )
					values ( "&dir.", "&name." );
			quit;
      	%end;
      	%else %if %index(&name., .) > 0 %then %do;
			* No extension so assume it is a subdirectory;
        	%list_files(&dir.\&name., &ext.);
      	%end;

	%end; /* file loop */

	* Close directory and unassign fileref;
	%let rc = %sysfunc(dclose(&did.));
	%let rc = %sysfunc(filename(filrf));     

%mend list_files;

*******************************************************************************;

/**
* Coverts XPT files into SAS datasets with XPT files.
*
* @param dirxpt		Folder containing XPT files.
* @param libsas		Name of library containing datasets to compare.
*/
%macro ds_convert_xpt_sas ( dirxpt=, libsas= );

	* Find XPT files to import;
	%list_files(&dirxpt., XPT, xptfiles);

	* Derive a list of xptfiles;
	%local xptlist ixpt xpt ds;
	proc sql;
		select filename into :xptlist separated by ' '
			from xptfiles
			order by 1;
	quit;

	* Loop through XPT files;
	%let ixpt = 1;
	%do %while(%scan(&xptlist., &ixpt., ' ') ne );
		%let xpt = %scan(&xptlist., &ixpt., ' ');

		* Convert XPT file back to SAS dataset;
		filename xptfile "&dirxpt.\&xpt.";
		%let ds = %qscan(&xpt., 1, .);
		%xpt2loc(libref=&libsas., memlist=&ds., filespec=xptfile);

		%let ixpt = %eval(&ixpt+1);
	%end; /* XPT file loop */

%mend ds_convert_xpt_sas;

*******************************************************************************;
* Main code
*******************************************************************************;

* Import XPT files as SAS datasets;
%ds_convert_xpt_sas(dirxpt=&dirxpt., libsas=adam);
