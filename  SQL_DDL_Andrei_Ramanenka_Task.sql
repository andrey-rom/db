CREATE DATABASE mountaineering_club

DROP TABLE IF EXISTS Climbers CASCADE;
DROP TABLE IF EXISTS Mountains CASCADE;
DROP TABLE IF EXISTS Climbs CASCADE;
DROP TABLE IF EXISTS Climber_Mountain CASCADE;
DROP TABLE IF EXISTS Equipment CASCADE;
DROP TABLE IF EXISTS Climber_Equipment CASCADE;
DROP TABLE IF EXISTS Guides CASCADE;
DROP TABLE IF EXISTS Mountain_Guides CASCADE;
DROP TABLE IF EXISTS Weather_Conditions CASCADE;
DROP TABLE IF EXISTS Climb_Weather CASCADE;
DROP TABLE IF EXISTS Accidents CASCADE;
DROP TABLE IF EXISTS Rescue_Teams CASCADE;


CREATE TABLE Climbers (
  Climber_ID serial PRIMARY KEY,
  First_Name varchar NOT NULL,
  Last_Name varchar NOT NULL,
  Address varchar NOT NULL,
  Email varchar NOT NULL,
  Phone varchar NOT NULL,
  Weight int NOT NULL,
  CONSTRAINT chk_weight CHECK (Weight >= 0),
  CONSTRAINT chk_unique_email UNIQUE (Email),
  CONSTRAINT chk_unique_phone UNIQUE (Phone)
);

CREATE TABLE Mountains (
  Mountain_ID serial PRIMARY KEY,
  Mountain_Name varchar NOT NULL,
  Height int NOT NULL,
  Country varchar NOT NULL,
  Area varchar NOT NULL,
  Complexity_Level varchar NOT NULL,
  CONSTRAINT chk_height CHECK (Height >= 0),
  CONSTRAINT chk_country CHECK (Country IN ('Nepal', 'China', 'India', 'United States', 'Canada', 'Russia', 'France', 'Switzerland', 'Italy', 'Japan')),
  CONSTRAINT chk_complexity_level CHECK (Complexity_Level IN ('Easy', 'Medium', 'Hard'))
);

CREATE TABLE Climbs (
  Climb_ID serial PRIMARY KEY,
  Climber_ID int NOT NULL,
  Mountain_ID int NOT NULL,
  Start_Date date NOT NULL,
  End_Date date NOT NULL,
  Traveled_Route varchar DEFAULT 'Empty!',
  Notes text DEFAULT 'Empty!',
  CONSTRAINT fk_climber_id FOREIGN KEY (Climber_ID) REFERENCES Climbers (Climber_ID),
  CONSTRAINT fk_mountain_id FOREIGN KEY (Mountain_ID) REFERENCES Mountains (Mountain_ID),
  CONSTRAINT chk_start_date CHECK (Start_Date > '2000-01-01'),
  CONSTRAINT chk_end_date CHECK (End_Date > '2000-01-01')
);

CREATE TABLE Climber_Mountain (
  Climber_ID int NOT NULL,
  Mountain_ID int NOT NULL,
  CONSTRAINT fk_climber_id FOREIGN KEY (Climber_ID) REFERENCES Climbers (Climber_ID),
  CONSTRAINT fk_mountain_id FOREIGN KEY (Mountain_ID) REFERENCES Mountains (Mountain_ID)
);

CREATE TABLE Equipment (
  Equipment_ID serial PRIMARY KEY,
  Equipment_Name varchar NOT NULL,
  Category varchar NOT NULL,
  Description text DEFAULT 'Empty!'
);

CREATE TABLE Climber_Equipment (
  Climber_ID int NOT NULL,
  Equipment_ID int NOT NULL,
  CONSTRAINT fk_climber_id FOREIGN KEY (Climber_ID) REFERENCES Climbers (Climber_ID),
  CONSTRAINT fk_equipment_id FOREIGN KEY (Equipment_ID) REFERENCES Equipment (Equipment_ID)
);

CREATE TABLE Guides (
  Guide_ID serial PRIMARY KEY,
  Guide_Name varchar NOT NULL,
  Certification_Level varchar NOT NULL,
  Contact_Info varchar NOT NULL,
  CONSTRAINT chk_certification_level CHECK (Certification_Level IN ('Beginner', 'Intermediate', 'Advanced'))
);

CREATE TABLE Mountain_Guides (
  Mountain_ID int NOT NULL,
  Guide_ID int NOT NULL,
  CONSTRAINT fk_mountain_id FOREIGN KEY (Mountain_ID) REFERENCES Mountains (Mountain_ID),
  CONSTRAINT fk_guide_id FOREIGN KEY (Guide_ID) REFERENCES Guides (Guide_ID)
);

CREATE TABLE Weather_Conditions (
  Condition_ID serial PRIMARY KEY,
  Condition_Name varchar NOT NULL,
  Description text DEFAULT 'Empty!'
);

CREATE TABLE Climb_Weather (
  Climb_ID int NOT NULL,
  Condition_ID int NOT NULL,
  CONSTRAINT fk_climb_id FOREIGN KEY (Climb_ID) REFERENCES Climbs (Climb_ID),
  CONSTRAINT fk_condition_id FOREIGN KEY (Condition_ID) REFERENCES Weather_Conditions (Condition_ID)
);

CREATE TABLE Accidents (
  AccidentID serial PRIMARY KEY,
  Climb_ID int NOT NULL,
  Date date NOT NULL,
  Description text DEFAULT 'Empty!',
  CONSTRAINT fk_climb_id FOREIGN KEY (Climb_ID) REFERENCES Climbs (Climb_ID),
  CONSTRAINT chk_date CHECK (Date > '2000-01-01')  
);


CREATE TABLE Rescue_Teams (
  Team_ID serial PRIMARY KEY,
  Team_Name varchar,
  Contact_Info varchar NOT NULL,
  Mountain_ID int NOT NULL,
  CONSTRAINT chk_team_name UNIQUE (Team_Name),
  CONSTRAINT fk_mountain_id FOREIGN KEY (Mountain_ID) REFERENCES Mountains (Mountain_ID)
);



INSERT INTO Climbers (Climber_ID, First_Name, Last_Name, Address, Email, Phone, Weight)
VALUES
  (1, 'Alice', 'Wonderland', '5566 Looking-Glass Street', 'alice.wonderland@email.com', '+1 771-1234', 45),
  (2, 'Jane', 'Smith', '456 Elm Avenue', 'janesmith@example.com', '987-654-3210', 62),
  (4, 'Alex', 'Johnson', '789 Oak Lane', 'alexjohnson@example.com', '555-123-4567', 68),
  (3, 'Michael', 'Brown', '567 Pine Road', 'michaelbrown@example.com', '111-222-3333', 70);


INSERT INTO Mountains (Mountain_Name, Height, Country, Area, Complexity_Level)
VALUES
  ('Mount Everest', 8848, 'Nepal', 'Himalayas', 'Hard'),
  ('Denali', 6190, 'United States', 'Alaska', 'Easy');


INSERT INTO Climbs (Climber_ID, Mountain_ID, Start_Date, End_Date, Traveled_Route, Notes)
VALUES
  (1, 1, '2020-05-01', '2020-05-20', 'South Col Route', 'Reached the summit successfully.'),
  (4, 1, '2024-08-01', '2024-08-10', 'West Buttress Route', 'Experienced heavy snowfall during the ascent.'),
  (2, 2, '2023-06-01', '2023-06-15', 'Standard Route', 'Encountered challenging weather conditions.');


INSERT INTO Climber_Mountain (Climber_ID, Mountain_ID)
VALUES
  (1, 1),
  (2, 1),
  (3, 2),
  (4, 1);


INSERT INTO Equipment (Equipment_Name, Category, Description)
VALUES
  ('Ice Axe', 'Climbing Gear', 'An essential tool for ice climbing.'),
  ('Sleeping Bag', 'Camping Gear', 'Insulated bag for sleeping in cold conditions.');


INSERT INTO Climber_Equipment (Climber_ID, Equipment_ID)
VALUES
  (1, 1),
  (1, 2);


INSERT INTO Guides (Guide_Name, Certification_Level, Contact_Info)
VALUES
  ('Robert Smith', 'Beginner', 'robertsmith@example.com'),
  ('Daniel Thompson', 'Intermediate', 'danielthompson@example.com');


INSERT INTO Weather_Conditions (Condition_Name, Description)
VALUES
  ('Clear', 'Sunny and clear skies.'),
  ('Cloudy', 'Partly cloudy with some cloud cover.'),
  ('Rainy', 'Light rain.'),
  ('Snowy', 'Heavy snowfall, low visibility.'),
  ('Foggy', 'Thick fog reducing visibility.');


INSERT INTO Climb_Weather (Climb_ID, Condition_ID)
VALUES
  (1, 1),
  (1, 2);


INSERT INTO Accidents (Climb_ID, Date, Description)
VALUES
  (1, '2021-07-20', 'Developed altitude sickness and had to be evacuated.'),
  (2, '2023-08-05', 'Lost equipment during a snowstorm.');


INSERT INTO Rescue_Teams (Team_Name, Contact_Info, Mountain_ID)
VALUES
  ('Everest Rescue', 'everestrescue@example.com', 1),
  ('Himalayan Assistance', 'himalayanassistance@example.com', 1),
  ('Capricorns', 'capricorns.rescue@email.com', 2);


ALTER TABLE Climbers
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Climbers
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Mountains
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Mountains
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Climbs
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Climbs
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Climber_Mountain
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Climber_Mountain
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Equipment
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Equipment
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Climber_Equipment
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Climber_Equipment
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Guides
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Guides
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Mountain_Guides
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Mountain_Guides
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Weather_Conditions
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Weather_Conditions
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Climb_Weather
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Climb_Weather
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Accidents
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Accidents
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;


ALTER TABLE Rescue_Teams
ADD COLUMN record_ts date DEFAULT CURRENT_DATE;


UPDATE Rescue_Teams
SET record_ts = CURRENT_DATE
WHERE record_ts IS NULL;
