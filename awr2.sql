/*
This script generates AWR Reports, it is called by awr.sql

Created by Eduardo Claro, 2021-04-01
Last changes on 2021-10-29
*/

prompt Generating report, please wait...

set term off
@inc/save_set.sql
col AWRSPOOL NEW_VALUE AWRSPOOL
col INS new_value INS
col INS2 new_value INS2
col FORMAT new_value FORMAT
col rac new_value rac
col DBID new_value DBID
col SUFFIX new_value SUFFIX
select
	case when upper('&rac') = 'Y' then 'Y' else 'N' end rac,
	case when upper('&fmt') = 'TEXT' then 'TEXT' else 'HTML' end FORMAT,
	case when upper('&fmt') = 'TEXT' then 'txt' else 'html' end SUFFIX
from dual;
select
	case when '&rac' = 'Y' then '&ins' else coalesce('&ins','1') end ins,
	coalesce('&ins2','&ins','1') ins2,
	to_char(dbid) dbid,
	'&tmp/' || 
		case when upper('&typ') in ('AWR','ASH','SQL') then upper('&typ') else 'AWR' end || 
		'_' || DB_UNIQUE_NAME || 
		case when '&rac' = 'Y' then '_RAC' end ||
		case when '&bs2' is not null then '_DIFF' end ||
		'_' || case when '&ins' is not null then '&ins._' end || '&bs.-&es.' || 
		case when upper('&typ') = 'SQL' then '_&sqlid' end ||
		case when '&bs2' is not null then '_vs_' || case when '&ins2' is not null then coalesce('&ins2','&ins') || '_' end || '&bs2.-&es2.' end || 
		'.&SUFFIX' as AWRSPOOL
from v$database;
def BTIME=""
def ETIME=""
col BTIME new_value BTIME
col ETIME new_value ETIME
select
	case 
		when '&bd' is not null then to_char(to_date('&bd','yyyy/mm/dd-hh24:mi'),'yyyy-mm-dd hh24:mi:ss')
		when '&bs' is not null then (select to_char(end_interval_time,'yyyy-mm-dd hh24:mi:ss') BTIME from dba_hist_snapshot where instance_number = '&ins' and snap_id=to_number('&bs'))
		else q'[&BTIME]' 
	end BTIME,
	case 
		when '&ed' is not null then to_char(to_date('&ed','yyyy/mm/dd-hh24:mi'),'yyyy-mm-dd hh24:mi:ss')
		when '&bs' is not null then (select to_char(end_interval_time,'yyyy-mm-dd hh24:mi:ss') ETIME from dba_hist_snapshot where instance_number = '&ins' and snap_id=to_number('&es'))
		else q'[&ETIME]'
	end ETIME
from dual;

SET HEAD OFF VER OFF FEED OFF TIMING OFF ECHO OFF
spool &awrspool

--Regular AWR report
select * from table(
	DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_&FORMAT(
	   l_dbid       =>    '&dbid',
	   l_inst_num   =>    '&ins',
	   l_bid        =>    '&bs',
	   l_eid        =>    '&es',
	   l_options    =>    '&opt'))
	where upper('&typ') = 'AWR' and '&rac' = 'N' and '&bs2' is NULL
UNION ALL
--Diff AWR report
select * from table(
	DBMS_WORKLOAD_REPOSITORY.AWR_DIFF_REPORT_&FORMAT(
		DBID1     => '&dbid',
		INST_NUM1 => '&ins',
		BID1      => '&bs',
		EID1      => '&es',
		DBID2     => '&dbid',
		INST_NUM2 => '&ins2',
		BID2      => '&bs2',
		EID2      => '&es2',
		P_OPTIONS => '&opt'))
	where upper('&typ') = 'AWR' and '&rac' = 'N' and '&bs2' is not NULL
UNION ALL
-- Global (RAC) AWR Report
select * from table(
	DBMS_WORKLOAD_REPOSITORY.AWR_GLOBAL_REPORT_&FORMAT(
	   l_dbid       =>    '&dbid',
	   l_inst_num   =>    '&ins',
	   l_bid        =>    '&bs',
	   l_eid        =>    '&es',
	   l_options    =>    '&opt'))
	where upper('&typ') = 'AWR' and '&rac' = 'Y' and '&bs2' is NULL
-- Global (RAC) Diff AWR Report
UNION ALL
select * from table(
	DBMS_WORKLOAD_REPOSITORY.AWR_GLOBAL_DIFF_REPORT_&FORMAT(
		DBID1     => '&dbid',
		INST_NUM1 => '&ins',
		BID1      => '&bs',
		EID1      => '&es',
		DBID2     => '&dbid',
		INST_NUM2 => '&ins2',
		BID2      => '&bs2',
		EID2      => '&es2',
		P_OPTIONS => '&opt'))
	where upper('&typ') = 'AWR' and '&rac' = 'Y' and '&bs2' is not NULL
UNION ALL
-- AWR SQL Report
select * from table(
	DBMS_WORKLOAD_REPOSITORY.AWR_SQL_REPORT_&FORMAT(
		L_DBID      => '&dbid',
		L_INST_NUM  => '&ins',
		L_BID       => '&bs',
		L_EID       => '&es',
		L_SQLID     => '&sqlid',
		L_OPTIONS   => '&opt',
		L_CON_DBID  => ''))
	where upper('&typ') = 'SQL'
UNION ALL
-- Regular ASH Report
select * from table(
	DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_&FORMAT(
	   l_dbid       =>    '&dbid',
	   l_inst_num   =>    '&ins',
	   l_btime      =>    to_date('&BTIME','yyyy-mm-dd hh24:mi:ss'),
	   l_etime      =>    to_date('&ETIME','yyyy-mm-dd hh24:mi:ss'),
	   l_options    =>    '&opt'))
	where upper('&typ') = 'ASH' and '&rac' = 'N'
UNION ALL
-- Global (RAC) ASH Report
select * from table(
	DBMS_WORKLOAD_REPOSITORY.ASH_GLOBAL_REPORT_&FORMAT(
	   l_dbid       =>    '&dbid',
	   l_inst_num   =>    '&ins',
	   l_btime      =>    to_date('&BTIME','yyyy-mm-dd hh24:mi:ss'),
	   l_etime      =>    to_date('&ETIME','yyyy-mm-dd hh24:mi:ss'),
	   l_options    =>    '&opt'))
	where upper('&typ') = 'ASH' and '&rac' = 'Y'
;

spool off

prompt Report generated on "&AWRSPOOL"

@inc/load_set.sql
set term on

prompt Report generated at &awrspool
