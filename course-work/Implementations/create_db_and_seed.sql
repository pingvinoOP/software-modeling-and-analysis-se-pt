SET NOCOUNT ON;
USE Cults3D_DB;
GO

--DROP OBJECTS IF THEY ALREADY EXIST--
IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL DROP TABLE dbo.Users;
IF OBJECT_ID(N'dbo.Designers', N'U') IS NOT NULL DROP TABLE dbo.Designers;
IF OBJECT_ID(N'dbo.Categories', N'U') IS NOT NULL DROP TABLE dbo.Categories;
IF OBJECT_ID(N'dbo.Tags', N'U') IS NOT NULL DROP TABLE dbo.Tags;
IF OBJECT_ID(N'dbo.Models', N'U') IS NOT NULL DROP TABLE dbo.Models;
IF OBJECT_ID(N'dbo.Purchases', N'U') IS NOT NULL DROP TABLE dbo.Purchases;
IF OBJECT_ID(N'dbo.Downloads', N'U') IS NOT NULL DROP TABLE dbo.Downloads;
IF OBJECT_ID(N'dbo.Comments', N'U') IS NOT NULL DROP TABLE dbo.Comments;
IF OBJECT_ID(N'dbo.Ratings', N'U') IS NOT NULL DROP TABLE dbo.Ratings;
IF OBJECT_ID(N'dbo.Collections', N'U') IS NOT NULL DROP TABLE dbo.Collections;
IF OBJECT_ID(N'dbo.ModelCategories', N'U') IS NOT NULL DROP TABLE dbo.ModelCategories;
IF OBJECT_ID(N'dbo.ModelTags', N'U') IS NOT NULL DROP TABLE dbo.ModelTags;
IF OBJECT_ID(N'dbo.CollectionModels', N'U') IS NOT NULL DROP TABLE dbo.CollectionModels;
IF OBJECT_ID(N'dbo.DownloadsAudit', N'U') IS NOT NULL DROP TABLE dbo.DownloadsAudit;
IF OBJECT_ID(N'dbo.vModelRatingSummary', N'V') IS NOT NULL DROP VIEW dbo.vModelRatingSummary;
GO

--USERS--
CREATE TABLE dbo.Users (
  UserID       INT IDENTITY(1,1) NOT NULL,
  Username     NVARCHAR(50)  NOT NULL,
  Email        NVARCHAR(100) NOT NULL,
  PasswordHash NVARCHAR(255) NOT NULL,
  Country      NVARCHAR(50)  NULL,
  JoinDate     DATETIME      NOT NULL CONSTRAINT DF_Users_JoinDate DEFAULT (GETDATE()),
  IsDesigner   BIT           NOT NULL CONSTRAINT DF_Users_IsDesigner DEFAULT (0),
  CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserID),
  CONSTRAINT UQ_Users_Username UNIQUE (Username),
  CONSTRAINT UQ_Users_Email    UNIQUE (Email)
);
GO

--DESIGNERS--
CREATE TABLE dbo.Designers (
  DesignerID INT NOT NULL,  --same as Users.UserID--
  Bio        NVARCHAR(255) NULL,
  Website    NVARCHAR(255) NULL,
  Verified   BIT NOT NULL CONSTRAINT DF_Designers_Verified DEFAULT (0),
  CONSTRAINT PK_Designers PRIMARY KEY CLUSTERED (DesignerID),
  CONSTRAINT FK_Designers_Users
    FOREIGN KEY (DesignerID) REFERENCES dbo.Users(UserID)
      ON DELETE CASCADE
);
GO

--CATEGORIES--
CREATE TABLE dbo.Categories (
  CategoryID INT IDENTITY(1,1) NOT NULL,
  Name       NVARCHAR(50) NOT NULL,
  CONSTRAINT PK_Categories PRIMARY KEY CLUSTERED (CategoryID),
  CONSTRAINT UQ_Categories_Name UNIQUE (Name)
);
GO

--TAGS--
CREATE TABLE dbo.Tags (
  TagID INT IDENTITY(1,1) NOT NULL,
  Name  NVARCHAR(50) NOT NULL,
  CONSTRAINT PK_Tags PRIMARY KEY CLUSTERED (TagID),
  CONSTRAINT UQ_Tags_Name UNIQUE (Name)
);
GO

--MODELS--
CREATE TABLE dbo.Models (
  ModelID      INT IDENTITY(1,1) NOT NULL,
  Title        NVARCHAR(100)  NOT NULL,
  Description  NVARCHAR(1000) NULL,
  Price        DECIMAL(10,2)  NOT NULL CONSTRAINT DF_Models_Price DEFAULT (0),
  UploadDate   DATETIME       NOT NULL CONSTRAINT DF_Models_UploadDate DEFAULT (GETDATE()),
  FileURL      NVARCHAR(255)  NOT NULL,
  ThumbnailURL NVARCHAR(255)  NULL,
  DesignerID   INT            NOT NULL,
  License      NVARCHAR(50)   NULL,
  IsFree       BIT            NOT NULL CONSTRAINT DF_Models_IsFree DEFAULT (0),
  CONSTRAINT PK_Models PRIMARY KEY CLUSTERED (ModelID),
  CONSTRAINT FK_Models_Designers
    FOREIGN KEY (DesignerID) REFERENCES dbo.Designers(DesignerID)
      ON DELETE NO ACTION,
  CONSTRAINT CK_Models_Price_NonNegative CHECK (Price >= 0)
);
GO

CREATE INDEX IX_Models_DesignerID ON dbo.Models(DesignerID);
GO

--CACHE AVERAGE RATING PER MODEL--
ALTER TABLE dbo.Models
ADD AverageRating DECIMAL(4,2) NULL;
GO

--PURCHASES--
CREATE TABLE dbo.Purchases (
  PurchaseID    INT IDENTITY(1,1) NOT NULL,
  UserID        INT           NOT NULL,
  ModelID       INT           NOT NULL,
  PurchaseDate  DATETIME      NOT NULL CONSTRAINT DF_Purchases_Date DEFAULT (GETDATE()),
  Amount        DECIMAL(10,2) NOT NULL,
  Currency      CHAR(3)       NOT NULL CONSTRAINT DF_Purchases_Currency DEFAULT ('USD'),
  PaymentMethod NVARCHAR(30)  NULL,
  CONSTRAINT PK_Purchases PRIMARY KEY CLUSTERED (PurchaseID),
  CONSTRAINT FK_Purchases_Users  FOREIGN KEY (UserID)  REFERENCES dbo.Users(UserID),
  CONSTRAINT FK_Purchases_Models FOREIGN KEY (ModelID) REFERENCES dbo.Models(ModelID),
  CONSTRAINT CK_Purchases_Amount_NonNegative CHECK (Amount >= 0)
);
GO

CREATE INDEX IX_Purchases_UserID  ON dbo.Purchases(UserID);
CREATE INDEX IX_Purchases_ModelID ON dbo.Purchases(ModelID);
GO

--DOWNLOADS--
CREATE TABLE dbo.Downloads (
  DownloadID   INT IDENTITY(1,1) NOT NULL,
  UserID       INT          NOT NULL,
  ModelID      INT          NOT NULL,
  DownloadDate DATETIME     NOT NULL CONSTRAINT DF_Downloads_Date DEFAULT (GETDATE()),
  Source       NVARCHAR(30) NULL, --direct / after_purchase / etc--
  CONSTRAINT PK_Downloads PRIMARY KEY CLUSTERED (DownloadID),
  CONSTRAINT FK_Downloads_Users  FOREIGN KEY (UserID)  REFERENCES dbo.Users(UserID),
  CONSTRAINT FK_Downloads_Models FOREIGN KEY (ModelID) REFERENCES dbo.Models(ModelID)
);
GO

CREATE INDEX IX_Downloads_UserID  ON dbo.Downloads(UserID);
CREATE INDEX IX_Downloads_ModelID ON dbo.Downloads(ModelID);
GO

--COMMENTS--
CREATE TABLE dbo.Comments (
  CommentID       INT IDENTITY(1,1) NOT NULL,
  UserID          INT              NOT NULL,
  ModelID         INT              NOT NULL,
  CommentText     NVARCHAR(1000)   NOT NULL,
  CreatedAt       DATETIME         NOT NULL CONSTRAINT DF_Comments_CreatedAt DEFAULT (GETDATE()),
  ParentCommentID INT              NULL,
  CONSTRAINT PK_Comments PRIMARY KEY CLUSTERED (CommentID),
  CONSTRAINT FK_Comments_Users   FOREIGN KEY (UserID)
      REFERENCES dbo.Users(UserID),
  CONSTRAINT FK_Comments_Models  FOREIGN KEY (ModelID)
      REFERENCES dbo.Models(ModelID),
  CONSTRAINT FK_Comments_Parent  FOREIGN KEY (ParentCommentID)
      REFERENCES dbo.Comments(CommentID)
);
GO

CREATE INDEX IX_Comments_ModelID ON dbo.Comments(ModelID);
CREATE INDEX IX_Comments_UserID  ON dbo.Comments(UserID);
CREATE INDEX IX_Comments_Parent  ON dbo.Comments(ParentCommentID);
GO

--RATINGS--
CREATE TABLE dbo.Ratings (
  RatingID  INT IDENTITY(1,1) NOT NULL,
  UserID    INT NOT NULL,
  ModelID   INT NOT NULL,
  Score     INT NOT NULL,
  CreatedAt DATETIME NOT NULL CONSTRAINT DF_Ratings_CreatedAt DEFAULT (GETDATE()),
  CONSTRAINT PK_Ratings PRIMARY KEY CLUSTERED (RatingID),
  CONSTRAINT FK_Ratings_Users  FOREIGN KEY (UserID)  REFERENCES dbo.Users(UserID),
  CONSTRAINT FK_Ratings_Models FOREIGN KEY (ModelID) REFERENCES dbo.Models(ModelID),
  CONSTRAINT CK_Ratings_Score CHECK (Score BETWEEN 1 AND 5),
  CONSTRAINT UQ_Ratings_User_Model UNIQUE (UserID, ModelID)
);
GO

CREATE INDEX IX_Ratings_ModelID ON dbo.Ratings(ModelID);
GO

--COLLECTIONS--
CREATE TABLE dbo.Collections (
  CollectionID INT IDENTITY(1,1) NOT NULL,
  UserID       INT           NOT NULL,  --owner--
  Name         NVARCHAR(100) NOT NULL,
  CreatedAt    DATETIME      NOT NULL CONSTRAINT DF_Collections_CreatedAt DEFAULT (GETDATE()),
  Visibility   NVARCHAR(10)  NULL,
  CONSTRAINT PK_Collections PRIMARY KEY CLUSTERED (CollectionID),
  CONSTRAINT FK_Collections_Users FOREIGN KEY (UserID) REFERENCES dbo.Users(UserID),
  CONSTRAINT CK_Collections_Visibility CHECK (Visibility IN (N'public', N'private')),
  CONSTRAINT UQ_Collections_User_Name UNIQUE (UserID, Name)
);
GO

CREATE INDEX IX_Collections_UserID ON dbo.Collections(UserID);
GO

--MODEL <-> CATEGORY MANY2MANY--
CREATE TABLE dbo.ModelCategories (
  ModelID    INT NOT NULL,
  CategoryID INT NOT NULL,
  CONSTRAINT PK_ModelCategories PRIMARY KEY CLUSTERED (ModelID, CategoryID),
  CONSTRAINT FK_ModelCategories_Models
    FOREIGN KEY (ModelID) REFERENCES dbo.Models(ModelID) ON DELETE CASCADE,
  CONSTRAINT FK_ModelCategories_Categories
    FOREIGN KEY (CategoryID) REFERENCES dbo.Categories(CategoryID) ON DELETE CASCADE
);
GO

--MODEL <-> TAG MANY2MANY--
CREATE TABLE dbo.ModelTags (
  ModelID INT NOT NULL,
  TagID   INT NOT NULL,
  CONSTRAINT PK_ModelTags PRIMARY KEY CLUSTERED (ModelID, TagID),
  CONSTRAINT FK_ModelTags_Models FOREIGN KEY (ModelID) REFERENCES dbo.Models(ModelID) ON DELETE CASCADE,
  CONSTRAINT FK_ModelTags_Tags   FOREIGN KEY (TagID)   REFERENCES dbo.Tags(TagID)   ON DELETE CASCADE
);
GO

--COLLECTION <-> MODEL MANY2MANY--
CREATE TABLE dbo.CollectionModels (
  CollectionID INT NOT NULL,
  ModelID      INT NOT NULL,
  AddedAt      DATETIME NOT NULL CONSTRAINT DF_CollectionModels_AddedAt DEFAULT (GETDATE()),
  CONSTRAINT PK_CollectionModels PRIMARY KEY CLUSTERED (CollectionID, ModelID),
  CONSTRAINT FK_CollectionModels_Collections
    FOREIGN KEY (CollectionID) REFERENCES dbo.Collections(CollectionID) ON DELETE CASCADE,
  CONSTRAINT FK_CollectionModels_Models
    FOREIGN KEY (ModelID) REFERENCES dbo.Models(ModelID) ON DELETE CASCADE
);
GO

--VIEW: SUMMARY OF RATINGS--
CREATE VIEW dbo.vModelRatingSummary AS
SELECT
  m.ModelID,
  m.Title,
  COUNT(r.RatingID) AS RatingsCount,
  AVG(CAST(r.Score AS DECIMAL(5,2))) AS AverageScore
FROM dbo.Models m
LEFT JOIN dbo.Ratings r ON r.ModelID = m.ModelID
GROUP BY m.ModelID, m.Title;
GO

--SEED DATA--

--USERS--
INSERT INTO Users (Username, Email, PasswordHash, Country, JoinDate, IsDesigner) VALUES
('makerjoe',      'joe@example.com',        'hash_joe',      'USA',       DATEADD(DAY,-180, GETDATE()), 1),
('sofia_maker',   'sofia@example.bg',       'hash_sofia',    'Bulgaria',  DATEADD(DAY,-150, GETDATE()), 1),
('designhub',     'hub@example.com',        'hash_hub',      'Portugal',  DATEADD(DAY,-120, GETDATE()), 1),
('printgirl',     'sara@example.com',       'hash_sara',     'UK',        DATEADD(DAY,-100, GETDATE()), 0),
('proBuyer',      'probuyer@example.com',   'hash_pb',       'Germany',   DATEADD(DAY,-90,  GETDATE()), 0),
('casual_user',   'casual@example.com',     'hash_casual',   'France',    DATEADD(DAY,-70,  GETDATE()), 0),
('eurobuyer',     'euro@example.eu',        'hash_euro',     'Italy',     DATEADD(DAY,-60,  GETDATE()), 0),
('bulgarian_user','bg.user@example.bg',     'hash_bg',       'Bulgaria',  DATEADD(DAY,-45,  GETDATE()), 0),
('reviewer1',     'rev1@example.com',       'hash_r1',       'USA',       DATEADD(DAY,-30,  GETDATE()), 0),
('reviewer2',     'rev2@example.com',       'hash_r2',       'Spain',     DATEADD(DAY,-20,  GETDATE()), 0);
GO

--DESIGNERS--
INSERT INTO Designers (DesignerID, Bio, Website, Verified)
SELECT UserID, 'Functional & articulated models', 'https://cults3d.com/@makerjoe', 1
FROM Users WHERE Username = 'makerjoe';

INSERT INTO Designers (DesignerID, Bio, Website, Verified)
SELECT UserID, 'Cosplay & props designer', 'https://cults3d.com/@sofia_maker', 1
FROM Users WHERE Username = 'sofia_maker';

INSERT INTO Designers (DesignerID, Bio, Website, Verified)
SELECT UserID, 'Low-poly & decorative art', 'https://cults3d.com/@designhub', 0
FROM Users WHERE Username = 'designhub';
GO

--CATEGORIES--
INSERT INTO Categories (Name) VALUES
('Miniatures'), ('Household'), ('Tools'), ('Cosplay'),
('Art'), ('Gadgets');
GO

--TAGS--
INSERT INTO Tags (Name) VALUES
('articulated'), ('low-poly'), ('vase-mode'), ('fdm-friendly'),
('supportless'), ('terrain'), ('functional'), ('mechanical'),
('cosplay'), ('miniature');
GO

--MODELS--
INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Articulated Dragon', 'Poseable dragon with snap joints', 4.99,
       DATEADD(DAY,-110,GETDATE()), 'https://files/dragon.stl', 'https://thumbs/dragon.png',
       d.DesignerID, 'CC-BY', 0
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'makerjoe';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Cable Organizer', 'Clip system to manage cables on desks', 0.00,
       DATEADD(DAY,-105,GETDATE()), 'https://files/cableclip.stl', 'https://thumbs/cableclip.png',
       d.DesignerID, 'CC0', 1
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'makerjoe';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Low-Poly Fox', 'Stylized fox figurine', 1.99,
       DATEADD(DAY,-95,GETDATE()), 'https://files/fox.stl', 'https://thumbs/fox.png',
       d.DesignerID, 'CC-BY', 0
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'designhub';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Vase Spiral', 'Single-wall spiral vase for vase-mode', 0.00,
       DATEADD(DAY,-92,GETDATE()), 'https://files/vase.stl', 'https://thumbs/vase.png',
       d.DesignerID, 'CC0', 1
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'designhub';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Cosplay Helmet MK1', 'Printable helmet shell with inserts', 12.00,
       DATEADD(DAY,-88,GETDATE()), 'https://files/helmet.stl', 'https://thumbs/helmet.png',
       d.DesignerID, 'Standard', 0
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'sofia_maker';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Phone Stand Adjustable', 'Angle-adjustable phone stand', 2.49,
       DATEADD(DAY,-80,GETDATE()), 'https://files/stand.stl', 'https://thumbs/stand.png',
       d.DesignerID, 'CC-BY', 0
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'makerjoe';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Dungeon Door Set', 'Miniature doors for tabletop terrain', 3.50,
       DATEADD(DAY,-75,GETDATE()), 'https://files/doors.stl', 'https://thumbs/doors.png',
       d.DesignerID, 'CC-BY-SA', 0
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'designhub';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Parametric Storage Box', 'Customizable storage box with lid', 0.00,
       DATEADD(DAY,-70,GETDATE()), 'https://files/box.stl', 'https://thumbs/box.png',
       d.DesignerID, 'CC0', 1
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'makerjoe';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Garden Gnome Statue', 'Cute gnome decoration', 1.50,
       DATEADD(DAY,-65,GETDATE()), 'https://files/gnome.stl', 'https://thumbs/gnome.png',
       d.DesignerID, 'CC-BY', 0
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'designhub';

INSERT INTO Models (Title, Description, Price, UploadDate, FileURL, ThumbnailURL, DesignerID, License, IsFree)
SELECT 'Cosplay Shoulder Armor', 'Segmented pauldron pieces', 5.00,
       DATEADD(DAY,-60,GETDATE()), 'https://files/pauldron.stl', 'https://thumbs/pauldron.png',
       d.DesignerID, 'Standard', 0
FROM Designers d JOIN Users u ON d.DesignerID = u.UserID
WHERE u.Username = 'sofia_maker';
GO

--MODEL <-> CATEGORY MANY2MANY--
INSERT INTO ModelCategories (ModelID, CategoryID)
SELECT m.ModelID, c.CategoryID FROM Models m CROSS JOIN Categories c
WHERE (m.Title IN ('Articulated Dragon') AND c.Name IN ('Miniatures','Art'))
   OR (m.Title IN ('Cable Organizer')   AND c.Name IN ('Household','Gadgets'))
   OR (m.Title IN ('Low-Poly Fox')      AND c.Name IN ('Art','Miniatures'))
   OR (m.Title IN ('Vase Spiral')       AND c.Name IN ('Art','Household'))
   OR (m.Title IN ('Cosplay Helmet MK1')AND c.Name IN ('Cosplay','Gadgets'))
   OR (m.Title IN ('Phone Stand Adjustable') AND c.Name IN ('Gadgets','Household'))
   OR (m.Title IN ('Dungeon Door Set')  AND c.Name IN ('Miniatures','Tools'))
   OR (m.Title IN ('Parametric Storage Box') AND c.Name IN ('Household','Tools'))
   OR (m.Title IN ('Garden Gnome Statue') AND c.Name IN ('Art'))
   OR (m.Title IN ('Cosplay Shoulder Armor') AND c.Name IN ('Cosplay'));
GO

--MODEL <-> TAG MANY2MANY--
INSERT INTO ModelTags (ModelID, TagID)
SELECT m.ModelID, t.TagID FROM Models m CROSS JOIN Tags t
WHERE (m.Title='Articulated Dragon'       AND t.Name IN ('articulated','fdm-friendly','miniature'))
   OR (m.Title='Cable Organizer'          AND t.Name IN ('functional','supportless'))
   OR (m.Title='Low-Poly Fox'             AND t.Name IN ('low-poly','miniature'))
   OR (m.Title='Vase Spiral'              AND t.Name IN ('vase-mode','fdm-friendly'))
   OR (m.Title='Cosplay Helmet MK1'       AND t.Name IN ('cosplay','mechanical'))
   OR (m.Title='Phone Stand Adjustable'   AND t.Name IN ('functional','mechanical'))
   OR (m.Title='Dungeon Door Set'         AND t.Name IN ('terrain','miniature'))
   OR (m.Title='Parametric Storage Box'   AND t.Name IN ('functional','supportless'))
   OR (m.Title='Garden Gnome Statue'      AND t.Name IN ('articulated'))
   OR (m.Title='Cosplay Shoulder Armor'   AND t.Name IN ('cosplay','mechanical'));
GO

--COLLECTIONS--
INSERT INTO Collections (UserID, Name, CreatedAt, Visibility)
SELECT u.UserID, 'Cosplay Ideas', DATEADD(DAY,-40,GETDATE()), 'public'
FROM Users u WHERE u.Username='printgirl';

INSERT INTO Collections (UserID, Name, CreatedAt, Visibility)
SELECT u.UserID, 'Desk Helpers',  DATEADD(DAY,-35,GETDATE()), 'public'
FROM Users u WHERE u.Username='proBuyer';

INSERT INTO Collections (UserID, Name, CreatedAt, Visibility)
SELECT u.UserID, 'Free Prints',   DATEADD(DAY,-30,GETDATE()), 'private'
FROM Users u WHERE u.Username='casual_user';
GO

--COLLECTION <-> MODEL MANY2MANY--
INSERT INTO CollectionModels (CollectionID, ModelID, AddedAt)
SELECT c.CollectionID, m.ModelID, DATEADD(DAY,-28,GETDATE())
FROM Collections c JOIN Models m ON m.Title IN ('Cosplay Helmet MK1','Cosplay Shoulder Armor')
WHERE c.Name='Cosplay Ideas';

INSERT INTO CollectionModels (CollectionID, ModelID, AddedAt)
SELECT c.CollectionID, m.ModelID, DATEADD(DAY,-25,GETDATE())
FROM Collections c JOIN Models m ON m.Title IN ('Cable Organizer','Phone Stand Adjustable','Parametric Storage Box')
WHERE c.Name='Desk Helpers';

INSERT INTO CollectionModels (CollectionID, ModelID, AddedAt)
SELECT c.CollectionID, m.ModelID, DATEADD(DAY,-22,GETDATE())
FROM Collections c JOIN Models m ON m.Title IN ('Vase Spiral','Cable Organizer','Parametric Storage Box')
WHERE c.Name='Free Prints';
GO

--PURCHASES / TRANSACTIONS--
INSERT INTO Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-55,GETDATE()), 12.00, 'USD', 'Card'
FROM Users u CROSS JOIN Models m
WHERE u.Username='printgirl' AND m.Title='Cosplay Helmet MK1';

INSERT INTO Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-54,GETDATE()), 5.00, 'EUR', 'PayPal'
FROM Users u CROSS JOIN Models m
WHERE u.Username='proBuyer' AND m.Title='Cosplay Shoulder Armor';

INSERT INTO Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-53,GETDATE()), 4.99, 'USD', 'Card'
FROM Users u CROSS JOIN Models m
WHERE u.Username='eurobuyer' AND m.Title='Articulated Dragon';

INSERT INTO Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-50,GETDATE()), 1.99, 'USD', 'Card'
FROM Users u CROSS JOIN Models m
WHERE u.Username='bulgarian_user' AND m.Title='Low-Poly Fox';

INSERT INTO Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-48,GETDATE()), 3.50, 'USD', 'Card'
FROM Users u CROSS JOIN Models m
WHERE u.Username='reviewer1' AND m.Title='Dungeon Door Set';

INSERT INTO Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-46,GETDATE()), 2.49, 'USD', 'Card'
FROM Users u CROSS JOIN Models m
WHERE u.Username='reviewer2' AND m.Title='Phone Stand Adjustable';

INSERT INTO Purchases (UserID, ModelID, PurchaseDate, Amount, Currency, PaymentMethod)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-45,GETDATE()), 1.50, 'USD', 'Card'
FROM Users u CROSS JOIN Models m
WHERE u.Username='proBuyer' AND m.Title='Garden Gnome Statue';
GO

--DOWNLOADS (FREE MODELS + AFTER PURCHASE)--
INSERT INTO Downloads (UserID, ModelID, DownloadDate, Source)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-52,GETDATE()), 'direct'
FROM Users u CROSS JOIN Models m
WHERE u.Username IN ('casual_user','proBuyer','eurobuyer','bulgarian_user')
  AND m.Title IN ('Vase Spiral','Cable Organizer','Parametric Storage Box');

INSERT INTO Downloads (UserID, ModelID, DownloadDate, Source)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-44,GETDATE()), 'after_purchase'
FROM Users u JOIN Models m ON m.Title='Articulated Dragon'
WHERE u.Username='eurobuyer';

INSERT INTO Downloads (UserID, ModelID, DownloadDate, Source)
SELECT u.UserID, m.ModelID, DATEADD(DAY,-43,GETDATE()), 'after_purchase'
FROM Users u JOIN Models m ON m.Title='Cosplay Helmet MK1'
WHERE u.Username='printgirl';
GO

--RATINGS / REVIEWS--
INSERT INTO Ratings (UserID, ModelID, Score, CreatedAt)
SELECT u.UserID, m.ModelID, 5, DATEADD(DAY,-42,GETDATE())
FROM Users u JOIN Models m ON m.Title='Articulated Dragon'
WHERE u.Username IN ('reviewer1');

INSERT INTO Ratings (UserID, ModelID, Score, CreatedAt)
SELECT u.UserID, m.ModelID, 4, DATEADD(DAY,-41,GETDATE())
FROM Users u JOIN Models m ON m.Title='Low-Poly Fox'
WHERE u.Username='bulgarian_user';

INSERT INTO Ratings (UserID, ModelID, Score, CreatedAt)
SELECT u.UserID, m.ModelID, 5, DATEADD(DAY,-40,GETDATE())
FROM Users u JOIN Models m ON m.Title='Cosplay Helmet MK1'
WHERE u.Username='printgirl';

INSERT INTO Ratings (UserID, ModelID, Score, CreatedAt)
SELECT u.UserID, m.ModelID, 3, DATEADD(DAY,-39,GETDATE())
FROM Users u JOIN Models m ON m.Title='Garden Gnome Statue'
WHERE u.Username='proBuyer';

INSERT INTO Ratings (UserID, ModelID, Score, CreatedAt)
SELECT u.UserID, m.ModelID, 4, DATEADD(DAY,-38,GETDATE())
FROM Users u JOIN Models m ON m.Title='Dungeon Door Set'
WHERE u.Username='reviewer1';

INSERT INTO Ratings (UserID, ModelID, Score, CreatedAt)
SELECT u.UserID, m.ModelID, 5, DATEADD(DAY,-37,GETDATE())
FROM Users u JOIN Models m ON m.Title='Phone Stand Adjustable'
WHERE u.Username='reviewer2';
GO

--COMMENTS / FEEDBACK--
INSERT INTO Comments (UserID, ModelID, CommentText, CreatedAt, ParentCommentID)
SELECT u.UserID, m.ModelID, 'Printed great at 0.2mm, no supports needed!', DATEADD(DAY,-36,GETDATE()), NULL
FROM Users u JOIN Models m ON m.Title='Cable Organizer'
WHERE u.Username='proBuyer';

INSERT INTO Comments (UserID, ModelID, CommentText, CreatedAt, ParentCommentID)
SELECT u.UserID, m.ModelID, 'Amazing detail on the joints!', DATEADD(DAY,-35,GETDATE()), NULL
FROM Users u JOIN Models m ON m.Title='Articulated Dragon'
WHERE u.Username='reviewer1';

INSERT INTO Comments (UserID, ModelID, CommentText, CreatedAt, ParentCommentID)
SELECT u.UserID, m.ModelID, 'Scaled to 70% for my head—fits perfectly.', DATEADD(DAY,-34,GETDATE()), NULL
FROM Users u JOIN Models m ON m.Title='Cosplay Helmet MK1'
WHERE u.Username='printgirl';

INSERT INTO Comments (UserID, ModelID, CommentText, CreatedAt, ParentCommentID)
SELECT u.UserID, m.ModelID, 'Worked well as terrain for my campaign.', DATEADD(DAY,-33,GETDATE()), NULL
FROM Users u JOIN Models m ON m.Title='Dungeon Door Set'
WHERE u.Username='reviewer2';

INSERT INTO Comments (UserID, ModelID, CommentText, CreatedAt, ParentCommentID)
SELECT u.UserID, m.ModelID, 'Beautiful vase—printed in PETG vase-mode.', DATEADD(DAY,-32,GETDATE()), NULL
FROM Users u JOIN Models m ON m.Title='Vase Spiral'
WHERE u.Username='casual_user';
GO
