CREATE OR REPLACE PROCEDURE public.data_archiver(IN retain_days integer, IN prod_main_table character varying, IN archive_table_name character varying)
 LANGUAGE plpgsql
AS $procedure$
        declare _date_time timestamp;
        declare _data_count integer;
        declare _prod_main_tbl varchar(100);
        declare _archive_table_name varchar(100);
        declare _is_table_exists integer=0;
        declare _myschema varchar(10):='public';
        declare _data_archive_date_colmn varchar(20):='data_archived_date';
        declare _is_column_exists integer=0;
        declare _current_db_name varchar(30);
        declare _start_time timestamp;
        declare _end_time timestamp;
        declare _time_diff double precision;
BEGIN

_prod_main_tbl=FORMAT('%I',prod_main_table);
_archive_table_name=FORMAT('%I',archive_table_name);
_date_time=TO_DATE(TO_CHAR(now()- interval  '1 days' * retain_days, 'yyyy-mm-dd'),'YYYY-MM-DD');

EXECUTE FORMAT('SELECT CURRENT_DATABASE()') INTO _current_db_name;
EXECUTE FORMAT('SELECT count(*) FROM  %I WHERE updated_at< $1',_prod_main_tbl) USING  _date_time INTO _data_count;
        -- ************* VARIABLE STATUS ***********
        RAISE INFO 'Current DB: %',_current_db_name;
        RAISE INFO 'Production main table: %',_prod_main_tbl;
        RAISE INFO 'Archive table: %',_archive_table_name;
        RAISE INFO 'Archived from date : %',_date_time;
        RAISE INFO 'Retention days: %',retain_days;
        RAISE INFO 'Archived data count: % ',_data_count;

        -- *************GET ARCHIVED TABLE EXISTS OR NOT ***********
EXECUTE FORMAT('SELECT 1 FROM pg_catalog.pg_tables WHERE  schemaname =$1  AND tablename  =$2 ') USING _myschema,_archive_table_name INTO _is_table_exists;



IF _is_table_exists = 1
THEN
        IF _data_count>0
        THEN
                _start_time:=(SELECT clock_timestamp());
                RAISE INFO 'Table exists prod:% archive:%',_prod_main_tbl,_archive_table_name;
                RAISE LOG 'Table exists prod:% archive:%',_prod_main_tbl,_archive_table_name;

                -- *************GET ARCHIVED EXTRA COLUMN INFORMATION ***********
                EXECUTE FORMAT ('SELECT 1 FROM information_schema.columns WHERE table_name=$1 and column_name=$2') USING _archive_table_name,_data_archive_date_colmn INTO _is_column_exists;

                -- *************DELETE TABLE DATA AND STORE INTO ARCHIVED LOCATION***********
                RAISE INFO 'Data archiving in progress...... ';
                EXECUTE FORMAT('WITH purge_table  as (DELETE FROM %I WHERE updated_at<$1 RETURNING *)
                INSERT INTO %I select * from purge_table',_prod_main_tbl,_archive_table_name) USING _date_time;

                RAISE INFO 'Data archived into % table.Total data archived count: %',_archive_table_name,_data_count;
                _end_time:=(SELECT clock_timestamp());
                _time_diff:=(EXTRACT( epoch from _end_time)-EXTRACT( epoch from _start_time))/60;
                RAISE INFO 'Total duraiton to archive in sec:%',_time_diff;
        ELSE
                RAISE INFO 'No data found for archive: %', _data_count;
        END IF;

ELSE
        IF _data_count>0
        THEN
                _start_time:=(SELECT clock_timestamp());
                RAISE LOG 'Table does not exists creating archive:%',_archive_table_name;

                -- *************CREATE ARCIVE TABLE***********
                RAISE INFO 'Archive table does not exists, creating now: %',_archive_table_name;
                RAISE LOG 'Archive table does not exists, creating now: %',_archive_table_name;
                EXECUTE FORMAT('CREATE TABLE %I  as TABLE %I WITH NO DATA',_archive_table_name,_prod_main_tbl);

                -- *************GET ARCHIVED EXTRA COLUMN INFORMATION ***********
                EXECUTE FORMAT ('SELECT 1 FROM information_schema.columns WHERE table_name=$1 and column_name=$2') USING _archive_table_name,_data_archive_date_colmn INTO _is_column_exists;

                -- *************CHECK ARCHIVED EXTRA COLUMN EXISTS OR NOT*************
        --      IF   _is_column_exists IS NOT NULL
        --      THEN
        --              RAISE INFO 'Extra column: % exists',_data_archive_date_colmn;
        --              RAISE LOG 'Extra column: % exists',_data_archive_date_colmn;
        --      ELSE
        --              EXECUTE FORMAT('ALTER TABLE %I ADD COLUMN data_archived_date timestamp DEFAULT now()',_archive_table_name);
        --              RAISE INFO 'Extra column: % has beed added to %',_data_archive_date_colmn,_archive_table_name;
        --              RAISE LOG 'Extra column: % has beed added to %',_data_archive_date_colmn,_archive_table_name;
        --      END IF;

                -- *************DELETE TABLE DATA AND STORE INTO ARCHIVED LOCATION***********
                RAISE INFO 'Data archiving in progress...... ';
                RAISE LOG 'Data archiving in progress...... ';
        --      EXECUTE FORMAT('WITH purge_table  as (DELETE FROM %I WHERE updated_at<$1 RETURNING *)
        --      INSERT INTO %I select * from purge_table',_prod_main_tbl,_archive_table_name) USING _date_time;

                EXECUTE FORMAT('INSERT INTO %I SELECT * FROM %I WHERE updated_at<$1',_archive_table_name,_prod_main_tbl) USING _date_time;
                EXECUTE FORMAT('DELETE FROM %I WHERE updated_at<$1',_prod_main_tbl) USING _date_time;

                RAISE NOTICE 'Data archived into % .Total data archived count: %',_archive_table_name,_data_count;
                RAISE LOG 'Data archived into % table.Total data archived count: %',_archive_table_name,_data_count;

                _end_time:=(SELECT clock_timestamp());
                _time_diff:=(EXTRACT(epoch from _end_time)-EXTRACT( epoch from _start_time))/60;
                RAISE INFO 'Total duraiton to archive in sec:%',_time_diff;
        ELSE
                RAISE NOTICE 'No data found for archive: %', _data_count;
        END IF;

END IF;
END; $procedure$

