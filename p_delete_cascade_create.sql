undefine schema
alter session set current_schema=&schema;
set serverout on size 1000000

drop table tmp_delete_cascade_stmt;
drop sequence seq_delete_cascade;

create table tmp_delete_cascade_stmt (
	id number primary key, lev number, owner varchar2(30), table_name varchar2(30), parent_constraint varchar2(30), 
	child_constraint varchar2(30), statement clob, rows_deleted number);
create sequence seq_delete_cascade;

@@p_delete_cascade
