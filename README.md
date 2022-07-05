## This Repo is still under construction


### Known Issue and TODO:
1. Install Anaconda and make it avaiable to all users
2. Set up shared file system
3. Now, when execute srun, the user name is shown as I don't have a username!, which apparently should be fixed.


# Slurm-ubuntu20
This repo is for setting up [SLURM](https://github.com/SchedMD/slurm) with GPU nodes on Ubuntu 20.04. This is tested on a cluster with 2 GPU nodes and 1 controller.

OS: Ubuntu 20.04 LTS
## Table of Content
- [Slurm-ubuntu20](#slurm-ubuntu20)
  - [Table of Content](#table-of-content)
  - [References](#references)
  - [Guide](#guide)
    - [Sync Time](#sync-time)
    - [Setup munge and slurm user](#setup-munge-and-slurm-user)
    - [Sync GUI and UIDs](#sync-gui-and-uids)
    - [Create shared storage](#create-shared-storage)
    - [Install Munge](#install-munge)
      - [Install Munge on Controller Node](#install-munge-on-controller-node)
      - [Install Munge on Worker Node](#install-munge-on-worker-node)
    - [Install Slurm](#install-slurm)
      - [Install Slurm on Controller Node](#install-slurm-on-controller-node)
      - [Set up Inernet Configuration](#set-up-inernet-configuration)
      - [Install Slurm on Worker Node](#install-slurm-on-worker-node)
  - [Troubleshooting](#troubleshooting)
    - [Internet Permission](#internet-permission)
    - [Can't find the PIDFile](#cant-find-the-pidfile)
    - [How to Debug](#how-to-debug)
  
## References

This repo is based two main resources:
1. [slurm_gpu_ubuntu](https://github.com/nateGeorge/slurm_gpu_ubuntu) by NateGeorge
2. [ubuntu-slurm](https://github.com/mknoxnv/ubuntu-slurm) by mknoxnv
3. The maintainer of our slurm system Stefan Staeglis. The prolog and epilog are both referred from his implementation. Many thanks!

## Guide
I assume that you have installed Ubuntu 20.04 LTS. Before, we start to install slurm, I would recommend to run sudo apt-get update and apt-get upgrade, then execute a rebooting, to avoid underlying errors casued by some out-of-date packages. After you have upgraded all your packages, we can now start to install slurm.

### Sync Time

### Setup munge and slurm user
Create munge and slurm user on all nodes (incl. controller and work nodes)
```bash
sudo adduser -u 1111 munge --disabled-password --gecos ""
sudo adduser -u 1121 slurm --disabled-password --gecos ""
```
### Sync GUI and UIDs
Since we create users/groups using the same uid and gid on all nodes, this should be automatically done.


### Create shared storage
See [slurm_gpu_ubuntu](https://github.com/nateGeorge/slurm_gpu_ubuntu)

### Install Munge
#### Install Munge on Controller Node
```
sudo apt-get install libmunge-dev libmunge2 munge -y
sudo systemctl enable munge
sudo systemctl start munge
```
If this is installed properly, you can test your installation by
```
munge -n | unmunge | grep STATUS
```
This should return ``Success(0)``. Then we can copy the munge key to the storage folder to share with the other nodes
```
sudo cp /etc/munge/munge.key /storage/
sudo chown munge:munge /storage/munge.key
sudo chmod 400 /storage/munge.key
```

#### Install Munge on Worker Node
```
sudo apt-get install libmunge-dev libmunge2 munge
sudo cp /storage/munge.key /etc/munge/munge.key
sudo systemctl enable munge
sudo systemctl start munge
```
Execute ``munge -n | unmunge | grep STATUS``, this should still return ``Success(0)``. You can also test your installation by connection to the controller node by ``munge -n | ssh CONTROLLER_HOST unmunge`` (Replace the CONTROLLER_HOST to your hostname)

### Install Slurm
#### Install Slurm on Controller Node
```
sudo apt-get install git gcc make ruby ruby-dev libpam0g-dev libmariadb-client-lgpl-dev libmysqlclient-dev mariadb-server build-essential libssl-dev -y
sudo gem install fpm

```

Then we set up MariaDB by using the following commands:
```
sudo systemctl enable mysql
sudo systemctl start mysql
```

 We copy the data base config file to the storage by running: 
```
cd /storage
git clone https://github.com/2BH/Slurm-ubuntu20.git
cp /storage/ubuntu-slurm/slurmdbd.conf /storage
```
In our example config files, you should change two positions:

In slurm.conf, you should change the following two lines to your setup:
1. SlurmctldHost
2. ClusterName

(Optional)
In slurmdbd.conf, if you don't use the same slurmdb password as the example, you should also modify:

3. StoragePass


We will also configure mysql. In mysql, assuming the **slurmdb password** we use is ``slurmdbpass`` (if you have changed it in the last step, use your password), we write:
```
sudo mysql -u root
create database slurm_acct_db;
create user 'slurm'@'localhost';
set password for 'slurm'@'localhost' = password('slurmdbpass');
grant usage on *.* to 'slurm'@'localhost';
grant all privileges on slurm_acct_db.* to 'slurm'@'localhost';
flush privileges;
exit
```

Now we can install slurm on the controller by:
```
sudo apt install slurm-wlm
sudo apt install slurmdbd
```

Then we create all the directories needed by slurm
```
sudo mkdir -p /etc/slurm-llnl /etc/slurm-llnl/prolog.d /etc/slurm-llnl/epilog.d /var/spool/slurm-llnl/ctld /var/spool/slurm-llnl/d /var/log/slurm-llnl
```

Now we copy our slurm config files (slurm.conf and slurmdbd.conf), slurmctld service and slurmdbd service:
```
sudo cp /storage/Slurm-ubuntu20/slurmdbd.conf /etc/slurm-llnl/
sudo cp /storage/Slurm-ubuntu20/slurm.conf /etc/slurm-llnl/
sudo cp /storage/Slurm-ubuntu20/cgroup.conf /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/cgroup_allowed_devices_file.conf /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/gres.conf /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/epilog.sh /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/prolog.sh /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/slurmdbd.service /etc/systemd/system/
sudo cp /storage/Slurm-ubuntu20/slurmctld.service /etc/systemd/system/
```

Then, we change the owner of the directories and files to slurm user
```
sudo chown -R slurm:slurm /var/spool/slurm-llnl/ctld /var/spool/slurm-llnl/d /var/log/slurm-llnl /var/spool/slurm-llnl
chmod -R 751 /var/log/slurm-llnl
```

Now we will start all slurm services:
```
sudo systemctl daemon-reload
sudo systemctl enable slurmdbd
sudo systemctl start slurmdbd
sudo systemctl enable slurmctld
sudo systemctl start slurmctld
```

In our case, the slurm controller won't be expected to work as a worker node, but if it's requested, please refer to NateGeroge's setup

#### Set up Inernet Configuration
Slurm controller listens the messages from worker nodes on port 6817, if you use my config. Therefore, we will open the port for the workers by:
```
ufw allow from worker1_id_addr to any port any 6817
ufw allow from worker2_id_addr to any port any 6817
```

srun will use random port, therefore, it's better to set up a range for it, which is done in the config file by setting ``SrunPortRange=30000-50000`` in the slurm.conf file. Of course, you can also change it based on your system. But be careful that you will change it also on all worker nodes. Now, we will also open the ports on the controller node by adding these rules to your firewall.
```
ufw allow from worker1_id_addr to any port any 30000:50000 proto tcp
ufw allow from worker2_id_addr to any port any 30000:50000 proto tcp
```

#### Install Slurm on Worker Node
First let's create the directories we will need:
```
mkdir -p /var/spool/slurm-llnl /etc/slurm-llnl /var/log/slurm-llnl
```
 we will install slurm by running:
```
sudo apt install slurmd
```
Then we will copy all the config files we need from the controller to the worker node.
```
sudo cp /storage/Slurm-ubuntu20/slurmdbd.conf /etc/slurm-llnl/
sudo cp /storage/Slurm-ubuntu20/slurm.conf /etc/slurm-llnl/
sudo cp /storage/Slurm-ubuntu20/cgroup.conf /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/cgroup_allowed_devices_file.conf /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/gres.conf /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/epilog.sh /etc/slurm-llnl
sudo cp /storage/Slurm-ubuntu20/prolog.sh /etc/slurm-llnl
```

Then we change the owner and set the permissions by:
```
chown -R slurm:slurm /var/spool/slurm-llnl /etc/slurm-llnl /var/log/slurm-llnl
chmod -R 751 /var/log/slurm-llnl /etc/slurm-llnl /var/spool/slurm-llnl
```

Now we can start the slurmd service on the worker node:
```
sudo systemctl restart slurmd
```

Going back to the controller node, we will also start the controller by:
```
sudo systemctl restart slurmctld
sudo systemctl restart slurmdbd
sudo systemctl restart slurmd
```
Now we can create a cluster by (Don't forget substitue YourClusterName with your cluster name as it's defined in the slurm.conf):
```
sudo sacctmgr add cluster YourClusterName
```
## Troubleshooting
### Internet Permission
Slurm controller listens the messages from worker nodes on port 6817, if you use my config. Therefore, we will open the port for the workers by:
```
ufw allow from worker1_id_addr to any port any 6817
ufw allow from worker2_id_addr to any port any 6817
```

srun will use random port, therefore, it's better to set up a range for it, which is done in the config file. We will also open the ports on the controller node by adding these rules to your firewall.
```
ufw allow from worker1_id_addr to any port any 30000:50000 proto tcp
ufw allow from worker2_id_addr to any port any 30000:50000 proto tcp
```

### Can't find the PIDFile
You should first check if the pid file exists in the /var/run folder, if so, this is just a timing problem. If not, please check the permissions and configuration file

### How to Debug
Try running ``sudo slurmctld -Dvvv`` and ``sudo slurmdbd -Dvvv`` on the controller and ``sudo slurmd -Dvvv`` on the worker node. Then execute/submit jobs and look at the logs.




