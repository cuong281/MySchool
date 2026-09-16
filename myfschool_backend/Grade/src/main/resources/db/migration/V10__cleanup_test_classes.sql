-- V10: Cleanup dummy test classes created during automated test runs
DELETE FROM SchoolClasses WHERE ClassName LIKE '%ISOLATED%';
