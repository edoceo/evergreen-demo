-- An "l_" prefix indicates a reference to legacy data
-- An "eg_" prefix refers to Evergreen data to be loaded
-- Assumes all items will be mapped to "Example Branch 2" which has a default "id" = 5

INSERT INTO config.circ_modifier (code, name, description, sip2_media_type) VALUES ('book', 'book', 'Monograph', '001');

DROP SCHEMA m_demo CASCADE;
create schema m_demo;
\i sql/10-base.sql
select migration_tools.init('m_demo');
select migration_tools.build('m_demo');

DROP TABLE IF EXISTS m_demo.asset_copy_legacy;
CREATE table m_demo.asset_copy_legacy (
egid BIGINT,
hseq BIGINT,
l_location TEXT,
l_barcode TEXT,
l_subf_c TEXT,
l_subf_d TEXT,
l_call_num_prefix TEXT,
l_call_num TEXT,
l_price TEXT,
_whole_call_number TEXT) inherits (m_demo.asset_copy);

\copy m_demo.asset_copy_legacy(egid, hseq, l_location, l_barcode, l_call_num_prefix, l_call_num, l_price ) from 10-item-data.txt

-- drop items without barcodes

UPDATE m_demo.asset_copy_legacy SET
  l_barcode = BTRIM(l_barcode),
  l_call_num = BTRIM(l_call_num),
  l_call_num_prefix = BTRIM(l_call_num_prefix),
  l_location = BTRIM(l_location);

DELETE FROM m_demo.asset_copy_legacy WHERE l_barcode = '';


-- clear invalid prices
UPDATE m_demo.asset_copy_legacy set
l_price = ''
where l_price <> '' and btrim(replace(l_price, '$', '')) !~ E'^[0-9]+\.[0-9][0-9]$';

-- set values
UPDATE m_demo.asset_copy_legacy SET
  circ_lib = 5,
  creator = 1,
  editor = 1,
  loan_duration = 2,
  fine_level = 2,
  price = nullif(replace(l_price, '$', ''), '')::numeric(8,2),
  barcode = l_barcode
;

-- location
UPDATE m_demo.asset_copy_legacy
SET l_location = UPPER(l_location);

CREATE TABLE m_demo.loc_map (
  l_location TEXT,
  eg_circ_mod TEXT,
  eg_location TEXT
);
create unique index m_demo_idx1 on m_demo.loc_map (l_location);
\copy m_demo.loc_map from mapping/location_map.txt

ALTER TABLE m_demo.asset_copy_legacy 
ADD COLUMN eg_circ_mod TEXT,
ADD COLUMN eg_location TEXT;

UPDATE m_demo.asset_copy_legacy a
SET eg_circ_mod = b.eg_circ_mod,
    eg_location = b.eg_location
FROM m_demo.loc_map b
WHERE a.l_location = b.l_location;

-- handle defaults
UPDATE m_demo.asset_copy_legacy
SET eg_location = 'Migrated Items With No Legacy Location',
    eg_circ_mod = 'book'
WHERE eg_circ_mod is null;

UPDATE m_demo.asset_copy_legacy
SET eg_circ_mod = BTRIM(eg_circ_mod),
    eg_location = BTRIM(eg_location);

UPDATE m_demo.asset_copy_legacy
SET eg_circ_mod = 'book';

-- all circ mods defined?
SELECT eg_circ_mod, count(*)
FROM m_demo.asset_copy_legacy
WHERE eg_circ_mod NOT IN (
  SELECT code FROM config.circ_modifier
)
GROUP BY eg_circ_mod;

UPDATE m_demo.asset_copy_legacy
SET circ_modifier = eg_circ_mod;

-- copy location
INSERT INTO m_demo.asset_copy_location (name, owning_lib)
SELECT DISTINCT eg_location, circ_lib
FROM m_demo.asset_copy_legacy;

UPDATE m_demo.asset_copy_legacy a
SET location = b.id
FROM m_demo.asset_copy_location b
where a.eg_location = b.name
and a.circ_lib = b.owning_lib;

-- remove items that are not linked to any bibs
CREATE TABLE m_demo.items_sans_bibs
AS SELECT * FROM m_demo.asset_copy_legacy
WHERE egid NOT IN (select id from biblio.record_entry);

DELETE FROM m_demo.asset_copy_legacy
WHERE egid NOT IN (select id from biblio.record_entry);

-- internal barcode dupes
SELECT barcode, count(*)
FROM m_demo.asset_copy
GROUP BY barcode
HAVING COUNT(*) > 1;

CREATE TABLE m_demo.item_internal_dupes
AS SELECT * FROM m_demo.asset_copy_legacy
WHERE barcode IN (
  SELECT barcode FROM m_demo.asset_copy
  GROUP BY BARCODE HAVING COUNT(*) > 1
);
DELETE FROM m_demo.asset_copy
WHERE id IN (select id from m_demo.item_internal_dupes);

DELETE FROM m_demo.asset_call_number
WHERE id NOT IN (select call_number FROM m_demo.asset_copy);

DELETE FROM m_demo.asset_stat_cat_entry_copy_map
WHERE owning_copy NOT IN (
  SELECT id FROM
  m_demo.asset_copy);

-- dupes with incumbant items
SELECT barcode 
FROM m_demo.asset_copy
JOIN asset.copy USING (barcode)
WHERE NOT copy.deleted; 

\echo and add a prefix to dupes
UPDATE m_demo.asset_copy
SET barcode = 'westlaf-' || barcode
WHERE barcode IN (
SELECT barcode FROM m_demo.asset_copy
WHERE barcode IN (SELECT barcode FROM asset.copy)
);

-- call number
UPDATE m_demo.asset_copy_legacy
SET _whole_call_number = BTRIM(
  REPLACE(
    l_call_num_prefix || ' ' || 
    l_call_num
  , '  ', ' ')
);

TRUNCATE m_demo.asset_call_number;
INSERT INTO m_demo.asset_call_number ( label, record, owning_lib, creator, editor ) SELECT DISTINCT
    _whole_call_number,
    egid,
    5,
    1,
    1 
FROM m_demo.asset_copy_legacy AS i WHERE egid <> -1 ORDER BY 1,2,3;

--link call number labels to asset.copy
UPDATE m_demo.asset_copy_legacy AS i SET call_number = COALESCE(

    (SELECT c.id FROM m_demo.asset_call_number AS c WHERE label = _whole_call_number AND record = egid AND owning_lib = circ_lib),

    -1 

);


BEGIN;

INSERT INTO asset.copy_location SELECT * FROM m_demo.asset_copy_location;
INSERT INTO asset.call_number SELECT * FROM m_demo.asset_call_number;
INSERT INTO asset.copy SELECT * FROM m_demo.asset_copy;

UPDATE asset.copy SET loan_duration=2 WHERE circ_lib=5;

COMMIT;

