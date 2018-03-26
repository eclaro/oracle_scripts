-- Providers
create table T_PROVIDER (
	provider_id number constraint pk_provider primary key, 
	provider_name varchar2(20) not null
);
insert into T_PROVIDER values (1,'Provider 1');
insert into T_PROVIDER values (2,'Provider 2');
commit;

-- Warehouses
create table T_WAREHOUSE (
	warehouse_id number constraint pk_warehouse primary key,
	warehouse_name varchar2(20) not null
);
insert into T_WAREHOUSE values (1,'Warehouse 1');
insert into T_WAREHOUSE values (2,'Warehouse 2');
commit;

-- Products
create table T_PRODUCT (
	product_id number constraint pk_product primary key, 
	product_name varchar2(20) not null, 
	provider_id number not null constraint fk_prod_prov references T_PROVIDER,
	provider_product_id number not null,
	product_equivalent number constraint fk_prod_prod references T_PRODUCT,
	constraint uk_prov_prodid unique (provider_id, provider_product_id)
);
insert into T_PRODUCT values (1,'Product 1',1,9991,NULL);
insert into T_PRODUCT values (2,'Product 2',2,9991,1);
insert into T_PRODUCT values (3,'Product 3',1,9992,NULL);
insert into T_PRODUCT values (4,'Product 4',1,9993,NULL);
insert into T_PRODUCT values (5,'Product 5',2,9992,NULL);
insert into T_PRODUCT values (6,'Product 6',2,9993,NULL);
commit;

-- Products per Warehouses
create table T_PRODUCT_WAREHOUSE (
	product_id number not null constraint fk_prodware_product references T_PRODUCT, 
	warehouse_id number not null constraint fk_prodware_warehouse references T_WAREHOUSE,
	pieces_in_stock number not null,
	constraint pk_prodware primary key (product_id, warehouse_id)
);
insert into T_PRODUCT_WAREHOUSE values (1,1,10);
insert into T_PRODUCT_WAREHOUSE values (1,2,15);
insert into T_PRODUCT_WAREHOUSE values (2,1,7);
insert into T_PRODUCT_WAREHOUSE values (3,1,11);
insert into T_PRODUCT_WAREHOUSE values (4,2,3);
insert into T_PRODUCT_WAREHOUSE values (5,2,1);
insert into T_PRODUCT_WAREHOUSE values (6,1,4);
insert into T_PRODUCT_WAREHOUSE values (6,2,10);
commit;

-- Invoices
create table T_INVOICE (
	invoice_id number constraint pk_invoice primary key, 
	invoice_date date default sysdate not null
);
insert into T_INVOICE values (1,sysdate);
insert into T_INVOICE values (2,sysdate);
insert into T_INVOICE values (3,sysdate);
insert into T_INVOICE values (4,sysdate);
commit;

-- Invoice Items
create table T_INVOICE_ITEM (
	invoice_id number not null constraint fk_invitem_invoice references T_INVOICE,
	product_id number not null constraint fk_invitem_product references T_PRODUCT, 
	quantity number not null,
	constraint pk_invitem primary key (invoice_id,product_id)
);
insert into T_INVOICE_ITEM values (1,1,2);
insert into T_INVOICE_ITEM values (1,6,1);
insert into T_INVOICE_ITEM values (2,2,5);
insert into T_INVOICE_ITEM values (3,4,3);
insert into T_INVOICE_ITEM values (3,6,4);
insert into T_INVOICE_ITEM values (4,3,5);
commit;

-- Invoice Items Delivery
create table T_INVOICE_ITEM_DELIVERY (
	invoice_id number not null,
	product_id number not null, 
	delivery_date date default sysdate not null,
	quantity_delivered number not null,
	constraint pk_invitdel primary key (invoice_id,product_id,delivery_date),
	constraint fk_invitdel foreign key (invoice_id,product_id) references T_INVOICE_ITEM
);
insert into T_INVOICE_ITEM_DELIVERY values (1,1,sysdate-1,1);
insert into T_INVOICE_ITEM_DELIVERY values (1,1,sysdate,1);
insert into T_INVOICE_ITEM_DELIVERY values (1,6,sysdate-1,1);
insert into T_INVOICE_ITEM_DELIVERY values (3,4,sysdate,3);
insert into T_INVOICE_ITEM_DELIVERY values (3,6,sysdate-1,4);
commit;

-- Generate, execute and show (but don't COMMIT yet) the DELETE statements
begin
	P_DELETE_CASCADE(
		p_owner=>user,
		p_table=>'T_PRODUCT',
		p_where=>'product_id in (1,6)',
		p_mode => 'GX'
		);
end;
/

-- Verify the statements and the number of rows affected by each one
col statement for a80 word_wrap
select table_name, statement, rows_deleted from tmp_delete_cascade_stmt order by lev desc, id;

-- Check which records remain
select * from T_PRODUCT;
select * from T_PRODUCT_WAREHOUSE;
select * from T_INVOICE;
select * from T_INVOICE_ITEM;
select * from T_INVOICE_ITEM_DELIVERY;

-- Please note that the Invoices 1 and 2 still exist in the T_INVOICE table, despite there is no child record in T_INVOICE_ITEM for them.
-- This is normal because this rule is not enforced by any constraint, so I must delete them manually.
