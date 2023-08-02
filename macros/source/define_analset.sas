/*!
********************************************************************************
* Create a work dataset to define the analysis set population;
* @author Karl Wallendszus
* @created 2023-08-02
*
* @param mdlib		Library containing metadata datasets.
* @param datalib	Library containing data to be analysed.
* @param analsetid	Analysis set ID.
* @param dsout		Output dataset.
********************************************************************************
*/
%macro define_analset ( mdlib=, datalib=, analsetid=, dsout=analset );

	* Get analysis set details;
	%local analsetlabel dscond condvar condstr;
	proc sql;
		select a.label, a.condition_dataset, a.condition_variable, 
				e.expression
				into :analsetlabel, :dscond, :condvar, :condstr
			from &mdlib..analysissets a join &mdlib..expressions e
				on a.id = e.id
			where a.id = "&analsetid.";
	quit;

	* Create a dataset to define the analysis set population;
	data &dsout. ( keep = usubjid &condvar. );
		set &datalib..&dscond. ( where = (&condstr.) );
	run;

%mend define_analset;

*******************************************************************************;
