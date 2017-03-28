use kohadata;
SELECT * FROM kohadata.borrowers;
DELETE FROM borrowers WHERE borrowers.categorycode = "EITILASTO";
DELETE FROM borrowers WHERE borrowers.cardnumber = "jukkpiet"
