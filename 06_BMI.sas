/************************************************************************************
	STEP 1. merge BMI information with our study cohort
************************************************************************************/

* 1.0. patients - date of BMI measurement - BMI;

proc contents data=tx.vitals_signs;
	title "m.vitals_signs";
run;

proc print data=m.vitals_signs (obs=30);
	title "m.vitals_signs";
run;

* 1.1. make a table with only BMI information sorted by patients.id;
/**************************************************
* new table: m.bmi
* original table: m.vitals_signs
* description: only bmi info sorted by patients.id
**************************************************/

proc sort data=tx.vitals_signs
		out=min.bmi;
	where code="39156-5";
	by patient_id;
run;               /* 70,570,365 obs */

proc print data=min.bmi (obs=30); run;

* 1.2. add variable named 'startdate' to indicate 'minimum date of BMI measurement';
/**************************************************
* new table: m.bmi_startdate (deleted)
* original table: m.bmi
* description: indicate the min(date) as startdate
**************************************************/

proc sql;
	create table min.bmi_startdate as
	select patient_id, min(date) as startdate
	from min.bmi
	group by patient_id;
quit;
proc print data=min.bmi_startdate (obs=30);
	title "m.bmi_startdate";
run;


* 1.3. do mapping startdate with 'm.bmi' table by patient.id;
/**************************************************
* new table: m.bmi_date
* original table: m.bmi + m.bmi_startdate
* description: left join m.bmi & m.bmi_startdate
**************************************************/

proc sql;
  create table min.bmi_date as
  select distinct a.*, b.startdate
  from min.bmi a left join min.bmi_startdate b 
  on a.patient_id=b.patient_id;
quit;                  /* 68975615 obs */  

proc sort data=min.bmi_date; by patient_id date; run;


data min.bmi_date;
    set min.bmi_date;
    date_num = input(date, yymmdd8.);
    format date_num yymmdd10.;
    drop date;
    rename date_num = date;
run;

proc means data=min.bmi_date n nmiss;
	var date;
 run;
proc contents data=m.bmi_date;
run;

/* delete */
proc datasets library=m nolist;
    delete bmi_startdate;
quit;

* 1.4. merge the BMI information with our study cohort;
/**************************************************
* new table: min.bs_glp1_bmi_v00   /* not distinct */
* original table: min.bs_glp1_user_v03 + m.bmi_date
* description: left join min.bs_glp1_user_v03 + m.bmi_date
**************************************************/

proc SQL;
	create table min.bs_glp1_bmi_v00 as
 	select a.*, b.date, b.value
  	from min.bs_glp1_user_v03 as a left join min.bmi_date as b
   	on a.patient_id = b.patient_id;
quit;                         /* 2,043,588 incl. duplicated */
    
data min.bs_glp1_bmi_v00;
    set min.bs_glp1_bmi_v00;
    rename date = bmi_date glp1_date = glp1_last_date value = bmi;
run;

proc sql;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_glp1_bmi_v00;
quit;           /* it should be the same as "82212 - BS users" - yes, it is! */

* 1.5. remove missing BMI or BMI_date;
/* we don't exclude the extreme BMI value */

data min.bs_glp1_bmi_v01;
	set min.bs_glp1_bmi_v00;
 	if missing(bmi_date) then delete;
run;  

data min.bs_glp1_bmi_v01;
	set min.bs_glp1_bmi_v01;
 	if missing(bmi) then delete;
run;    /* 1756746 obs */

* 1.6. avg BMI if multiple BMI within a day;
data min.bs_glp1_bmi_v01; 
    set min.bs_glp1_bmi_v01; 
    bmi_num = input(bmi, best32.); 
run;

data min.bs_glp1_bmi_v01; 
    set min.bs_glp1_bmi_v01 (drop=bmi); 
    rename bmi_num = bmi; 
run;

Proc sql;
Create table min.bs_glp1_bmi_v02 as
Select distinct patient_id, bmi_date, avg(bmi) as bmi
From min.bs_glp1_bmi_v01
Group by patient_id, bmi_date;
Quit;      /* 1567838 obs */

/************************************************************************************
	STEP 2. BMI at baseline | bmi_index | the clostest value prior to the first bs_date
************************************************************************************/

/**************************************************
              Variable Definition
* table:
* 	min.bs_glp1_bmi_baseline
* 	
* variables
*  bmi_index : the clostest value prior to the first bs_date
*  bmi_bf_glp1 : the clostest value prior to the first glp1 prescription date
**************************************************/

* find pts with bmi 180days prior first prescription;
Proc sql;
Create table min.bs_glp1_bmi_6mprior AS
Select distinct a.patient_id, a.temporality, a.bs_date, b.bmi_date, b.bmi
From min.bs_glp1_user_v03 a inner join min.bs_glp1_bmi_v02 b on (a.patient_id =b.patient_id and b.bmi_date < a.bs_date and b.bmi_date >= (a.bs_date-180));
Quit;

* latest bmi 6mon prior index, only have date in the output;
Proc sql;
Create table bs_glp1_bmi_latest as
Select distinct patient_id, bs_date, max(bmi_date) as latest_bmi_date format=yymmdd10.
From min.bs_glp1_bmi_6mprior
Group by patient_id, bs_date;
Quit;  

* left join latest BMI date with bmi value;
Proc sql;
Create table min.bs_glp1_bmi_baseline as
Select distinct i.* , p.bmi,  p.temporality
From bs_glp1_bmi_latest i left join min.bs_glp1_bmi_6mprior p on (i.patient_id = p.patient_id and i.bs_date=p.bs_date and i.latest_bmi_date = p.bmi_date);
Quit;

* calculate median BMI value at baseline ; 
proc means data=min.bs_glp1_bmi_baseline n nmiss median p25 p75;
  var bmi;
  title "bmi at baseline in total study population";
run;

proc means data=min.bs_glp1_bmi_baseline n nmiss median p25 p75;
  var bmi;
  where temporality = 0;
  title "bmi at baseline in non-users";
run;

proc means data=min.bs_glp1_bmi_baseline n nmiss median p25 p75;
  var bmi;
  where temporality = 2;
  title "bmi at baseline in users";
run;


/************************************************************************************
	STEP 3. To compare BMI trend for GLP-1 users vs non-users, make variables for BMI value over time from BS date
************************************************************************************/

/*
variables' name
bmi_1y_bf | BMI 1 year before the BS date
bmi_6m_bf | BMI 6 months before the BS date
bmi_1y_af | BMI 1 year after the BS date
bmi_2y_af | BMI 2 years after the BS date
bmi_3y_af | BMI 3 years after the BS date
*/

* merge bmi_dataset with consideration excluding bmi value after glp1 initiation;
/**************************************************
* for GLP1 users | min.bmi_glp1_users ;
* for non-users | min.bmi_non_users;
* for total study population | min.bmi_studypopulation;
**************************************************/

* find pts with bmi prior first glp1 initiation AMONG ONLY GLP1 USERS ;
Proc sql;
Create table min.bs_glp1_bmi_glp1_prior AS
Select distinct a.patient_id, a.glp1_initiation_date, b.bmi_date, b.bmi
From min.glp1_users_13268 a inner join min.bs_glp1_bmi_v02 b on (a.patient_id =b.patient_id and b.bmi_date < a.glp1_initiation_date);
Quit;

* for GLP1 users | min.bmi_glp1_users ;
proc sql;
create table min.bmi_glp1_users as
select distinct a.patient_id, a.temporality, a.bs_date, a.glp1_initiation_date, b.bmi_date, b.bmi
from min.glp1_users_13268 a inner join min.bs_glp1_bmi_glp1_prior b on (a.patient_id = b.patient_id and b.bmi_date < a.glp1_initiation_date);
quit;   /* 333142 obs */

proc print data=min.bmi_glp1_users (obs = 30);
run;

* for non-users | min.bmi_non_users;
proc sql;
create table min.bmi_non_users as
select distinct a.patient_id, a.temporality, a.bs_date, b.bmi_date, b.bmi
from min.bs_glp1_user_v03 a inner join min.bs_glp1_bmi_v02 b on (a.patient_id = b.patient_id and a.temporality =0);
quit;     /* 1139110 obs */

proc print data=min.bmi_non_users (obs = 30);
run;

* for total study population | min.bmi_glp1_users + min.bmi_non_users;
data min.bmi_studypopulation;
  set min.bmi_glp1_users min.bmi_non_users;
run;  /* 1472252 obs */


* 4.1. bmi_1y_bf | BMI 1 year before the BS date;
/**************************************************
* new table: min.bs_glp1_bmi_1y_bf_v01 
* original table: min.bmi_studypopulation
**************************************************/

data min.bs_glp1_bmi_1y_bf_v00;
   set min.bmi_studypopulation;
   if bs_date - 365 < bmi_date and bmi_date < bs_date then do;
   	gap = bmi_date - bs_date + 365;
   end;
   else delete;
run;

proc sort data = min.bs_glp1_bmi_1y_bf_v00;
	by patient_id gap;
run;     /* the smaller gap = the closer from the 1 yr prior to the surgery */

/* distinct population */
data min.bs_glp1_bmi_1y_bf_v01;
	set min.bs_glp1_bmi_1y_bf_v00;
 	by patient_id;
 	if first.patient_id;
run; 

/* distribution of the values */
proc sort data = min.bs_glp1_bmi_1y_bf_v01;
	by temporality;
run;

proc means data=min.bs_glp1_bmi_1y_bf_v01 n nmiss median p25 p75 min max;
	var bmi;
 	title "min.bs_glp1_bmi_1y_bf";
run;
proc means data=min.bs_glp1_bmi_1y_bf_v01 n nmiss median p25 p75 min max;
	var bmi;
 	by temporality;
 	title "min.bs_glp1_bmi_1y_bf";
run;

* 4.2. bmi_6m_bf | BMI 6 months before the BS date;
/**************************************************
* new table: min.bs_glp1_bmi_6m_bf_v01   
* original table: min.bmi_studypopulation
**************************************************/

data min.bs_glp1_bmi_6m_bf_v00;
   set min.bmi_studypopulation;
   if bs_date - 365/2 < bmi_date and bmi_date < bs_date then do;
   	gap = bmi_date - bs_date + 365/2;
   end;
   else delete;
run;

proc sort data = min.bs_glp1_bmi_6m_bf_v00;
	by patient_id gap;
run;     /* the smaller gap = the closer from the 6 months prior to the surgery */

/* distinct population */
data min.bs_glp1_bmi_6m_bf_v01;
	set min.bs_glp1_bmi_6m_bf_v00;
 	by patient_id;
 	if first.patient_id;
run;     

/* distribution of the values */
proc sort data = min.bs_glp1_bmi_6m_bf_v01;
	by temporality;
run;

proc means data=min.bs_glp1_bmi_6m_bf_v01 n nmiss median p25 p75 min max;
	var bmi;
 	title "min.bs_glp1_bmi_6m_bf";
run;
proc means data=min.bs_glp1_bmi_6m_bf_v01 n nmiss median p25 p75 min max;
	var bmi;
 	by temporality;
 	title "min.bs_glp1_bmi_6m_bf";
run;

* 6.3. bmi_1y_af | BMI 1 year after the BS date;
/**************************************************
* new table: min.bs_glp1_bmi_1y_af_v01
* original table: min.bmi_studypopulation
**************************************************/

data min.bs_glp1_bmi_1y_af_v01;
   set min.bmi_studypopulation;
   if bs_date + 365 < bmi_date and bmi_date < bs_date + 365 + 90 then do;
   	gap = bmi_date - bs_date;
   end;
   else delete;
run;

proc sort data = min.bs_glp1_bmi_1y_af_v00;
	by patient_id gap;
run;    

/* distinct population */
data min.bs_glp1_bmi_1y_af_v01;
	set min.bs_glp1_bmi_1y_af_v00;
 	by patient_id;
 	if first.patient_id;
run;       

/* distribution of the values */
proc sort data = min.bs_glp1_bmi_1y_af_v01;
	by temporality;
run;

proc means data=min.bs_glp1_bmi_1y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
 	title "min.bs_glp1_bmi_1y_af";
run;
proc means data=min.bs_glp1_bmi_1y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
	by temporality;
 	title "min.bs_glp1_bmi_1y_af";
run;

* 6.4. bmi_2y_af | BMI 2 years after the BS date;
/**************************************************
* new table: min.bs_glp1_bmi_2y_af_v01    
* original table: min.bmi_studypopulation
**************************************************/

data min.bs_glp1_bmi_2y_af_v00;
   set min.bmi_studypopulation;
   if bs_date + 365*2 < bmi_date and bmi_date < bs_date + 365*2 + 90 then do;
   	gap = bmi_date - bs_date;
   end;
   else delete;
run;

proc sort data = min.bs_glp1_bmi_2y_af_v00;
	by patient_id gap;
run;    

/* distinct population */
data min.bs_glp1_bmi_2y_af_v01;
	set min.bs_glp1_bmi_2y_af_v00;
 	by patient_id;
 	if first.patient_id;
run;      

/* distribution of the values */
proc sort data = min.bs_glp1_bmi_2y_af_v01;
	by temporality;
run;

proc means data=min.bs_glp1_bmi_2y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
 	title "min.bs_glp1_bmi_2y_af";
run;
proc means data=min.bs_glp1_bmi_2y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
	by temporality;
 	title "min.bs_glp1_bmi_2y_af";
run;

* 6.5. bmi_3y_af | BMI 3 years after the BS date;
/**************************************************
* new table: min.bs_glp1_bmi_3y_af_v01    
* original table: min.bmi_studypopulation
**************************************************/

data min.bs_glp1_bmi_3y_af_v00;
   set min.bmi_studypopulation;
   if bs_date + 365*3 < bmi_date and bmi_date < bs_date + 365*3 + 90 then do;
   	gap = bmi_date - bs_date;
   end;
   else delete;
run;

proc sort data = min.bs_glp1_bmi_3y_af_v00;
	by patient_id gap;
run;    

/* distinct population */
data min.bs_glp1_bmi_3y_af_v01;
	set min.bs_glp1_bmi_3y_af_v00;
 	by patient_id;
 	if first.patient_id;
run;       

/* distribution of the values */
proc sort data = min.bs_glp1_bmi_3y_af_v01;
	by temporality;
run;

proc means data=min.bs_glp1_bmi_3y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
 	title "min.bs_glp1_bmi_3y_af";
run;
proc means data=min.bs_glp1_bmi_3y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
	by temporality;
 	title "min.bs_glp1_bmi_3y_af";
run;

* 4.6. bmi_4y_af | BMI 4 years after the BS date;
/**************************************************
* new table: min.bs_glp1_bmi_4y_af_v01    
* original table: min.bmi_studypopulation
**************************************************/

data min.bs_glp1_bmi_4y_af_v00;
   set min.bmi_studypopulation;
   if bs_date + 365*4 < bmi_date and bmi_date < bs_date + 365*4 + 90 then do;
   	gap = bmi_date - bs_date;
   end;
   else delete;
run;

proc sort data = min.bs_glp1_bmi_4y_af_v00;
	by patient_id gap;
run;    

/* distinct population */
data min.bs_glp1_bmi_4y_af_v01;
	set min.bs_glp1_bmi_4y_af_v00;
 	by patient_id;
 	if first.patient_id;
run;       

/* distribution of the values */
proc sort data = min.bs_glp1_bmi_4y_af_v01;
	by temporality;
run;

proc means data=min.bs_glp1_bmi_4y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
 	title "min.bs_glp1_bmi_4y_af";
run;
proc means data=min.bs_glp1_bmi_4y_af_v01 n nmiss median p25 p75 min max;
	var bmi;
	by temporality;
 	title "min.bs_glp1_bmi_4y_af";
run;
