--#Core comamnd flow for removing one record
ALTER TABLE biblio.record_entry DISABLE RULE protect_bib_rec_delete;
ALTER TABLE biblio.record_entry DISABLE TRIGGER bbb_simple_rec_trigger;
ALTER TABLE asset.copy DISABLE RULE protect_copy_delete;
ALTER TABLE asset.call_number DISABLE RULE protect_cn_delete;

BEGIN;
\set docid 1002
DELETE FROM biblio.record_entry WHERE id = :docid;
DELETE FROM biblio.record_entry WHERE id = :docid;
DELETE FROM asset.copy WHERE call_number = (SELECT id FROM asset.call_number WHERE record = :docid);
DELETE FROM asset.call_number WHERE record = :docid;
DELETE FROM metabib.metarecord WHERE master_record = :docid;
COMMIT;

ALTER TABLE biblio.record_entry ENABLE RULE protect_bib_rec_delete;
ALTER TABLE biblio.record_entry ENABLE TRIGGER bbb_simple_rec_trigger;
ALTER TABLE asset.copy ENABLE RULE protect_copy_delete;
ALTER TABLE asset.call_number ENABLE RULE protect_cn_delete;

--#Generalized command for removing all records

--#First DELETE the records using the existing functions, which make sure record is cleanly removed from auxiliary tables.
DELETE FROM biblio.record_entry;

ALTER TABLE biblio.record_entry DISABLE RULE protect_bib_rec_delete;
ALTER TABLE biblio.record_entry DISABLE TRIGGER bbb_simple_rec_trigger;
ALTER TABLE asset.copy DISABLE RULE protect_copy_delete;
ALTER TABLE asset.call_number DISABLE RULE protect_cn_delete;

--#Hard DELETE records and copies
BEGIN;
DELETE FROM biblio.record_entry;
DELETE FROM asset.copy;
DELETE FROM asset.call_number;
DELETE FROM metabib.metarecord;
COMMIT;

ALTER TABLE biblio.record_entry ENABLE RULE protect_bib_rec_delete;
ALTER TABLE biblio.record_entry ENABLE TRIGGER bbb_simple_rec_trigger;
ALTER TABLE asset.copy ENABLE RULE protect_copy_delete;
ALTER TABLE asset.call_number ENABLE RULE protect_cn_delete;