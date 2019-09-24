
--========== FIRST ==========--

DROP FUNCTION IF EXISTS fstf_AddressObjects_AddressObjectTree(a_AOGUID UUID,
a_CurrStatus INTEGER);
/*************************************************************************/
/* Возвращает дерево (список взаимосвязанных строк) с характеристиками   */
/* адресообразующего элемента                                            */
/*************************************************************************/
CREATE OR REPLACE FUNCTION fstf_AddressObjects_AddressObjectTree(
  a_AOGUID UUID, /* Глобальный уникальный идентификатор */
  /* адресообразующего элемента*/
  a_CurrStatus INTEGER default NULL /* Статус актуальности КЛАДР 4:	 */
  /*	0 - актуальный,  */
  /* 1-50 - исторический, т.е. */
  /*  элемент был переименован, */
  /* в данной записи приведено одно */
  /* из прежних его наименований, */
  /* 51 - переподчиненный */
)
  RETURNS TABLE (rtf_AOGUID UUID, rtf_CurrStatus INTEGER, rtf_ActStatus INTEGER,
                 rtf_AOLevel INTEGER,rtf_ShortTypeName VARCHAR(10),
                 rtf_AddressObjectName VARCHAR(100)) AS
$BODY$
DECLARE
  c_ActualStatusCode CONSTANT INTEGER :=1; /* Признак актуальной записи  */
  /* адресообразующего элемента */
  c_NotActualStatusCode CONSTANT INTEGER :=0;	/* Значение кода актуальной записи */
  v_AOGUID     UUID;	 /* ИД адресообразующего элемента */
  v_ParentGUID UUID; /* Идентификатор родительского элемента */
  v_CurrStatus    INTEGER; /* Статус актуальности КЛАДР 4*/
  v_ActStatus     INTEGER; /* Статус актуальности */
  /* адресообразующего элемента ФИАС. */
  v_AOLevel      INTEGER; /*Уровень адресообразующего элемента  */
  v_ShortName  VARCHAR(10); /* Краткое наименование типа элемента */
  v_FormalName VARCHAR(120); /* Формализованное наименование элемента */
  v_Return_Error INTEGER;  /* Код возврата */
  --***********************************************************************
  --***********************************************************************
BEGIN
  IF a_CurrStatus IS NOT NULL THEN
    SELECT INTO  v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel,
      v_ShortName, v_FormalName
      ao.aoguid,ao.parentguid,ao.currstatus,ao.actstatus,ao.aolevel,
      ao.shortname, ao.formalname
    FROM addrobj ao
    WHERE ao.aoguid=a_AOGUID AND ao.currstatus=a_CurrStatus;
  ELSE
    SELECT INTO v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel,
      v_ShortName, v_FormalName
      ao.aoguid,ao.parentguid,ao.currstatus,ao.actstatus,ao.aolevel,
      ao.shortname, ao.formalname
    FROM addrobj ao
    WHERE ao.aoguid=a_AOGUID AND ao.actstatus=c_ActualStatusCode;
    IF NOT FOUND THEN
      SELECT INTO v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel,
        v_ShortName, v_FormalName
        ao.aoguid,ao.parentguid,ao.currstatus,ao.actstatus,ao.aolevel,
        ao.shortname, ao.formalname
      FROM addrobj ao
      WHERE ao.aoguid=a_AOGUID
        AND ao.actstatus=c_NotActualStatusCode
        AND ao.currstatus = (SELECT MAX(iao.currstatus)
                             FROM addrobj iao
                             WHERE ao.aoguid = iao.aoguid);
    END IF;
  END IF;
  RETURN QUERY SELECT v_AOGUID,v_CurrStatus,v_ActStatus,v_AOLevel,
                      v_ShortName,v_FormalName;
  WHILE  v_ParentGUID IS NOT NULL LOOP
    SELECT INTO v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel,
      v_ShortName, v_FormalName
      ao.aoguid,ao.parentguid,ao.currstatus,ao.actstatus,ao.aolevel,
      ao.shortname,ao.formalname
    FROM addrobj ao
    WHERE ao.aoguid=v_ParentGUID AND ao.actstatus=c_ActualStatusCode;
    IF NOT FOUND THEN
      SELECT INTO v_AOGUID,v_ParentGUID,v_CurrStatus,v_ActStatus,v_AOLevel,
        v_ShortName,v_FormalName
        ao.aoguid,ao.parentguid,ao.currstatus,ao.actstatus,ao.aolevel,
        ao.shortname, ao.formalname
      FROM addrobj ao
      WHERE ao.aoguid=v_ParentGUID
        AND ao.actstatus=c_NotActualStatusCode
        AND ao.currstatus = (SELECT MAX(iao.currstatus)
                             FROM addrobj iao
                             WHERE ao.aoguid = iao.aoguid);
    END IF;
    RETURN QUERY SELECT v_AOGUID,v_CurrStatus,v_ActStatus,v_AOLevel,v_ShortName,
                        v_FormalName;
  END LOOP;
END;
$BODY$
  LANGUAGE plpgsql;
COMMENT ON FUNCTION fstf_AddressObjects_AddressObjectTree(a_AOGUID UUID,
  a_CurrStatus INTEGER)
  IS 'Возвращает дерево (список взаимосвязанных строк) 
                                 с характеристиками адресообразующего элемента';


--========== SECOND ==========--

DROP FUNCTION IF EXISTS fsfn_AddressObjects_ObjectGroup(a_AOGUID UUID,a_CurrStatus INTEGER);
/*****************************************************************************/
/* Возвращает признак группы адресообразующего элемента по его идентификатору */
/* addrobj                                                    */
/*****************************************************************************/
CREATE OR REPLACE FUNCTION fsfn_AddressObjects_ObjectGroup(
  a_AOGUID  UUID, /* Глобальный уникальный идентификатор */
  /* адресообразующего элемента*/
  a_CurrStatus INTEGER default NULL /* Статус актуальности КЛАДР 4: */
  /* 0 - актуальный, */
  /* 1-50 - исторический, */
  /*     т.е. элемент был переименован, */
  /*      в данной записи приведено одно */
  /*       из прежних его наименований, */
  /* 51 - переподчиненный */
)
  RETURNS VARCHAR(50) /* Группа адресообразующего элемента */
AS
$BODY$
DECLARE
  c_CountryGroupValue   CONSTANT VARCHAR(50):='Country';
  c_RegionGroupValue	    CONSTANT VARCHAR(50):='Region';
  c_CityGroupValue          CONSTANT VARCHAR(50):='City';
  c_TerritoryGroupValue  CONSTANT VARCHAR(50):='Territory';
  c_LocalityGroupValue   CONSTANT VARCHAR(50):='Locality';
  c_MotorRoadValue        CONSTANT VARCHAR(50):='MotorRoad';
  c_RailWayObjectValue  CONSTANT VARCHAR(50):='RailWayObject';
  c_VillageCouncilValue  CONSTANT VARCHAR(50):='VillageCouncil';
  c_StreetGroupValue       CONSTANT VARCHAR(50):='Street';
  c_AddlTerritoryValue    CONSTANT VARCHAR(50):='AddlTerritory';
  c_PartAddlTerritoryValue CONSTANT VARCHAR(50):='PartAddlTerritory';
  v_ShortTypeName         VARCHAR(10);   /* Тип адресообразующего элемента */
  v_AddressObjectName  VARCHAR(100); /* Название адресообразующего элемента */
  v_AOLevel                     INTEGER;    /* Уровень адресообразующего элемента*/
  v_CurrStatus                  INTEGER;    /* Текущий статус адресообразующего элемента*/
  v_ObjectGroup              VARCHAR(50);   /* Группа адресообразующего элемента	*/
  v_Return_Error		Integer :=0;	/* Код возврата */
  --**************************************************************************
  --**************************************************************************
BEGIN
  SELECT INTO v_CurrStatus COALESCE(a_CurrStatus,MIN(addrobj.currstatus))
  FROM addrobj WHERE addrobj.aoguid=a_AOGUID;
  SELECT INTO v_ShortTypeName,v_AddressObjectName,v_AOLevel
    shortname,formalname,aolevel
  FROM addrobj addrobj
  WHERE addrobj.aoguid=a_AOGUID AND addrobj.currstatus = v_CurrStatus
  LIMIT 1;
  IF v_AOLevel = 1 AND UPPER(v_ShortTypeName) <> 'Г' THEN /*  уровень региона */
    v_ObjectGroup:=c_RegionGroupValue;
  ELSIF v_AOLevel = 1 AND UPPER(v_ShortTypeName) =  'Г' THEN /*  уровень города */
  /* как региона  */
    v_ObjectGroup:=c_CityGroupValue;
  ELSIF v_AOLevel = 3 THEN /* уровень района */
    v_ObjectGroup:=c_TerritoryGroupValue;
  ELSIF (v_AOLevel = 4 AND UPPER(v_ShortTypeName) NOT IN ('С/С','С/А','С/О','С/МО'))
    OR (v_AOLevel = 1 AND UPPER(v_ShortTypeName) <> 'Г')  THEN /* уровень города */
    v_ObjectGroup:=c_CityGroupValue;
  ELSIF v_AOLevel IN (4,6)  AND UPPER(v_ShortTypeName) IN ('С/С','С/А','С/О','С/МО')
    AND UPPER(v_ShortTypeName) NOT LIKE ('Ж/Д%') THEN /* уровень сельсовета */
    v_ObjectGroup:=c_VillageCouncilValue;
  ELSIF v_AOLevel = 6 AND UPPER(v_ShortTypeName) NOT IN ('С/С','С/А','С/О','С/МО',
                                                         'САД','СНТ','ТЕР',
                                                         'АВТОДОРОГА',
                                                         'ПРОМЗОНА',
                                                         'ДП','МКР')
    AND UPPER(v_ShortTypeName) NOT LIKE ('Ж/Д%') THEN   /* уровень населенного */
  /* пункта */
    v_ObjectGroup:=c_LocalityGroupValue;
  ELSIF  UPPER(v_ShortTypeName) IN ('АВТОДОРОГА') THEN /* уровень */
  /* автомобильной дороги */
    v_ObjectGroup:=c_MotorRoadValue;
  ELSIF  v_AOLevel IN (6,7) AND UPPER(v_ShortTypeName) LIKE ('Ж/Д%') THEN
    /* уровень элемент */
    /* на железной дороге */
    v_ObjectGroup:=c_RailWayObjectValue;
  ELSIF v_AOLevel = 7 AND UPPER(v_ShortTypeName) NOT LIKE ('Ж/Д%')
          AND UPPER(v_ShortTypeName) NOT IN ('УЧ-К','ГСК','ПЛ-КА','СНТ','ТЕР')
    OR (v_AOLevel = 6 AND UPPER(v_ShortTypeName) IN ('МКР') )  THEN
    /* уровень улицы */
    v_ObjectGroup:=c_StreetGroupValue;
  ELSIF v_AOLevel = 90 OR v_AOLevel = 6 AND UPPER(v_ShortTypeName) IN ('САД',
                                                                       'СНТ','ТЕР','ПРОМЗОНА','ДП')
    OR v_AOLevel = 7
          AND UPPER(v_ShortTypeName) IN ('УЧ-К','ГСК','ПЛ-КА','СНТ','ТЕР')  THEN
    /*  уровень дополнительных */
    /* территорий */
    v_ObjectGroup:=c_AddlTerritoryValue;
  ELSIF v_AOLevel = 91 THEN  /* уровень подчиненных дополнительным территориям */
  /* объектов */
    v_ObjectGroup:=c_PartAddlTerritoryValue;
  END IF;
  RETURN v_ObjectGroup;
END;
$BODY$
  LANGUAGE plpgsql;
COMMENT ON FUNCTION fsfn_AddressObjects_ObjectGroup(a_AOGUID UUID,
  a_CurrStatus INTEGER)
  IS 'Возвращает  признак группы адресного объекта по его идентификатору в таблице addrobj';

--========== THIRD ==========--

  DROP FUNCTION IF EXISTS fsfn_AddressObjects_TreeActualName(a_AOGUID UUID,a_MaskArray VARCHAR(2)[10]) CASCADE;
/*****************************************************************************/
/* Возвращает строку с полным названием адресообразующего элемента  */
/*****************************************************************************/
CREATE OR REPLACE FUNCTION fsfn_AddressObjects_TreeActualName(
  a_AOGUID		UUID DEFAULT NULL,  /* Идентификтор */
  /* адресообразующего  элемента */
  a_MaskArray		VARCHAR(2)[10] default '{TP,LM,LP,ST}'	/* Массив масок, */
  /* управляющий содержанием строки */
  /* с адресом дома*/
)
  RETURNS VARCHAR(1000) AS
$BODY$
DECLARE
  c_CountryGroupValue	 CONSTANT VARCHAR(50):='Country'; /* Признак группы - Страна*/
  c_RegionGroupValue	 CONSTANT VARCHAR(50):='Region'; /* Признак группы - Регион*/
  c_CityGroupValue	 CONSTANT VARCHAR(50):='City';	/* Признак группы - Основной */
  /* населенный пункт*/
  c_TerritoryGroupValue CONSTANT VARCHAR(50):='Territory';/* Признак группы - район */
  c_LocalityGroupValue   CONSTANT VARCHAR(50):='Locality';/* Признак группы - */
  /* населенный  пункт, */
  /* подчиненный основному */
  c_MotorRoadValue      CONSTANT VARCHAR(50):='MotorRoad';/* Признак группы - */
  /* автомобильная дорога */
  c_RailWayObjectValue	 CONSTANT VARCHAR(50):='RailWayObject';/* Признак группы - */
  /* железная дорога */
  c_VillageCouncilValue	 CONSTANT VARCHAR(50):='VillageCouncil';
  /* Признак группы - сельсовет */
  c_StreetGroupValue	  CONSTANT VARCHAR(50):='Street';
  /* Признак группы - */
  /* улица в населенном пункте */
  c_AddlTerritoryValue	 CONSTANT VARCHAR(50):='AddlTerritory';/* Признак группы - */
  /* дополнительная территория*/
  c_PartAddlTerritoryValue CONSTANT VARCHAR(50):='PartAddlTerritory';/* Признак группы */
  /* - часть дополнительной территории*/
  c_StreetMask	 	CONSTANT  VARCHAR(2)[1] :='{ST}';/* Маска улица */
  c_PostIndexMask	CONSTANT  VARCHAR(2)[1] :='{ZC}';/* Маска почтовый индекс */
  c_DistrictMask		CONSTANT  VARCHAR(2)[1] :='{DT}';/* Маска городской район*/
  c_PartLocalityMask	CONSTANT  VARCHAR(2)[1] :='{LP}';/* Маска подчиненный */
  /* населенный пункт*/
  c_MainLocalityMask	CONSTANT  VARCHAR(2)[1] :='{LM}';/* Маска основной */
  /* населенный пункт*/
  c_PartTerritoryMask	CONSTANT  VARCHAR(2)[1] :='{TP}';/* Маска района */
  /* субъекта федерации*/
  c_MainTerritoryMask	CONSTANT  VARCHAR(2)[1] :='{TM}';/* Маска субъект федерации */
  /* (регион)*/
  c_CountryMask		CONSTANT  VARCHAR(2)[1] :='{CY}';/* Маска страна*/
  v_ShortTypeName	VARCHAR(10);	/* Тип адресообразующего элемента */
  v_AddressObjectName VARCHAR(100); /* Название адресообразующего элемента */
  v_AOLevel                INTEGER;         /* Уровень адресообразующего элемента*/
  v_MinCurrStatus       INTEGER;		/* Минимальное значение текущего статуса */
  /* адресообразующего элемента*/
  v_TreeAddressObjectName	VARCHAR(1000); /* Полное в иерархии название элемента*/
  v_ObjectGroup         VARCHAR(50); /* Группа адресообразующего элемента */
  v_TreeLeverCount    INTEGER;		/* Счетчик цикла*/
  v_Return_Error_i     Integer := 0;     /* Код возврата*/
  cursor_AddressObjectTree RefCURSOR;  /* курсор по иерархии адреса*/
  v_Return_Error       Integer :=0;	/* Код возврата */
  --******************************************************************************  
  --******************************************************************************
BEGIN
  SELECT INTO v_MinCurrStatus MIN(addrobj.currstatus)
  FROM addrobj
  WHERE aoguid=a_AOGUID;
  OPEN cursor_AddressObjectTree FOR SELECT rtf_ShortTypeName,
                                           REPLACE(rtf_AddressObjectName,'  ',' '),
                                           rtf_AOLevel,fsfn_AddressObjects_ObjectGroup(rtf_AOGUID )
                                    FROM fstf_AddressObjects_AddressObjectTree(a_AOGUID)
                                    ORDER BY rtf_AOLevel;
  v_TreeLeverCount:=0;
  v_TreeAddressObjectName:='';
  FETCH FIRST FROM cursor_AddressObjectTree INTO v_ShortTypeName,v_AddressObjectName,
    v_AOLevel,v_ObjectGroup;
  WHILE FOUND
    LOOP
      v_TreeLeverCount:=v_TreeLeverCount+1;
      IF v_ObjectGroup=c_CountryGroupValue AND c_CountryMask <@ a_MaskArray
        AND v_AOLevel =0 THEN
        v_TreeAddressObjectName:=v_TreeAddressObjectName||
                                 CASE WHEN v_TreeAddressObjectName='' THEN ''
                                      ELSE ', ' END ||
                                 v_AddressObjectName||' '||v_ShortTypeName;
      ELSIF v_ObjectGroup=c_RegionGroupValue
        AND c_MainTerritoryMask <@ a_MaskArray
        AND v_AOLevel <=2 THEN
        v_TreeAddressObjectName:=v_TreeAddressObjectName||
                                 CASE WHEN v_TreeAddressObjectName='' THEN ''
                                      ELSE ', ' END ||
                                 CASE WHEN UPPER(v_ShortTypeName) LIKE
                                           UPPER('%Респ%') THEN 'Республика ' ||
                                                                v_AddressObjectName ELSE v_AddressObjectName||
                                                                                         ' '||v_ShortTypeName END;
      ELSIF v_ObjectGroup=c_TerritoryGroupValue
        AND c_PartTerritoryMask <@ a_MaskArray
        AND v_AOLevel =3 THEN
        v_TreeAddressObjectName:=v_TreeAddressObjectName||
                                 CASE WHEN v_TreeAddressObjectName='' THEN ''
                                      ELSE ', ' END ||
                                 v_AddressObjectName||' '||v_ShortTypeName;
      ELSIF v_ObjectGroup=c_CityGroupValue
        AND c_MainLocalityMask <@ a_MaskArray AND v_AOLevel =4 THEN
        v_TreeAddressObjectName:=v_TreeAddressObjectName||
                                 CASE WHEN v_TreeAddressObjectName='' THEN ''
                                      ELSE ', ' END ||
                                 CASE WHEN UPPER(LEFT(v_AddressObjectName,6+
                                                                          LENGTH(v_ShortTypeName)))='ЗАТО '||
                                                                                                    UPPER(TRIM(v_ShortTypeName))||'.'  THEN
                                        v_AddressObjectName
                                      ELSE v_ShortTypeName ||' '|| v_AddressObjectName END;
      ELSIF v_ObjectGroup=c_LocalityGroupValue
        AND c_DistrictMask <@ a_MaskArray AND v_AOLevel =5 THEN
        v_TreeAddressObjectName:=v_TreeAddressObjectName||
                                 CASE WHEN v_TreeAddressObjectName='' THEN ''
                                      ELSE ', ' END ||
                                 v_AddressObjectName||' '||v_ShortTypeName ;
      ELSIF v_ObjectGroup=c_LocalityGroupValue
        AND c_PartLocalityMask <@ a_MaskArray
        AND v_AOLevel =6 THEN
        v_TreeAddressObjectName:=v_TreeAddressObjectName||
                                 CASE WHEN v_TreeAddressObjectName='' THEN ''
                                      ELSE ', ' END ||
                                 v_ShortTypeName ||' '|| v_AddressObjectName;
      ELSIF v_ObjectGroup=c_StreetGroupValue
        AND c_StreetMask <@ a_MaskArray
        AND v_AOLevel =7  THEN
        v_TreeAddressObjectName:=v_TreeAddressObjectName||
                                 CASE WHEN v_TreeAddressObjectName='' THEN ''
                                      ELSE ', ' END ||
                                 v_ShortTypeName ||' '|| v_AddressObjectName;
      END IF;
      FETCH NEXT  FROM cursor_AddressObjectTree INTO v_ShortTypeName,
        v_AddressObjectName,
        v_AOLevel,v_ObjectGroup;
    END LOOP;
  CLOSE cursor_AddressObjectTree;
  RETURN 	v_TreeAddressObjectName;
END;
$BODY$
  LANGUAGE plpgsql ;
COMMENT ON FUNCTION fsfn_AddressObjects_TreeActualName(a_AOGUID UUID,
  a_MaskArray VARCHAR(2)[10])
  IS 'Возвращает  строку с полным названием адресообразующего элемента';


  --========== FOURTH ==========--


  DROP FUNCTION IF EXISTS fstf_AddressObjects_SearchByName(
  a_FormalName VARCHAR(150), a_ShortName VARCHAR(20),
  a_ParentFormalName VARCHAR(150),a_ParentShortName VARCHAR(20),
  a_GrandParentFormalName VARCHAR(150),a_GrandParentShortName VARCHAR(20));
/************************************************************************/
/* Возвращает результат поиска в списке адресообразующих элементов ФИАС */
/* по их названию и типу	 		                        */
/***********************************************************************/
CREATE OR REPLACE FUNCTION fstf_AddressObjects_SearchByName(
  a_FormalName VARCHAR(150),	 /* Оптимизированное для поиска наименование */
  /* адресообразующего элемента*/
  a_ShortName VARCHAR(20) default NULL,	/* Сокращенное наименование типа */
  /*адресообразующего элемента */
  a_ParentFormalName 	VARCHAR(150) default NULL, /* Оптимизированное для поиска */
  /* наименование адресообразующего элемента*/
  a_ParentShortName VARCHAR(20) default NULL,	/* Сокращенное наименование типа */
  /*адресообразующего элемента */
  a_GrandParentFormalName VARCHAR(150) default NULL, /*Оптимизированное для поиска */
  /* наименование адресообразующего элемента*/
  a_GrandParentShortName	VARCHAR(20) default NULL	/* Сокращенное наименование типа */
  /* адресообразующего элемента */
)
  RETURNS  TABLE (rtf_AOGUID UUID,
                  rtf_AOLevel INTEGER,
                  rtf_AddressObjectsFullName VARCHAR(1000),
                  rtf_ShortName VARCHAR(20),
                  rtf_FormalName VARCHAR(150),
                  rtf_CurrStatus INTEGER,
                  rtf_ParentShortName VARCHAR(20),
                  rtf_ParentFormalName VARCHAR(150),
                  rtf_GrandParentShortName VARCHAR(20),
                  rtf_GrandParentFormalName VARCHAR(150))
AS
$BODY$
DECLARE
  c_WildChar   CONSTANT VARCHAR(2)='%';
  c_BlankChar  CONSTANT VARCHAR(2)=' ';
  v_FormalNameTemplate VARCHAR(150); /* Шаблон для поиска наименования */
  /* адресообразующего элемента*/
  v_ShortNameTemplate		VARCHAR(20);	/* Шаблон для поиска типа */
  /* адресообразующего элемента */
  v_ParentFormalNameTemplate VARCHAR(150); /* Шаблон для поиска наименования */
  /* родительского адресообразующего элемента*/
  v_ParentShortNameTemplate VARCHAR(20); /* Шаблон для поиска типа родительского */
  /* адресообразующего элемента */
  v_GrandParentFormalNameTemplate	VARCHAR(150);	/* Шаблон для поиска */
  /* наименования родительского адресообразующего элемента*/
  v_GrandParentShortNameTemplate	VARCHAR(20);	/* Шаблон для поиска типа */
  /* родительского адресообразующего элемента */
  --************************************************************
  --************************************************************
BEGIN
  v_ShortNameTemplate:=UPPER(COALESCE(c_WildChar||
                                      REPLACE(TRIM(a_ShortName),c_BlankChar,c_WildChar)||
                                      c_WildChar,c_WildChar));
  v_FormalNameTemplate:=UPPER(c_WildChar||
                              REPLACE(TRIM(a_FormalName),c_BlankChar,c_WildChar)||
                              c_WildChar);
  IF a_ParentFormalName IS NULL AND a_ParentShortName IS NULL
    AND a_GrandParentFormalName IS NULL
    AND a_GrandParentShortName IS NULL THEN
    RETURN QUERY
      SELECT cfa.aoguid,cfa.aolevel,
             fsfn_AddressObjects_TreeActualName(cfa.aoguid),
             cfa.shortname,cfa.formalname,
             cfa.currstatus,NULL::VARCHAR,NULL::VARCHAR,
             NULL::VARCHAR,NULL::VARCHAR
      FROM addrobj cfa
      WHERE cfa.currstatus=
            CASE WHEN 0 < ALL(SELECT iao.currstatus FROM addrobj iao
                              WHERE cfa.aoguid = iao.aoguid)
                   THEN (SELECT MAX(iao.currstatus) FROM addrobj iao
                         WHERE cfa.aoguid = iao.aoguid)
                 ELSE 0
              END
        AND UPPER(cfa.formalname) LIKE v_FormalNameTemplate
        AND  UPPER(cfa.shortname) LIKE v_ShortNameTemplate
      ORDER BY cfa.aolevel,cfa.shortname,cfa.formalname;
  ELSIF a_ParentFormalName IS NOT NULL
    AND a_GrandParentFormalName IS NULL
    AND a_GrandParentShortName IS NULL THEN
    v_ParentShortNameTemplate:=UPPER(COALESCE(c_WildChar||
                                              REPLACE(TRIM(a_ParentShortName),c_BlankChar,c_WildChar)||
                                              c_WildChar,c_WildChar));
    v_ParentFormalNameTemplate:=UPPER(c_WildChar||
                                      REPLACE(TRIM(a_ParentFormalName),c_BlankChar,c_WildChar)||
                                      c_WildChar);
    v_FormalNameTemplate:=COALESCE(v_FormalNameTemplate,c_WildChar);
    RETURN QUERY
      SELECT cfa.aoguid,cfa.AOLevel,fsfn_AddressObjects_TreeActualName(cfa.aoguid),
             cfa.shortname,cfa.formalname,cfa.currstatus,
             pfa.shortname,pfa.formalname,
             NULL::VARCHAR,NULL::VARCHAR
      FROM addrobj pfa
             INNER JOIN addrobj cfa ON pfa.aoguid=cfa.parentguid
      WHERE cfa.currstatus=CASE WHEN 0 <
        ALL (SELECT iao.currstatus FROM addrobj iao
             WHERE cfa.aoguid = iao.aoguid)
                                  THEN (SELECT MAX(iao.currstatus) FROM addrobj iao
                                        WHERE cfa.aoguid = iao.aoguid)
                                ELSE 0 END
        AND pfa.currstatus=CASE WHEN 0 <
        ALL(SELECT iao.currstatus FROM addrobj iao
            WHERE pfa.aoguid = iao.aoguid)
                                  THEN (SELECT MAX(iao.currstatus) FROM addrobj iao
                                        WHERE pfa.aoguid = iao.aoguid)
                                ELSE 0 END
        AND UPPER(pfa.formalname) LIKE v_ParentFormalNameTemplate
        AND  UPPER(pfa.shortname) LIKE v_ParentShortNameTemplate
        AND UPPER(cfa.formalname) LIKE v_FormalNameTemplate
        AND  UPPER(cfa.shortname) LIKE v_ShortNameTemplate
      ORDER BY pfa.shortname,pfa.formalname,
               cfa.aolevel,cfa.shortname,cfa.formalname;
  ELSE
    v_GrandParentShortNameTemplate:=UPPER(COALESCE(c_WildChar||
                                                   REPLACE(TRIM(a_GrandParentShortName),c_BlankChar,c_WildChar)||
                                                   c_WildChar,c_WildChar));
    v_GrandParentFormalNameTemplate:=UPPER(c_WildChar||
                                           REPLACE(TRIM(a_GrandParentFormalName),c_BlankChar,c_WildChar)||
                                           c_WildChar);
    v_ParentShortNameTemplate:=COALESCE(UPPER(COALESCE(c_WildChar||
                                                       REPLACE(TRIM(a_ParentShortName),c_BlankChar,c_WildChar)||
                                                       c_WildChar,c_WildChar)),c_WildChar);
    v_ParentFormalNameTemplate:=COALESCE(UPPER(c_WildChar||
                                               REPLACE(TRIM(a_ParentFormalName),c_BlankChar,c_WildChar)||
                                               c_WildChar),c_WildChar);
    v_FormalNameTemplate:=COALESCE(v_FormalNameTemplate,c_WildChar);
    RETURN QUERY
      SELECT cfa.aoguid,cfa.aolevel,fsfn_AddressObjects_TreeActualName(cfa.aoguid),
             cfa.shortname,cfa.formalname,
             cfa.currstatus,pfa.shortname,pfa.formalname,
             gpfa.shortname,gpfa.formalname
      FROM addrobj gpfa
             INNER JOIN addrobj pfa ON gpfa.aoguid=pfa.parentguid
             INNER JOIN addrobj cfa ON pfa.aoguid=cfa.parentguid
      WHERE cfa.currstatus=CASE WHEN 0 <
        ALL(SELECT iao.currstatus FROM addrobj iao
            WHERE 	cfa.aoguid = iao.aoguid)
                                  THEN (SELECT MAX(iao.currstatus) FROM addrobj iao
                                        WHERE cfa.aoguid = iao.aoguid)
                                ELSE 0 END
        AND pfa.currstatus=CASE WHEN 0 <
        ALL(SELECT iao.currstatus FROM addrobj iao
            WHERE pfa.aoguid = iao.aoguid)
                                  THEN (SELECT MAX(iao.currstatus) FROM addrobj iao
                                        WHERE pfa.aoguid = iao.aoguid)
                                ELSE 0 END
        AND gpfa.currstatus=CASE WHEN 0 <
        ALL(SELECT iao.currstatus FROM addrobj iao
            WHERE gpfa.aoguid = iao.aoguid)
                                   THEN (SELECT MAX(iao.currstatus) FROM addrobj iao
                                         WHERE gpfa.aoguid = iao.aoguid)
                                 ELSE 0 END
        AND UPPER(gpfa.formalname) LIKE v_GrandParentFormalNameTemplate
        AND  UPPER(gpfa.shortname) LIKE v_GrandParentShortNameTemplate
        AND UPPER(pfa.formalname) LIKE v_ParentFormalNameTemplate
        AND  UPPER(pfa.shortname) LIKE v_ParentShortNameTemplate
        AND UPPER(cfa.formalname) LIKE v_FormalNameTemplate
        AND  UPPER(cfa.shortname) LIKE v_ShortNameTemplate
      ORDER BY gpfa.shortname,gpfa.formalname,
               pfa.shortname,pfa.formalname,
               cfa.aolevel,cfa.shortname,cfa.formalname;
  END IF;
END;  $BODY$
  LANGUAGE plpgsql;
COMMENT ON FUNCTION fstf_AddressObjects_SearchByName(
  a_FormalName VARCHAR(150),a_ShortName VARCHAR(20),
  a_ParentFormalName VARCHAR(150),a_ParentShortName VARCHAR(20),
  a_GrandParentFormalName VARCHAR(150),a_GrandParentShortName VARCHAR(20))
  IS 'Возвращает результат поиска в списке адресообразующих элементов ФИАС по их названию и типу';


  --========== DONE ==========--