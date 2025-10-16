/********************************************************************************/
/**************Example Code for ECRSN.com Workshop*******************************/
/****************by Leonard Li (UNSW Sydney)*************************************/

/********************************************************************************/
proc sql;

	create table mf1 as select ticker, anndats format=DATE9., intnx('month',
		mdy(prd_mon, 1, prd_yr),0,'e') as MF_datadate format=DATE9., pdicity,
		case when (not missing(val_2)) then (val_1 + val_2) / 2 when
		missing(val_2) then val_1 end as MF, mean_at_date as Consensus from
		IBES.DET_GUIDANCE where year(anndats) between 2001 and 2019 and usfirm=1
		and pdicity in ('ANN', 'QTR') and anndats <= CALCULATED MF_datadate and
		not missing(val_1) and measure="EPS" order by ticker, anndats, measure,
		MF_datadate, pdicity;

	create table Act1 as select distinct ticker, intnx('month', pends, 0,'e') as
		datadate format=DATE9., pdicity, value as Actual
		label="Actual value from IBES" from IBES.ACT_EPSUS where year(pends) >=
		2001 and usfirm=1 and not missing (value) and pdicity in ('ANN', 'QTR')
		and measure="EPS" order by ticker, datadate, measure, pdicity;

	/* Merge Actual Values */
	create table mf2 as select a.*, b.Actual from mf1 a left join Act1 b on
		a.ticker=b.ticker and a.pdicity=b.pdicity and a.MF_datadate=b.datadate;

	/* Drop dulicate MFs */
	create table mf3 as select *, missing(Consensus) as mark, abs(MF - Actual)
		as Error from mf2 order by ticker, anndats, MF_datadate, pdicity, mark,
		Error;

	create table MF_Raw (drop=mark Error) as select distinct monotonic() as N, *
		from mf3 group by ticker, anndats, MF_datadate, pdicity having N=min(N)
		order by N;

	drop table mf1, mf2, mf3, Act, Act1;

quit;
