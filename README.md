# goofys-allure-docker-service
[Dockerhub](https://hub.docker.com/repository/docker/ssubhabrata/goofys-allure-docker-service) link. Image - **ssubhabrata/goofys-allure-docker-service:v1**
<br/>
This is a project to integrate [cloudposse/goofys](https://github.com/cloudposse/goofys) and [allure-docker-service](https://github.com/fescobar/allure-docker-service) into a single docker image. Before discussing this project's utility lets gather a little more information about Goofys and Allure.

<br/>

## Allure Framework
Allure Framework provides you good looking reports like below for automation testing. For using this tool it is required to install a server. Allure needs a storage backend like local filesystem, ebs, s3 bucket where it could store the test-results and generate the test-reports.
You can find more find reference about Allure at [Official Documentation](https://docs.qameta.io/allure/).

![Report](https://raw.githubusercontent.com/fescobar/allure-docker-service/master/resources/allure01.png)

## Goofys
Goofys allows you to mount an S3 bucket as a filey system.
It's a Filey System instead of a File System because goofys strives for performance first and POSIX second. Particularly things that are difficult to support on S3 or would translate into more than one round-trip would either fail (random writes) or faked (no per-file permission). Goofys does not have an on disk data cache (checkout catfs), and consistency model is close-to-open.
So basically you can mount an S3 bucket at any mountpoint in your VM or container.

Reference:- [kahing/goofys](https://github.com/kahing/goofys) and [cloudposse/goofys](https://github.com/cloudposse/goofys)

```
Eg:-
ss@subhabrata:~$ docker run -d --rm --privileged -e BUCKET="my-s3-bucket-goofys-test" -e AWS_ACCESS_KEY="XXXXXXXXXXXX" -e AWS_SECRET_KEY="XXXXXXXXXXXX" -e REGION="ap-south-1" -e MOUNT_DIR="/var/log" cloudposse/goofys-subhabrata
6fef5dc5a6e36dd52ce3e1264499358deb7ecec9dae5434d9a8486b1903502f6
ss@subhabrata:~$
ss@subhabrata:~$ docker exec -it 6fef5dc sh
/ # 
/ # df -h
Filesystem                 Size  Used Avail Use% Mounted on
overlay                    232G   89G  132G  41% /
tmpfs                       64M     0   64M   0% /dev
tmpfs                      7.8G     0  7.8G   0% /sys/fs/cgroup
shm                         64M     0   64M   0% /dev/shm
/dev/mapper/vgubuntu-root  232G   89G  132G  41% /mnt/s3
my-s3-bucket-goofys-test   1.0P     0  1.0P   0% /var/log
```

### Now, coming to the actual story :-

## FEATURES of goofys-allure-docker-service

Allure needs a backend storage where it could store the test-results and generate the test-reports. The storage could be local storage or ebs or s3 (or anywhere where you can send your test-results, Allure generates the test-reports from those results) .

So this image (hosted on dockerhub) mounts S3 storage to the container directly and starts the Allure web-service. Once Allure server is up and running you should be able to create new projects and generate reports and visualise them as usual.

How to run :-

```
docker run -it --rm --privileged -e BUCKET="my-s3-bucket-goofys-test" -e AWS_ACCESS_KEY="XXXXXXXXXXXXXX" -e AWS_SECRET_KEY="XXXXXXXXXXXXXX"  -p 5050:5050 -e CHECK_RESULTS_EVERY_SECONDS=1 -e KEEP_HISTORY=1 -e KEEP_HISTORY_LATEST=10 --user 0 ssubhabrata/goofys-allure-docker-service:v1
```
Wait for **15secs atleast** for the service to start up.
<br/>
By default it will mount to /app/allure-docker-api/static/projects directory. **And should not be changed.** Default REGION is ap-south-1. If the s3 bucket is in any other region then pass REGION environment variable. Eg: `-e REGION="us-west-2"` 

## ENV VAR

BUCKET = name-of-s3-bucket
<br/>
AWS_ACCESS_KEY = aws_access_key of iam user who has access to the bucket.
<br/>
AWS_SECRET_KEY = aws_secret_key of the same iam user.
<br/>
REGION = region where the s3 bucket is present. default "ap-south-1"
<br/>
CHECK_RESULTS_EVERY_SECONDS = time interval in secs to check for new results. For multiple projects configuration you must use CHECK_RESULTS_EVERY_SECONDS with value NONE. Otherwise, your performance machine would be affected, it could consume high memory, processors and storage. Use the endpoint GET /generate-report on demand after sending the results POST /send-results.
<br/>
KEEP_HISTORY = Enable KEEP_HISTORY environment variable to work with history & trends. `KEEP_HISTORY: "TRUE"` or `KEEP_HISTORY: 1`
<br/>
KEEP_HISTORY_LATEST = No. of latest history of results and reports to keep.
<br/>

<br/>
This will by-default create a **Multi-Project** Allure container server. You could generate multiple reports for multiple projects and create, delete and get projects using [Project Endpoints](https://github.com/fescobar/allure-docker-service#project-endpoints). You can use Swagger documentation to help you.

The path for allure-test-results is `/app/allure-docker-api/static/projects/allure-results` and the reports will be populated at `/app/allure-docker-api/static/projects/allure-reports` .

Currently Image ARCHITECTURE=amd64.
