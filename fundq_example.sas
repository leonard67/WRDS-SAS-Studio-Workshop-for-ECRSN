/*********************************************************************************/
/**************Example Code for ECRSN.com Workshop *******************************/
/****************by Leonard Li (UNSW Sydney)**************************************/

/*********************************************************************************/
proc sql;
	create table link as select * from crsp.ccmxpf_lnkhist where linktype in
		("LU", "LC", "LS") and not missing(lpermno) and not missing(gvkey) order
		by gvkey, linkdt;

	create table Comp1 as select gvkey, fyearq as fyear, fqtr, cusip,
		intnx('month', datadate,0,'e') as datadate format=DATE9., intnx('month',
		datadate,3,'e') as fdate format=DATE9., rdq format=DATE9., atq, ceqq,
		saleq, prccq, prccq*cshoq as MV, log(atq) as Size label="Log at",
		prccq*cshoq / ceqq as MB label="prcc*csho / ceq", sum(missing(CALCULATED
		MV), missing(CALCULATED MB),missing(ceqq)) as mis from comp.fundq where
		year(datadate) between 2000 and 2020 and datafmt="STD" and consol="C"
		and popsrc="D" and not missing(atq) and atq > 0 and not missing(fqtr);

	create table Comp2 as select a.*, b.lpermno as permno, case b.linkprim when
		'P' then 1 when 'C' then 2 when 'J' then 3 when 'N' then 4 end as mark1,
		case b.linktype when "LU" then 1 when "LC" then 2 when "LS" then 3 end
		as mark2 from Comp1 a, link b where a.gvkey=b.gvkey and (b.linkdt <=
		a.datadate or b.linkdt=.B) and (a.datadate <= b.linkenddt or
		b.linkenddt=.E) order by a.gvkey, fyear, fqtr, mis, mark1, mark2,
		permno, datadate desc;

	create table Comp3 (drop=N) as select distinct*, monotonic() as N from Comp2
		group by gvkey, fyear, fqtr having N=min(N);

	create table Comp4 as select * from Comp3 order by gvkey, datadate, mis,
		mark1, mark2, permno, fyear desc, fqtr desc;

	create table Comp5 (drop=mis mark1 mark2) as select distinct monotonic() as
		N, * from Comp4 group by gvkey, datadate having N=min(N);

	/*Merge IBES TICKER********************************************************************************************************************************/
	create table Comp6 as select a.gvkey, b.ticker as ticker, a.*, b.fdate as
		begdate format=DATE9., b.ldate as enddate format=DATE9. from Comp5 a
		left join cibeslnk b on a.gvkey=b.gvkey and a.permno=b.permno and
		(b.fdate <= a.datadate or b.fdate=.B) and (a.datadate <= b.ldate or
		b.ldate=.E) order by N, missing(ticker), enddate desc, begdate desc;

	create table Comp7 (drop=begdate enddate N1) as select distinct *,
		monotonic() as N1 from Comp6 (where=(not missing(ticker))) group by N
		having N1=min(N1);

	/**Merge EA Date*******************************************************************************************************************************/
	create table Comp8 as select a.*, b.anndats as IBES_EA format=DATE9.,
		b.value as IBES_EPS, b.actdats, case when b.anndats < a.rdq+14 then
		abs(b.anndats - a.rdq) else 99 end as mark1, case when (b.pdicity="ANN"
		and fqtr=4) or (b.pdicity="QTR" and fqtr ne 4) then 1 else 2 end as
		mark2 from Comp7 as a left join ibes.act_epsus (where=(not
		missing(value))) as b on a.ticker=b.ticker and a.datadate=b.pends and
		b.anndats < a.fdate order by N, mark1, mark2, missing(IBES_EPS), actdats
		desc;

	create table Comp9 (drop=rdq N N1 actdats IBES_EA IBES_EPS mark1 mark2) as
		select distinct *, case when not missing(IBES_EA) then IBES_EA when
		missing(IBES_EA) and not missing(rdq) and rdq < fdate then rdq end as
		EA_date format=DATE9., monotonic() as N1 from Comp8 group by N having N1
		=min(N1);

	create table Comp10 as select a.*, b.EA_date as F_EA_date from Comp9 a left
		join Comp9 b on a.gvkey=b.gvkey and intck('month',a.datadate,b.datadate)
		=3;

	create table Comp_Quarter as select a.gvkey, a.permno, a.ticker, a.cusip,
		a.fyear, a.fqtr, a.datadate, a.EA_date, a.F_EA_date, a.fdate, a.*,
		input(b.sic, best.) as sicc, input(b.cik, best.) as CIK_Comp, b.state as
		State_Comp from Comp10 a left join comp.company b on a.gvkey=b.gvkey;

	drop table Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9,
		Comp10, iclink, link;

quit;
