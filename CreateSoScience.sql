-- Creates the login SoScienceExecuter with password 'k6UwAf4K*puBTEb^'.
CREATE DATABASE SoScience;
GO

USE SoScience;
GO
CREATE LOGIN SoScienceExecuter   
	WITH PASSWORD = 'k6UwAf4K*puBTEb^';  
CREATE USER SoScienceExecuter FOR LOGIN SoScienceExecuter;  

CREATE LOGIN SoScienceExecuter   
	WITH PASSWORD = 'k6UwAf4K*puBTEb^';  
CREATE USER SoScienceExecuter FOR LOGIN SoScienceExecuter;  

GO

GO
--DROP TABLE dbo.CompletedPart
--DROP TABLE dbo.DocumentPart
--DROP TABLE dbo.Document
--DROP TABLE dbo.ProjectMember
--DROP TABLE dbo.Project
GO
CREATE TABLE Project(
	ID int IDENTITY (132, 1),
	name NVARCHAR(255) NOT NULL,
	completed BIT,
	lastEdited DATETIME,
	EndDate DATETIME,
	PRIMARY KEY(ID),
);
CREATE TABLE ProjectMember(
	ProjectID INT NOT NULL,
	username NVARCHAR(255),
	PRIMARY KEY(ProjectID,username),
	FOREIGN KEY(ProjectID) REFERENCES Project(ID), 
);
CREATE TABLE Document(
	ID INT IDENTITY (32, 1),
	ProjectID INT NOT NULL,
	Title NVARCHAR(255),
	Data text,
	PRIMARY KEY (ID),
	FOREIGN KEY (ProjectID) REFERENCES Project(ID),
);
CREATE TABLE RemoteFile(
	ID INT IDENTITY (37, 1),
	ProjectID INT NOT NULL,
	Title NVARCHAR(255),
	Type NVARCHAR(255),
	Path NVARCHAR(255),
	PRIMARY KEY (ID),
	FOREIGN KEY (ProjectID) REFERENCES Project(ID),
);
CREATE TABLE DocumentPart(
	ID INT IDENTITY (1, 1),
	Title NVARCHAR(255),
	PRIMARY KEY (ID),
);
CREATE TABLE CompletedPart(
	DocumentID INT NOT NULL,
	PartID INT NOT NULL,
	PRIMARY KEY (DocumentID, PartID),
	FOREIGN KEY (DocumentID) REFERENCES Document(ID),
	FOREIGN KEY (PartID) REFERENCES DocumentPart(ID),
);
GO

--Document overveiw
CREATE PROCEDURE SPGetDocumentsSimple @id int
AS
	SELECT ProjectID, ID,Title, (SELECT COUNT(PartID) FROM CompletedPart WHERE DocumentID = Document.ID) as completed FROM Document WHERE ProjectID = @id;
GO
CREATE PROCEDURE SPGetCompletedParts @id int
AS
	SELECT Title FROM DocumentPart WHERE ID in (SELECT PartID FROM CompletedPart WHERE DocumentID = @id );
GO

CREATE PROCEDURE SPGetDocument @id int
AS
	SELECT ProjectID, ID,Title,Data FROM Document WHERE ID = @id;
GO
CREATE PROCEDURE SPGetMissingPart @id INT
AS
	SELECT title FROM DocumentPart WHERE ID IN (SELECT PartID FROM CompletedPart WHERE DocumentID = @id);
GO
CREATE PROCEDURE SPInsertCompleted @did INT, @title NVARCHAR(255)
AS
	INSERT INTO CompletedPart (DocumentID, PartID) VALUES (@did, (SELECT id FROM DocumentPart WHERE Title = @title))
GO
CREATE PROCEDURE SPClearCompleted @did INT
AS
	DELETE FROM CompletedPart WHERE DocumentID = @did;
GO

--Document
CREATE PROCEDURE SPInsertDocument @id INT, @title NVARCHAR(255), @data text
AS
	INSERT INTO Document (ProjectID,Title,Data) VALUES (@id,@title,@data);
	SELECT @@IDENTITY as ID;
GO
CREATE PROCEDURE SPUpdateDocument @id INT, @title NVARCHAR(255), @data text
AS
	UPDATE Document SET Title = @title, Data = @data OUTPUT INSERTED.Id WHERE ID = @id;
GO
CREATE PROCEDURE SPDeleteDocument @id INT, @pid INT
AS
	IF EXISTS(select * FROM Document WHERE ID = @id AND ProjectID = @pid)
	BEGIN
		DELETE FROM CompletedPart WHERE DocumentID = @id;
		DELETE FROM Document OUTPUT deleted.Id WHERE id = @id;
	END
GO

--project
CREATE PROCEDURE SPInsertProject @username nvarchar(255), @name nvarchar(255), @completed BIT, @lastEdited DATETIME, @endDate DATETIME
AS
	INSERT INTO Project (name,completed,lastEdited,EndDate) VALUES (@name,@completed,@lastEdited,@endDate);
	DECLARE @id INT = (SELECT @@IDENTITY);
	INSERT INTO ProjectMember (ProjectID, username) VALUES (@id, @username);
	SELECT @id;
GO
CREATE PROCEDURE SPUpdateProject @id int, @name nvarchar(255), @completed BIT, @lastEdited DATETIME
AS
	UPDATE Project SET name = @name, completed = @completed, lastEdited = @lastEdited OUTPUT INSERTED.Id WHERE ID = @id;
GO
CREATE PROCEDURE SPGetProjects @username nvarchar(255)
AS
	SELECT ID,name,completed,lastEdited,EndDate FROM Project WHERE ID IN (SELECT ProjectID FROM ProjectMember WHERE username = @username)
GO
CREATE PROCEDURE SPGetProject @id int, @username nvarchar(255)
AS
	SELECT ID,name,completed,lastEdited,EndDate FROM Project WHERE ID = @id and ID in (SELECT ID FROM ProjectMember WHERE username = @username);
GO
CREATE PROCEDURE SPDeleteProject @id int, @username nvarchar(255)
AS
	IF EXISTS(select * FROM ProjectMember WHERE ProjectID = @id AND username = @username)
	BEGIN
		DELETE FROM CompletedPart WHERE DocumentID IN (SELECT ID FROM Document WHERE ProjectID = @id);
		DELETE FROM Document WHERE ProjectID = @id;
		DELETE FROM RemoteFile WHERE ProjectID = @id;
		DELETE FROM ProjectMember WHERE ProjectID = @id;
		DELETE FROM Project OUTPUT deleted.Id WHERE id = @id;
	END
	select @id as id;
GO

--Remote file
CREATE PROCEDURE SPGetRFile @id int
as
	SELECT ID,Title,ProjectID,Path,Type FROM RemoteFile WHERE ID = @id;
GO
CREATE PROCEDURE SPGetRFiles @pid int
as
	SELECT ID,Title,ProjectID,Type FROM RemoteFile WHERE ProjectID = @pid;
GO
CREATE PROCEDURE SPDeleteRFile @id int, @pid INT
as
	DELETE FROM RemoteFile OUTPUT deleted.Id as ID WHERE ID = @id AND ProjectID = @pid;
GO
CREATE PROCEDURE SPInsertRFile @title NVARCHAR(255),@pid INT,@path NVARCHAR(255), @type NVARCHAR(255)
as
	INSERT INTO RemoteFile (Title,ProjectID,Path,Type) VALUES (@title,@pid,@path,@Type);
	SELECT @@IDENTITY as ID;
GO
CREATE PROCEDURE SPUpdateRFile @id INT, @title NVARCHAR(255)
as
	Update RemoteFile Set Title = @title WHERE ID = @id;
	SELECT @id as ID;
GO

GRANT EXECUTE ON dbo.SPInsertProject TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPUpdateProject TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPDeleteProject TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPGetProjects TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPGetProject TO SoScienceExecuter;

GRANT EXECUTE ON dbo.SPGetDocumentsSimple TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPGetCompletedParts TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPGetDocument TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPGetMissingPart TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPInsertCompleted TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPClearCompleted TO SoScienceExecuter;

GRANT EXECUTE ON dbo.SPInsertDocument TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPUpdateDocument TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPDeleteDocument TO SoScienceExecuter;

GRANT EXECUTE ON dbo.SPInsertRFile TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPGetRFile TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPGetRFiles TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPDeleteRFile TO SoScienceExecuter;
GRANT EXECUTE ON dbo.SPUpdateRFile TO SoScienceExecuter;

GO 
USE SoScience;
GO
INSERT INTO DocumentPart (Title) VALUES ('Forside');
INSERT INTO DocumentPart (Title) VALUES ('Formaal');
INSERT INTO DocumentPart (Title) VALUES ('Materiale');
INSERT INTO DocumentPart (Title) VALUES ('Forsoegsopstilling');
INSERT INTO DocumentPart (Title) VALUES ('Sikkerhed');
INSERT INTO DocumentPart (Title) VALUES ('Teori');
INSERT INTO DocumentPart (Title) VALUES ('Resultater');
INSERT INTO DocumentPart (Title) VALUES ('Diskussion');
INSERT INTO DocumentPart (Title) VALUES ('Fejlkilder');
INSERT INTO DocumentPart (Title) VALUES ('Konklusion');
INSERT INTO DocumentPart (Title) VALUES ('Kilder');
GO