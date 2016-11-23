CREATE TABLE change_register (
	filename varchar(225) NULL,
	change_event varchar(225) NULL,
	fullpath varchar(225) NULL,
	date_registered datetime NULL
) 
CREATE TABLE filecopy_register (
	filename varchar(225) NULL,	
	full_source_path varchar(225) NULL,
   full_destination_path varchar(225) NULL,
	date_registered datetime NULL,
   change_event varchar(225) NULL,
   log_message varchar(500) NULL
) 