use todomanager;
CREATE TABLE IF NOT EXISTS tUsers
		( UserID int NOT NULL AUTO_INCREMENT,
		  UserName varchar(25) NOT NULL UNIQUE,
		  password varchar(30) NOT NULL,
		  PRIMARY KEY(UserID)
		  );
CREATE TABLE IF NOT EXISTS tStatus
	(
		StatusID int not null PRIMARY KEY,
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
    


