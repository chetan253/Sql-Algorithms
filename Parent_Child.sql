-- Author: Chetan Patil
DROP TABLE IF EXISTS Parent_Child;
CREATE TABLE Parent_Child(pid integer, cpid integer);

INSERT INTO Parent_Child VALUES(1,2);
INSERT INTO Parent_Child VALUES(1,3);
INSERT INTO Parent_Child VALUES(2,4);
INSERT INTO Parent_Child VALUES(3,6);
INSERT INTO Parent_Child VALUES(6,8);
INSERT INTO Parent_Child VALUES(1,5);
INSERT INTO Parent_Child VALUES(5,9);

CREATE OR REPLACE FUNCTION assignLevel(newnodeid integer)
RETURNS void AS
$$
DECLARE	isroot boolean;
	parent integer;
	parentlevel integer;
BEGIN
	SELECT INTO isroot EXISTS(SELECT cpid FROM Parent_Child WHERE cpid = newnodeid);--its the root node
	IF isroot = FALSE THEN	
		UPDATE levels SET nidlevel = 0 WHERE nid = newnodeid;
		UPDATE levelAssign SET lvlassigned = TRUE WHERE nid = newnodeid;
	ELSE --its a child node
		SELECT DISTINCT pid INTO parent FROM Parent_Child WHERE cpid = newnodeid;
		SELECT nidlevel INTO parentlevel FROM levels WHERE nid = parent;
		UPDATE levels SET nidlevel = parentlevel + 1  WHERE nid = newnodeid;
		UPDATE levelAssign SET lvlassigned = TRUE WHERE nid = newnodeid;
	END IF; 
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION twoSiblings()
RETURNS void AS
$$
DECLARE	sibling1 integer;
	sibling2 integer;
	pc RECORD;
	pidlevelassigned boolean;
	cpidlevelassigned boolean;
	pidpresent integer;
	cpidpresent integer;
BEGIN
	DROP TABLE IF EXISTS levels;
	DROP TABLE IF EXISTS levelAssign;
	CREATE TABLE levels(nid integer, nidlevel integer);
	CREATE TABLE levelAssign(nid integer, lvlassigned boolean);
	FOR pc IN SELECT pid, cpid FROM Parent_Child
	LOOP
		SELECT COUNT(1) INTO pidpresent FROM levels WHERE nid = pc.pid;
		SELECT COUNT(1) INTO cpidpresent FROM levels WHERE nid = pc.cpid;
		IF pidpresent = 0 THEN
			INSERT INTO levels VALUES(pc.pid, NULL);
			INSERT INTO levelAssign VALUES(pc.pid, FALSE);
		END IF;
		IF cpidpresent = 0 THEN
			INSERT INTO levels VALUES(pc.cpid, NULL);
			INSERT INTO levelAssign VALUES(pc.cpid, FALSE);
		END IF;
		SELECT INTO pidlevelassigned EXISTS(SELECT nid FROM levelAssign WHERE nid = pc.pid AND lvlassigned = TRUE);
		SELECT INTO cpidlevelassigned EXISTS(SELECT nid FROM levelAssign WHERE nid = pc.cpid AND lvlassigned = TRUE);
		IF pidlevelassigned = FALSE THEN
			PERFORM assignLevel(pc.pid);
		END IF;
		IF cpidlevelassigned = FALSE THEN
			PERFORM assignLevel(pc.cpid);
		END IF; 	
	END LOOP;
	DROP TABLE levelAssign;
END;
$$ LANGUAGE PLPGSQL;
SELECT twoSiblings();
SELECT l.nid, l1.nid FROM levels l, levels l1 WHERE l.nidlevel = l1.nidlevel;
DROP TABLE IF EXISTS Parent_Child;
DROP TABLE IF EXISTS levels;
DROP TABLE IF EXISTS levelAssign;

/*
Expected Output
 nid | nid 
-----+-----
   1 |   1
   3 |   3
   3 |   5
   3 |   2
   5 |   3
   5 |   5
   5 |   2
   2 |   3
   2 |   5
   2 |   2
   9 |   9
   9 |   4
   9 |   6
   4 |   9
   4 |   4
   4 |   6
   6 |   9
   6 |   4
   6 |   6
   8 |   8
(20 rows)
*/
