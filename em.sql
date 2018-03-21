/*
This script emulates the EM performance chart
Created by Eduardo Claro, 2018-03-14
Last changes on 2018-03-20

WARNING: It uses ASH repository, so YOU NEED Diagnostics Pack

It can be used to display the Wait Class or the 5 main events of a specific Wait Class

Parameters (can be passed in any order in the form parameter=value)

	class    : specify the Wait Class (just the 3 first letters are enough) to show their events breakdown. If not specified, show the Wait Classes breakdown.
	begin    : begin date as a DATE expression, like sysdate-1/24.
	end      : end   date as a DATE expression, like sysdate-1/24.
	minutes  : if a positive number is provided, the period is defined starting with &BEGIN and ending the number of minutes after that (&END parameter is ignored).
	           if a negative number is provided, the period is defined starting the number of minutes before now (sysdate) and ending now (&BEGIN and &END are ignored).
	view     : the ASH view to query. Enter D to query DBA_ACTIVE_SESS_HISTORY. Any other value will use GV$ACTIVE_SESSION_HISTORY.
	group    : group (Y) or not (N) the rows by minute.
	color    : define if you want to see characters instead of colors (no), 8 colors (8) or 256 colors (256).
	show     : SHOW (Y) or not (N) the number of sessions for each Wait Class or Event.
	mult     : the multiplier to define how many boxes will be painted for each Average Active Session. If mult=2 and there are 3 sessions, 6 (3 * 2) boxes will be painted.
	zeros    : show (Y) or not (N) the samples that have no active session (especially useful when showing just one Wait Class
	inst     : specify an Instance to show (for RAC environments). NULL show all instances.

Example:

	@em
	@em class=app view=D
	@em group=N
	@em begin=sysdate-3/24 show=n

Attention:
	If the script seems to hang waiting for something, it is probably due to the SQL*Plus number variables (&1-&16) not be defined
	The SQL*Plus variables &1-&16 must be defined BEFORE running this script
	It is usually done by putting some statements in the login.sql, like this:
		set termout off
		COLUMN  1  NEW_VALUE  1    noprint
		COLUMN  2  NEW_VALUE  2    noprint
		COLUMN  3  NEW_VALUE  3    noprint
		...
		SELECT '' as "1",'' as "2",'' as "3" ... FROM dual;
		set termout on
*/

-- Default values for the parameters
define CLASS=""
define BEGIN="sysdate-1/24"
define END="sysdate"
define MINUTES=""
define VIEW=""
define GROUP=Y
define COLOR=256
define SHOW=N
define MULT=1
define ZEROS=Y
define INST=""

-- Parse the received parameters
@@parser

clear breaks
set echo off timing off ver off feed off

define RESET =[0m
alter session set nls_Date_format="dd-MON hh24:mi:ss";
set pages 500

set term off

col MULT new_value MULT
col xVIEW new_value VIEW
col xEND new_value END
col xBEGIN new_value BEGIN
col QUERY new_value QUERY
col INSTCOL new_value INSTCOL
col SCRIPT new_value SCRIPT
select
--	case when upper('&GROUP') = 'Y' then &MULT else 1 end MULT,
	case when upper('&VIEW') = 'D' then 'DBA_HIST_ACTIVE_SESS_HISTORY' else 'GV$ACTIVE_SESSION_HISTORY' end xVIEW,
	case when upper('&VIEW') = 'D' then 'INSTANCE_NUMBER' else 'INST_ID' end INSTCOL,
	case when to_number('&MINUTES') < 0 then q'[trunc(sysdate,'mi')+(&MINUTES./24/60)]' else q'[&BEGIN]' end xBEGIN,
	case when '&MINUTES' is null then q'[&END]' when to_number('&MINUTES') < 0 then 'sysdate' else q'[&BEGIN.+&MINUTES./24/60]' end xEND,
	case when '&CLASS' IS NULL then 'ash_class_final' else 'ash_event_final' end || case when upper('&SHOW') = 'N' then '2' end QUERY,
	case when '&COLOR' in ('8','256') then 'em_&COLOR.colors' else 'em_nocolors' end SCRIPT
from dual;

-- Set the colors
@@&SCRIPT

col MINUTE head "TIME"
col chart for a400 trunc
col ONCPU  for 99.9 head "OnCPU"
col USERIO for 99.9 head "UsrIO"
col SYSTIO for 99.9 head "SysIO"
col CONC   for 99.9 head "Conc"
col APPLIC for 99.9 head "Appl"
col COMM   for 99.9 head "Comm"
col CONF   for 99.9 head "Conf"
col ADMIN  for 99.9 head "Admin"
col SCHED  for 99.9 head "Sched"
col CLUST  for 99.9 head "Clust"
col QUEUE  for 99.9 head "Queue"
col NETW   for 99.9 head "Netwk"
col OTHER  for 99.9 head "Other"
col TOTAL  for 99.9 head "TOTAL"
col EV1  for 99.9 
col EV2  for 99.9 
col EV3  for 99.9 
col EV4  for 99.9 
col EV5  for 99.9 

-- Using DELETE instead of TRUNCATE just for not to end a transaction in course
delete from plan_table where STATEMENT_ID = 'EM-SQLPLUS'
;
insert into plan_table (STATEMENT_ID, TIMESTAMP, REMARKS)
select
	'EM-SQLPLUS',
	cast(sample_time as date) sample_time, --remove sub-seconds difference of the RAC instances
	'ALL SAMPLES' wait_class
from &VIEW
where sample_time between &begin and &end
and ('&INST' is null OR &INSTCOL = nvl('&INST','&INSTCOL'))
;
insert into plan_table (STATEMENT_ID, TIMESTAMP, REMARKS, COST)
select
	'EM-SQLPLUS',
	cast(sample_time as date) sample_time, --remove sub-seconds difference of the RAC instances
	nvl(wait_class,'On CPU') wait_class, count(*) sessions
from &VIEW
where '&class' IS NULL and sample_time between &begin and &end 
and ('&INST' is null OR &INSTCOL = nvl('&INST','&INSTCOL'))
group by cast(sample_time as date), wait_class
;
insert into plan_table (STATEMENT_ID, TIMESTAMP, REMARKS, PLAN_ID, COST)
select
	'EM-SQLPLUS',
	cast(sample_time as date) sample_time, --remove sub-seconds difference of the RAC instances
	event, event_id, count(*) sessions
from &VIEW
where '&class' IS NOT NULL and sample_time between &begin and &end 
	and wait_class = (select wait_class from v$event_name where upper(wait_class) like upper('&class%') and rownum = 1)
and ('&INST' is null OR &INSTCOL = nvl('&INST','&INSTCOL'))
group by cast(sample_time as date), event, event_id
;
set term on

WITH
ash_allsamples AS (
	select distinct
		TIMESTAMP sample_time
	from plan_table
	where STATEMENT_ID = 'EM-SQLPLUS' and REMARKS = 'ALL SAMPLES'
),
ash_class AS (
	select * from (
		select TIMESTAMP sample_time, REMARKS wait_class, COST sessions,
			count(distinct TIMESTAMP) over (partition by trunc(TIMESTAMP,'MI')) SAMPLES_PER_MIN
		from plan_table
		where STATEMENT_ID = 'EM-SQLPLUS'
	) where wait_class <> 'ALL SAMPLES'
),
ash_event AS (
	select * from (
		select TIMESTAMP sample_time, REMARKS event, PLAN_ID event_id, COST sessions,
			count(distinct TIMESTAMP) over (partition by trunc(TIMESTAMP,'MI')) SAMPLES_PER_MIN
		from plan_table
		where STATEMENT_ID = 'EM-SQLPLUS'
	) where event <> 'ALL SAMPLES'
),
ash_mainevents AS (
	select 
		event, position
	from (
		select 
			event,
			rank() over (order by sum(sessions) desc, event_id) position
		from ash_event
		group by event, event_id
		order by sum(sessions) desc
	)
	where position <= 5
),
ash_class_minute AS (
	select 
		case when upper('&GROUP') = 'Y' then trunc(sample_time,'MI') else sample_time end minute,
		case when wait_class in ('On CPU','User I/O','System I/O','Concurrency','Application','Commit','Configuration',
			'Administrative','Scheduler','Cluster','Queueing','Network','Other') then wait_class else 'Other' end wait_class,
		case when upper('&GROUP') = 'Y' then sum(sessions)/SAMPLES_PER_MIN else sum(sessions) end avg_sessions
	from ash_allsamples left join ash_class using (sample_time)
	group by SAMPLES_PER_MIN,
		case when upper('&GROUP') = 'Y' then trunc(sample_time,'MI') else sample_time end,
		case when wait_class in ('On CPU','User I/O','System I/O','Concurrency','Application','Commit','Configuration',
			'Administrative','Scheduler','Cluster','Queueing','Network','Other') then wait_class else 'Other' end	
), 
ash_event_minute AS (
	select 
		case when upper('&GROUP') = 'Y' then trunc(sample_time,'MI') else sample_time end minute, 
		to_char(nvl(position,0)) position,
		case when upper('&GROUP') = 'Y' then sum(sessions)/SAMPLES_PER_MIN else sum(sessions) end avg_sessions
	from ash_allsamples left join ash_event e using (sample_time) left join ash_mainevents m on e.event = m.event 
	group by SAMPLES_PER_MIN,
		case when upper('&GROUP') = 'Y' then trunc(sample_time,'MI') else sample_time end, position
), 
ash_class_pivot AS (
	select minute, nvl(ONCPU,0) ONCPU, nvl(USERIO,0) USERIO, nvl(SYSTIO,0) SYSTIO, nvl(APPLIC,0) APPLIC, 
		nvl(CONC,0) CONC, nvl(CONF,0) CONF, nvl(COMM,0) COMM, nvl(ADMIN,0) ADMIN, nvl(SCHED,0) SCHED, 
		nvl(CLUST,0) CLUST, nvl(QUEUE,0) QUEUE, nvl(NETW,0) NETW, nvl(OTHER,0) OTHER
	from (
		select *
		from ash_class_minute
		pivot
			(sum(avg_sessions) for wait_class in (
				 'On CPU' as ONCPU
				,'User I/O' as USERIO
				,'System I/O' as SYSTIO
				,'Application' as APPLIC
				,'Concurrency' as CONC
				,'Configuration' as CONF
				,'Commit' as COMM
				,'Administrative' as ADMIN
				,'Scheduler' as SCHED
				,'Cluster' as CLUST
				,'Queueing' as QUEUE
				,'Network' as NETW
				,'Other' as OTHER)))
),
ash_event_pivot AS (
	select minute, nvl(EV1,0) EV1, nvl(EV2,0) EV2, nvl(EV3,0) EV3, nvl(EV4,0) EV4, nvl(EV5,0) EV5, nvl(OTHER,0) OTHER
	from (
		select *
		from ash_event_minute
		pivot
			(sum(avg_sessions) for position in (
				 '1' as EV1
				,'2' as EV2
				,'3' as EV3
				,'4' as EV4
				,'5' as EV5
				,'0' as OTHER)))
),
ash_class_final AS (
	select ash_class_pivot.*, 
		ONCPU + USERIO + SYSTIO + APPLIC + CONC + CONF + COMM + ADMIN + SCHED + CLUST + QUEUE + NETW + Other as TOTAL, 
		'&RESET' ||
			'&BG_ONCPU' || lpad('&CH_ONCPU', round(ONCPU  * &MULT) , '&CH_ONCPU') || 
			'&BG_USER'  || lpad('&CH_USER' , round(USERIO * &MULT) , '&CH_USER' ) || 
			'&BG_SYST'  || lpad('&CH_SYST' , round(SYSTIO * &MULT) , '&CH_SYST' ) || 
			'&BG_CONC'  || lpad('&CH_CONC' , round(CONC   * &MULT) , '&CH_CONC' ) || 
			'&BG_APPL'  || lpad('&CH_APPL' , round(APPLIC * &MULT) , '&CH_APPL' ) || 
			'&BG_CONF'  || lpad('&CH_CONF' , round(CONF   * &MULT) , '&CH_CONF' ) || 
			'&BG_COMM'  || lpad('&CH_COMM' , round(COMM   * &MULT) , '&CH_COMM' ) || 
			'&BG_ADMI'  || lpad('&CH_ADMI' , round(ADMIN  * &MULT) , '&CH_ADMI' ) || 
			'&BG_SCHE'  || lpad('&CH_SCHE' , round(SCHED  * &MULT) , '&CH_SCHE' ) || 
			'&BG_CLUS'  || lpad('&CH_CLUS' , round(CLUST  * &MULT) , '&CH_CLUS' ) || 
			'&BG_QUEU'  || lpad('&CH_QUEU' , round(QUEUE  * &MULT) , '&CH_QUEU' ) || 
			'&BG_NETW'  || lpad('&CH_NETW' , round(NETW   * &MULT) , '&CH_NETW' ) || 
			'&BG_OTHE'  || lpad('&CH_OTHE' , round(Other  * &MULT) , '&CH_OTHE' ) || 
		'&RESET' chart
	from ash_class_pivot
	order by minute
),
ash_class_final2 AS (
	select minute, total, chart from ash_class_final
),
ash_event_final AS (
	select ash_event_pivot.*, 
		EV1 + EV2 + EV3 + EV4 + EV5 + Other as TOTAL,
		'&RESET' ||
			'&BG_USER'  || lpad('&CH_EV1' ,  round(EV1   * &MULT) , '&CH_EV1' ) || 
			'&BG_SYST'  || lpad('&CH_EV2' ,  round(EV2   * &MULT) , '&CH_EV2' ) || 
			'&BG_CONC'  || lpad('&CH_EV3' ,  round(EV3   * &MULT) , '&CH_EV3' ) || 
			'&BG_APPL'  || lpad('&CH_EV4' ,  round(EV4   * &MULT) , '&CH_EV4' ) || 
			'&BG_CONF'  || lpad('&CH_EV5' ,  round(EV5   * &MULT) , '&CH_EV5' ) || 
			'&BG_OTHE'  || lpad('&CH_OTHE' , round(OTHER * &MULT) , '&CH_OTHE' ) || 
		'&RESET' chart
	from ash_event_pivot
	order by minute
),
ash_event_final2 AS (
	select minute, total, chart from ash_event_final
)
select * from &QUERY
where (upper('&ZEROS') = 'Y' OR round(total,1) > 0)
/

col CHART for a30
col xGROUP head "WAIT CLASS" for a20 trunc
SELECT * FROM (
	select 'On CPU'         xGROUP, '&BG_ONCPU' || lpad('&CH_ONCPU', 5 , '&CH_ONCPU') || '&RESET' chart from dual UNION ALL
	select 'User I/O'       xGROUP, '&BG_USER'  || lpad('&CH_USER' , 5 , '&CH_USER' ) || '&RESET' chart from dual UNION ALL
	select 'System I/O'     xGROUP, '&BG_SYST'  || lpad('&CH_SYST' , 5 , '&CH_SYST' ) || '&RESET' chart from dual UNION ALL
	select 'Application'    xGROUP, '&BG_APPL'  || lpad('&CH_APPL' , 5 , '&CH_APPL' ) || '&RESET' chart from dual UNION ALL
	select 'Concurrency'    xGROUP, '&BG_CONC'  || lpad('&CH_CONC' , 5 , '&CH_CONC' ) || '&RESET' chart from dual UNION ALL
	select 'Configuration'  xGROUP, '&BG_CONF'  || lpad('&CH_CONF' , 5 , '&CH_CONF' ) || '&RESET' chart from dual UNION ALL
	select 'Commit'         xGROUP, '&BG_COMM'  || lpad('&CH_COMM' , 5 , '&CH_COMM' ) || '&RESET' chart from dual UNION ALL
	select 'Administrative' xGROUP, '&BG_ADMI'  || lpad('&CH_ADMI' , 5 , '&CH_ADMI' ) || '&RESET' chart from dual UNION ALL
	select 'Scheduler'      xGROUP, '&BG_SCHE'  || lpad('&CH_SCHE' , 5 , '&CH_SCHE' ) || '&RESET' chart from dual UNION ALL
	select 'Cluster'        xGROUP, '&BG_CLUS'  || lpad('&CH_CLUS' , 5 , '&CH_CLUS' ) || '&RESET' chart from dual UNION ALL
	select 'Queueing'       xGROUP, '&BG_QUEU'  || lpad('&CH_QUEU' , 5 , '&CH_QUEU' ) || '&RESET' chart from dual UNION ALL
	select 'Network'        xGROUP, '&BG_NETW'  || lpad('&CH_NETW' , 5 , '&CH_NETW' ) || '&RESET' chart from dual UNION ALL
	select 'Other'          xGROUP, '&BG_OTHE'  || lpad('&CH_OTHE' , 5 , '&CH_OTHE' ) || '&RESET' chart from dual 
) WHERE '&class' IS NULL
;
col xGROUP head "EVENT" for a64 trunc
WITH events AS (
	select 
		event, position
	from (
		select 
			REMARKS event,
			rank() over (order by SUM(COST) desc, PLAN_ID) position
		from plan_table
		where STATEMENT_ID = 'EM-SQLPLUS' and REMARKS <> 'ALL SAMPLES'
		group by REMARKS, PLAN_ID
		order by SUM(COST) desc
	)
	where position <= 5
)
select * from (
	select event   xGROUP, '&BG_USER'  || lpad('&CH_EV1' , 5 , '&CH_EV1' ) || '&RESET' chart from events WHERE position = 1 UNION ALL
	select event   xGROUP, '&BG_SYST'  || lpad('&CH_EV2' , 5 , '&CH_EV2' ) || '&RESET' chart from events WHERE position = 2 UNION ALL
	select event   xGROUP, '&BG_APPL'  || lpad('&CH_EV3' , 5 , '&CH_EV3' ) || '&RESET' chart from events WHERE position = 3 UNION ALL
	select event   xGROUP, '&BG_CONC'  || lpad('&CH_EV4' , 5 , '&CH_EV4' ) || '&RESET' chart from events WHERE position = 4 UNION ALL
	select event   xGROUP, '&BG_CONF'  || lpad('&CH_EV5' , 5 , '&CH_EV5' ) || '&RESET' chart from events WHERE position = 5 UNION ALL
	select 'Other' xGROUP, '&BG_OTHE'  || lpad('&CH_OTHE' , 5 , '&CH_OTHE' ) || '&RESET' chart from dual 
) WHERE '&class' IS NOT NULL
;

define 1=""
define 2=""
define 3=""
define 4=""
define 5=""
define 6=""
define 7=""
define 8=""
define 9=""
define 10=""
define 11=""
define 12=""
define 13=""
define 14=""
define 15=""
define 16=""
