DELIMITER //
DROP PROCEDURE IF EXISTS Recalculate_modulo10//
CREATE PROCEDURE Recalculate_modulo10()
BEGIN
	DECLARE row_counter INT(10) DEFAULT 0;
	DECLARE helper_int INT(2);
	DECLARE helper_char CHAR(1);
	DECLARE inum INT(11);
	DECLARE bcode VARCHAR(20);
	DECLARE docid VARCHAR(10);
	DECLARE new_bcode VARCHAR(20);
	DECLARE docid_sum INT(2);
	DECLARE docid_length INT(1);
	DECLARE docid_index INT(1);
	DECLARE docid_char INT(1);
	DECLARE weight INT(1);
	DECLARE new_checksum INT(1);
	DECLARE no_more_rows BOOLEAN DEFAULT FALSE;
	DECLARE item CURSOR FOR SELECT itemnumber, barcode FROM koha.items;
	  -- Declare 'handlers' for exceptions
	DECLARE CONTINUE HANDLER FOR NOT FOUND
		SET no_more_rows = TRUE;
	
	OPEN item;
	FETCH item INTO inum, bcode;
	
	WHILE no_more_rows = FALSE DO
	
		SET new_bcode = '0';
	
		IF bcode REGEXP '[0123456789]{3}[Nn][0123456789]{8}$' THEN
			SET docid = SUBSTR(bcode,5,7);
			
			SET docid_sum = 0;
			SET docid_length = LENGTH(docid);
			SET docid_index = 1;
			WHILE docid_index <= docid_length DO
				SET docid_char = SUBSTR(docid, docid_index, 1);
			
				SET weight = 0;
				IF MOD(docid_index, 2) = 1 THEN
					SET weight = 2;
				ELSE
					SET weight = 1;
				END IF;
				
				SET docid_sum = docid_sum + weight * docid_char;
				SET docid_index = docid_index + 1;
			
			END WHILE;
			
			SET new_checksum = MOD(docid_sum, 10);
			SET new_bcode = CONCAT( SUBSTR(bcode,1,11),CAST(new_checksum AS CHAR) );
			
		END IF;
		
		
		IF STRCMP(new_bcode, "0") != 0 THEN
			UPDATE koha.items SET items.barcode=new_bcode WHERE items.itemnumber=inum;
		END IF;
	
		SET row_counter = row_counter + 1;
		IF MOD(row_counter, 1000) = 0 THEN
			SELECT row_counter;
		END IF;
	
		FETCH item INTO inum, bcode;
	END WHILE;
	
CLOSE item;
END//
DELIMITER ;