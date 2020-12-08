WITH COMP AS 
 (
 SELECT DISTINCT SP.LOCATION_ID, SP.SERVICE_PROVIDER_ID, 			
                SP.MAX_INTERNET_SPEED_QTY
, CASE WHEN (SP.MAX_INTERNET_SPEED_QTY > 100 AND sP.service_provider_id = 1) THEN 'ATT FIBER' 			
                WHEN ((SP.MAX_INTERNET_SPEED_QTY BETWEEN 7 AND 100 OR SP.MAX_INTERNET_SPEED_QTY IS NULL) AND SP.SERVICE_PROVIDER_ID = 1) THEN 'ATT NON-FIBER'		
				WHEN ((SP.MAX_INTERNET_SPEED_QTY <= 6 OR SP.MAX_INTERNET_SPEED_QTY IS NULL) AND SP.SERVICE_PROVIDER_ID = 1) THEN 'ATT DSL'			
                WHEN ( SP.SERVICE_PROVIDER_ID = 17) THEN 'RCN'			
                WHEN ( SP.SERVICE_PROVIDER_ID = 23) THEN 'TDS'			
                WHEN ( SP.SERVICE_PROVIDER_ID = -1 OR SP.SERVICE_PROVIDER_ID IS NULL) THEN 'NONE'			
                 ELSE SR.SERVICE_PROVIDER_NAME END AS COMP	
				 
                FROM NDW_BASE_VIEWS.SERVICE_PROVIDER_LOCATION AS SP			
                LEFT JOIN NDW_BASE_VIEWS.SERVICE_PROVIDER_REF AS SR			
                    ON SP.SERVICE_PROVIDER_ID = SR.SERVICE_PROVIDER_ID		
                 WHERE  SP.service_provider_id = 1
				 --SP.MAX_INTERNET_SPEED_QTY
				 --SP.service_provider_id IN (1,2,4, 5,9,10,11,16,17,23,27,28,129, 323)		AND YEAR		
				  -- ATT 1, CTL 2, FTR 4, EPB 9, Google Fiber 10, Hotwire 11, Metronet 16, RCN 17, TDS 23, Windstream 27, WOW 28, WebPass 129		
				  --SAMPLE 500;
                )

, SUB_DEMO AS (
    SELECT DISTINCT SB.DIVISION, SB.REGION, SB.DMA, SB.CITY, SB.ZIP, SB.LOCATION_ID 
		, SB.FLEX_IND, SB.HSD_TIER_NAME AS H_TIER, PRODUCT_MIX_WITH_XM AS P_MIX
  , CASE WHEN SB.ETHNICITY_ROLL_UP = 'HISP' OR SB.HISP_FOOTPRINT_2020_SEG IN ('1','2','3','E') THEN 'HISP_SB'
                WHEN SB.ETHNICITY_ROLL_UP = 'AFAM' OR SB.AFRICAN_AMERICAN_2020_SEG IN ('1','2','3','E') THEN 'AF_AM_SB'
                WHEN SB.ETHNICITY_ROLL_UP IN ('PCAS','MEST','SOAS') THEN 'ASIA_ME_SB'
                WHEN SB.ETHNICITY_ROLL_UP NOT IN ('HISP','AFAM','PCAS','MEST','SOAS') THEN 'OTHER_SB'
                ELSE 'UNK' END AS ETHNICITY
  , CASE WHEN SB.INCOME_CODE IN ('<15K','15-25K','25-35K','35-50K') THEN 'INC_CONST_SB'
                WHEN SB.INCOME_CODE IN ('50-75K','75-100K','100-125K')  THEN 'DISP_INC_SB'
                WHEN SB.INCOME_CODE IN ('125-150K','150-175K','175-200K') THEN 'INC_HI_SB'
                WHEN SB.INCOME_CODE IN ('200-250K','250K+')  THEN 'INC_LUX_SB'
                ELSE 'UNK' END AS INCOME
    , SB.DWELL_TYPE_GROUP AS DWELL, SB.SUB_CONSR6_SEGMENT_classification AS SEGMENT 
    , SB.CUSTOMER_ACCOUNT_ID      , SB.MONTH_END_DT
    FROM NDW_ROSETTA_VIEWS.ROSETTA_2020 AS SB
                WHERE SB.customer_type = 'RESIDENTIAL'
                --AND SB.dwell_type_group IN ('MDU','SFU')
                AND SB.division = 'CENTRAL DIVISION'
				AND SB.BULK_IND = 0
				AND INCOME = 'INC_CONST_SB'
				AND RGU_HSD = 1
                --GROUP BY 1,2,3,4,5,6,7,8,9--,10,11
                --SAMPLE 500
        )
				
				SEL DISTINCT SUB_DEMO.DIVISION, SUB_DEMO.REGION, SUB_DEMO.DMA, SUB_DEMO.CITY, SUB_DEMO.ZIP
				,SUB_DEMO.MONTH_END_DT--, SUB_DEMO.SEGMENT
				--, HP_DEMO.INCOME, HP_DEMO.DWELL, HP_DEMO.BAD_DEBT, HP_DEMO.SEGMENT , HP.ETHNICITY
				, COMP.COMP
				,COUNT(DISTINCT SUB_DEMO.CUSTOMER_ACCOUNT_ID) AS SB
				FROM SUB_DEMO
				LEFT JOIN COMP
				ON SUB_DEMO.LOCATION_ID = COMP.LOCATION_ID
				WHERE COMP.COMP IS NOT NULL
				GROUP BY 1,2,3,4,5,6,7--,8--,9