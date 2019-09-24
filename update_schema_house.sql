
--============ HOUSE ============--
-- cast column house.houseguid to uuid
BEGIN;
    alter table house rename column houseguid to houseguid_x;
    alter table house add column houseguid uuid;
    update house set houseguid = houseguid_x::uuid;
    alter table house drop column houseguid_x;
COMMIT;

-- cast column house.houseid to uuid
BEGIN;
    alter table house rename column houseid to houseid_x;
    alter table house add column houseid uuid;
    update house set houseid = houseid_x::uuid;
    alter table house drop column houseid_x;
COMMIT;

-- cast column house.aoguid to uuid
BEGIN;
    alter table house rename column aoguid to aoguid_x;
    alter table house add column aoguid uuid;
    update house set aoguid = aoguid_x::uuid;
    alter table house drop column aoguid_x;
COMMIT;


