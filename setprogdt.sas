/*!
* Sets the following macro variables containing the current date/time.
* <ul>
* <li>progdtc_iso: in format YYYY-MM-DDTHH:MM:SS (complies with ISO8601)</li>
* <li>progdtc_name: in format YYYY-MM-DDTHH-MM-SS (can be used in filenames)</li>
* </ul>
* @author Karl Wallendszus
* @created 2016-08-24
*/
*******************************************************************************;

%global progdtc_iso progdtc_name;
data _null_;
	now = datetime();
	now_iso = put(now, E8601DT19.);

	* Replace colons with dashes to enable variable to be used in filenames;
	now_name = translate(now_iso, '-', ':');

	call symput("progdtc_iso", now_iso);
	call symput("progdtc_name", now_name);
run;
