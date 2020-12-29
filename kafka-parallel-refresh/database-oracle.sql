
/*
CREATE TABLESPACE cdcdemo DATAFILE '/datum/oradata/cont/cdcdemo01.dbf' SIZE 1G AUTOEXTEND ON NEXT 64M MAXSIZE 16G;
CREATE USER cdcdemo IDENTIFIED BY "passw0rd" DEFAULT TABLESPACE cdcdemo QUOTA UNLIMITED ON cdcdemo;
*/


CREATE TABLE cdcdemo.tab_big (
  A INTEGER NOT NULL PRIMARY KEY,
  B VARCHAR2(100) NOT NULL,
  C TIMESTAMP NOT NULL,
  D NUMBER NOT NULL,
  E VARCHAR2(50),
  F CHAR(10)
) TABLESPACE cdcdemo;


CREATE OR REPLACE PROCEDURE cdcdemo.gen_tab_big AS
  v_sql VARCHAR2(1000);
BEGIN
  FOR v_i IN 0..999 LOOP
    INSERT /*+ APPEND PARALLEL */ INTO cdcdemo.tab_big(A,B,C,D,E,F)
      SELECT 100000*v_i + row_number() OVER (ORDER BY x)
            ,dbms_random.string('p', dbms_random.value(10, 70))
            ,SYSTIMESTAMP - dbms_random.value()
            ,dbms_random.value(1, 1000)
            ,dbms_random.string('a', dbms_random.value(1, 50))
            ,dbms_random.string('x', 10)
      FROM (SELECT '*' AS x FROM all_tab_columns WHERE ROWNUM<=1000) r1,
           (SELECT '*' AS x FROM all_tab_columns WHERE ROWNUM<=100) r2;
    COMMIT;
  END LOOP;
END;
/

CALL cdcdemo.gen_tab_big;

ALTER TABLE cdcdemo.tab_big ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;

-- End Of File
