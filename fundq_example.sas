/*********************************************************************************/
/**************Example Code for ECRSN.com Workshop *******************************/
/****************BY Leonard Li (UNSW Sydney)**************************************/

/*********************************************************************************/
proc sql;
	CREATE TABLE link AS SELECT * FROM crsp.ccmxpf_lnkhist WHERE linktype IN
		("LU", "LC", "LS") AND NOT MISSING(lpermno) AND NOT MISSING(gvkey) ORDER
		BY gvkey, linkdt;

	CREATE TABLE Comp1 AS SELECT gvkey, fyearq AS fyear, fqtr, cusip,
		intnx('month', datadate,0,'e') AS datadate format=DATE9., intnx('month',
		datadate,3,'e') AS fdate format=DATE9., rdq format=DATE9., atq, ceqq,
		saleq, prccq, prccq*cshoq AS MV, log(atq) AS Size label="Log at",
		prccq*cshoq / ceqq AS MB label="prcc*csho / ceq", sum(MISSING(CALCULATED
		MV), MISSING(CALCULATED MB),MISSING(ceqq)) AS mis FROM comp.fundq WHERE
		year(datadate) BETWEEN 2000 AND 2020 AND datafmt="STD" AND consol="C"
		AND popsrc="D" AND NOT MISSING(atq) AND atq > 0 AND NOT MISSING(fqtr);

	CREATE TABLE Comp2 AS SELECT a.*, b.lpermno AS permno, CASE b.linkprim WHEN
		'P' THEN 1 WHEN 'C' THEN 2 WHEN 'J' THEN 3 WHEN 'N' THEN 4 END AS mark1,
		CASE b.linktype WHEN "LU" THEN 1 WHEN "LC" THEN 2 WHEN "LS" THEN 3 END
		AS mark2 FROM Comp1 a, link b WHERE a.gvkey=b.gvkey AND (b.linkdt <=
		a.datadate OR b.linkdt=.B) AND (a.datadate <= b.linkenddt OR
		b.linkenddt=.E) ORDER BY a.gvkey, fyear, fqtr, mis, mark1, mark2,
		permno, datadate DESC;

	CREATE TABLE Comp3 (drop=N) AS SELECT distinct*, monotonic() AS N FROM Comp2
		GROUP BY gvkey, fyear, fqtr HAVING N=min(N);

	CREATE TABLE Comp4 AS SELECT * FROM Comp3 ORDER BY gvkey, datadate, mis,
		mark1, mark2, permno, fyear DESC, fqtr DESC;

	CREATE TABLE Comp5 (drop=mis mark1 mark2) AS SELECT distinct monotonic() AS
		N, * FROM Comp4 GROUP BY gvkey, datadate HAVING N=min(N);

	/*Merge IBES TICKER********************************************************************************************************************************/
	CREATE TABLE Comp6 AS SELECT a.gvkey, b.ticker AS ticker, a.*, b.fdate AS
		begdate format=DATE9., b.ldate AS enddate format=DATE9. FROM Comp5 a
		LEFT JOIN cibeslnk b on a.gvkey=b.gvkey AND a.permno=b.permno AND
		(b.fdate <= a.datadate or b.fdate=.B) AND (a.datadate <= b.ldate or
		b.ldate=.E) ORDER BY N, MISSING(ticker), enddate DESC, begdate DESC;

	CREATE TABLE Comp7 (drop=begdate enddate N1) AS SELECT distinct *,
		monotonic() AS N1 FROM Comp6 (WHERE=(NOT MISSING(ticker))) GROUP BY N
		HAVING N1=min(N1);

	/**Merge EA Date*******************************************************************************************************************************/
	CREATE TABLE Comp8 AS SELECT a.*, b.anndats AS IBES_EA format=DATE9.,
		b.value AS IBES_EPS, b.actdats, CASE WHEN b.anndats < a.rdq+14 THEN
		abs(b.anndats - a.rdq) else 99 end AS mark1, CASE WHEN (b.pdicity="ANN"
		AND fqtr=4) or (b.pdicity="QTR" AND fqtr ne 4) THEN 1 else 2 end AS
		mark2 FROM Comp7 AS a LEFT JOIN ibes.act_epsus (WHERE=(NOT
		MISSING(value))) AS b on a.ticker=b.ticker AND a.datadate=b.pends AND
		b.anndats < a.fdate ORDER BY N, mark1, mark2, MISSING(IBES_EPS), actdats
		DESC;

	CREATE TABLE Comp9 (drop=rdq N N1 actdats IBES_EA IBES_EPS mark1 mark2) AS
		SELECT distinct *, CASE WHEN NOT MISSING(IBES_EA) THEN IBES_EA WHEN
		MISSING(IBES_EA) AND NOT MISSING(rdq) AND rdq < fdate THEN rdq end AS
		EA_date format=DATE9., moNOTonic() AS N1 FROM Comp8 GROUP BY N HAVING N1
		=min(N1);

	CREATE TABLE Comp10 AS SELECT a.*, b.EA_date AS F_EA_date FROM Comp9 AS a LEFT
		JOIN Comp9 b ON a.gvkey=b.gvkey AND intck('month',a.datadate,b.datadate)
		=3;

	CREATE TABLE Comp_Quarter AS SELECT a.gvkey, a.permno, a.ticker, a.cusip,
		a.fyear, a.fqtr, a.datadate, a.EA_date, a.F_EA_date, a.fdate, a.*,
		input(b.sic, best.) AS sicc, input(b.cik, best.) AS CIK_Comp, b.state AS
		State_Comp FROM Comp10 a LEFT JOIN comp.company b ON a.gvkey=b.gvkey;

	DROP TABLE Comp1, Comp2, Comp3, Comp4, Comp5, Comp6, Comp7, Comp8, Comp9,
		Comp10, iclink, link;

quit;
