### 错误1
```sh
hudson.plugins.git.GitException: Command "git fetch --tags --force --progress --prune -- origin +refs/heads/main:refs/remotes/origin/main" returned status code 128:
stdout: 
stderr: No ED25519 host key is known for github.com and you have requested strict checking.
Host key verification failed.
fatal: Could not read from remote repository.
```

### 解决，先进入jenkins容器,
```sh
[root@VM-0-8-opencloudos ~]# docker exec -it jenkins /bin/bash
```
### 执行1
```sh
root@493956f4e595:/# git ls-remote -h -- git@github.com:sidgeek/jenkins_node.git HEAD
The authenticity of host 'github.com (20.205.243.166)' can't be established.
ED25519 key fingerprint is SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? y
Please type 'yes', 'no' or the fingerprint: yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
root@493956f4e595:/#
```
