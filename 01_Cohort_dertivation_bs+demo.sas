/************************************************************************************
| Project name : Thesis - BS and GLP1
| Program name : 01_Cohort_dertivation
| Date (update): June 2024
| Task Purpose : 
|      1. select all Bariatric Surgery(BS) users from 100% data (N = 99,350)
|      2. BS users (initial use date) between 2016 - 2020    (N = 45,761)
|      3. Merge "BS users 2016 - 2020" + demographic data (N = 45,761)
|      4. select Age >= 18 (N = 44,959)
|      5. exclude individuals without sex information (N = 42,535)
| Main dataset : (1) procedure, (2) tx.patient, (3) tx.patient_cohort & tx.genomic (but not merged)
| Final dataset : min.bs_user_all_v07 (with distinct indiv)
************************************************************************************/


/************************************************************************************
	STEP 1. All Bariatric Surgery(BS) users	     N = 99,350
************************************************************************************/

* 1.0. explore procedure dataset;

proc print data=tx.procedure (obs=40);
    title "tx.procedure";
run;                      
proc contents data=tx.procedure;
    title "tx.procedure";
run;                /* 1,582,000,163 obs  */

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from tx.procedure;
  	title "the number of total population in tx.procedure";
quit;   /*  obs */



* 1.1. list up all of the value of code_system;

/**************************************************
* new table: min.procedure_codelist
* original table: tx.procedure
* description: select "all" BS_users from tx.procedure
**************************************************/

proc sql;
  create table min.procedure_codelist as
  select distinct code_system
  from tx.procedure; 
quit; 
proc print data=min.procedure_codelist; 
  title "min.procedure_codelist";
run;


* 1.2. Select all BS_users and categorize them by the type of BS;

/**************************************************
* new table: min.bs_user_rygb_v01
*	           min.bs_user_sg_v01
* original table: tx.procedure
* description: select each type of BS_users from tx.procedure
**************************************************/

* 1.2.1. RYGB users (n = 70266 obs);

data min.bs_user_rygb;
  set tx.procedure;
  length bs_type $8;     
  if code in ("43644", "43645", "43846", "43847", "43633", "43.7", "44.39", "44.38", "0D16078", "0D16479", "0D1647A", "0D164J9", "0D164JA", "0D164K9", "0D164KA", "0D164Z9", "0D164ZA", "0D164ZB") then do;
  	bs_type = "rygb";
  end;
  else delete;
run;              /* 70266 obs */

proc print data=min.bs_user_rygb (obs=30);
  title "min.bs_user_rygb";
run;


data min.bs_user_rygb_v01;  /* distinct patient-date */
	set min.bs_user_rygb (keep = patient_id date bs_type);
run;                /* 67724 obs */
proc sort data = min.bs_user_rygb_v01 nodupkey out =min.bs_user_rygb_v01;
	by _all_;
run;                /* 36145 obs - it includes all of dates for individuals who have more than one date */

proc print data=min.bs_user_rygb_v01 (obs=30);
  title "min.bs_user_rygb_v01";
run;                

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_rygb_v01;
  	title "the number of distinct RYGB users";
quit;   /* 31034 obs -> 32630 obs - it includes only distinct RYGB users list */


* 1.2.2. SG users (n = 39738 -> 42981 obs);

data min.bs_user_sg;
  set tx.procedure;
  length bs_type $8;      /* define the length of variable first */
  if code in ("43842", "43843", "43775", "44.68", "44.69", "43.82", "43.89", "0DQ60ZZ", "0DB64ZZ", "0DB64Z3") then do;
  	bs_type = "sg";
  end;
  else delete;
run;             /* 79955 obs -> 61463 -> 84925 */

proc print data=min.bs_user_sg (obs=30);
  title "min.bs_user_sg";
run;


data min.bs_user_sg_v01;  /* distinct patient-date */
	set min.bs_user_sg (keep = patient_id date bs_type);
run;                /* 79955 obs */
proc sort data = min.bs_user_sg_v01 nodupkey out =min.bs_user_sg_v02;
	by _all_;
run;                /* 40531 obs -> 43948 obs - it includes all of dates for individuals who have more than one date */

proc print data=min.bs_user_sg_v02 (obs=30);
  title "min.bs_user_sg_v02";
run;                

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_sg_v02;
quit;         /* 39738 obs -> 42981 obs - it includes only distinct SG users list */


* 1.2.3. AGB users (n = 2465);

data min.bs_user_agb;
  set tx.procedure;
  length bs_type $8;      /* define the length of variable first */
  if code in ("43770", "S2082", "44.95", "0DV64CZ") then do;
  	bs_type = "agb";
  end;
  else delete;
run;             /* 3881 obs */

proc print data=min.bs_user_agb (obs=30);
  title "min.bs_user_agb";
run;


data min.bs_user_agb_v01;  /* distinct patient-date */
	set min.bs_user_agb (keep = patient_id date bs_type);
run;                /* 3881 obs */
proc sort data = min.bs_user_agb_v01 nodupkey out =min.bs_user_agb_v02;
	by _all_;
run;                /* 2534 obs - it includes all of dates for individuals who have more than one date */

proc print data=min.bs_user_agb_v02 (obs=30);
  title "min.bs_user_agb_v02";
run;                

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_agb_v02;
quit;         /* 2465 obs - it includes only distinct AGB users list */


* 1.2.4. SADI-S users (n = 5841);
* min.bs_user_sadi_s;

data min.bs_user_sadi_s;
  set tx.procedure;
  length bs_type $8;      /* define the length of variable first */
  if code in ("43659") then do;
  	bs_type = "sadi_s";
  end;
  else delete;
run;             /* 8292 obs */

proc print data=min.bs_user_sadi_s (obs=30);
  title "min.bs_user_sadi_s";
run;


data min.bs_user_sadi_s_v01;  /* distinct patient-date */
	set min.bs_user_sadi_s (keep = patient_id date bs_type);
run;                
proc sort data = min.bs_user_sadi_s_v01 nodupkey out =min.bs_user_sadi_s_v02;
	by _all_;
run;                /* 6056 obs - it includes all of dates for individuals who have more than one date */

proc print data=min.bs_user_sadi_s_v02 (obs=30);
  title "min.bs_user_sadi_s_v02";
run;                

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_sadi_s_v02;
quit;         /* 5841 obs - it includes only distinct SADI-S users list */


* 1.2.5. BPD users (n = 26278);
* min.bs_user_bpd2 ;
/* "43845", "45.91", "45.51", "43.89", "0D190Z9", "0DB60ZZ", "0DB80ZZ" */

data min.bs_user_bpd;
  set tx.procedure;
  length bs_type $8;      /* define the length of variable first */
  if code in ("43845") then do;
  	bs_type = "bpd";
  end;
  else delete;
run;             /* 36944 -> 227 obs */

data min.bs_user_bpd2;
  set tx.procedure;
  length bs_type $8;      /* define the length of variable first */
  if code in ("43845", "45.91", "45.51", "43.89") then do;
  	bs_type = "bpd";
  end;
  else delete;
run;             /* 36944 -> 5836 obs */

proc print data=min.bs_user_bpd2 (obs=30);
  title "min.bs_user_bpd";
run;

data min.bs_user_bpd_v01;  /* distinct patient-date */
	set min.bs_user_bpd2 (keep = patient_id date bs_type);
run;                
proc sort data = min.bs_user_bpd_v01 nodupkey out =min.bs_user_bpd_v02;
	by _all_;
run;                /* 28303 obs - it includes all of dates for individuals who have more than one date */

proc print data=min.bs_user_bpd_v02 (obs=30);
  title "min.bs_user_bpd_v02";
run;                

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_bpd_v02;
quit;         /* 3987 obs - it includes only distinct BPD users list */


* 1.2.6. VBG users (n = 573);

data min.bs_user_vbg;
  set tx.procedure;
  length bs_type $8;      /* define the length of variable first */
  if code in ("43842", "44.68", "0DV64CZ") then do;
  	bs_type = "vbg";
  end;
  else delete;
run;             /* 650 obs */

proc print data=min.bs_user_vbg (obs=30);
  title "min.bs_user_vbg";
run;


data min.bs_user_vbg_v01;  /* distinct patient-date */
	set min.bs_user_vbg (keep = patient_id date bs_type);
run;                
proc sort data = min.bs_user_vbg_v01 nodupkey out =min.bs_user_vbg_v02;
	by _all_;
run;                /* 582 obs - it includes all of dates for individuals who have more than one date */

proc print data=min.bs_user_vbg_v02 (obs=30);
  title "min.bs_user_vbg_v02";
run;                

proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_vbg_v02;
quit;         /* 573 obs - it includes only distinct BPD users list */


* 1.3. Merge all datasets of each type of BS to have all BS users file;

/**************************************************
* new table: min.bs_user_all_v00
		min.bs_user_all_v01
* original table: = min.bs_user_rygb_v02 + min.bs_user_sg_v02 + min.bs_user_agb_v02 + min.bs_user_sadi_s_v02 + min.bs_user_bpd_v02 + min.bs_user_vbg_v02
* description: select "all" BS_users
**************************************************/

data min.bs_user_all_v00;
	set min.bs_user_rygb_v02 min.bs_user_sg_v02 min.bs_user_agb_v02 min.bs_user_sadi_s_v02 min.bs_user_bpd_v02 min.bs_user_vbg_v02;
run;                          
proc sort data=min.bs_user_all_v00;
	by patient_id date;
run;                    /* 109585 obs -> 90494 */

proc print data=min.bs_user_all_v00 (obs=40);
	title "min.bs_user_all_v00";
run;

/* to count distinct number of BS users */
proc SQL;
	select count(distinct patient_id) as distinct_patient_count
 	from min.bs_user_all_v00;
quit;   /* 81008 obs */

* 1.4. make variable "bs_count" indicating the number of BS by patient;

proc sql;
    create table min.bs_user_all_v00 as
    select *, count(*) as bs_count
    from min.bs_user_all_v00
    group by patient_id;
quit;
proc print data=min.bs_user_all_v00 (obs=40);
	title "min.bs_user_all_v00";
run;

* 1.5. select the first BS date if patients have multiple BS (n = 81008) ;

proc sort data=min.bs_user_all_v00;
	by patient_id date;
run;             
data min.bs_user_all_v01;
	set min.bs_user_all_v00;
	by patient_id;
	if first.patient_id;
run;           /* 81008 obs */

proc print data=min.bs_user_all_v01 (obs=40);
	title "min.bs_user_all_v01";
run;
proc contents data=min.bs_user_all_v01;
	title "min.bs_user_all_v01";
run;


* 1.6. count how many individuals have multiple BS procedures;

proc freq data=min.bs_user_all_v01;
	table bs_count;
 	title "frequency distribution of bs_count";
run;


* 1.7. format date;

data min.bs_user_all_v01;
	set min.bs_user_all_v01;
	bs_date = input(date, yymmdd8.);
	format bs_date yymmdd10.;
	drop date;
run;
proc contents data=min.bs_user_all_v01;
	title "min.bs_user_all_v01";
run;


* 1.8. frequency distribution of users by BS type and count;

proc freq data=min.bs_user_all_v01;
	table bs_type;
 	title "frequency distribution of bs_type";
run;

proc freq data=min.bs_user_all_v01;
	table bs_count;
 	title "frequency distribution of bs_count";
run;

/************************************************************************************
	STEP 2. BS users (initial use date) between 2015 - 2021    N = 46711
************************************************************************************/

* 2.1. select BS users between 2016 - 2021 ;

/**************************************************
* new table: min.bs_user_all_v02
* original table: min.bs_user_all_v01
* description: select BS users between 2015 - 2021
**************************************************/

data min.bs_user_all_v02;
	set min.bs_user_all_v01;
	where year(bs_date) >= 2015 and year(bs_date) <= 2021;
run;         /* 46711 obs */

* 2.2. frequency distribution of users by BS type and count;

proc freq data=min.bs_user_all_v02;
	table bs_type;
 	title "frequency distribution of bs_type";
run;

proc freq data=min.bs_user_all_v02;
	table bs_count;
 	title "frequency distribution of bs_count";
run;

/************************************************************************************
	STEP 3. Merge "BS users 2015 - 2021" + "demographic data"       N = 46,711
************************************************************************************/

* 3.0. see the demograph data;

proc print data=tx.patient (obs=40);
    title "tx.patient";
run;
proc contents data=tx.patient;
    title "tx.patient";
run;


proc print data=tx.patient_cohort (obs=40);
    title "tx.patient_cohort";
run;
proc contents data=tx.patient_cohort;
    title "tx.patient_cohort";
run;


proc print data=tx.genomic (obs=40);
    title "tx.genomic";
run;
proc contents data=tx.genomic;
    title "tx.genomic";
run;

* 3.1. Merge "BS users 2015 - 2021" + "demographic data";

/**************************************************
* new table: min.bs_user_all_v03
* original table: min.bs_user_all_v02 + tx.patient
* description: Merge "BS users 2016 - 2020" + "demographic data" 
**************************************************/     

proc sql;
  create table min.bs_user_all_v03 as
  select a.*, b.*
  from min.bs_user_all_v02 as a
  join tx.patient as b
  on a.patient_id = b.patient_id;
quit;

proc print data=min.bs_user_all_v03 (obs=40); 
  title "min.bs_user_all_v03"; 
run;
  

/************************************************************************************
	STEP 4. Age >= 18         N = 466
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v05
*             min.bs_user_all_v04
* original table: min.bs_user_all_v03
* description: "BS users 2016 - 2020" + age >= 18 
**************************************************/    

* 4.1. format date;

data min.bs_user_all_v04;
    set min.bs_user_all_v03;
	  year_of_birth_num = input(year_of_birth, $6.);
    format year_of_birth_num 6.;
    drop year_of_birth;
  rename year_of_birth_num = year_of_birth;
run;
proc contents data=min.bs_user_all_v04;
	title "min.bs_user_all_v04";
run;

* 4.2. to convert 'year_of_birth' to 'age', change the format of the 'year_of_birth';

data min.bs_user_all_v04;
  set min.bs_user_all_v04;
  age_at_bs = year(bs_date) - year_of_birth;
run;
proc print data=min.bs_user_all_v04 (obs = 30);
	title "min.bs_user_all_v04";
run;


* 4.3. select individuals aged more than 18 years;

data min.bs_user_all_v05;
  set min.bs_user_all_v04;
  if age_at_bs >=18;
run;      /* 46245 obs */

proc print data=min.bs_user_all_v05 (obs=30);
	title "in.bs_user_all_v05";
run;


/************************************************************************************
	STEP 5. Exclude individuals without sex      N = 1229
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v06
* original table: min.bs_user_all_v05
* description: Exclude individuals without sex 
**************************************************/
proc freq data = min.bs_user_all_v05;
	table sex;
run;                   /* nmiss in(sex) = 1229 */

data min.bs_user_all_v06;	
	set min.bs_user_all_v05;
	if not missing (sex);
run;                   /* 45016 obs */


/************************************************************************************
	STEP 6. Exclude individuals outside the US       N = 1020
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v07
* original table: min.bs_user_all_v06
* description: Exclude individuals without sex 
**************************************************/

* postal_code: Diamond network : patient_regional_location;

proc freq data = min.bs_user_all_v06;
	table patient_regional_location;
run;               /* Ex-US = 68, Unknown = 952 -> total = 1020 */ 

data min.bs_user_all_v07;	
	set min.bs_user_all_v06;
	if patient_regional_location in('Midwest', 'Northeast', 'South', 'West');
run;        /* 42535 -> 43996 obs */

* 6.1. frequency distribution of users by BS type and count;

proc freq data=min.bs_user_all_v07;
	table bs_type;
 	title "frequency distribution of bs_type";
run;

proc freq data=min.bs_user_all_v07;
	table bs_count;
 	title "frequency distribution of bs_count";
run;

/************************************************************************************
	STEP 7. Exclude individual with invalid information (death < bs_date)      N = 553
************************************************************************************/

/**************************************************
* new table: min.bs_user_all_v08
* original table: min.bs_user_all_v07
* description: Exclude individual with invalid information (death < bs_date) 
**************************************************/
* convert death-date;
data min.bs_user_all_v08;
  set min.bs_user_all_v07;
  death_year = input(substr(month_year_death, 1, 4), 4.);
  death_month = input(substr(month_year_death, 5, 2), 2.);
  death_date = mdy(death_month,15,death_year);
  format death_date yymmdd10.;
run;

* delete the "not missing(death_date) and death_date < bs_date" individual;
data min.bs_user_all_v08;
    set min.bs_user_all_v08;
    if not missing(death_date) and death_date < bs_date then delete;
run;       /* 43996 -> 43443 = 553 */

/************************************************************************************
	 min.bs_user_all_v08, N = 43,443
************************************************************************************/
proc print data=min.bs_user_all_v08 (obs=30);
title "min.bs_user_all_v08";
run;
