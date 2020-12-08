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
                 --WHERE  SP.service_provider_id = 1
				 --SP.MAX_INTERNET_SPEED_QTY
				 --SP.service_provider_id IN (1,2,4, 5,9,10,11,16,17,23,27,28,129, 323)		AND YEAR		
				  -- ATT 1, CTL 2, FTR 4, EPB 9, Google Fiber 10, Hotwire 11, Metronet 16, RCN 17, TDS 23, Windstream 27, WOW 28, WebPass 129		
				  --SAMPLE 500;
                )
				
				, CONN_ACT AS (
SELECT AV.EFFECTIVE_DATE, AV.MONTH_END_DT, AV.CUSTOMER_ACCOUNT_ID, AV.LOCATION_ID
, HP.CITY, HP.STATE, HP.DMA, HP.ZIP, HP.DWELL_TYPE_GROUP AS DWELL, HP.DIVISION, HP.REGION
	
FROM EBI_NSD_VIEWS.NSD_MASTER_DAILY_ACTIVITY AS AV
LEFT JOIN ndw_rosetta_views.rosetta_homes_passed_current AS HP	
ON HP.LOCATION_ID = AV.LOCATION_ID	
WHERE YEAR(AV.MONTH_END_DT) > 2019	
                AND ORDER_STATUS = 'COMPLETED'	
				AND ACTIVITYDETAIL LIKE 'NEW CONNECT' --, 'UPGRADE'
                --AND HSI_TIER = 'INTERNET ESSENTIALS'	
                AND CUSTOMER_TYPE = 'RESIDENTIAL'	
                AND DIVISION_NAME LIKE '%central%'	
				--SAMPLE 500;
)

, SUB_DEMO AS (
    SELECT DISTINCT SB.DIVISION, SB.REGION, SB.DMA, SB.CITY, SB.ZIP, SB.LOCATION_ID 
		--, SB.PRODUCT_MIX , SB.MRC
  , CASE WHEN SB.ETHNICITY_ROLL_UP = 'HISP' THEN 'HISP_SB'
                WHEN SB.ETHNICITY_ROLL_UP = 'AFAM' THEN  'AF_AM_SB'
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
                --GROUP BY 1,2,3,4,5,6,7,8,9--,10,11
                --SAMPLE 500
        )

SEL DISTINCT CONN_ACT.MONTH_END_DT, CONN_ACT.DIVISION, CONN_ACT.REGION, CONN_ACT.DMA, CONN_ACT.CITY, CONN_ACT.ZIP
, COMP.COMP
--, SUB_DEMO.INCOME
				--, HP_DEMO.INCOME, HP_DEMO.DWELL, HP_DEMO.BAD_DEBT, HP_DEMO.SEGMENT , HP.ETHNICITY
,COUNT(DISTINCT CONN_ACT.CUSTOMER_ACCOUNT_ID)
FROM CONN_ACT
LEFT JOIN COMP 
ON CONN_ACT.LOCATION_ID = COMP.LOCATION_ID
LEFT JOIN SUB_DEMO
ON SUB_DEMO.LOCATION_ID = CONN_ACT.LOCATION_ID AND SUB_DEMO.MONTH_END_DT = ADD_MONTHS (CONN_ACT.MONTH_END_DT, 1)
GROUP BY 1,2,3,4,5,6,7