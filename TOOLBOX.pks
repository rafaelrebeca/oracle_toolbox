CREATE OR REPLACE PACKAGE TOOLBOX
AS
    --v1.2.2.1
	
	-- Constantes:
			--MAIN
			C_SCHEMA   	VARCHAR2 (30) := 'DUMMY';
			
			--LOGGING
			C_LOG      	VARCHAR2 (30) := 'DISABLED';
			C_LOG_TABLE	VARCHAR2 (30) := 'DUMMY_TOOLBOX_LOG';


	--analisa os objectos do schema utilizado e retorna os invalidos
   PROCEDURE PRC_TB_REPORT_INVALIDOS;

   --tenta fazer rebuild/compile ao objectos invalidos do schema utilizado
   PROCEDURE PRC_TB_REBUILD_INVALIDOS;

   --realiza um relatorio completo de todos os objectos invalidos na bd
   PROCEDURE PRC_TB_FULL_REPORT;

    --recolhe as estatistica para uma tabela e percentagem
   PROCEDURE PRC_TB_GATHER_STATS (TABLE_NAME         IN VARCHAR2,
                               ESTIMATE_PERCENT   IN VARCHAR2);
                               
   --recolhe as estatistica para uma tabela                           
   PROCEDURE PRC_TB_ANALYZE(TABLE_NAME IN VARCHAR2);
   
   --recolhe as estatistica para tabelas envelhecidas
   PROCEDURE PRC_TB_ANALYZE_OLD(DIAS IN NUMBER);
   
END TOOLBOX;
/