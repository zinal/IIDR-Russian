#! /bin/bash

set -e
set -u

XVAL1="$1"
XVAL2="$1"

sqlplus cdcuser/passw0rd@wrk1 <<EOF
SET SERVEROUTPUT ON
DECLARE
  v_id PLS_INTEGER;
BEGIN
  FOR i IN 1..100000 LOOP
    v_id := ( $XVAL1 * 100000) + CEIL(DBMS_RANDOM.VALUE(0, 100000));
    UPDATE demo1 SET b=DBMS_RANDOM.STRING('x', 43) WHERE a=v_id;
    v_id := ( $XVAL2 * 100000) + CEIL(DBMS_RANDOM.VALUE(0, 100000));
    DELETE FROM demo1 WHERE a=v_id;
    INSERT INTO demo1 VALUES(v_id, DBMS_RANDOM.STRING('x',33));
    COMMIT;
  END LOOP;
END;
/
EXIT;
EOF
