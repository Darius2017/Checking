-- --
-- Update an existing OTRS database from 1.2 to 1.3 
-- Copyright (C) 2001-2004 Martin Edenhofer <martin+code@otrs.org>
-- --
-- $Id: DBUpdate-to-1.3.mysql.sql,v 1.3 2004-05-10 12:57:02 martin Exp $
-- --
--
-- usage: cat DBUpdate-to-1.3.mysql.sql | mysql -f -u root otrs
--
-- --

--
-- drop not used ticket log types
--
DELETE FROM ticket_history_type WHERE name = 'WatingForClose+';
DELETE FROM ticket_history_type WHERE name = 'WatingForClose-';
DELETE FROM ticket_history_type WHERE name = 'WatingForReminder';
DELETE FROM ticket_history_type WHERE name = 'Open';
DELETE FROM ticket_history_type WHERE name = 'Reopen';
DELETE FROM ticket_history_type WHERE name = 'Close unsuccessful';
DELETE FROM ticket_history_type WHERE name = 'Close successful';
DELETE FROM ticket_history_type WHERE name = 'SetPending';

--
-- new ticket history stuff
--
INSERT INTO ticket_history_type
        (name, valid_id, create_by, create_time, change_by, change_time)
        VALUES
        ('TicketLinkAdd', 1, 1, current_timestamp, 1, current_timestamp);
INSERT INTO ticket_history_type
        (name, valid_id, create_by, create_time, change_by, change_time)
        VALUES
        ('TicketLinkDelete', 1, 1, current_timestamp, 1, current_timestamp);

--
-- alter article table (just a bug in mysql script!)
--
ALTER TABLE article CHANGE ticket_id ticket_id BIGINT;

--
-- add more attachment info
--
ALTER TABLE article_attachment ADD content_size VARCHAR (30);


--
-- change max customer user login size
--
ALTER TABLE group_customer_user CHANGE user_id user_id VARCHAR (100);

--
-- postmaster filter table
--
CREATE TABLE postmaster_filter
(
    f_name varchar (200) NOT NULL,
    f_type varchar (20) NOT NULL,
    f_key varchar (200) NOT NULL,
    f_value varchar (200) NOT NULL
);

