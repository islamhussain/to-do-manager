use todomanager;
CREATE TABLE IF NOT EXISTS tUsers
		( UserID int NOT NULL AUTO_INCREMENT,
		  UserName varchar(25) NOT NULL UNIQUE,
		  password varchar(30) NOT NULL,
		  PRIMARY KEY(UserID)
		  );
CREATE TABLE IF NOT EXISTS tStatus
	(
		StatusID int not null PRIMARY KEY AUTO_INCREMENT,
        StatusCode varchar(30) not null
    );
CREATE TABLE IF NOT EXISTS tGoals
	(
		GoalID int NOT NULL AUTO_INCREMENT,
        GoalSummary text not null,
        GoalDescription text,
        GoalProgress int not null,
        GoalStatusID int not null,
        PRIMARY KEY (GoalID),
        FOREIGN KEY (GoalStatusID) REFERENCES tStatus(StatusID)
	);
CREATE TABLE IF NOT EXISTS tTasks
	(
		TaskID int NOT NULL AUTO_INCREMENT,
        TaskSummary text not null,
        TaskDescription text,
        TaskProgress int not null,
        TaskStatusID int not null,
        PRIMARY KEY (TaskID),
        FOREIGN KEY (TaskStatusID) REFERENCES tStatus(StatusID)
    );
CREATE TABLE IF NOT EXISTS tUsertoGoalMap
	(
		UserToGoalMapID int NOT NULL AUTO_INCREMENT,
		UserID int NOT NULL,
        GoalID int NOT NULL,
        PRIMARY KEY (UserToGoalMapID),
        FOREIGN KEY (UserID) REFERENCES tUsers(UserID),
        FOREIGN KEY (GoalID) REFERENCES tGoals(GoalID)
    );
CREATE TABLE IF NOT EXISTS tUsertoTaskMap
	(
		UserToTaskMapID int NOT NULL AUTO_INCREMENT,
		UserID int NOT NULL,
        TaskID int NOT NULL,
        PRIMARY KEY (UserToTaskMapID),
        FOREIGN KEY (UserID) REFERENCES tUsers(UserID),
        FOREIGN KEY (TaskID) REFERENCES tTasks(TaskID)
    );
CREATE TABLE IF NOT EXISTS tGoaltoTaskMap
	(
		GoalToTaskMapID int NOT NULL AUTO_INCREMENT,
		GoalID int NOT NULL,
        TaskID int NOT NULL,
        PRIMARY KEY (GoalToTaskMapID),
        FOREIGN KEY (GoalID) REFERENCES tGoals(GoalID),
        FOREIGN KEY (TaskID) REFERENCES tTasks(TaskID)
    );



DROP TRIGGER  IF EXISTS trCheckGoalSummaryIsNotEmptyOnInsert;
delimiter $$
CREATE TRIGGER trCheckGoalSummaryIsNotEmptyOnInsert
BEFORE INSERT on tGoals
FOR EACH ROW
BEGIN
IF NEW.GoalSummary = '' THEN SET NEW.GoalSummary = NULL;
END IF;
END$$
delimiter ;

DROP TRIGGER  IF EXISTS trCheckGoalSummaryIsNotEmptyOnUpdate;
delimiter $$
CREATE TRIGGER trCheckGoalSummaryIsNotEmptyOnUpdate
BEFORE UPDATE on tGoals
FOR EACH ROW
BEGIN
IF NEW.GoalSummary = '' THEN SET NEW.GoalSummary = NULL;
END IF;
END$$
delimiter ;

DROP TRIGGER  IF EXISTS trCheckTaskSummaryIsNotEmptyOnUpdate;
delimiter $$
CREATE TRIGGER trCheckTaskSummaryIsNotEmptyOnUpdate
BEFORE UPDATE on tTasks
FOR EACH ROW
BEGIN
IF NEW.TaskSummary = '' THEN SET NEW.TaskSummary = NULL;
END IF;
END$$
delimiter ;

DROP TRIGGER  IF EXISTS trCheckTaskSummaryIsNotEmptyOnInsert;
delimiter $$
CREATE TRIGGER trCheckTaskSummaryIsNotEmptyOnInsert
BEFORE INSERT on tTasks
FOR EACH ROW
BEGIN
IF NEW.TaskSummary = '' THEN SET NEW.TaskSummary = NULL;
END IF;
END$$
delimiter ;

SET GLOBAL log_bin_trust_function_creators = 1;
DROP Function  IF EXISTS validateProgress;
delimiter $$
CREATE FUNCTION validateProgress(progress int)
RETURNS boolean
BEGIN
DECLARE valid boolean default false;
IF progress = '' THEN SET progress = NULL;
ELSEIF progress < 0 THEN 
	SIGNAL SQLSTATE '45000' 
	SET MESSAGE_TEXT = "Progress can not be lesser than 0";
ELSEIF progress > 100 THEN 
	SIGNAL SQLSTATE '45000' 
	SET MESSAGE_TEXT = "Progress can not be Greater than 100";
else set valid = True;
END IF;
return valid;
end$$
delimiter ;

DROP TRIGGER  IF EXISTS trCheckGoalProgressIsValidOnUpdate;
delimiter $$
CREATE TRIGGER trCheckGoalProgressIsValidOnUpdate
BEFORE UPDATE on tGoals
FOR EACH ROW
BEGIN
 declare prog bool default false;
 select validateProgress(NEW.GoalProgress) into prog;
END$$
delimiter ;


DROP TRIGGER  IF EXISTS trCheckGoalProgressIsValidOnInsert;
delimiter $$
CREATE TRIGGER trCheckGoalProgressIsValidOnInsert
BEFORE INSERT on tGoals
FOR EACH ROW
BEGIN
declare prog bool default false;
select validateProgress(NEW.GoalProgress) into prog;
END$$
delimiter ;

DROP TRIGGER  IF EXISTS trCheckTaskProgressIsValidOnUpdate;
delimiter $$
CREATE TRIGGER trCheckTaskProgressIsValidOnUpdate
BEFORE UPDATE on tTasks
FOR EACH ROW
BEGIN
declare prog bool default false;
select validateProgress(NEW.TaskProgress) into prog;
END$$
delimiter ;

DROP TRIGGER  IF EXISTS trCheckTaskProgressIsValidOnInsert;
delimiter $$
CREATE TRIGGER trCheckTaskProgressIsValidOnInsert
BEFORE INSERT on tTasks
FOR EACH ROW
BEGIN
declare prog bool default false;
select validateProgress(NEW.TaskProgress) into prog;
END$$
delimiter ;

DROP function  IF EXISTS validateuser;
delimiter $$
create function validateuser(username varchar(25), userpass varchar(30))
returns boolean
begin
	declare valid bool default false;
    select exists (select * from tUsers u
    where u.UserName = username
    and u.password = userpass
    ) into valid;
    return valid;
end$$
delimiter ;

drop PROCEDURE if exists insert_goals;
delimiter $$
CREATE PROCEDURE insert_goals(IN username varchar(25), IN userpass varchar(30),
								 IN  goalSummary text,IN  goalDescription text,
								 In goalProgress int, In StatusCode varchar(30))
BEGIN
	declare userID int default 0;
    declare statusID int default 0;
    declare new_id int default 0;
    declare validuser int default false;
	select validateuser(username, userpass) into validuser;
    if validuser then
		select s.StatusID into statusID from tStatus s where s.StatusCode = StatusCode;
        select u.UserID into userID from tUsers u where u.UserName = username and u.password = userpass;
		INSERT into tGoals( GoalSummary, GoalDescription, GoalProgress, GoalStatusID) 
			values(goalSummary, goalDescription, goalProgress, statusID);
		SELECT LAST_INSERT_ID() INTO new_id FROM tGoals LIMIT 1;
		Insert into tUserToGoalMap(UserID, GoalID) values(userID, new_id);
	else 
		SIGNAL SQLSTATE '45000' 
		SET MESSAGE_TEXT = "Invalid User credentials, please recheck.";
	end if;
end$$
delimiter ;

drop PROCEDURE if exists insert_tasks;
delimiter $$
CREATE PROCEDURE insert_tasks(IN username varchar(25), IN userpass varchar(30),
								 IN  taskSummary text,IN  taskDescription text,
								 In taskProgress int, In StatusCode varchar(30), In goalID int)
BEGIN
	declare userID int default 0;
    declare statusID int default 0;
    declare new_id int default 0;
    declare validuser int default false;
	select validateuser(username, userpass) into validuser;
    if validuser then
		select s.StatusID into statusID from tStatus s where s.StatusCode = StatusCode;
        select u.UserID into userID from tUsers u where u.UserName = username and u.password = userpass;
		INSERT into tTasks( TaskSummary, TaskDescription, TaskProgress, TaskStatusID) 
			values(taskSummary, taskDescription, taskProgress, statusID);
		SELECT LAST_INSERT_ID() INTO new_id FROM tTasks LIMIT 1;
		Insert into tUserToTaskMap(UserID, TaskID) values(userID, new_id);
        Insert into tGoalToTaskMap(GoalID, TaskID) values(goalID, new_id);
	end if;
end$$
delimiter ;



/*
Data part
-- Inserting users
insert into tUsers (UserName, password) values('test', 'test'),('test2', 'test2');

-- Inserting staus codes
insert into tStatus (StatusCode) values('Not Started'),('In Progress'),('On Hold'), ('Completed');

-- Inserting Goals
call insert_goals('test', 'test', 'My Project', 'This is a DBMS project', 0, 'Not Started')

--Inserting Tasks
call insert_tasks('test', 'test', 'PPT', 'This task is about creating PPT for the project', 0, 'Not Started', 1)




--Invoking -ve cases
--Querying different tables and functions
select StatusID  from tStatus s where s.StatusCode = 'Not Started';
select * from tGoals
select * from tUserToGoalMap
select validateuser('test', 'test') as validuser;
*/
