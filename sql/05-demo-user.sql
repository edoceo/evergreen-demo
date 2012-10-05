/**
    Create a User called 'demo'
    Works! /djb 2012-10-04
*/

BEGIN;
/* profile 10 = Local Sys Admin, 4 = Cataloguer */
/* Admin Or Root User? */

/* Demo User */
INSERT INTO actor.usr (profile, ident_type, usrname, home_ou, family_name, passwd, first_given_name, second_given_name, expire_date, dob, suffix) VALUES (10, 1, 'staff', 8, 'demo', 'demo', 'Demo User', NULL, '2020-12-31', '1970-01-01', NULL);
INSERT INTO actor.usr_address (country, within_city_limits, post_code, street1, valid, state, city, street2, county, usr) VALUES ('USA', 't', '12345', '123 Main Street', 'f', 'IN', 'Smithville', '', 'Greene', CURRVAL('actor.usr_id_seq'));
INSERT INTO actor.card (barcode, usr) VALUES ('100000000000000', CURRVAL('actor.usr_id_seq'));

UPDATE actor.usr SET card = CURRVAL('actor.card_id_seq'), billing_address = CURRVAL('actor.usr_address_id_seq'), credit_forward_balance = '0', mailing_address = CURRVAL('actor.usr_address_id_seq') WHERE id=CURRVAL('actor.usr_id_seq');

INSERT INTO permission.usr_work_ou_map (usr, work_ou) VALUES (CURRVAL('actor.usr_id_seq'), 4);
INSERT INTO permission.usr_work_ou_map (usr, work_ou) VALUES (CURRVAL('actor.usr_id_seq'), 5);
INSERT INTO permission.usr_work_ou_map (usr, work_ou) VALUES (CURRVAL('actor.usr_id_seq'), 6);
INSERT INTO permission.usr_work_ou_map (usr, work_ou) VALUES (CURRVAL('actor.usr_id_seq'), 7);
INSERT INTO permission.usr_work_ou_map (usr, work_ou) VALUES (CURRVAL('actor.usr_id_seq'), 8);
INSERT INTO permission.usr_work_ou_map (usr, work_ou) VALUES (CURRVAL('actor.usr_id_seq'), 9);
COMMIT;

