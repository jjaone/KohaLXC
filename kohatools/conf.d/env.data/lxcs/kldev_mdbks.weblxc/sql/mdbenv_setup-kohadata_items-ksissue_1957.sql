/*
 * File: mdbenv_setup-kohadata_items-ksissue_1957.sql
 * Dir: $KOHALXC_TOOLDIR/conf.d/env.data/lxs/sql/{{inventory_hostname}}/sqld
 *
 * Description: kohadata.(deleted)items tables schema changes:
 * - add/check new columns: genre, sub_location, itemnotes_nonpublic
 * - TABLE/COLUMN structure ALTER done in PROCEDURE:addcolumns ( checks columns do not exist)
 * Code(sql):
 *  ALTER TABLE items ADD COLUMN itemnotes_nonpublic MEDIUMTEXT DEFAULT NULL AFTER itemnotes
 *  ALTER TABLE deleteditems ADD COLUMN itemsnotes_nonpublic MEDIUMTEXT DEFAULT NULL AFTER itemnotes
 *  ALTER TABLE items ADD COLUMN genre VARCHAR(10) DEFAULT NULL
 *  ALTER TABLE deleteditems ADD COLUMN genre VARCHAR(10) DEFAULT NULL
 *  ALTER TABLE items ADD COLUMN sub_location VARCHAR(80) DEFAULT NULL
 *  ALTER TABLE deleteditems ADD COLUMN sub_location VARCHAR(80) DEFAULT NULL
 *
 * Issue (resolved): https://tiketti.koha-suomi.fi:83/issues/1957
 *
 * Author: Jukka Aaltonen, Koha-Lappi, Rovaniemi/Lapland.
 * Date: 2017-06-04 by @roikohadev
 */

-- Library database: 'kohadata'
USE kohadata;

/*
-- Show the current schema of kohadata.items
DESCRIBE items;
*/

/* Add columns to (deleted)items table(s)
*/

-- queries to add column (deleted)items.itemnotes_nonpublic
SET @s_items_itemnotes_nonpublic = 'ALTER TABLE items ADD COLUMN itemnotes_nonpublic MEDIUMTEXT DEFAULT NULL AFTER itemnotes';
SET @s_deleteditems_itemnotes_nonpublic = 'ALTER TABLE deleteditems ADD COLUMN itemnotes_nonpublic MEDIUMTEXT DEFAULT NULL AFTER itemnotes';
-- queries to add column (deleted)items.genre
SET @s_items_genre = 'ALTER TABLE items ADD COLUMN genre VARCHAR(10) DEFAULT NULL';
SET @s_deleteditems_genre = 'ALTER TABLE deleteditems ADD COLUMN genre VARCHAR(10) DEFAULT NULL';
-- queries to add column (deleted)items.sub_location
SET @s_items_sublocation = 'ALTER TABLE items ADD COLUMN sub_location VARCHAR(80) DEFAULT NULL';
SET @s_deleteditems_sublocation = 'ALTER TABLE deleteditems ADD COLUMN sub_location VARCHAR(80) DEFAULT NULL';
-- dummy query: just describe the items table
SET @s_dummy = 'DESCRIBE items';

-- Show the procedures we have 
SHOW PROCEDURE STATUS;

-- Delete procedures we are going to define (if any)
DROP PROCEDURE IF EXISTS kohadata.addcolumn;

DELIMITER //
-- Add column 'col' to 'db.tbl' with alter 'stm', if not there already
CREATE PROCEDURE kohadata.addcolumn(IN db CHAR(64),  In tbl CHAR(64),
				    In col CHAr(64), IN stm CHAR(255))
   BEGIN
	SET @title = CONCAT('SELECT \'', tbl, '\' as \'\' ;');
	SET @s_dummy = CONCAT('SHOW COLUMNS FROM ', db, '.', tbl, ' LIKE \'', col, '%\'');

	SET @columnexists = (SELECT IF(count(*) = 1, 'Yes','No') AS result
	FROM information_schema.columns
	WHERE table_schema = db AND
	  (table_name = tbl AND column_name = col)
	 );

   	SET @s = IF (@columnexists = 'No', stm, @s_dummy);

	PREPARE q FROM @title;
	EXECUTE q;
	DROP PREPARE q;

	PREPARE q FROM @s;
	EXECUTE q;
	DROP PREPARE q;

   END //
DELIMITER ;

/*
-- Show how our procedure was defined
SHOW CREATE PROCEDURE kohadata.addcolumn;
*/ 

-- Add the required columns  (if not already)
-- - items.itemnotes_nonpublic:
CALL kohadata.addcolumn('kohadata', 'items',
			'itemnotes_nonpublic', @s_items_itemnotes_nonpublic);
-- - deleteditems.itemnotes_nonpublic:
CALL kohadata.addcolumn('kohadata', 'deleteditems',
     			'itemnotes_nonpublic', @s_deleteditems_itemnotes_nonpublic);
-- - items.genre:
CALL kohadata.addcolumn('kohadata', 'items',
			'genre', @s_items_genre);
-- - deleteditems.genre:
CALL kohadata.addcolumn('kohadata', 'deleteditems',
     			'genre', @s_deleteditems_genre);
-- - items.sub_location:
CALL kohadata.addcolumn('kohadata', 'items',
			'sub_location', @s_items_sublocation);
-- - deleteditems.sub_location:
CALL kohadata.addcolumn('kohadata', 'deleteditems',
     			'sub_location', @s_deleteditems_sublocation);

-- Verify that columns in 'items' under consideration should now exist..
SHOW COLUMNS FROM items LIKE 'itemnotes%';
SHOW COLUMNS FROM items LIKE 'genre%';
SHOW COLUMNS FROM items LIKE 'sub_location%';
