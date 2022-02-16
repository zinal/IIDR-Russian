#! /bin/bash

set -e
set -u

XVAL1="$1"
XVAL2="$1"

sqlplus demo1/passw0rd@pdb1 <<EOF
SET SERVEROUTPUT ON
DECLARE
  v_id PLS_INTEGER;
  v_rand VARCHAR2(100);
BEGIN
  FOR i IN 1..100000 LOOP
    v_rand := DBMS_RANDOM.STRING('x', 43);
    v_id := ( $XVAL1 * 100000) + CEIL(DBMS_RANDOM.VALUE(0, 100000));
    UPDATE demo1 SET b=v_rand, c=SYSTIMESTAMP WHERE a=v_id;
    UPDATE demo2 SET b=v_rand, c=SYSTIMESTAMP WHERE a=v_id;
    v_id := ( $XVAL2 * 100000) + CEIL(DBMS_RANDOM.VALUE(0, 100000));
    v_rand := DBMS_RANDOM.STRING('x', 33);
    DELETE FROM demo1 WHERE a=v_id;
    INSERT INTO demo1(a,b,c) VALUES(v_id, v_rand, SYSTIMESTAMP);
    UPDATE demo2 SET b=v_rand, c=SYSTIMESTAMP WHERE a=v_id;
    COMMIT;
  END LOOP;
END;
/
EXIT;
EOF
