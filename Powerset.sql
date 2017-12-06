-- Author: Chetan Patil
DROP TABLE IF EXISTS A;
CREATE TABLE A(x integer);
INSERT INTO A VALUES(1);
INSERT INTO A VALUES(2);
INSERT INTO A VALUES(3);
INSERT INTO A VALUES(4);
INSERT INTO A VALUES(5);

CREATE OR REPLACE FUNCTION powerset()
RETURNS integer AS
$$
DECLARE counter integer;
	sets integer[];
	element integer;
	maxval integer;
	nt integer:= 0;
BEGIN
	DROP TABLE IF EXISTS powerset;
	CREATE TABLE powerset(subset integer[]);
	INSERT INTO powerset VALUES('{}');
	FOR counter IN 1..(SELECT COUNT(*) FROM A)
	LOOP
		FOR element IN(SELECT x FROM A)
		LOOP
			FOR sets IN (SELECT subset FROM powerset WHERE cardinality(subset) = counter - 1)
			LOOP
				IF counter = 1 THEN
					INSERT INTO powerset VALUES(array_append(sets, element));
				ELSE
					SELECT max(x) INTO maxval FROM UNNEST(sets)x;
					IF element > maxval THEN
						INSERT INTO powerset VALUES(array_append(sets, element));
					END IF;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;
	return nt;
END;
$$ LANGUAGE PLPGSQL;
SELECT powerset();
SELECT * FROM powerset;
DROP TABLE IF EXISTS powerset;
DROP TABLE IF EXISTS A;


/*
Expected Output
 {}
 {1}
 {2}
 {3}
 {4}
 {5}
 {1,2}
 {1,3}
 {2,3}
 {1,4}
 {2,4}
 {3,4}
 {1,5}
 {2,5}
 {3,5}
 {4,5}
 {1,2,3}
 {1,2,4}
 {1,3,4}
 {2,3,4}
 {1,2,5}
 {1,3,5}
 {2,3,5}
 {1,4,5}
 {2,4,5}
 {3,4,5}
 {1,2,3,4}
 {1,2,3,5}
 {1,2,4,5}
 {1,3,4,5}
 {2,3,4,5}
 {1,2,3,4,5}
(32 rows)
*/
