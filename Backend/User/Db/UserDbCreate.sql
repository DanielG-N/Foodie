CREATE DATABASE UserDB
GO

USE UserDB
GO

CREATE TABLE Users(
	Id int NOT NULL PRIMARY KEY IDENTITY(1,1),
	email varchar(255),
	username varchar(255),
	password varchar(255)
)
GO
-- SELECT * FROM Items
