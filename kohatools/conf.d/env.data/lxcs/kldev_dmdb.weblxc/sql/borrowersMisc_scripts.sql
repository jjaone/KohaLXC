use kohadata;
SELECT * FROM kohadata.borrowers;
SELECT * FROM kohadata.borrowers WHERE categorycode = 'S';
SELECT * FROM kohadata.borrowers WHERE categorycode <> 'S';
DELET FROM kohadata.borrowers WHERE categorycode = 'HENKILO' AND borrowernumber <> 1;
UPDAT borrowers SET categorycode = "HENKILO" WHERE borrowernumber <> 1;