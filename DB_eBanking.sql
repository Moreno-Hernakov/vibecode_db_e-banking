/*
SQLyog Community v13.3.1 (64 bit)
MySQL - 8.4.3 : Database - authentication
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`authentication` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `authentication`;

/*Table structure for table `h_login_log` */

DROP TABLE IF EXISTS `h_login_log`;

CREATE TABLE `h_login_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `cif_number` varchar(20) NOT NULL,
  `login_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(50) DEFAULT NULL,
  `device_id` varchar(100) DEFAULT NULL,
  `user_agent` text,
  `status` enum('SUCCESS','FAILED','LOCKED') DEFAULT 'SUCCESS',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `h_login_log` */

insert  into `h_login_log`(`id`,`cif_number`,`login_time`,`ip_address`,`device_id`,`user_agent`,`status`) values 
(1,'CIF001','2026-05-27 18:19:25','192.168.1.10','IPHONE-15',NULL,'SUCCESS'),
(2,'CIF002','2026-05-27 18:19:25','10.20.30.45','SAMSUNG-S24',NULL,'SUCCESS'),
(3,'CIF001','2026-05-27 18:19:25','192.168.1.10','IPHONE-15',NULL,'FAILED');

/*Table structure for table `m_password_history` */

DROP TABLE IF EXISTS `m_password_history`;

CREATE TABLE `m_password_history` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  CONSTRAINT `m_password_history_ibfk_1` FOREIGN KEY (`username`) REFERENCES `m_user` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_password_history` */

insert  into `m_password_history`(`id`,`username`,`password_hash`,`created_at`) values 
(1,'budi_hartono','$2a$12$old_password_hash_budi','2026-05-27 18:19:25');

/*Table structure for table `m_user` */

DROP TABLE IF EXISTS `m_user`;

CREATE TABLE `m_user` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `cif_number` varchar(20) NOT NULL,
  `status` varchar(20) DEFAULT 'ACTIVE',
  `failed_attempts` int DEFAULT '0',
  `last_failed_login` timestamp NULL DEFAULT NULL,
  `suspend_until` timestamp NULL DEFAULT NULL,
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `cif_number` (`cif_number`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_user` */

insert  into `m_user`(`id`,`username`,`password`,`cif_number`,`status`,`failed_attempts`,`last_failed_login`,`suspend_until`,`created`,`updated`) values 
(1,'budi_hartono','$2a$12$eImiTxAk4vmMZdG84IXtneX','CIF001','ACTIVE',0,NULL,NULL,'2026-05-27 18:19:25','2026-05-27 18:19:25'),
(2,'siti_aminah','$2a$12$L8b0VbXOnW1vN9oI2K2OueE','CIF002','ACTIVE',0,NULL,NULL,'2026-05-27 18:19:25','2026-05-27 18:19:25'),
(3,'john_doe','dummy_hash','CIF003','LOCKED',0,NULL,NULL,'2026-05-27 18:19:25','2026-05-27 18:19:25');

/* Trigger structure for table `h_login_log` */

DELIMITER $$

/*!50003 DROP TRIGGER*//*!50032 IF EXISTS */ /*!50003 `trg_login_success` */$$

/*!50003 CREATE */ /*!50017 DEFINER = 'root'@'localhost' */ /*!50003 TRIGGER `trg_login_success` AFTER INSERT ON `h_login_log` FOR EACH ROW BEGIN
    IF NEW.status = 'SUCCESS' THEN
        UPDATE m_user
        SET failed_attempts = 0,
            updated = NOW()
        WHERE cif_number = NEW.cif_number;
    END IF;
END */$$


DELIMITER ;

/* Trigger structure for table `h_login_log` */

DELIMITER $$

/*!50003 DROP TRIGGER*//*!50032 IF EXISTS */ /*!50003 `trg_login_failed` */$$

/*!50003 CREATE */ /*!50017 DEFINER = 'root'@'localhost' */ /*!50003 TRIGGER `trg_login_failed` AFTER INSERT ON `h_login_log` FOR EACH ROW BEGIN
    IF NEW.status = 'FAILED' THEN
        UPDATE m_user
        SET
            failed_attempts = failed_attempts + 1,
            last_failed_login = NOW(),
            status = CASE
                WHEN failed_attempts + 1 >= 3 THEN 'LOCKED'
                ELSE status
            END,
            updated = NOW()
        WHERE cif_number = NEW.cif_number;
    END IF;
END */$$


DELIMITER ;

/* Procedure structure for procedure `sp_change_password` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_change_password` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_change_password`(
    IN p_username VARCHAR(50),
    IN p_old_password VARCHAR(255),
    IN p_new_password VARCHAR(255),
    OUT r_response_code VARCHAR(5)
)
BEGIN
    DECLARE v_current_password VARCHAR(255);
    DECLARE v_history_count INT;

    -- Error Handler: Rollback jika ada SQL Exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET r_response_code = '99'; -- System Error
    END;

    -- 1. Ambil password yang sekarang aktif
    SELECT password INTO v_current_password 
    FROM m_user WHERE username = p_username;

    -- 2. Validasi User & Password Lama
    IF v_current_password IS NULL THEN
        SET r_response_code = '01'; -- User Tidak Ditemukan
    ELSEIF v_current_password != p_old_password THEN
        SET r_response_code = '01'; -- Password Lama Salah
    ELSE
        -- 3. Cek History Password (Anti-Reuse)
        -- User nggak boleh pake password yang sama dengan yang sekarang atau yang ada di history
        SELECT COUNT(*) INTO v_history_count 
        FROM m_password_history 
        WHERE username = p_username AND password_hash = p_new_password;

        IF v_history_count > 0 OR v_current_password = p_new_password THEN
            SET r_response_code = '02'; -- Password Pernah Digunakan
        ELSE
            -- 4. Eksekusi Ganti Password (Atomic)
            START TRANSACTION;
            
            -- Pindahkan password lama ke history
            INSERT INTO m_password_history (username, password_hash)
            VALUES (p_username, v_current_password);
            
            -- Update password baru di tabel utama
            UPDATE m_user 
            SET password = p_new_password, updated = NOW() 
            WHERE username = p_username;
            
            COMMIT;
            SET r_response_code = '00'; -- Sukses
        END IF;
    END IF;
END */$$
DELIMITER ;

/* Procedure structure for procedure `sp_login_user` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_login_user` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_login_user`(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    OUT r_response_code VARCHAR(5)
)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_failed_attempts INT;
    DECLARE v_db_password VARCHAR(255);

    -- 1. Check if user exists and get status
    SELECT status, failed_attempts, password 
    INTO v_status, v_failed_attempts, v_db_password
    FROM m_user WHERE username = p_username;

    IF v_status IS NULL THEN
        SET r_response_code = "01"; -- User Not Found
    ELSEIF v_status = "LOCKED" THEN
        SET r_response_code = "02"; -- Account Locked
    ELSE
        -- 2. Check Password
        IF v_db_password = p_password THEN
            UPDATE m_user SET failed_attempts = 0 WHERE username = p_username;
            SET r_response_code = "00"; -- Success
        ELSE
            -- 3. Wrong Password Logic
            SET v_failed_attempts = v_failed_attempts + 1;
            IF v_failed_attempts >= 3 THEN
                UPDATE m_user SET status = "LOCKED", failed_attempts = v_failed_attempts WHERE username = p_username;
                SET r_response_code = "02"; -- Just locked now
            ELSE
                UPDATE m_user SET failed_attempts = v_failed_attempts WHERE username = p_username;
                SET r_response_code = "03"; -- Wrong Password
            END IF;
        END IF;
    END IF;
END */$$
DELIMITER ;

/*Table structure for table `vw_user_security_status` */

DROP TABLE IF EXISTS `vw_user_security_status`;

/*!50001 DROP VIEW IF EXISTS `vw_user_security_status` */;
/*!50001 DROP TABLE IF EXISTS `vw_user_security_status` */;

/*!50001 CREATE TABLE  `vw_user_security_status`(
 `username` varchar(50) ,
 `cif_number` varchar(20) ,
 `status` varchar(20) ,
 `failed_attempts` int ,
 `last_failed_login` timestamp ,
 `last_login_success` timestamp 
)*/;

/*View structure for view vw_user_security_status */

/*!50001 DROP TABLE IF EXISTS `vw_user_security_status` */;
/*!50001 DROP VIEW IF EXISTS `vw_user_security_status` */;

/*!50001 CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_user_security_status` AS select `u`.`username` AS `username`,`u`.`cif_number` AS `cif_number`,`u`.`status` AS `status`,`u`.`failed_attempts` AS `failed_attempts`,`u`.`last_failed_login` AS `last_failed_login`,(select max(`u`.`created`) from `h_login_log` `l` where ((`l`.`cif_number` = `u`.`cif_number`) and (`l`.`status` = 'SUCCESS'))) AS `last_login_success` from `m_user` `u` */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

/*
SQLyog Community v13.3.1 (64 bit)
MySQL - 8.4.3 : Database - dsi_mb_srd
*********************************************************************
*/

/*!40101 SET NAMES utf8 */;

/*!40101 SET SQL_MODE=''*/;

/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
CREATE DATABASE /*!32312 IF NOT EXISTS*/`dsi_mb_srd` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `dsi_mb_srd`;

/*Table structure for table `h_audit_trail` */

DROP TABLE IF EXISTS `h_audit_trail`;

CREATE TABLE `h_audit_trail` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `table_name` varchar(50) DEFAULT NULL,
  `action_type` enum('INSERT','UPDATE','DELETE') DEFAULT NULL,
  `record_id` varchar(50) DEFAULT NULL,
  `old_value` text,
  `new_value` text,
  `action_by` varchar(50) DEFAULT NULL,
  `action_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `h_audit_trail` */

insert  into `h_audit_trail`(`id`,`table_name`,`action_type`,`record_id`,`old_value`,`new_value`,`action_by`,`action_at`) values 
(1,'m_customer','INSERT','CIF001',NULL,'New Customer: Budi','ADMIN_HQ','2026-05-27 18:19:25'),
(2,'m_account','UPDATE','1001001',NULL,'Initial Deposit 5jt','SYSTEM','2026-05-27 18:19:25');

/*Table structure for table `m_account` */

DROP TABLE IF EXISTS `m_account`;

CREATE TABLE `m_account` (
  `account_number` varchar(20) NOT NULL,
  `cif_number` varchar(20) NOT NULL,
  `product_type_id` int NOT NULL,
  `balance` decimal(15,2) DEFAULT '0.00',
  `status` varchar(20) DEFAULT 'ACTIVE',
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`account_number`),
  KEY `fk_account_customer` (`cif_number`),
  KEY `fk_account_product` (`product_type_id`),
  CONSTRAINT `fk_account_customer` FOREIGN KEY (`cif_number`) REFERENCES `m_customer` (`cif_number`),
  CONSTRAINT `fk_account_product` FOREIGN KEY (`product_type_id`) REFERENCES `m_product_type` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_account` */

insert  into `m_account`(`account_number`,`cif_number`,`product_type_id`,`balance`,`status`,`created`,`updated`) values 
('1001001','CIF001',1,5000000.00,'ACTIVE','2026-05-27 18:19:25','2026-05-27 18:19:25'),
('1001002','CIF001',1,1000000.00,'ACTIVE','2026-05-27 18:19:25','2026-05-27 18:19:25'),
('2001001','CIF002',2,75000000.00,'ACTIVE','2026-05-27 18:19:25','2026-05-27 18:19:25');

/*Table structure for table `m_customer` */

DROP TABLE IF EXISTS `m_customer`;

CREATE TABLE `m_customer` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `cif_number` varchar(20) NOT NULL,
  `customer_name` varchar(100) NOT NULL,
  `customer_phone` varchar(20) DEFAULT NULL,
  `customer_email` varchar(100) DEFAULT NULL,
  `classification` int DEFAULT '1',
  `client_pin` varchar(255) NOT NULL,
  `need_authorized_unblock` tinyint(1) DEFAULT '0',
  `created` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `cif_number` (`cif_number`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_customer` */

insert  into `m_customer`(`id`,`cif_number`,`customer_name`,`customer_phone`,`customer_email`,`classification`,`client_pin`,`need_authorized_unblock`,`created`,`updated`) values 
(1,'CIF001','BUDI HARTONO','081234567890','budi@gmail.com',1,'$2a$12$hashedpin1',0,'2026-05-27 18:19:25','2026-05-27 18:19:25'),
(2,'CIF002','SITI AMINAH','081122334455','siti@gmail.com',2,'$2a$12$hashedpin2',0,'2026-05-27 18:19:25','2026-05-27 18:19:25');

/*Table structure for table `m_feature` */

DROP TABLE IF EXISTS `m_feature`;

CREATE TABLE `m_feature` (
  `feature_code` varchar(10) NOT NULL,
  `feature_name` varchar(100) NOT NULL,
  `fee` decimal(15,2) DEFAULT '0.00',
  PRIMARY KEY (`feature_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_feature` */

insert  into `m_feature`(`feature_code`,`feature_name`,`fee`) values 
('101','Transfer Sesama Bank',0.00),
('102','Transfer Antar Bank',6500.00),
('201','Pembayaran PLN',3000.00);

/*Table structure for table `m_limit` */

DROP TABLE IF EXISTS `m_limit`;

CREATE TABLE `m_limit` (
  `id` int NOT NULL AUTO_INCREMENT,
  `feature_code` varchar(10) NOT NULL,
  `classification` int NOT NULL,
  `limit_amount` decimal(15,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_limit` */

insert  into `m_limit`(`id`,`feature_code`,`classification`,`limit_amount`,`created_at`) values 
(1,'101',1,10000000.00,'2026-05-27 18:19:25'),
(2,'101',2,50000000.00,'2026-05-27 18:19:25'),
(3,'102',1,5000000.00,'2026-05-27 18:19:25');

/*Table structure for table `m_product_type` */

DROP TABLE IF EXISTS `m_product_type`;

CREATE TABLE `m_product_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `product_name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_product_type` */

insert  into `m_product_type`(`id`,`product_name`) values 
(1,'TABUNGAN'),
(2,'GIRO'),
(3,'DEPOSITO');

/*Table structure for table `m_response_code` */

DROP TABLE IF EXISTS `m_response_code`;

CREATE TABLE `m_response_code` (
  `response_code` varchar(5) NOT NULL,
  `response_message` varchar(150) NOT NULL,
  PRIMARY KEY (`response_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `m_response_code` */

insert  into `m_response_code`(`response_code`,`response_message`) values 
('00','Success'),
('51','Insufficient Fund'),
('61','Exceeds Daily Limit'),
('68','External Timeout'),
('99','System Error');

/*Table structure for table `t_transaction` */

DROP TABLE IF EXISTS `t_transaction`;

CREATE TABLE `t_transaction` (
  `id_transaction` bigint NOT NULL AUTO_INCREMENT,
  `reference_number` varchar(50) NOT NULL,
  `cif_number` varchar(20) NOT NULL,
  `from_account_number` varchar(20) NOT NULL,
  `customer_reference` varchar(50) NOT NULL,
  `transaction_amount` decimal(15,2) NOT NULL,
  `fee` decimal(15,2) NOT NULL,
  `transaction_status` varchar(20) NOT NULL,
  `transaction_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `feature_code` varchar(10) DEFAULT NULL,
  `response_code` varchar(5) DEFAULT NULL,
  `ipaddress` varchar(50) DEFAULT NULL,
  `biller_name` varchar(100) DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id_transaction`),
  UNIQUE KEY `reference_number` (`reference_number`),
  KEY `fk_trx_customer` (`cif_number`),
  KEY `fk_trx_account` (`from_account_number`),
  KEY `fk_trx_feature` (`feature_code`),
  KEY `fk_trx_response` (`response_code`),
  CONSTRAINT `fk_trx_account` FOREIGN KEY (`from_account_number`) REFERENCES `m_account` (`account_number`),
  CONSTRAINT `fk_trx_customer` FOREIGN KEY (`cif_number`) REFERENCES `m_customer` (`cif_number`),
  CONSTRAINT `fk_trx_feature` FOREIGN KEY (`feature_code`) REFERENCES `m_feature` (`feature_code`),
  CONSTRAINT `fk_trx_response` FOREIGN KEY (`response_code`) REFERENCES `m_response_code` (`response_code`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*Data for the table `t_transaction` */

insert  into `t_transaction`(`id_transaction`,`reference_number`,`cif_number`,`from_account_number`,`customer_reference`,`transaction_amount`,`fee`,`transaction_status`,`transaction_date`,`feature_code`,`response_code`,`ipaddress`,`biller_name`,`location`) values 
(1,'TRX-001','CIF001','1001001','2001001',500000.00,0.00,'SUCCESS','2026-05-27 18:19:25','101','00','192.168.1.10',NULL,'MOBILE-APPS'),
(2,'TRX-002','CIF001','1001002','2001001',2000000.00,0.00,'FAILED','2026-05-27 18:19:25','101','51','192.168.1.10',NULL,'MOBILE-APPS'),
(3,'TRX-003','CIF002','2001001','900800700',1000000.00,6500.00,'SUCCESS','2026-05-27 18:19:25','102','00','10.20.30.45',NULL,'MOBILE-APPS'),
(4,'TRX-004','CIF001','1001001','5432109876',150000.00,3000.00,'SUCCESS','2026-05-27 18:19:25','201','00','192.168.1.10','PLN PRABAYAR','MOBILE-APPS');

/* Trigger structure for table `m_account` */

DELIMITER $$

/*!50003 DROP TRIGGER*//*!50032 IF EXISTS */ /*!50003 `trg_audit_account` */$$

/*!50003 CREATE */ /*!50017 DEFINER = 'root'@'localhost' */ /*!50003 TRIGGER `trg_audit_account` AFTER UPDATE ON `m_account` FOR EACH ROW BEGIN
	-- produk
	IF NOT (OLD.product_type_id <=> NEW.product_type_id) THEN
        INSERT INTO h_audit_trail (
            TABLE_NAME,
            action_type,
            record_id,
            old_value,
            new_value,
            action_by
        )
        VALUES (
            'm_account',
            'UPDATE',
            OLD.account_number,
            OLD.product_type_id,
            NEW.product_type_id,
            CURRENT_USER()
        );
    END IF;

    -- balance
    IF NOT (OLD.balance <=> NEW.balance) THEN
        INSERT INTO h_audit_trail (
            TABLE_NAME,
            action_type,
            record_id,
            old_value,
            new_value,
            action_by
        )
        VALUES (
            'm_account',
            'UPDATE',
            OLD.account_number,
            OLD.balance,
            NEW.balance,
            CURRENT_USER()
        );
    END IF;
    
     -- status
    IF NOT (OLD.status <=> NEW.status) THEN
        INSERT INTO h_audit_trail (
            TABLE_NAME,
            action_type,
            record_id,
            old_value,
            new_value,
            action_by
        )
        VALUES (
            'm_account',
            'UPDATE',
            OLD.account_number,
            OLD.status,
            NEW.status,
            CURRENT_USER()
        );
    END IF;
    END */$$


DELIMITER ;

/* Trigger structure for table `m_customer` */

DELIMITER $$

/*!50003 DROP TRIGGER*//*!50032 IF EXISTS */ /*!50003 `trg_audit_customer` */$$

/*!50003 CREATE */ /*!50017 DEFINER = 'root'@'localhost' */ /*!50003 TRIGGER `trg_audit_customer` AFTER UPDATE ON `m_customer` FOR EACH ROW BEGIN
	IF NOT (OLD.customer_email <=> NEW.customer_email) THEN
        INSERT INTO h_audit_trail (
            TABLE_NAME,
            action_type,
            record_id,
            old_value,
            new_value,
            action_by
        )
        VALUES (
            'm_customer',
            'UPDATE',
            OLD.cif_number,
            OLD.customer_email,
            NEW.customer_email,
            CURRENT_USER()
        );
    END IF;

    -- NO TELP
    IF NOT (OLD.customer_phone <=> NEW.customer_phone) THEN
        INSERT INTO h_audit_trail (
            TABLE_NAME,
            action_type,
            record_id,
            old_value,
            new_value,
            action_by
        )
        VALUES (
            'm_customer',
            'UPDATE',
            OLD.cif_number,
            OLD.customer_phone,
            NEW.customer_phone,
            CURRENT_USER()
        );
    END IF;
    
     -- NAMA
    IF NOT (OLD.customer_name <=> NEW.customer_name) THEN
        INSERT INTO h_audit_trail (
            TABLE_NAME,
            action_type,
            record_id,
            old_value,
            new_value,
            action_by
        )
        VALUES (
            'm_customer',
            'UPDATE',
            OLD.cif_number,
            OLD.customer_name,
            NEW.customer_name,
            CURRENT_USER()
        );
    END IF;
    
     -- PIN
    IF NOT (OLD.client_pin <=> NEW.client_pin) THEN
        INSERT INTO h_audit_trail (
            TABLE_NAME,
            action_type,
            record_id,
            old_value,
            new_value,
            action_by
        )
        VALUES (
            'm_customer',
            'UPDATE',
            OLD.cif_number,
            OLD.client_pin,
            NEW.client_pin,
            CURRENT_USER()
        );
    END IF;
    END */$$


DELIMITER ;

/* Function  structure for function  `fn_format_idr` */

/*!50003 DROP FUNCTION IF EXISTS `fn_format_idr` */;
DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` FUNCTION `fn_format_idr`(rupiah decimal(15,2)) RETURNS varchar(20) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
	DECLARE uang_rupiah VARCHAR(20);
	SET uang_rupiah=CONCAT('Rp ', FORMAT(rupiah,0,'id_ID'));
	RETURN uang_rupiah;
    END */$$
DELIMITER ;

/* Function  structure for function  `fn_get_current_balance` */

/*!50003 DROP FUNCTION IF EXISTS `fn_get_current_balance` */;
DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` FUNCTION `fn_get_current_balance`(param_acc_number VARCHAR(20)) RETURNS varchar(20) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
	DECLARE saldo DECIMAL(15,2);
	DECLARE saldo_rupiah VARCHAR(20);
	
	SELECT balance INTO saldo FROM m_account
	WHERE account_number = param_acc_number
	ORDER BY updated DESC
	LIMIT 1;
	
	SET saldo_rupiah = CONCAT('Rp ', FORMAT(saldo,0,'id_ID'));
	RETURN saldo_rupiah;
    END */$$
DELIMITER ;

/* Function  structure for function  `fn_mask_account` */

/*!50003 DROP FUNCTION IF EXISTS `fn_mask_account` */;
DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` FUNCTION `fn_mask_account`(param_acc_number VARCHAR(20)) RETURNS varchar(20) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
	DECLARE nomor_rekening VARCHAR(20);
	SET nomor_rekening=CONCAT(SUBSTRING(param_acc_number, 1, 2), 'xxx', SUBSTRING(param_acc_number, 6, 2));
	RETURN nomor_rekening;
    END */$$
DELIMITER ;

/* Procedure structure for procedure `mutasi` */

/*!50003 DROP PROCEDURE IF EXISTS  `mutasi` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `mutasi`(IN nomor_cif VARCHAR(20))
BEGIN
    SELECT 
        mc.cif_number,
        mc.customer_name,
        t.reference_number, 
        t.transaction_amount,
        t.biller_name, 
        mf.fee, 
        mr.response_message, 
        t.transaction_date, 
        t.location 
    FROM t_transaction t
    JOIN m_customer mc ON mc.cif_number = t.cif_number
    JOIN m_feature mf ON mf.feature_code = t.feature_code
    JOIN m_response_code mr ON mr.response_code = t.response_code
    WHERE mc.cif_number = nomor_cif 
    AND DATE(t.transaction_date) = CURDATE()
    ORDER BY t.transaction_date DESC;
END */$$
DELIMITER ;

/* Procedure structure for procedure `sp_fund_transfer` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_fund_transfer` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_fund_transfer`(
    IN p_from_account VARCHAR(20),
    IN p_to_account VARCHAR(20),
    IN p_amount DECIMAL(15, 2),
    IN p_feature_code VARCHAR(10),
    IN p_cif_number VARCHAR(20),
    IN p_ip_address VARCHAR(50),
    OUT r_response_code VARCHAR(5),
    OUT r_reference_number VARCHAR(50)
)
BEGIN
    DECLARE v_from_balance DECIMAL(15, 2);
    DECLARE v_from_status VARCHAR(20);
    DECLARE v_to_status VARCHAR(20);
    DECLARE v_fee DECIMAL(15, 2);
    DECLARE v_classification INT;
    DECLARE v_daily_limit DECIMAL(15, 2);
    DECLARE v_total_today DECIMAL(15, 2);
    DECLARE v_ref_no VARCHAR(50);
    
    -- Error Handler: Rollback jika ada SQL Exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET r_response_code = '99'; -- System Error
    END;

    -- Generate Reference Number via SP
    CALL sp_generate_reference('TRX', v_ref_no);
    SET r_reference_number = v_ref_no;

    -- 1. Get Initial Data & Validation
    SELECT balance, status INTO v_from_balance, v_from_status 
    FROM m_account WHERE account_number = p_from_account;
    
    SELECT status INTO v_to_status 
    FROM m_account WHERE account_number = p_to_account;
    
    SELECT fee INTO v_fee 
    FROM m_feature WHERE feature_code = p_feature_code;
    
    SELECT classification INTO v_classification 
    FROM m_customer WHERE cif_number = p_cif_number;

    -- 2. Business Rules Validation
    IF v_from_status IS NULL OR v_to_status IS NULL THEN
        SET r_response_code = '14'; -- Invalid Account
    ELSEIF v_from_status != 'ACTIVE' OR v_to_status != 'ACTIVE' THEN
        SET r_response_code = '14'; -- Account Blocked/Inactive
    ELSEIF v_from_balance < (p_amount + v_fee) THEN
        SET r_response_code = '51'; -- Insufficient Fund
    ELSE
        -- 3. Daily Limit Validation
        SELECT limit_amount INTO v_daily_limit 
        FROM m_limit 
        WHERE feature_code = p_feature_code AND classification = v_classification;

        SELECT IFNULL(SUM(transaction_amount), 0) INTO v_total_today 
        FROM t_transaction 
        WHERE cif_number = p_cif_number 
        AND feature_code = p_feature_code 
        AND transaction_status = 'SUCCESS'
        AND DATE(transaction_date) = CURDATE();

        IF (v_total_today + p_amount) > v_daily_limit THEN
            SET r_response_code = '61'; -- Exceeds Daily Limit
        ELSE
            -- 4. Execution (Atomic)
            START TRANSACTION;
            
            -- Potong Saldo Pengirim
            UPDATE m_account 
            SET balance = balance - (p_amount + v_fee) 
            WHERE account_number = p_from_account;
            
            -- Tambah Saldo Penerima
            UPDATE m_account 
            SET balance = balance + p_amount 
            WHERE account_number = p_to_account;
            
            -- Catat Transaksi
            INSERT INTO t_transaction (
                reference_number, cif_number, from_account_number, customer_reference, 
                transaction_amount, fee, transaction_status, feature_code, 
                response_code, ipaddress, location
            ) VALUES (
                v_ref_no, p_cif_number, p_from_account, p_to_account, 
                p_amount, v_fee, 'SUCCESS', p_feature_code, 
                '00', p_ip_address, 'MOBILE-APPS'
            );
            
            COMMIT;
            SET r_response_code = '00'; -- Success
        END IF;
    END IF;

    -- Jika Gagal (selain System Error 99), tetap catat sebagai Failed Transaction
    IF r_response_code != '00' AND r_response_code != '99' THEN
        INSERT INTO t_transaction (
            reference_number, cif_number, from_account_number, customer_reference, 
            transaction_amount, fee, transaction_status, feature_code, 
            response_code, ipaddress, location
        ) VALUES (
            v_ref_no, p_cif_number, p_from_account, p_to_account, 
            p_amount, IFNULL(v_fee, 0), 'FAILED', p_feature_code, 
            r_response_code, p_ip_address, 'MOBILE-APPS'
        );
    END IF;
END */$$
DELIMITER ;

/* Procedure structure for procedure `sp_generate_reference` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_generate_reference` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_reference`(
    IN p_prefix VARCHAR(10),
    OUT r_reference_number VARCHAR(50)
)
BEGIN
    -- Format: PREFIX-YYYYMMDDHHMMSS-RAND(3)
    SET r_reference_number = CONCAT(
        p_prefix, '-', 
        DATE_FORMAT(NOW(), '%Y%m%d%H%i%s'), '-', 
        LPAD(FLOOR(RAND() * 1000), 3, '0')
    );
END */$$
DELIMITER ;

/* Procedure structure for procedure `sp_register_customer` */

/*!50003 DROP PROCEDURE IF EXISTS  `sp_register_customer` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_register_customer`(
    IN p_customer_name VARCHAR(100),
    IN p_customer_phone VARCHAR(20),
    IN p_customer_email VARCHAR(100),
    IN p_client_pin VARCHAR(255),
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    OUT r_response_code VARCHAR(5),
    OUT r_cif_number VARCHAR(20)
)
BEGIN
    DECLARE v_new_id BIGINT;
    DECLARE v_new_cif VARCHAR(20);
    
    -- Error Handler: Rollback jika ada SQL Exception
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET r_response_code = '99'; -- System Error
        SET r_cif_number = NULL;
    END;

    START TRANSACTION;

    -- 1. Insert ke Master Customer (Temporary CIF)
    INSERT INTO m_customer (customer_name, customer_phone, customer_email, cif_number, client_pin)
    VALUES (p_customer_name, p_customer_phone, p_customer_email, 'TEMP_CIF', p_client_pin);

    -- 2. Ambil ID yang barusan digenerate & buat CIF_NUMBER
    SET v_new_id = LAST_INSERT_ID();
    SET v_new_cif = CONCAT('CIF', LPAD(v_new_id, 6, '0'));

    -- 3. Update CIF_NUMBER yang bener di Customer
    UPDATE m_customer SET cif_number = v_new_cif WHERE id = v_new_id;

    -- 4. Insert ke Authentication Database
    INSERT INTO authentication.m_user (username, password, cif_number, status)
    VALUES (p_username, p_password, v_new_cif, 'ACTIVE');

    COMMIT;

    SET r_response_code = '00'; -- Success
    SET r_cif_number = v_new_cif;
END */$$
DELIMITER ;

/* Procedure structure for procedure `tutup_buku` */

/*!50003 DROP PROCEDURE IF EXISTS  `tutup_buku` */;

DELIMITER $$

/*!50003 CREATE DEFINER=`root`@`localhost` PROCEDURE `tutup_buku`()
BEGIN
    SELECT 
        mc.cif_number,
        mc.customer_name,
        COUNT(*) AS 'Total', 
        SUM(transaction_amount) AS 'Jumlah Transaksi' 
    FROM t_transaction t
    JOIN m_customer mc ON mc.cif_number = t.cif_number
    WHERE DATE(t.transaction_date) = CURDATE()
    GROUP BY mc.cif_number, mc.customer_name;
END */$$
DELIMITER ;

/*Table structure for table `lihat_transaksi` */

DROP TABLE IF EXISTS `lihat_transaksi`;

/*!50001 DROP VIEW IF EXISTS `lihat_transaksi` */;
/*!50001 DROP TABLE IF EXISTS `lihat_transaksi` */;

/*!50001 CREATE TABLE  `lihat_transaksi`(
 `cif_number` varchar(20) ,
 `customer_name` varchar(100) ,
 `transaction_amount` decimal(15,2) ,
 `feature_name` varchar(100) ,
 `fee` decimal(15,2) 
)*/;

/*Table structure for table `vw_customer_portfolio` */

DROP TABLE IF EXISTS `vw_customer_portfolio`;

/*!50001 DROP VIEW IF EXISTS `vw_customer_portfolio` */;
/*!50001 DROP TABLE IF EXISTS `vw_customer_portfolio` */;

/*!50001 CREATE TABLE  `vw_customer_portfolio`(
 `cif_number` varchar(20) ,
 `customer_name` varchar(100) ,
 `total_accounts` bigint ,
 `total_balance` decimal(37,2) ,
 `classification_name` varchar(7) 
)*/;

/*Table structure for table `vw_daily_transaction_report` */

DROP TABLE IF EXISTS `vw_daily_transaction_report`;

/*!50001 DROP VIEW IF EXISTS `vw_daily_transaction_report` */;
/*!50001 DROP TABLE IF EXISTS `vw_daily_transaction_report` */;

/*!50001 CREATE TABLE  `vw_daily_transaction_report`(
 `transaction_date` timestamp ,
 `reference_number` varchar(50) ,
 `customer_name` varchar(100) ,
 `feature_name` varchar(100) ,
 `amount` decimal(15,2) ,
 `fee` decimal(15,2) ,
 `transaction_status` varchar(20) ,
 `response_message` varchar(150) 
)*/;

/*View structure for view lihat_transaksi */

/*!50001 DROP TABLE IF EXISTS `lihat_transaksi` */;
/*!50001 DROP VIEW IF EXISTS `lihat_transaksi` */;

/*!50001 CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `lihat_transaksi` AS select `t`.`cif_number` AS `cif_number`,`mc`.`customer_name` AS `customer_name`,`t`.`transaction_amount` AS `transaction_amount`,`mf`.`feature_name` AS `feature_name`,`mf`.`fee` AS `fee` from ((`t_transaction` `t` join `m_customer` `mc` on((`mc`.`cif_number` = `t`.`cif_number`))) join `m_feature` `mf` on((`mf`.`feature_code` = `t`.`feature_code`))) where (`t`.`transaction_date` >= (now() - interval 7 day)) */;

/*View structure for view vw_customer_portfolio */

/*!50001 DROP TABLE IF EXISTS `vw_customer_portfolio` */;
/*!50001 DROP VIEW IF EXISTS `vw_customer_portfolio` */;

/*!50001 CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_customer_portfolio` AS select `mc`.`cif_number` AS `cif_number`,`mc`.`customer_name` AS `customer_name`,count(`ma`.`account_number`) AS `total_accounts`,sum(`ma`.`balance`) AS `total_balance`,(case when (`mc`.`classification` = 1) then 'REGULER' when (`mc`.`classification` = 2) then 'GOLD' else 'UNKNOWN' end) AS `classification_name` from (`m_customer` `mc` left join `m_account` `ma` on((`mc`.`cif_number` = `ma`.`cif_number`))) group by `mc`.`cif_number`,`mc`.`customer_name`,`mc`.`classification` */;

/*View structure for view vw_daily_transaction_report */

/*!50001 DROP TABLE IF EXISTS `vw_daily_transaction_report` */;
/*!50001 DROP VIEW IF EXISTS `vw_daily_transaction_report` */;

/*!50001 CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_daily_transaction_report` AS select `t`.`transaction_date` AS `transaction_date`,`t`.`reference_number` AS `reference_number`,`mc`.`customer_name` AS `customer_name`,`mf`.`feature_name` AS `feature_name`,`t`.`transaction_amount` AS `amount`,`t`.`fee` AS `fee`,`t`.`transaction_status` AS `transaction_status`,`mr`.`response_message` AS `response_message` from (((`t_transaction` `t` join `m_customer` `mc` on((`t`.`cif_number` = `mc`.`cif_number`))) join `m_feature` `mf` on((`t`.`feature_code` = `mf`.`feature_code`))) join `m_response_code` `mr` on((`t`.`response_code` = `mr`.`response_code`))) where (cast(`t`.`transaction_date` as date) = curdate()) */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;



