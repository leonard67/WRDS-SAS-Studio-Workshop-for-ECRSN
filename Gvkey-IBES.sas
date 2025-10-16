%ICLINK;

/*
Link IBES ticker to Compustat GVKEY. The following code is adapted from WRDS sample code:
https://wrds-www.wharton.upenn.edu/pages/support/sample-programs/ibes/link-ibes-ticker-compustat-gvkey/
 */
proc sort data=crsp.ccmxpf_lnkhist out=lnk;
        where linktype in ("LU", "LC" , "LS");
        by gvkey linkdt;
run;

/*Creating GVKEY-TICKER link for CRSP firms, call it CIBESLNK*/
proc sql;
        create table lnk1 (drop=score where=(missing(ticker)=0)) as select *
                from lnk (keep=gvkey lpermno lpermco linkdt linkenddt linktype
                linkprim) as a left join iclink (keep=ticker permno score
                where=(score in (0,1,2))) as b on a.lpermno=b.permno;
quit;

proc sort data=lnk1;
        by gvkey ticker linkdt;
run;

data fdate ldate;
        set lnk1;
        by gvkey ticker;
        if first.ticker then output fdate;
        if last.ticker then output ldate;
run;

data temp;
        merge fdate (keep=gvkey ticker permno linktype linkprim linkdt
                rename=(linkdt=fdate)) ldate (keep=gvkey ticker permno linktype
                linkprim linkenddt rename=(linkenddt=ldate));
        by gvkey ticker;
run;

/*Check for duplicates*/
data dups nodups;
        set temp;
        by gvkey ticker;
        if first.gvkey=0 or last.gvkey=0 then output dups;
        if not (first.gvkey=0 or last.gvkey=0) then output nodups;
run;

proc sort data=dups;
        by gvkey fdate ldate ticker;
run;

data dups (where=(flag ne 1));
        set dups;
        by gvkey;
        if first.gvkey=0 and (fdate<=lag(ldate) or lag(ldate)=.E) then flag=1;
run;

/*CIBESLNK contains gvkey-ticker links over non-overlapping time periods*/
data cibeslnk;
        set nodups dups (drop=flag);
run;

proc sql;
        drop table temp, nodups, dups, fdate, ldate, lnk, lnk1;
quit;
