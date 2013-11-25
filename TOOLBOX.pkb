CREATE OR REPLACE PACKAGE BODY TOOLBOX
AS
PROCEDURE PRC_TB_LOG(MSG IN VARCHAR2)
AS
MY_ID NUMBER;
MY_SQL VARCHAR2(300);
BEGIN
IF(C_LOG IS NOT NULL AND C_LOG = 'ENABLED') THEN
--CREATE TABLE C_SCHEMA.C_SCHEMA_TOOLBOX_LOG(
--ID NUMBER,
--MSG VARCHAR2(500),
--LOAD_DATE DATE
--);
MY_SQL := 'SELECT (MAX(ID)+1) FROM ( SELECT MAX(ID) ID FROM '|| C_SCHEMA ||'.'||C_SCHEMA|| '_TOOLBOX_LOG UNION SELECT 0 FROM DUAL )';
EXECUTE IMMEDIATE MY_SQL INTO MY_ID;
MY_SQL := 'INSERT INTO '|| C_SCHEMA ||'.'||C_SCHEMA|| '_TOOLBOX_LOG(ID,MSG,LOAD_DATE) VALUES('|| MY_ID ||','''|| MSG||''',SYSDATE)';
EXECUTE IMMEDIATE MY_SQL;
COMMIT;
END IF;
EXCEPTION
WHEN OTHERS THEN
DBMS_OUTPUT.put_line ('Erro ao salvar log');
END PRC_TB_LOG;
PROCEDURE PRC_TB_RB_INVALIDOS_BY_OBJ(
    OBJECTO IN VARCHAR2,
    TIPO    IN VARCHAR2)
AS
BEGIN
  EXECUTE IMMEDIATE 'ALTER ' || TIPO || ' ' || C_SCHEMA || '.' || OBJECTO || ' COMPILE';
  DBMS_OUTPUT.put_line (OBJECTO || ' recuperado(a)');
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ( 'Recuperação falhou para o objecto ' || OBJECTO);
  PRC_TB_LOG('Recuperação falhou para o objecto ' || OBJECTO || ' do tipo ' || TIPO);
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
  DBMS_OUTPUT.put_line ('=======        Recuperação        =======');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=======>INDEX');
  FOR rec IN
  (SELECT INDEX_NAME
  FROM all_indexes
  WHERE STATUS NOT IN ('VALID', 'N/A')
  AND owner         = C_SCHEMA
  )
  LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX ' || C_SCHEMA || '.' || rec.INDEX_NAME || ' REBUILD';
    DBMS_OUTPUT.put_line (rec.INDEX_NAME || ' recuperado');
  END LOOP;
  FOR rec2 IN
  (SELECT INDEX_NAME,
    PARTITION_NAME
  FROM all_IND_PARTITIONS
  WHERE STATUS   <> 'USABLE'
  AND index_owner = C_SCHEMA
  GROUP BY INDEX_NAME,
    PARTITION_NAME,
    STATUS,
    TABLESPACE_NAME
  )
  LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX ' || C_SCHEMA || '.' || rec2.INDEX_NAME || ' REBUILD PARTITION ' || rec2.PARTITION_NAME;
    DBMS_OUTPUT.put_line (rec2.INDEX_NAME || ' @ ' || rec2.PARTITION_NAME || ' recuperado');
  END LOOP;
  FOR rec3 IN
  (SELECT OBJECT_NAME,
    OBJECT_TYPE
  FROM all_OBJECTS
  WHERE STATUS <> 'VALID'
  AND owner     = C_SCHEMA
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
  AND owner     = C_SCHEMA
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
  AND owner         = C_SCHEMA
  UNION
  SELECT DISTINCT INDEX_NAME
  FROM all_IND_PARTITIONS
  WHERE STATUS   <> 'USABLE'
  AND index_owner = C_SCHEMA
  )
  LOOP
    DBMS_OUTPUT.put_line (rec2.INDEX_NAME || ' encontra-se inválido');
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
  AND owner         = C_SCHEMA
  UNION
  SELECT DISTINCT INDEX_NAME,
    INDEX_OWNER
  FROM all_IND_PARTITIONS
  WHERE STATUS   <> 'USABLE'
  AND index_owner = C_SCHEMA
  )
  LOOP
    DBMS_OUTPUT.put_line ( rec2.INDEX_NAME || ' do schema ' || rec2.OWNER || ' encontra-se inválido');
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
  DBMS_STATS.gather_table_stats (ownname => C_SCHEMA, tabname => TABLE_NAME, partname => NULL, CASCADE => TRUE, degree => 4, ESTIMATE_PERCENT => ESTIMATE_PERCENT);
  DBMS_OUTPUT.put_line (TABLE_NAME || ' analisada');
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ('Erro ao calcular as estatisticas para a tabela' || TABLE_NAME);
  PRC_TB_LOG('Erro ao calcular as estatisticas para a tabela' || TABLE_NAME);
END PRC_TB_GATHER_STATS;
PROCEDURE PRC_TB_ANALYZE(
    TABLE_NAME IN VARCHAR2)
AS
BEGIN
  EXECUTE immediate 'ANALYZE TABLE ' || C_SCHEMA||'.'||TABLE_NAME || ' estimate statistics sample 30 percent';
  DBMS_OUTPUT.put_line (TABLE_NAME || ' analisada');
EXCEPTION
WHEN OTHERS THEN
  DBMS_OUTPUT.put_line ('Erro ao calcular as estatisticas para a tabela' || TABLE_NAME);
  PRC_TB_LOG('Erro ao calcular as estatisticas para a tabela' || TABLE_NAME);
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
  DBMS_OUTPUT.put_line ('======= Tabelas não Particionadas =======');
  DBMS_OUTPUT.put_line ('=========================================');
  FOR REC IN
  (SELECT table_name
  FROM all_tables
  WHERE owner                           = C_SCHEMA
  AND TO_CHAR(last_analyzed,'YYYYMMDD')<=TO_CHAR((SYSDATE-DIAS_V),'YYYYMMDD')
  AND PARTITIONED                       = 'NO'
  ORDER BY table_name
  )
  LOOP
    PRC_TB_ANALYZE(REC.table_name);    
  END LOOP;
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('=========================================');
  DBMS_OUTPUT.put_line ('=======   Tabelas Particionadas   =======');
  DBMS_OUTPUT.put_line ('=========================================');
  FOR REC2 IN
  (SELECT table_name
  FROM all_tables
  WHERE owner                           = C_SCHEMA
  AND TO_CHAR(last_analyzed,'YYYYMMDD')<=TO_CHAR((SYSDATE-DIAS_V),'YYYYMMDD')
  AND PARTITIONED                       = 'YES'
  ORDER BY table_name
  )
  LOOP
    PRC_TB_GATHER_STATS(REC2.table_name, 30);
  END LOOP;
  DBMS_OUTPUT.put_line(' ');
  DBMS_OUTPUT.put_line ('========================================================================================');
  DBMS_OUTPUT.put_line (' ');
END;
END TOOLBOX;
/