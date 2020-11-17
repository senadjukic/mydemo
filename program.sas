***********************************************************
*** Initialization
***********************************************************;
%let SAS_Version= Viya3.5;
%let n=5000;

***********************************************************
***  Helper Macros
***********************************************************;
%macro Start;
proc sql noprint;
select time() into :start from _dual_;
quit;
%mend;
%macro Ende;
proc sql noprint;
select time() into :end from _dual_;
quit;
%mend;
%macro InsertLog(pos,text);
proc sql;
  insert into work._Log_
  values (&pos,&n,&text,&start,&end,.);
quit;
%mend;
%macro LogMessage(message) ;
	%put  ;
	%put NOTE: -----------------------------------------------------------;
	%put NOTE:   &message ;
	%put NOTE: -----------------------------------------------------------;
%mend ;

***********************************************************
***  Performancetest Macro
***********************************************************;
%macro PerformanceTest(n);
title "SAS Performance Test with n=&n";
title2 "Executed on %SYSFUNC(DATE(), Date9.) at %SYSFUNC(TIME(), TIME8.)";
title3 "SAS-Version=&SAS_Version";

options source source2 mprint linesize = 100
        orientation = landscape;

%global start end;
%LogMessage(Start Performance Test with n=&n);

data _dual_;
 x=1;
run;

data _time_;
 format Pos 8.
        Start time8.;
		;
run;

data _log_;
 format Pos 8.
        N 8.
		Task $30.
		Start time8.
		End Time8.
		Duration  16.3;
run;

%LogMessage(Create Dataset P1);

%Start;

data work.p1;
 format a b c d 8. e $8.;
 do a = 1 to &n;
 b=uniform(1);
 c=uniform(2);
 d=ranuni(3);
 if uniform(4) > 0.5 then e='AAAAAAAA';
 else if uniform(5) > 0.5 then e='BBBBBBBB';
 else e = 'CCCCCCCC';
 output;
 end;
 run;

%Ende;
%InsertLog(1,'Creation of Dataset P1');

%LogMessage(Create Dataset P2);
%Start;

data p2;
 set p1(rename = (b=b2 c=c2 d=d2 e=e2));
 run;
%Ende;
%InsertLog(2,'Duplication to Dataset P2');

%LogMessage(Merge Datasets P1+P2=P3);
%Start;

proc sql;
 create table p3_sql
 as select * 
    from p1,p2
	where p1.a = p2.a;
quit;

%Ende;
%InsertLog(3,'SQL-Merge Datasets P1+P2=P3');

%LogMessage(Merge Datasets P1+P2=P3);
%Start;

data p3;
 merge p1 p2;
 by a;
run;

%Ende;
%InsertLog(4,'Merge Datasets P1+P2=P3');

%LogMessage(Sort Dataset P1);
%Start;

 proc sort data  =P1 out =p1_sort;
  by b;
  run;
%Ende;
%InsertLog(5,'Sort Dataset P1');

%LogMessage(Sort Dataset P3);
%Start;
 proc sort data = p3 out = p3_sort;
   by descending a b descending c d descending e;
 run;
%Ende;
%InsertLog(6,'Complex Sort Dataset P3');

%LogMessage(Correlation (Spearman));
%Start;

proc corr spearman data = p3 noprint;
 var a b c d;
 run;
%Ende;
%InsertLog(7,'Correlation (Spearman)');

%LogMessage(Univariate Statistics);
%Start;

proc univariate data = p3(where = (uniform(10) lt 0.2)) normal plot noprint;
 var a b c d;
run;
%Ende;
%InsertLog(8,'Univariate Statistics (20%)');

%LogMessage(Delete Datasets);
%Start;

proc datasets lib=work;
 delete p1 p2 p3 p1_sort p3_sort p3_sql;
quit;
%Ende;
%InsertLog(9,'Delete Datasets');

%LogMessage(Ausgabe der Ergebnisse);

data _log_;
 set _log_;
 if pos ne .;
 format Cumulative 16.3;
 duration = end - start;
 cumulative + duration;
 label Duration = "Duration (sec)"
       Cumulative = "Cumulative Duration (sec)";
 run;

proc print data = _log_ noobs label;
run;

%LogMessage(Ende - Performance Test with n=&n);

title;title2;title3;
%mend;

***********************************************************
***  Execution;
***********************************************************;

%PerformanceTest(&n);

