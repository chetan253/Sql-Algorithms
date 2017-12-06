-- Author: Chetan Patil
DROP TABLE IF EXISTS weightedGraph;
CREATE TABLE weightedGraph(source integer, target integer, cost integer);
INSERT INTO weightedGraph VALUES(1,2,5);
INSERT INTO weightedGraph VALUES(2,1,5);
INSERT INTO weightedGraph VALUES(1,3,3);
INSERT INTO weightedGraph VALUES(3,1,3);
INSERT INTO weightedGraph VALUES(2,3,2);
INSERT INTO weightedGraph VALUES(3,2,2);
INSERT INTO weightedGraph VALUES(2,5,2);
INSERT INTO weightedGraph VALUES(5,2,2);
INSERT INTO weightedGraph VALUES(3,5,4);
INSERT INTO weightedGraph VALUES(5,3,4);
INSERT INTO weightedGraph VALUES(2,4,8);
INSERT INTO weightedGraph VALUES(4,2,8);



CREATE OR REPLACE FUNCTION minimumspanningtree()
RETURNS VOID AS
$$
DECLARE	node RECORD;
	adjacentnodes RECORD;
	minCost RECORD;
	minchildnode integer;
	counter integer:= 0;
BEGIN
	DROP TABLE IF EXISTS verticesTaken;
	DROP TABLE IF EXISTS pathCosts;
	DROP TABLE IF EXISTS minimumSpanning;
	CREATE TABLE verticesTaken(vertex integer); --mstset
	CREATE TABLE pathCosts(parent integer, vertex integer, cost integer); --key in gfg
	CREATE TABLE minimumSpanning(source integer, target integer);
	--Initialize costs to null i.e infinite;
	FOR node IN (SELECT DISTINCT source FROM weightedGraph ORDER BY source ASC)
	LOOP
			IF node.source = (SELECT DISTINCT source FROM weightedGraph ORDER BY source ASC LIMIT 1) THEN
				INSERT INTO pathCosts VALUES(NULL, node.source, 0);
			ELSE
				INSERT INTO pathCosts VALUES(NULL, node.source, NULL);
			END IF;
	END LOOP;
	WHILE EXISTS(SELECT DISTINCT source FROM weightedGraph except SELECT vertex from verticestaken)
	LOOP
		FOR node IN SELECT pc.parent, pc.vertex, pc.cost FROM (SELECT parent, vertex, cost FROM pathCosts WHERE vertex NOT IN (SELECT vertex FROM verticestaken))pc WHERE pc.cost = (SELECT MIN(pc1.cost) FROM (SELECT vertex, cost FROM pathCosts WHERE vertex NOT IN (SELECT vertex FROM verticestaken))pc1)
		LOOP
			INSERT INTO verticesTaken VALUES(node.vertex);
		
			FOR adjacentnodes IN(SELECT source,target, cost FROM (SELECT source, target, cost FROM weightedGraph WHERE target NOT IN(SELECT vertex FROM verticestaken))foo WHERE source = node.vertex)
			LOOP
			
				--IF NOT EXISTS(SELECT 1 FROM verticesTaken WHERE vertex = adjacentnodes.target) THEN
					UPDATE pathCosts SET cost = adjacentnodes.cost, parent = adjacentnodes.source WHERE vertex = adjacentnodes.target;
				--END IF;
			END LOOP;
			IF counter > 0 THEN
				INSERT INTO minimumspanning VALUES(node.parent, node.vertex);
				INSERT INTO minimumspanning VALUES(node.vertex, node.parent);
			END IF;
			counter := counter + 1;
		END LOOP;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
SELECT minimumspanningtree();
SELECT * FROM minimumSpanning;
DROP TABLE IF EXISTS verticesTaken;
DROP TABLE IF EXISTS pathCosts;
DROP TABLE IF EXISTS minimumSpanning;
DROP TABLE IF EXISTS weightedGraph;
/*
Expected Output
 source | target 
--------+--------
      1 |      3
      3 |      1
      3 |      2
      2 |      3
      2 |      5
      5 |      2
      2 |      4
      4 |      2
(8 rows)
*/
