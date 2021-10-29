/*
This script shows AWR Snapshots
It shows the MINIMUM SNAP_ID per hour
With the default AWR interval of 1h, it should show all Snapshots
If the AWR interval is different from 1h OR there are manual snapshots, then only the minimum SNAP_ID per hour will be displayed

Created by Eduardo Claro, 2021-04-07
Last changes on 2021-10-28
*/

@@awrcontrol

prompt ===================
prompt AWR Snapshots
prompt ===================
prompt
prompt The SNAP_ID displayed is the MIN of the hour. An '*' besides the SNAP_ID means there was a STARTUP at that period.

col SNAP_00 for a6 just right head "00H "
col SNAP_01 for a6 just right head "01H "
col SNAP_02 for a6 just right head "02H "
col SNAP_03 for a6 just right head "03H "
col SNAP_04 for a6 just right head "04H "
col SNAP_05 for a6 just right head "05H "
col SNAP_06 for a6 just right head "06H "
col SNAP_07 for a6 just right head "07H "
col SNAP_08 for a6 just right head "08H "
col SNAP_09 for a6 just right head "09H "
col SNAP_10 for a6 just right head "10H "
col SNAP_11 for a6 just right head "11H "
col SNAP_12 for a6 just right head "12H "
col SNAP_13 for a6 just right head "13H "
col SNAP_14 for a6 just right head "14H "
col SNAP_15 for a6 just right head "15H "
col SNAP_16 for a6 just right head "16H "
col SNAP_17 for a6 just right head "17H "
col SNAP_18 for a6 just right head "18H "
col SNAP_19 for a6 just right head "19H "
col SNAP_20 for a6 just right head "20H "
col SNAP_21 for a6 just right head "21H "
col SNAP_22 for a6 just right head "22H "
col SNAP_23 for a6 just right head "23H "
col dt head "DATE"
col DATE for a10
col INST for 9999
WITH x as (
SELECT 
	trunc(end_interval_time) DT, INSTANCE_NUMBER,
	min(case when extract(hour from end_interval_time) =  0 then snap_id else NULL end) SN00,
	min(case when extract(hour from end_interval_time) =  1 then snap_id else NULL end) SN01,
	min(case when extract(hour from end_interval_time) =  2 then snap_id else NULL end) SN02,
	min(case when extract(hour from end_interval_time) =  3 then snap_id else NULL end) SN03,
	min(case when extract(hour from end_interval_time) =  4 then snap_id else NULL end) SN04,
	min(case when extract(hour from end_interval_time) =  5 then snap_id else NULL end) SN05,
	min(case when extract(hour from end_interval_time) =  6 then snap_id else NULL end) SN06,
	min(case when extract(hour from end_interval_time) =  7 then snap_id else NULL end) SN07,
	min(case when extract(hour from end_interval_time) =  8 then snap_id else NULL end) SN08,
	min(case when extract(hour from end_interval_time) =  9 then snap_id else NULL end) SN09,
	min(case when extract(hour from end_interval_time) = 10 then snap_id else NULL end) SN10,
	min(case when extract(hour from end_interval_time) = 11 then snap_id else NULL end) SN11,
	min(case when extract(hour from end_interval_time) = 12 then snap_id else NULL end) SN12,
	min(case when extract(hour from end_interval_time) = 13 then snap_id else NULL end) SN13,
	min(case when extract(hour from end_interval_time) = 14 then snap_id else NULL end) SN14,
	min(case when extract(hour from end_interval_time) = 15 then snap_id else NULL end) SN15,
	min(case when extract(hour from end_interval_time) = 16 then snap_id else NULL end) SN16,
	min(case when extract(hour from end_interval_time) = 17 then snap_id else NULL end) SN17,
	min(case when extract(hour from end_interval_time) = 18 then snap_id else NULL end) SN18,
	min(case when extract(hour from end_interval_time) = 19 then snap_id else NULL end) SN19,
	min(case when extract(hour from end_interval_time) = 20 then snap_id else NULL end) SN20,
	min(case when extract(hour from end_interval_time) = 21 then snap_id else NULL end) SN21,
	min(case when extract(hour from end_interval_time) = 22 then snap_id else NULL end) SN22,
	min(case when extract(hour from end_interval_time) = 23 then snap_id else NULL end) SN23,
	max(case when extract(hour from end_interval_time) =  0 then startup_time else NULL end) ST00,
	max(case when extract(hour from end_interval_time) =  1 then startup_time else NULL end) ST01,
	max(case when extract(hour from end_interval_time) =  2 then startup_time else NULL end) ST02,
	max(case when extract(hour from end_interval_time) =  3 then startup_time else NULL end) ST03,
	max(case when extract(hour from end_interval_time) =  4 then startup_time else NULL end) ST04,
	max(case when extract(hour from end_interval_time) =  5 then startup_time else NULL end) ST05,
	max(case when extract(hour from end_interval_time) =  6 then startup_time else NULL end) ST06,
	max(case when extract(hour from end_interval_time) =  7 then startup_time else NULL end) ST07,
	max(case when extract(hour from end_interval_time) =  8 then startup_time else NULL end) ST08,
	max(case when extract(hour from end_interval_time) =  9 then startup_time else NULL end) ST09,
	max(case when extract(hour from end_interval_time) = 10 then startup_time else NULL end) ST10,
	max(case when extract(hour from end_interval_time) = 11 then startup_time else NULL end) ST11,
	max(case when extract(hour from end_interval_time) = 12 then startup_time else NULL end) ST12,
	max(case when extract(hour from end_interval_time) = 13 then startup_time else NULL end) ST13,
	max(case when extract(hour from end_interval_time) = 14 then startup_time else NULL end) ST14,
	max(case when extract(hour from end_interval_time) = 15 then startup_time else NULL end) ST15,
	max(case when extract(hour from end_interval_time) = 16 then startup_time else NULL end) ST16,
	max(case when extract(hour from end_interval_time) = 17 then startup_time else NULL end) ST17,
	max(case when extract(hour from end_interval_time) = 18 then startup_time else NULL end) ST18,
	max(case when extract(hour from end_interval_time) = 19 then startup_time else NULL end) ST19,
	max(case when extract(hour from end_interval_time) = 20 then startup_time else NULL end) ST20,
	max(case when extract(hour from end_interval_time) = 21 then startup_time else NULL end) ST21,
	max(case when extract(hour from end_interval_time) = 22 then startup_time else NULL end) ST22,
	max(case when extract(hour from end_interval_time) = 23 then startup_time else NULL end) ST23
FROM dba_hist_snapshot
JOIN v$database using (DBID)
group by trunc(end_interval_time), INSTANCE_NUMBER
)
select 
	to_char(DT,'YYYY-MM-DD') DT, INSTANCE_NUMBER as INST,
	lpad(SN00 || case when ST00 is NOT NULL and ST00 <> lag(ST23) over (ORDER BY DT) then '*' else ' ' end,6,' ') as SNAP_00,
	lpad(SN01 || case when ST01 is NOT NULL and ST01 <> ST00 then '*' else ' ' end                        ,6,' ') as SNAP_01,
	lpad(SN02 || case when ST02 is NOT NULL and ST02 <> ST01 then '*' else ' ' end                        ,6,' ') as SNAP_02,
	lpad(SN03 || case when ST03 is NOT NULL and ST03 <> ST02 then '*' else ' ' end                        ,6,' ') as SNAP_03,
	lpad(SN04 || case when ST04 is NOT NULL and ST04 <> ST03 then '*' else ' ' end                        ,6,' ') as SNAP_04,
	lpad(SN05 || case when ST05 is NOT NULL and ST05 <> ST04 then '*' else ' ' end                        ,6,' ') as SNAP_05,
	lpad(SN06 || case when ST06 is NOT NULL and ST06 <> ST05 then '*' else ' ' end                        ,6,' ') as SNAP_06,
	lpad(SN07 || case when ST07 is NOT NULL and ST07 <> ST06 then '*' else ' ' end                        ,6,' ') as SNAP_07,
	lpad(SN08 || case when ST08 is NOT NULL and ST08 <> ST07 then '*' else ' ' end                        ,6,' ') as SNAP_08,
	lpad(SN09 || case when ST09 is NOT NULL and ST09 <> ST08 then '*' else ' ' end                        ,6,' ') as SNAP_09,
	lpad(SN10 || case when ST10 is NOT NULL and ST10 <> ST09 then '*' else ' ' end                        ,6,' ') as SNAP_10,
	lpad(SN11 || case when ST11 is NOT NULL and ST11 <> ST10 then '*' else ' ' end                        ,6,' ') as SNAP_11,
	lpad(SN12 || case when ST12 is NOT NULL and ST12 <> ST11 then '*' else ' ' end                        ,6,' ') as SNAP_12,
	lpad(SN13 || case when ST13 is NOT NULL and ST13 <> ST12 then '*' else ' ' end                        ,6,' ') as SNAP_13,
	lpad(SN14 || case when ST14 is NOT NULL and ST14 <> ST13 then '*' else ' ' end                        ,6,' ') as SNAP_14,
	lpad(SN15 || case when ST15 is NOT NULL and ST15 <> ST14 then '*' else ' ' end                        ,6,' ') as SNAP_15,
	lpad(SN16 || case when ST16 is NOT NULL and ST16 <> ST15 then '*' else ' ' end                        ,6,' ') as SNAP_16,
	lpad(SN17 || case when ST17 is NOT NULL and ST17 <> ST16 then '*' else ' ' end                        ,6,' ') as SNAP_17,
	lpad(SN18 || case when ST18 is NOT NULL and ST18 <> ST17 then '*' else ' ' end                        ,6,' ') as SNAP_18,
	lpad(SN19 || case when ST19 is NOT NULL and ST19 <> ST18 then '*' else ' ' end                        ,6,' ') as SNAP_19,
	lpad(SN20 || case when ST20 is NOT NULL and ST20 <> ST19 then '*' else ' ' end                        ,6,' ') as SNAP_20,
	lpad(SN21 || case when ST21 is NOT NULL and ST21 <> ST20 then '*' else ' ' end                        ,6,' ') as SNAP_21,
	lpad(SN22 || case when ST22 is NOT NULL and ST22 <> ST21 then '*' else ' ' end                        ,6,' ') as SNAP_22,
	lpad(SN23 || case when ST23 is NOT NULL and ST23 <> ST22 then '*' else ' ' end                        ,6,' ') as SNAP_23
from x
order by INSTANCE_NUMBER, DT
;
