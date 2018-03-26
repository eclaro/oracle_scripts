create or replace procedure P_DELETE_CASCADE (
/*
Created by EDUARDO CLARO, 2018/03/05
Latest update, 2018/03/26
This procedure is intended to DELETE rows in a table, and all related child rows in all child tables.
The parameters are explained below
The procedure scans all child tables of all levels, recursively, and generates/executes the DELETE statements
*/
	p_owner in varchar2,                      -- owner of the main table
	p_table in varchar2,                      -- the main table
	p_constraint in varchar2 default NULL,    -- the PK/UK constraint to use in the main_stmt table (if NULL, all)
	p_where in varchar2 default '1=1',        -- the WHERE clause to define which rows will be DELETED in the main table
	p_commit in number default 10000,         -- COMMIT interval (rows of the main table)
	p_mode in varchar2 default 'GS',          -- modes of execution: any combination of:
	                                          --     G (generate statements)
	                                          --     S (show the statements)
	                                          --     X (execute)
	                                          --     C (commit)
	                                          --     A (ALL = G + X + C)
	p_limit in number default 9999,           -- limit the number of levels
	p_level in number default 1,              -- (recursive parameter: the current level of recursive calls)
	p_parent_owner in varchar2 default NULL,  -- (recursive parameter: the parent owner, will be used to build the recursive DELETE statement)
	p_parent_table in varchar2 default NULL,  -- (recursive parameter: the parent table, will be used to build the recursive DELETE statement)
	p_parent_cols in varchar2 default NULL,   -- (recursive parameter: the parent columns, will be used to build the recursive DELETE statement)
	p_child_cols in varchar2 default NULL     -- (recursive parameter: the child columns, will be used to build the recursive DELETE statement)
	)
is
	v_delstmt clob;
	v_selstmt clob;
	v_where clob;
	v_rows number;
	v_totalrows number;
	v_parent_constraint varchar2(30);
	v_child_constraint varchar2(30);
	cursor C_CONS is
		select
			rcon.owner as r_owner, rcon.constraint_name as r_constraint_name, rcon.table_name as r_table_name, 
			listagg (rcol.column_name, ', ') WITHIN GROUP (ORDER BY rcol.owner, rcol.table_name, rcol.constraint_name) R_COLUMNS,
			rcon.constraint_type as type,
			con.owner, con.table_name, con.constraint_name,  
			listagg (col.column_name, ', ') WITHIN GROUP (ORDER BY col.owner, col.table_name, col.constraint_name) XCOLUMNS
		from 
			all_constraints rcon
			join all_cons_columns rcol
				on rcol.owner=rcon.owner and rcol.table_name=rcon.table_name and rcol.constraint_name=rcon.constraint_name	
			left join all_constraints con 
				on rcon.owner = con.r_owner and rcon.constraint_name = con.r_constraint_name
			left join all_cons_columns col
				on col.owner=con.owner and col.table_name=con.table_name and col.constraint_name=con.constraint_name
				and rcol.position = col.position
		where rcon.owner = upper(p_owner) and rcon.table_name = upper(p_table) and rcon.constraint_type in ('P','U') 
			and rcon.constraint_name = nvl(upper(p_constraint),rcon.constraint_name) and rcon.status = 'ENABLED'
		group by 
			rcon.owner, rcon.constraint_name, rcon.table_name, rcon.constraint_type,
			con.owner, con.table_name, con.constraint_name
		order by rcon.owner, rcon.constraint_name, rcon.constraint_type;
	cursor C_STMT is
		select * from tmp_delete_cascade_stmt order by lev desc, id;
begin

	------------------------------------------------------------------------------------------------------------------------------------
	--GENERATE STATEMENTS
	if upper(p_mode) like '%G%' OR upper(p_mode) like '%A%' then
	
		-- start truncating the tables and defining the where clause
		if p_level = 1 then
			execute immediate 'truncate table tmp_delete_cascade_stmt';
			v_where := p_where;
		else
			v_where := '(' || p_child_cols || ') in (SELECT ' || chr(10) || p_parent_cols || ' FROM ' || 
			p_parent_owner || '.' || p_parent_table || ' WHERE ' || chr(10) || p_where || ')' || chr(10);
		end if;

		-- show the level and table
		if upper(p_mode) like '%S%' then
			dbms_output.put_line('================================================================');
			dbms_output.put_line('Level  : ' || p_level);
			dbms_output.put_line('Table  : ' || p_table);
		end if;
		
		-- Build the delete statement
		v_delstmt := 'DELETE FROM ' || p_owner || '.' || p_table || ' WHERE ' || v_where;
		if upper(p_mode) like '%S%' then
			dbms_output.put_line('Statement: ' || chr(10) || v_delstmt);
		end if;
		
		-- Verify if the table has rows to delete
		v_selstmt := 'SELECT COUNT(1) FROM ' || p_owner || '.' || p_table || ' WHERE ' || v_where || ' AND ROWNUM = 1';
		execute immediate v_selstmt into v_rows;

		-- Enter in the recursive loop ONLY IF the level is under the limit AND there are rows to delete
		if p_level < p_limit AND v_rows = 1 then

			-- Loop of the parent and child constraints
			for R_CONS in C_CONS loop

				-- show the level and table
				if C_CONS%ROWCOUNT > 1 and upper(p_mode) like '%S%' then
					dbms_output.put_line('================================================================');
					dbms_output.put_line('Level  : ' || p_level);
					dbms_output.put_line('Table  : ' || p_table);
				end if;

				-- show the parent and child
				if upper(p_mode) like '%S%' then
					dbms_output.put_line('================================================================');
					dbms_output.put_line('Parent Constraint: '||R_CONS.r_constraint_name);
					dbms_output.put_line('Parent Table     : '||R_CONS.r_table_name);
					dbms_output.put_line('Child  Constraint: '||R_CONS.constraint_name);
					dbms_output.put_line('Child  Table     : '||R_CONS.table_name);
				end if;

				-- save values to use outside of the loop
				v_parent_constraint := R_CONS.r_constraint_name;
				v_child_constraint := R_CONS.constraint_name;

				-- If there are child tables
				if R_CONS.table_name IS NOT NULL then
					-- recursively calls the same procedure
					P_DELETE_CASCADE (
						p_owner => R_CONS.owner,
						p_table => R_CONS.table_name,
						p_where => v_where,
						p_commit => p_commit,
						p_mode => p_mode,
						p_limit => p_limit,
						p_level => p_level + 1,
						p_parent_owner => R_CONS.r_owner,
						p_parent_table => R_CONS.r_table_name,
						p_parent_cols => R_CONS.R_COLUMNS,
						p_child_cols => R_CONS.XCOLUMNS
					);
				end if;
			end loop;
		end if;

		-- Save the delete statement IF there are rows to delete
		if v_rows = 1 then
			if upper(p_mode) like '%S%' then
				dbms_output.put_line('Registering the statement to delete table ' || p_table);
			end if;
			insert into tmp_delete_cascade_stmt(id, lev, owner, table_name, parent_constraint, child_constraint, statement)
				values (seq_delete_cascade.nextval, p_level, p_owner, p_table, v_parent_constraint, v_child_constraint, v_delstmt);
		else
			if upper(p_mode) like '%S%' then
				dbms_output.put_line('The statement has no rows to delete');
			end if;
		end if;
		commit;

	end if;

	------------------------------------------------------------------------------------------------------------------------------------
	--EXECUTE and COMMIT
	if p_level = 1 AND (upper(p_mode) like '%A%' OR upper(p_mode) like '%X%' OR upper(p_mode) like '%C') then

		for R_STMT in C_STMT loop

			-- show the statements
			if upper(p_mode) like '%S%' then
				dbms_output.put_line('');
				dbms_output.put_line('================================================================');
				dbms_output.put_line('Statement ID: ' || R_STMT.id);
				dbms_output.put_line(R_STMT.statement);
			end if;

			if upper(p_mode) like '%X%' OR upper(p_mode) like '%A%' then

				v_rows := -1;
				v_totalrows := 0;

				while v_rows <> 0 loop
					v_delstmt := R_STMT.statement || ' AND ROWNUM <= ' || p_commit;
					execute immediate v_delstmt;
					v_rows := SQL%ROWCOUNT;
					v_totalrows := v_totalrows + v_rows;
					if upper(p_mode) like '%C%' OR upper(p_mode) like '%A%' then
						commit;
					end if;
				end loop;

				update tmp_delete_cascade_stmt set rows_deleted = v_totalrows where id = R_STMT.id;
				if upper(p_mode) like '%C%' OR upper(p_mode) like '%A%' then
					commit;
				end if;

				if upper(p_mode) like '%S%' then
					dbms_output.put_line(v_totalrows || ' rows deleted');
				end if;
			end if;
		end loop;
	end if;

exception
	when others then
		dbms_output.put_line('');
		dbms_output.put_line('');
		dbms_output.put_line('================================================================');
		dbms_output.put_line('****** ERROR ******');
		dbms_output.put_line(SQLCODE);
		dbms_output.put_line(SQLERRM);
		dbms_output.put_line('');
		dbms_output.put_line('Owner: ' || p_owner);
		dbms_output.put_line('Table: ' || p_table);
		dbms_output.put_line('Level: ' || p_level);
		dbms_output.put_line('Last DELETE Statement: ' || chr(10) || v_delstmt);

end;
/
