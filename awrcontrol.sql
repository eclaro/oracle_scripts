/*
This script shows AWR Control configuration

Created by Eduardo Claro
Last changes on 2021-10-28
*/

prompt ===================
prompt DBA_HIST_WR_CONTROL
prompt ===================

col SNAP_INTERVAL for a25
col RETENTION for a25
col DBID for 99999999999
col SRC_DBID like DBID
SELECT c.* FROM 
dba_hist_wr_control c
join v$database d on c.DBID = d.DBID;
