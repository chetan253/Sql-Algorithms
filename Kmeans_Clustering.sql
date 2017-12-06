-- Author: Chetan Patil
DROP TABLE IF EXISTS points;
CREATE TABLE points(pid integer, x float, y float);
INSERT INTO points VALUES(1,1,1);
INSERT INTO points VALUES(2,1,0);
INSERT INTO points VALUES(3,0,2);
INSERT INTO points VALUES(4,2,4);
INSERT INTO points VALUES(5,3,5);

CREATE OR REPLACE FUNCTION updateClusters()
RETURNS VOID AS
$$
DECLARE	counter integer;
BEGIN
	TRUNCATE TABLE centroids;
	INSERT INTO centroids SELECT ac.clusters, AVG(x) AS x, AVG(y) AS y FROM points p INNER JOIN assignedClusters ac ON p.pid = ac.points GROUP BY ac.clusters;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION kMeans(k integer) --new
RETURNS VOID AS
$$
DECLARE	centroid RECORD;
	getDist RECORD;
	distance float;
	mindist RECORD;
	clusterassign RECORD;
	c integer;
	checker integer := 0;
BEGIN	
	DROP TABLE IF EXISTS centroids;
	DROP TABLE IF EXISTS tempDistances;
	DROP TABLE IF EXISTS assignedClusters;
	DROP TABLE IF EXISTS prevAssignedClusters;
	CREATE TABLE centroids(points integer, x float, y float);
	CREATE TABLE tempDistances(points integer, clusters float, distances float);
	CREATE TABLE assignedClusters(points integer, clusters float);
	CREATE TABLE prevAssignedClusters(points integer, clusters float);
	INSERT INTO prevAssignedClusters SELECT pid, NULL FROM points;
	c := 1;
	FOR centroid IN SELECT pid, x, y FROM points ORDER BY RANDOM() LIMIT k
	LOOP
		INSERT INTO centroids VALUES(c, centroid.x, centroid.y);
		c := c + 1;
	END LOOP;
	WHILE EXISTS(SELECT * FROM prevassignedClusters except SELECT * FROM assignedclusters)
	LOOP
		checker := checker + 1;
		FOR getDist IN SELECT * FROM points
		LOOP
			FOR centroid IN SELECT points, x, y FROM centroids
			LOOP
				distance := SQRT(POWER(getDist.x - centroid.x,2) + POWER(getDist.y - centroid.y, 2));
				INSERT INTO tempDistances VALUES(getDist.pid, centroid.points, distance);
			END LOOP;
		END LOOP;
		TRUNCATE TABLE assignedClusters;
		FOR mindist IN SELECT points FROM tempDistances
		LOOP
			SELECT t.points, t.clusters INTO clusterAssign FROM tempDistances t WHERE t.points = mindist.points AND t.distances = (SELECT MIN(t1.distances) FROM tempDistances t1 WHERE t1.points = t.points);
			IF NOT EXISTS(SELECT points, clusters FROM assignedClusters WHERE points = clusterAssign.points AND clusters = clusterAssign.clusters) THEN
				INSERT INTO assignedClusters VALUES(clusterAssign.points, clusterAssign.clusters);
			END IF;
		END LOOP;
		PERFORM updateClusters();
		TRUNCATE TABLE tempDistances;
		TRUNCATE TABLE prevAssignedClusters;
		INSERT INTO prevAssignedClusters SELECT points, clusters FROM assignedClusters;
	END LOOP;
END;
$$LANGUAGE PLPGSQL;
SELECT kMeans(2);
SELECT * FROM assignedClusters;
DROP TABLE IF EXISTS centroids;
DROP TABLE IF EXISTS tempDistances;
DROP TABLE IF EXISTS assignedClusters;
DROP TABLE IF EXISTS prevAssignedClusters;
DROP TABLE IF EXISTS points;
/*
Expected Output
 points | clusters 
--------+----------
      1 |        1
      2 |        1
      3 |        2
      4 |        2
      5 |        2
(5 rows)
*/
