--========== HOUSE ==========--

--  create btree indexes
CREATE INDEX aoguid_house_idx ON house USING btree (aoguid);
CREATE INDEX houseid_house_idx ON house USING btree (houseid);
CREATE INDEX houseguid_house_idx ON house USING btree (houseguid);
CREATE INDEX housenum_idx ON house USING btree (housenum);

