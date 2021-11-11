/*
This script sets variables and call sqlmond1.sql

Created by Eduardo Claro on 2021-10-6
Last changes on 2021-11-10

Parameter 1: SQL_ID
Parameter 2: PLAN_HASH_VALUE
Parameter 3: SQL_EXEC_ID (optional)
Parameter 4: minutes (0=show all, default 1)
*/

def sqlid="&1"
def phv="&2"
def exec="&3"
def tim="&4"
@@sqlmond1
