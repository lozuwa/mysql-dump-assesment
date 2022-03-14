# Mysql dump assesment

# System design

## Questions by candidate and interviewer responses.
1. Will the script be executed from localhost or from a remote machine?
* Yes the script will be run from localhost.
2. Does the script need to run periodically, what would be the frequency?
* Yes, it needs to run every Saturday at 11PM.
3. Does the application use the database during the backup time previously defined?
* Yes, the application interacts with the database during backup time.
4. Does the file need to be sent to another location? Like maybe a s3 bucket?
* Yes, we need to dump the dumped databases to an external storage system.
5. What’s the average size of the data in mysql? Do you guys run a data retention policy or it increases over time.
* The average size is 10Gb. The data is kept in this size on average due to data retention.
6. Does the database run in a single instance or does it run in multimaster?
* It is a single database.

## Candidate providing more details on the question responses.
1. Q1
Running in localhost has more advantages because:
* Target the dump to a SSD disk with low usage to assure good performance.
* Compress the output of the mysqldump to reduce IO on the disk. Like gzip.
* If you need to copy the data to another location it is better to use an internal http server or scp, rsync instead of TCP over the origin and target server.

* * Use --opt --quick --single-transaction parameters to handle

2. Q2
The script will be executed by a cronjob configured in the machine. 

3. Q3
Make mysqldump use --single-transaction to avoid having locking the application.

4. Q4
The s3 CLI will be used to send the data to an external bucket through the script.

5. Q5
Size is doable. Bigger sizes would need a completely different approach. I would suggest to take a disk snapshot and load the disk to another server.

6. Q6
No multimaster means we are going to stay in the same server.

# Plan tasks
1. Implement script ~4-6 hours.
2. Implement unit test in the CI ~2 hours. 
4. Documentation 1 hour.
