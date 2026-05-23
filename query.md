//View Lihat Transaksi Seminggu Sebelumnya
CREATE OR REPLACE VIEW dsi_mb_srd.lihat_transaksi AS

SELECT t.customer_id,mc.cif_number,mc.customer_name,t.transaction_amount,mf.feature_name,mf.fee FROM t_transaction t
JOIN m_customer mc ON mc.id=t.customer_id
JOIN m_feature mf ON mf.feature_code=t.feature_code
WHERE t.transaction_date>=DATE_SUB(NOW(),INTERVAL 7 DAY);

//Query
SELECT * FROM lihat_transaksi


//mutasi procedure
DELIMITER $$
DROP PROCEDURE IF EXISTS `mutasi`$$
CREATE
    /*[DEFINER = { user | CURRENT_USER }]*/
    PROCEDURE `dsi_mb_srd`.`mutasi`(IN nomor_cif VARCHAR(20))
    /*LANGUAGE SQL
    | [NOT] DETERMINISTIC
    | { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
    | SQL SECURITY { DEFINER | INVOKER }
    | COMMENT 'string'*/
	BEGIN
	SELECT mc.cif_number,mc.customer_name,t.reference_number, t.transaction_amount,t.biller_name, 
	mf.fee, mr.response_message, t.transaction_date, t.location FROM t_transaction t
	JOIN m_customer mc ON mc.id=t.customer_id
	JOIN m_feature mf ON mf.feature_code=t.feature_code
	JOIN m_response_code mr ON mr.response_code=t.response_code
	WHERE mc.cif_number=nomor_cif 
	AND DATE(t.transaction_date) = CURDATE()
	ORDER BY t.transaction_date DESC;
	END$$

DELIMITER ;


//tutup buku procedure
DELIMITER $$
DROP PROCEDURE IF EXISTS `tutup_buku`$$
CREATE
    /*[DEFINER = { user | CURRENT_USER }]*/
    PROCEDURE `dsi_mb_srd`.`tutup_buku`()
    /*LANGUAGE SQL
    | [NOT] DETERMINISTIC
    | { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }
    | SQL SECURITY { DEFINER | INVOKER }
    | COMMENT 'string'*/
	BEGIN
	SELECT mc.cif_number,mc.customer_name,COUNT(*) AS 'Total', SUM(transaction_amount) AS 'Jumlah Transaksi' FROM t_transaction t
	JOIN m_customer mc ON mc.id=t.customer_id
	WHERE DATE(t.transaction_date)=CURDATE()
	GROUP BY mc.cif_number,mc.customer_name;
	
	END$$

DELIMITER ;



//Trigger Log In Sukses
DELIMITER $$
DROP TRIGGER IF EXISTS `authentication`.`login_success`$$
CREATE
    /*[DEFINER = { user | CURRENT_USER }]*/
    TRIGGER `authentication`.`login_success` AFTER INSERT
    ON `authentication`.`m_login_log`
    FOR EACH ROW BEGIN
	 IF NEW.login_status = 'SUCCESS' THEN

		UPDATE m_user
		SET login_attempt = 0
		WHERE cif_number = NEW.cif_number;

	 END IF;
    END$$

DELIMITER ;


//Trigger Log In Gagal
DELIMITER $$
DROP TRIGGER IF EXISTS `authentication`.`login_failed`$$
CREATE
    /*[DEFINER = { user | CURRENT_USER }]*/
    TRIGGER `authentication`.`login_failed` AFTER INSERT
    ON `authentication`.`m_login_log`
    FOR EACH ROW BEGIN
	  IF NEW.login_status = 'FAILED' THEN

		UPDATE authentication.m_user
		SET 
		    login_attempt = login_attempt + 1,
		    last_failed_login = NOW(),
		    STATUS = CASE
			WHEN login_attempt + 1 >= 3 THEN 'LOCKED'
			ELSE STATUS
		    END
		WHERE cif_number = NEW.cif_number;

	  END IF;
    END$$

DELIMITER ;




//Suspend
UPDATE m_user
SET 
    STATUS = 'SUSPEND',
    suspend_until = DATE_ADD(NOW(), INTERVAL 6 MONTH)
WHERE cif_number = 'CIF000123'

UPDATE m_user
SET 
    STATUS = 'ACTIVE',
    suspend_until = NULL
WHERE STATUS = 'SUSPEND'
AND suspend_until <= NOW()

// Login
SELECT * FROM m_user
WHERE cif_number = 'CIF000123'

INSERT INTO m_login_log (cif_number,login_status)
VALUES ('CIF000123', 'SUCCESS')

INSERT INTO m_login_log (cif_number, login_status)
VALUES ('CIF000123', 'FAILED')

SELECT cif_number, STATUS, login_attempt
FROM authentication.m_user
WHERE cif_number = 'CIF000456'
AND STATUS != 'LOCKED';



