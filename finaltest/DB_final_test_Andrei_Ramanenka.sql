drop table if exists task_log;
drop table if exists task_status;
drop table if exists project_team;
drop table if exists team_role;
drop table if exists team_member;
drop table if exists task;
drop table if exists project;

create table project(
	project_id serial primary key,
	project_name text not null unique);

insert into project(project_name) values
('P1'), ('P2'), ('P3');

create table task(
	task_id serial primary key,
	task_name text not null,
	project_id int not null,
	foreign key (project_id) references project(project_id));

insert into task(task_name, project_id) values
('T1P1', 1), ('T2P1', 1), ('T3P1', 1), 
('T1P2', 2), ('T2P2', 2), 
('T1P3', 3), ('T2P3', 3), ('T3P3', 3), ('T4P3', 3);

create table team_member(
	member_id serial primary key,
	name text not null);

insert into team_member(name) values
('TM1'), ('TM2'), ('TM3'), ('TM4'), ('TM5');

create table team_role(
	role_id serial primary key,
	role_name text not null unique);

insert into team_role(role_name) values
('Dev'), ('Test'), ('Manager');

create table project_team(
	project_id int,
	member_id int,
	role_id int,
	constraint pk_project_team primary key (project_id, member_id, role_id),
	foreign key (project_id) references project(project_id),
	foreign key (member_id) references team_member(member_id),
	foreign key (role_id) references team_role(role_id));

insert into project_team(project_id, member_id, role_id) values 
(1, 1, 1), (1, 2, 1), (1, 3, 3), (1, 4, 2),
(2, 2, 1), (2, 5, 2), (2, 1, 3),
(3, 3, 3), (3, 2, 1), (3, 1, 2);

create table task_status(
	status_id serial primary key,
	status_name text not null unique);
	
insert into task_status(status_name) values
('ToDo'), ('InProgress'), ('InTest'), ('Done');

create table task_log(
	task_log_id serial primary key,
	task_id int not null,
	member_id int not null,
	status_id int not null,
	assign_date date,
	foreign key (task_id) references task(task_id),
	foreign key (member_id) references team_member(member_id),
	foreign key (status_id) references task_status(status_id)
);

insert into task_log(task_id, member_id, status_id, assign_date) values
(1, 2, 2, '2024-01-02'),
(2, 2, 1, '2024-01-04'),
(3, 3, 4, '2023-12-23'),
(4, 5, 3, '2024-12-23'),
(5, 1, 2, '2024-01-08'),
(6, 3, 4, '2024-01-02'),
(7, 2, 2, '2024-02-02'),
(8, 1, 2, '2024-01-12'),
(9, 3, 2, '2024-01-25');


/*
1.
In the current database version, information regarding task status and assignment details are stored
in the same table. It's necessary to extend the schema to allow separate storage for 'status' and
'responsible person'. Additionally, there is a requirement to keep track of the history of changes to
both 'status' and 'assignment' for each task.

Write a script to update the database schema to meet these requirements. If you create new
table(s), write a data migration script that will move the current data to the appropriate enhanced
structures while preserving existing information.
*/

CREATE TABLE task_assignment (
  assignment_id SERIAL PRIMARY KEY,
  task_id INT NOT NULL,
  member_id INT NOT NULL,
  assigned_date DATE,
  FOREIGN KEY (task_id) REFERENCES task(task_id),
  FOREIGN KEY (member_id) REFERENCES team_member(member_id)
);

CREATE TABLE task_status_history (
  history_id SERIAL PRIMARY KEY,
  task_id INT NOT NULL,
  status_id INT NOT NULL,
  status_date DATE,
  FOREIGN KEY (task_id) REFERENCES task(task_id),
  FOREIGN KEY (status_id) REFERENCES task_status(status_id)
);

INSERT INTO task_assignment (task_id, member_id, assigned_date)
SELECT task_id, member_id, assign_date FROM task_log;

INSERT INTO task_status_history (task_id, status_id, status_date)
SELECT task_id, status_id, assign_date FROM task_log;

/*
2.
Create a View that facilitates the retrieval of all tasks associated with a particular project. The View
should include information on the current status of each task, as well as the name of the individual
to whom the task is assigned.
*/

CREATE VIEW project_tasks AS
SELECT p.project_name, t.task_name, ts.status_name, tm.name AS assigned_member
FROM project p
JOIN task t ON t.project_id = p.project_id
JOIN task_assignment ta ON ta.task_id = t.task_id
JOIN task_status_history tsh ON t.task_id = tsh.task_id
JOIN team_member tm ON ta.member_id = tm.member_id
JOIN task_status ts ON tsh.status_id = ts.status_id
WHERE tsh.status_date = (SELECT MAX(status_date) FROM task_status_history WHERE task_id = t.task_id);

/*
3.
Write a query that returns the name of projects along with the corresponding team roster, including
the role of each team member.
*/

SELECT
    p.project_name,
    tm.name AS team_member,
    tr.role_name
FROM
    project p
JOIN
    project_team pt ON p.project_id = pt.project_id
JOIN
    team_member tm ON pt.member_id = tm.member_id
JOIN
    team_role tr ON pt.role_id = tr.role_id
ORDER BY
    p.project_name, tm.name;

/*
4.
Develop a stored procedure to assign a task to a specific team member. The procedure should take
as input parameters the task's ID and the team member's ID. It must validate that the particular
team member is indeed part of the project team associated with the task. If the validation fails, the
procedure should raise an exception.
*/

CREATE OR REPLACE PROCEDURE assign_task(p_task_id INT, p_member_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Use the prefixed parameters p_task_id and p_member_id to avoid ambiguity
  IF NOT EXISTS (
    SELECT 1 FROM project_team WHERE member_id = p_member_id AND project_id = (
      SELECT project_id FROM task WHERE task_id = p_task_id
    )
  ) THEN
    RAISE EXCEPTION 'Member not part of the project team';
  END IF;

  INSERT INTO task_assignment (task_id, member_id, assigned_date)
  VALUES (p_task_id, p_member_id, CURRENT_DATE);
END;
$$;

/*
5.
Write a query that retrieves the history of a task. This should include the statuses the task has
transitioned through, when these statuses were updated, along with who the task was assigned to
and when that assignment took place.
*/

SELECT
    t.task_name,
    ts.status_name,
    tsh.status_date AS status_changed_on,
    tm.name AS assigned_to,
    ta.assigned_date AS assigned_on
FROM
    task t
JOIN
    task_status_history tsh ON t.task_id = tsh.task_id
JOIN
    task_status ts ON tsh.status_id = ts.status_id
JOIN
    task_assignment ta ON t.task_id = ta.task_id
JOIN
    team_member tm ON ta.member_id = tm.member_id
WHERE t.task_id = 1;

/*
6.
Write commands to add a new task for a project "P3" with "ToDo" status and assign the task to a
manager.
*/

DO $$
DECLARE
    new_task_id INT;
    manager_id INT;
BEGIN
    -- Insert the new task and retrieve its ID
    INSERT INTO task (task_name, project_id) VALUES ('P3', 3) RETURNING task_id INTO new_task_id;

    -- Select a manager's member_id for the project "P3"
    SELECT member_id INTO manager_id FROM project_team WHERE role_id = (SELECT role_id FROM team_role WHERE role_name = 'Manager') AND project_id = 3 LIMIT 1;

    -- Assign this task to the manager
    INSERT INTO task_assignment (task_id, member_id, assigned_date) VALUES (new_task_id, manager_id, CURRENT_DATE);

    -- Set the initial status to 'ToDo'
    INSERT INTO task_status_history (task_id, status_id, status_date) VALUES (new_task_id, (SELECT status_id FROM task_status WHERE status_name = 'ToDo'), CURRENT_DATE);
END $$;

/*
7.
Write commands to add a new task for a project "P3" with "ToDo" status and assign the task to a
manager.
*/


SELECT
    p.project_name,
    tm.name AS team_member_name,
    tr.role_name
FROM
    project p
JOIN
    project_team pt ON p.project_id = pt.project_id
JOIN
    team_member tm ON pt.member_id = tm.member_id
JOIN
    team_role tr ON pt.role_id = tr.role_id
ORDER BY
    p.project_name, tm.name;


UPDATE project_team
SET role_id = CASE
    WHEN role_id = (SELECT role_id FROM team_role WHERE role_name = 'Dev') THEN
        (SELECT role_id FROM team_role WHERE role_name = 'Test')
    WHEN role_id = (SELECT role_id FROM team_role WHERE role_name = 'Test') THEN
        (SELECT role_id FROM team_role WHERE role_name = 'Dev')
    ELSE role_id
END
WHERE project_id = 2;
