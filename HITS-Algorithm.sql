-- Author: Chetan Patil
DROP TABLE IF EXISTS HitsGraph;
CREATE TABLE HitsGraph(Source INTEGER, Target INTEGER);
INSERT INTO HitsGraph VALUES(1,2);
INSERT INTO HitsGraph VALUES(2,4);
INSERT INTO HitsGraph VALUES(4,3);
INSERT INTO HitsGraph VALUES(1,3);
INSERT INTO HitsGraph VALUES(3,1);
INSERT INTO HitsGraph VALUES(1,4);
INSERT INTO HitsGraph VALUES(2,3);
INSERT INTO HitsGraph VALUES(4,4);

CREATE OR REPLACE FUNCTION recalcAuths()
RETURNS VOID AS
$$
DECLARE sumauths float;
	node RECORD;
	authval float;
BEGIN
	SELECT sum(power(vals,2))::numeric::float INTO sumauths FROM authdummy;
	FOR node IN(SELECT nodeid, vals FROM authdummy)
	LOOP
		SELECT node.vals/SQRT(sumauths)::numeric::float INTO authval;
		UPDATE authdummy SET vals = authval WHERE nodeid = node.nodeid;
		UPDATE nodeHubAuth SET authority = authval WHERE nodeid = node.nodeid;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
CREATE OR REPLACE FUNCTION recalcHubs()
RETURNS VOID AS
$$
DECLARE sumhubs float;
	node RECORD;
	hubval float;
BEGIN
	SELECT sum(power(vals,2))::numeric::float INTO sumhubs FROM hubdummy;
	FOR node IN(SELECT nodeid, vals FROM hubdummy)
	LOOP
		SELECT node.vals/SQRT(sumhubs)::numeric::float INTO hubval;
		UPDATE hubdummy SET vals = hubval WHERE nodeid = node.nodeid;
		UPDATE nodeHubAuth SET hub = hubval WHERE nodeid = node.nodeid;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION HitsAlgo()
RETURNS VOID AS
$$
DECLARE	node integer;
	targetnode integer;
	hubcount integer;
	authoritycount integer;
	summatrix integer := 0;
	mat1val integer;
	mat2val integer;
	counter integer;
BEGIN
	DROP TABLE IF EXISTS prevNodeHubAuth;
	DROP TABLE IF EXISTS nodeHubAuth;
	DROP TABLE IF EXISTS transposeHitsGraph;
	DROP TABLE IF EXISTS matHitsGraph;
	DROP TABLE IF EXISTS authdummy;
	DROP TABLE IF EXISTS hubdummy;
	CREATE TABLE prevNodeHubAuth(nodeid integer, hub float, authority float);
	CREATE TABLE nodeHubAuth(nodeid integer, hub float, authority float);
	CREATE TABLE transposeHitsGraph(Source integer, Target integer, bin integer);
	CREATE TABLE matHitsGraph(source integer, target integer, bin integer);
	CREATE TABLE authdummy(nodeid integer, vals integer);
	CREATE TABLE hubdummy(nodeid integer, vals integer);
	FOR node IN (SELECT source FROM(SELECT source FROM HitsGraph UNION SELECT target FROM HitsGraph)foo)
	LOOP
		SELECT COUNT(target) INTO hubcount FROM hitsgraph WHERE source = node;
		SELECT COUNT(source) INTO authoritycount FROM hitsgraph WHERE target = node;
		INSERT INTO nodeHubAuth VALUES(node, hubcount, authoritycount);
	END LOOP;
	FOR node IN (SELECT source FROM(SELECT source FROM HitsGraph UNION SELECT target FROM HitsGraph)foo ORDER BY source ASC)
	LOOP
		FOR targetnode IN (SELECT source FROM(SELECT source FROM HitsGraph UNION SELECT target FROM HitsGraph)foo )
		LOOP
			IF EXISTS(SELECT 1 FROM hitsgraph WHERE source = node AND target = targetnode) THEN
				INSERT INTO transposeHitsGraph VALUES(targetnode, node, 1);
				INSERT INTO matHitsGraph VALUES(node, targetnode, 1);
			ELSE
				INSERT INTO transposeHitsGraph VALUES(targetnode, node, 0);
				INSERT INTO matHitsGraph VALUES(node, targetnode, 0);
			END IF;
		END LOOP;
	END LOOP;
	--calc auth vector using transpose
	FOR node IN (SELECT source FROM(SELECT source FROM HitsGraph UNION SELECT target FROM HitsGraph)foo ORDER BY source ASC)
	LOOP
		summatrix := 0;
		FOR mat1val IN (SELECT bin FROM transposehitsgraph WHERE source = node ORDER BY target ASC)
		LOOP
			mat2val := 1;
			summatrix := summatrix + mat1val * mat2val;
		END LOOP;
		INSERT INTO authdummy VALUES(node, summatrix);
		UPDATE nodeHubAuth SET authority = summatrix WHERE nodeid = node;
	END LOOP;
	FOR node IN (SELECT source FROM(SELECT source FROM HitsGraph UNION SELECT target FROM HitsGraph)foo ORDER BY source ASC)
	LOOP
		summatrix := 0;
		counter := 1;
		FOR mat1val IN (SELECT bin FROM mathitsgraph WHERE source = node ORDER BY target ASC)
		LOOP 
			SELECT vals INTO mat2val FROM authdummy WHERE nodeid = counter;
			summatrix := summatrix + mat1val * mat2val;
			counter := counter + 1;
		END LOOP;
		INSERT INTO hubdummy VALUES(node, summatrix);
		UPDATE nodeHubAuth SET hub = summatrix WHERE nodeid = node; 
	END LOOP;
	INSERT INTO prevNodeHubAuth SELECT nodeid, NULL, NULL FROM nodeHubAuth; 
	counter := 0;
	WHILE EXISTS(SELECT * FROM prevNodeHubAuth EXCEPT SELECT * FROM nodeHubAuth)
	LOOP
		PERFORM recalcHubs();
		PERFORM recalcAuths();
		TRUNCATE TABLE prevNodeHubAuth;
		INSERT INTO prevNodeHubAuth SELECT * FROM nodeHubAuth;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;
SELECT hitsAlgo();
SELECT * FROM nodeHubAuth;
DROP TABLE IF EXISTS prevNodeHubAuth;
DROP TABLE IF EXISTS nodeHubAuth;
DROP TABLE IF EXISTS transposeHitsGraph;
DROP TABLE IF EXISTS matHitsGraph;
DROP TABLE IF EXISTS authdummy;
DROP TABLE IF EXISTS hubdummy;
DROP TABLE IF EXISTS HitsGraph;
/*
Expected Output
 nodeid |        hub         |     authority     
--------+--------------------+-------------------
      1 |  0.633750222297627 | 0.223606797749979
      2 |  0.543214476255109 | 0.223606797749979
      3 | 0.0905357460425182 | 0.670820393249937
      4 |  0.543214476255109 | 0.670820393249937
(4 rows)

*/
