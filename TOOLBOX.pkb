CREATE OR REPLACE PACKAGE BODY TOOLBOX
AS
PROCEDURE PRC_TB_RB_INVALIDOS_BY_OBJ(
    OBJECTO IN VARCHAR2,
    TIPO    IN VARCHAR2)
AS
BEGIN
  EXECUTE IMMEDIATE 'ALTER ' || TIPO || ' ' || c_schema || '.' || OBJECTO || ' COMPILE';
  DBMS_OUTPUT.put_line (OBJECTO || ' recuperado(a)');
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ( 'Recupera��o falhou para o objecto ' || OBJECTO);
END PRC_TB_RB_INVALIDOS_BY_OBJ;
PROCEDURE PRC_TB_REBUILD_INVALIDOS
AS
  VAR_TYPE VARCHAR2(100);
BEGIN
  VAR_TYPE := ' ';
  -- recupera(rebuild) os indexes invalidos
  DBMS_OUTPUT.put_line (' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line ('=======        Recupera��o        =======');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=======>INDEX');
  FOR rec IN
  (SELECT INDEX_NAME
  FROM all_indexes
  WHERE STATUS NOT IN ('VALID', 'N/A')
  AND owner         = c_schema
  )
  LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX ' || c_schema || '.' || rec.INDEX_NAME || ' REBUILD';
    DBMS_OUTPUT.put_line (rec.INDEX_NAME || ' recuperado');
  END LOOP;
  FOR rec2 IN
  (SELECT INDEX_NAME,
    PARTITION_NAME
  FROM all_IND_PARTITIONS
  WHERE STATUS   <> 'USABLE'
  AND index_owner = c_schema
  GROUP BY INDEX_NAME,
    PARTITION_NAME,
    STATUS,
    TABLESPACE_NAME
  )
  LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX ' || c_schema || '.' || rec2.INDEX_NAME || ' REBUILD PARTITION ' || rec2.PARTITION_NAME;
    DBMS_OUTPUT.put_line (rec2.INDEX_NAME || ' @ ' || rec2.PARTITION_NAME || ' recuperado');
  END LOOP;
  FOR rec3 IN
  (SELECT OBJECT_NAME,
    OBJECT_TYPE
  FROM all_OBJECTS
  WHERE STATUS <> 'VALID'
  AND owner     = c_schema
  ORDER BY OBJECT_TYPE,
    OBJECT_NAME
  )
  LOOP
    -- Esta parte recupera tudo o resto
    IF(VAR_TYPE != rec3.OBJECT_TYPE) THEN
      DBMS_OUTPUT.put_line (' ');
      DBMS_OUTPUT.put_line ('=======>' || rec3.OBJECT_TYPE);
      VAR_TYPE := rec3.OBJECT_TYPE;
    END IF;
    IF rec3.OBJECT_TYPE IN ('VIEW', 'TRIGGER', 'PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY') THEN
      PRC_TB_RB_INVALIDOS_BY_OBJ (rec3.OBJECT_NAME, rec3.OBJECT_TYPE);
    END IF;
  END LOOP;
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line (' ');
END PRC_TB_REBUILD_INVALIDOS;
PROCEDURE PRC_TB_REPORT_INVALIDOS
AS
  VAR_TYPE VARCHAR2(100);
BEGIN
  VAR_TYPE := ' ';
  DBMS_OUTPUT.put_line (' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line ('=======    Lista de problemas     =======');
  DBMS_OUTPUT.put_line ('=========================================');
  FOR rec IN
  (SELECT OBJECT_NAME,
    OBJECT_TYPE,
    STATUS
  FROM all_objects
  WHERE STATUS <> 'VALID'
  AND owner     = c_schema
  ORDER BY OBJECT_TYPE,
    OBJECT_NAME
  )
  LOOP
    IF(VAR_TYPE != rec.OBJECT_TYPE) THEN
      DBMS_OUTPUT.put_line (' ');
      DBMS_OUTPUT.put_line ('=======>' || rec.OBJECT_TYPE);
      VAR_TYPE := rec.OBJECT_TYPE;
    END IF;
    DBMS_OUTPUT.put_line ( rec.OBJECT_NAME || ' encontra-se ' || rec.STATUS);
  END LOOP;
  DBMS_OUTPUT.put_line (' ');
  DBMS_OUTPUT.put_line ('=======>INDEX');
  FOR rec2 IN
  (SELECT INDEX_NAME
  FROM all_indexes
  WHERE STATUS NOT IN ('VALID', 'N/A')
  AND owner         = c_schema
  UNION
  SELECT DISTINCT INDEX_NAME
  FROM all_IND_PARTITIONS
  WHERE STATUS   <> 'USABLE'
  AND index_owner = c_schema
  )
  LOOP
    DBMS_OUTPUT.put_line (rec2.INDEX_NAME || ' encontra-se inv�lido');
  END LOOP;
  DBMS_OUTPUT.put_line (' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line (' ');
END PRC_TB_REPORT_INVALIDOS;
PROCEDURE PRC_TB_FULL_REPORT
AS
  VAR_TYPE VARCHAR2(100);
BEGIN
  VAR_TYPE := ' ';
  DBMS_OUTPUT.put_line (' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line ('=======    Lista de problemas     =======');
  DBMS_OUTPUT.put_line ('=========================================');
  FOR rec IN
  (SELECT OBJECT_NAME,
    OBJECT_TYPE,
    STATUS,
    OWNER
  FROM all_objects
  WHERE STATUS <> 'VALID'
  ORDER BY OBJECT_TYPE,
    OBJECT_NAME
  )
  LOOP
    IF(VAR_TYPE != rec.OBJECT_TYPE) THEN
      DBMS_OUTPUT.put_line (' ');
      DBMS_OUTPUT.put_line ('=======>' || rec.OBJECT_TYPE);
      VAR_TYPE := rec.OBJECT_TYPE;
    END IF;
    DBMS_OUTPUT.put_line ( rec.OBJECT_NAME || ' pertecente ao schema ' || rec.OWNER || ' encontra-se ' || rec.STATUS);
  END LOOP;
  DBMS_OUTPUT.put_line (' ');
  DBMS_OUTPUT.put_line ('=======>INDEX');
  FOR rec2 IN
  (SELECT INDEX_NAME,
    OWNER
  FROM all_indexes
  WHERE STATUS NOT IN ('VALID', 'N/A')
  AND owner         = c_schema
  UNION
  SELECT DISTINCT INDEX_NAME,
    INDEX_OWNER
  FROM all_IND_PARTITIONS
  WHERE STATUS   <> 'USABLE'
  AND index_owner = c_schema
  )
  LOOP
    DBMS_OUTPUT.put_line ( rec2.INDEX_NAME || ' do schema ' || rec2.OWNER || ' encontra-se inv�lido');
  END LOOP;
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line (' ');
END PRC_TB_FULL_REPORT;
PROCEDURE PRC_TB_GATHER_STATS(
    TABLE_NAME       IN VARCHAR2,
    ESTIMATE_PERCENT IN VARCHAR2)
AS
BEGIN
  DBMS_STATS.gather_table_stats (ownname => c_schema, tabname => TABLE_NAME, partname => NULL, CASCADE => TRUE, degree => 4, ESTIMATE_PERCENT => ESTIMATE_PERCENT);
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ('Erro ao calcular as estatisticas');
END PRC_TB_GATHER_STATS;
PROCEDURE PRC_TB_ANALYZE(
    TABLE_NAME IN VARCHAR2)
AS
BEGIN
  EXECUTE immediate 'ANALYZE TABLE ' || c_schema||'.'||TABLE_NAME || ' estimate statistics sample 30 percent';
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ('Erro ao calcular as estatisticas');
END PRC_TB_ANALYZE;
PROCEDURE PRC_TB_ANALYZE_OLD(
    DIAS IN NUMBER)
AS
  DIAS_V NUMBER;
BEGIN
  IF(DIAS  IS NULL) THEN
    DIAS_V := 0;
  ELSE
    DIAS_V := DIAS;
  END IF;
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line ('======= Tabelas n�o Particionadas =======');
  DBMS_OUTPUT.put_line ('=========================================');
  FOR REC IN
  (SELECT table_name
  FROM all_tables
  WHERE owner                           = c_schema
  AND TO_CHAR(last_analyzed,'YYYYMMDD')<=TO_CHAR((SYSDATE-DIAS_V),'YYYYMMDD')
  AND PARTITIONED                       = 'NO'
  ORDER BY table_name
  )
  LOOP
    PRC_TB_ANALYZE(REC.table_name);
    DBMS_OUTPUT.put_line (REC.table_name || ' analisada');
  END LOOP;
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line ('=======   Tabelas Particionadas   =======');
  DBMS_OUTPUT.put_line ('=========================================');
  FOR REC2 IN
  (SELECT table_name
  FROM all_tables
  WHERE owner                           = c_schema
  AND TO_CHAR(last_analyzed,'YYYYMMDD')<=TO_CHAR((SYSDATE-DIAS_V),'YYYYMMDD')
  AND PARTITIONED                       = 'YES'
  ORDER BY table_name
  )
  LOOP
    PRC_TB_GATHER_STATS(REC2.table_name, 30);
    DBMS_OUTPUT.put_line (REC2.table_name || ' analisada');
  END LOOP;
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line (' ');
END;
END TOOLBOX;
/