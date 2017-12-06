-- Author: Chetan Patil
DROP TABLE IF EXISTS inputtoheap;
CREATE TABLE inputtoheap(value integer);
INSERT INTO inputtoheap VALUES(1);
INSERT INTO inputtoheap VALUES(3);
INSERT INTO inputtoheap VALUES(2);
INSERT INTO inputtoheap VALUES(0);
INSERT INTO inputtoheap VALUES(7);
INSERT INTO inputtoheap VALUES(8);
INSERT INTO inputtoheap VALUES(9);
INSERT INTO inputtoheap VALUES(11);
INSERT INTO inputtoheap VALUES(1);
INSERT INTO inputtoheap VALUES(3);

CREATE OR REPLACE FUNCTION swap(parentpos integer, elementpos integer)
RETURNS boolean AS
$$
DECLARE	parentatpos integer;
	elementatpos integer;
BEGIN
	SELECT value INTO parentatpos FROM heap WHERE index = parentpos;
	IF EXISTS( SELECT 1 FROM heap WHERE index = elementpos) THEN
		SELECT value INTO elementatpos FROM heap WHERE index = element_pos;
		IF (parentatpos < elementatpos) THEN
			UPDATE heap SET value = elementatpos WHERE index = parentpos;
			UPDATE heap SET value = parentatpos WHERE index = elementpos;
			RETURN true;
		END IF; 
	END IF; 
	RETURN false;
END;
$$ LANGUAGE PLPGSQL;
 
CREATE OR REPLACE FUNCTION insertion(element integer)
RETURNS VOID AS
$$
DECLARE	parentpos integer;
	pos integer;
	swapped boolean;
	elempresent boolean;
BEGIN
	SELECT INTO elempresent EXISTS(SELECT 1 FROM heap LIMIT 1);
	IF elempresent THEN
		SELECT max(index) INTO pos FROM heap;
	ELSE
		pos := 0;
	END IF;
	pos := pos + 1;
	INSERT INTO heap VALUES(pos, element);
	IF(pos > 1)THEN 
		IF(pos % 2 != 0)THEN
			parentpos := (pos - 1) / 2;
		ELSE
			parentpos := pos / 2;
		END IF;
		SELECT * INTO swapped FROM swap(parentpos, pos);
		WHILE(swapped = true)
		LOOP
			pos := parentpos;
			IF(pos % 2 != 0)THEN
				parentpos := (pos - 1) / 2;
			ELSE
				parentpos := pos / 2;
			END IF;
			SELECT * INTO swapped FROM swap(parentpos, pos);
		END LOOP;
	END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION extraction(element integer)
RETURNS VOID AS
$$
DECLARE swapped boolean;
	elempos integer;
	elemval integer;
	leftpos integer;
	leftval integer;
	rightpos integer;
	rightval integer;
	largestpos integer;
	largestval integer;
	temppos integer;
BEGIN	
	elempos := 0;
	SELECT index INTO elempos FROM heap WHERE value = element;
	IF(elempos != 0) THEN
		SELECT MAX(index) INTO temppos FROM heap;
		IF(elempos != temppos) THEN
			SELECT * INTO swapped FROM swap(temppos, elempos);
		END IF;
		DELETE FROM heap WHERE index = temppos;
		SELECT value INTO elemval FROM heap WHERE index = elempos;
		WHILE(swapped = true)
		LOOP
			swapped := false;
			leftpos := elempos * 2;
			rightpos := leftpos + 1;
			SELECT value INTO leftval FROM heap WHERE index = leftpos;
			SELECT value INTO rightval FROM heap WHERE index = rightpos; 
			largestpos := elempos;
			largestval := elemval;
			IF(leftpos <= temppos AND leftval > largestval) THEN
				largestpos := leftpos;
				largestval := leftval;
			END IF;
			IF(rightpos <= temppos AND rightval > largestval)THEN
				largestpos := rightpos;
				largestval := rightval;
			END IF;
			IF(largestpos != elempos) THEN
				SELECT * INTO swapped FROM swap(elempos, largestpos);
				elempos := largestpos;
			END IF;
		END LOOP;
	END IF; 
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION heapsort()
RETURNS VOID AS
$$
DECLARE	heapsize integer;
	root integer;
	element integer;
BEGIN
	DROP TABLE IF EXISTS heap;
	DROP TABLE IF EXISTS sortedheap;
	CREATE TABLE heap(index integer, value integer, PRIMARY KEY(index));
	CREATE TABLE sortedheap(index integer, value integer);
	FOR element IN SELECT value FROM inputtoheap
	LOOP
		PERFORM insertion(element);
	END LOOP;
	SELECT MAX(index) INTO heapsize FROM heap;
	WHILE(heapsize >= 1)
	LOOP
		SELECT value INTO root FROM heap WHERE index = 1;
		INSERT INTO sortedheap VALUES(heapsize, root);
		PERFORM extraction(root);
		heapsize := heapsize - 1;
	END LOOP;
END;
$$ LANGUAGE PLPGSQL;

SELECT heapsort();
SELECT * FROM sortedheap ORDER BY index ASC;
DROP TABLE IF EXISTS heap;
DROP TABLE IF EXISTS sortedheap;
DROP TABLE IF EXISTS inputtoheap;

/*
Expected output
 index | value 
-------+-------
     1 |     0
     2 |     1
     3 |     1
     4 |     2
     5 |     3
     6 |     3
     7 |     7
     8 |     8
     9 |     9
    10 |    11
(10 rows)
*/
