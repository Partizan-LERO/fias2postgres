-- extension to implement trigrams;
CREATE EXTENSION pg_trgm;

--========== HOUSE ==========--

--  create btree indexes
CREATE UNIQUE INDEX aoguid_pk_idx ON house USING btree (aoguid);
CREATE UNIQUE INDEX houseid_idx ON house USING btree (houseid);
CREATE UNIQUE INDEX houseguid_idx ON house USING btree (houseguid);
CREATE INDEX housenum_idx ON house USING btree (housenum);

