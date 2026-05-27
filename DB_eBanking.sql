UPDATE m_customer
SET customer_phone='08123456789'
WHERE cif_number = 'CIF000005'

UPDATE m_account
SET product_type_id=2
WHERE account_number='1001001'

UPDATE m_account
SET product_type_id=1
WHERE account_number='1001001'

SELECT cif_number, fn_format_idr(balance) AS 'Saldo' FROM m_account WHERE cif_number = 'CIF001' 

SELECT fn_mask_account(account_number) AS 'Nomor Rekening' FROM m_account

SELECT fn_get_current_balance('1001002')
