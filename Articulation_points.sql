-- Author: Chetan Patil
DROP TABLE IF EXISTS Graph;
CREATE TABLE Graph(source integer, target integer);
INSERT INTO Graph VALUES(1,2);
INSERT INTO Graph VALUES(2,1);
INSERT INTO Graph VALUES(1,3);
INSERT INTO Graph VALUES(3,1);
INSERT INTO Graph VALUES(2,4);
INSERT INTO Graph VALUES(4,2);
INSERT INTO Graph VALUES(2,3);
INSERT INTO Graph VALUES(3,2);
INSERT INTO Graph VALUES(2,5);
INSERT INTO Graph VALUES(5,2);
INSERT INTO Graph VALUES(4,5);
INSERT INTO Graph VALUES(5,4);

CREATE OR REPLACE FUNCTION DFS(point integer, artipoint integer)
RETURNS VOID AS
$$
DECLARE visitingnode integer;
	loopcheck boolean;
	child integer;
BEGIN	
	DROP TABLE IF EXISTS queue;
	CREATE TABLE queue(id SERIAL, node integer);
	INSERT INTO queue VALUES(DEFAULT, point);
	WHILE EXISTS(SELECT 1 FROM queue)
	LOOP
		-- take node out of queue 
		FOR visitingnode IN SELECT node FROM queue ORDER BY id DESC LIMIT 1
		LOOP
			DELETE FROM queue WHERE node = visitingnode;
			UPDATE visited SET visited = TRUE WHERE source = visitingnode;
			DELETE FROM restTransitions WHERE target = visitingnode;
			--add childs of visited node back to queue
			FOR child IN SELECT target FROM restTransitions WHERE source = visitingnode
			LOOP
				INSERT INTO queue VALUES (DEFAULT,child);
			END LOOP;
		END LOOP;
	END LOOP;
	IF EXISTS(SELECT 1 FROM visited WHERE visited = FALSE) THEN
		INSERT INTO articulationpoints VALUES(artipoint);
	END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION findArtiPoints()
RETURNS SETOF RECORD AS
$$
DECLARE	artipoint RECORD;
	considered integer;
	removed integer;
	dfsinitnode integer;
BEGIN
	DROP TABLE IF EXISTS articulationpoints;
	DROP TABLE IF EXISTS restTransitions;
	DROP TABLE IF EXISTS consideredpoints;
	DROP TABLE IF EXISTS visited;
	CREATE TABLE articulationpoints(articulation_points integer);
	CREATE TABLE consideredpoints(point integer);
	CREATE TABLE restTransitions(source integer, target integer);
	CREATE TABLE visited(source integer, visited boolean); -- vertex visited or not
	--take out each point and check for connectivity
	FOR artipoint IN (SELECT source FROM Graph UNION SELECT target FROM Graph)
	LOOP
		IF NOT EXISTS(SELECT point FROM consideredpoints WHERE point = artipoint.source) THEN
			INSERT INTO consideredpoints VALUES(artipoint.source); --artipoint is considered next time diff point (do not truncate)
			--populate visited table containing all points except artipoint with visited as false (truncate coz next time new values)
			TRUNCATE TABLE visited;
			INSERT INTO visited SELECT source, FALSE FROM(SELECT source FROM graph WHERE source != artipoint.source UNION SELECT target FROM graph WHERE target != artipoint.source) foo;
			--get the remaining transitions except that contain artipoint in source or target(truncate coz next time new transitions)
			TRUNCATE TABLE restTransitions;
			INSERT INTO restTransitions SELECT source, target FROM graph WHERE source <> artipoint.source AND target <> artipoint.source;
			--now we perform dfs on rest transitions
			SELECT source INTO dfsinitnode FROM restTransitions LIMIT 1;
			PERFORM DFS(dfsinitnode, artipoint.source);
		END IF;
	END LOOP;	
END;
$$ LANGUAGE PLPGSQL;
SELECT findArtipoints();
SELECT * FROM articulationpoints;
DROP TABLE IF EXISTS articulationpoints;
DROP TABLE IF EXISTS restTransitions;
DROP TABLE IF EXISTS consideredpoints;
DROP TABLE IF EXISTS visited;
DROP TABLE IF EXISTS queue;
DROP TABLE IF EXISTS Graph;

/*
Expected output
 articulation_points 
---------------------
                   2
*/
