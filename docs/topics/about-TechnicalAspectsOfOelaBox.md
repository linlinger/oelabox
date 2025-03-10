<!--
SPDX-FileCopyrightText: 2024 Maxine Hayes <maxinehayes90@gmail.com>
SPDX-License-Identifier: CC-BY-SA-4.0
-->
# Technical Aspects of Oela Box

## Vagrant
Oela Box relies heavily on Vagrant to create and bring up the virtual machines that encompass the overall development infrastructure for Enterprise Linux. Vagrant's ease of use and programmable Vagrant files make it a great choice for Oela Box. It makes it incredibly easy to spin up virtual machines for testing and development. I have also found it useful for creating a micro infrastructure in a box for Enterprise Linux development.

### Virtual Machines
Oela Box utilizes Vagrant to create the currently 3 main virtual machines that are used to deploy development infrastructure. Each virtual machine is designated to different roles based on their function.

#### DNS Server
The DNS server is the first piece of infrastructure brought up and provisioned. It requires very few resources to run. Its sole purpose as of right now is to allow us to bootstrap the FreeIPA server created after. The reason we need a DNS server is FreeIPA requires one be set up in order to install it. FreeIPA also requires that it can do a domain name reverse lookup against the DNS server.

#### IPA Server
The IPA server handles identity management, authentication, DNS resolution and acts as a certificate authority for the Oela Box infrastructure. While arguably overkill and a big resource hog the IPA server makes it very easy to setup services, authentication for services, and create signed SSL certificates. The Koji server relies heavily on the IPA service for its SSL certificates and kerberos authentication. 

#### Koji Server
The Koji server is where the magic happens. Koji is a build system for Enterprise Linux. The Koji server is actually made up of a few different smaller pieces. 

##### Koji Builder
The Koji Builder or kojid is essentially a builder node that takes requests from the Koji Hub. At least one Koji builder is required for our use case. Multiple builders are expected in order to build other architectures however. 

##### Koji Hub
The Koji Hub is what users interact with and send build jobs to. Its job is to relay build tasks from the users to the builders. The Koji Hub uses an XML-RPC API to communicate with clients. It is paired with Koji Web to make it accessible over HTTP using Apache.

##### Koji Web
The Koji Web is the frontend you see in the browser and also makes the Koji Hub accessible over HTTP. Apache is used to run the Koji Web and Hub.

##### Kojira
Kojira is the daemon that is responsible for keeping our buildroot repo data updated.

##### Koji-gc
Koji-gc is the Koji garbage collector. It runs periodically to cleanup old buildroots.

##### Apache 2
Apache 2 is the webserver that hosts Koji Hub and Koji Web. 

##### IPA Client
Our Koji server is connected to our IPA server as a client. This allows us to use kerberos authentication, generate keytabs for services, and generate SSL certificates for Apache.

## Ansible
Ansible is a crucial automation tool used in Oela Box. It is responsible for provisioning the virtual machines that bring up our infrastructure. Ansible allows us to easily provision virtual machines in a manner which is reproducible and indempotent. Ansible gives us a lot of information and does a lot of checks during playbook runs. Ansible is also easily extendable through modules.

### Types of Playbooks and Task Files

#### Provisioning Playbooks
There are several Ansible playbooks for provisioning the virtual machines. Provisioning playbooks follow a specific naming scheme which helps identify each playbook.

```
provision-oelabox-xxxx.yml
```

As of writing there are 5 different provisioning playbooks. We can read the Vagrant file to see which VMs utilize which playbooks.

#### Initializer Playbooks
Initializer playbooks are playbooks for initializing services during or after virtual machine provisioning. Initializer playbooks follow a specific naming scheme which helps identify each playbook.

```
init-oelabox-xxxx-xxxx.yml
```

Initializer Playbooks do not do any provisioning. They configure and setup already provisioned services. They are meant to be included in the Vagrant file after provisioning playbooks, but if need be can be imported into a provisioning playbook. 

#### Import Task Files
Import task files are task files meant to be imported by initializer playbooks. Import task files follow a specific naming scheme which helps identify each task file.

```
import-xxxx.yml
```

The purpose of import task files is to essentially organize the various tasks an initializer playbook runs. They can also be used in other initializer playbooks if the user wants to write a version of an initializer playbook that suites their needs better.

### Roles Included With Oela Box
Oela Box includes some roles used by some of the Ansible playbooks. The roles included with Oela Box have a naming scheme to help identify them when external roles are added.

```
oelabox.xxxx
```

or

```
oelabox.xxxx.xxxx
```

The former naming scheme is for roles which have been forked and modified specifically for Oela Box. The Latter naming scheme is for roles which have been forked, but have not been modified specifically for Oela Box.

#### Role Naming Scheme Examples
The following are good examples of the naming schemes. They are roles currently included with Oela Box.

##### oelabox.kojid
The oelabox.kojid role is a role forked from its Rocky Linux counterpart. It has been modified to suite the needs and expectations of Oela Box. In a sense we could consider this a "first-level" name.

##### oelabox.geerlingguy.postgresql
The oelabox.geerlingguy.postgresql role forked from geerlingguy.postgresql. It has not been modified whatsoever. This can be considered a "second-level" name.

To give more background on this role: Initially this role wasn't going to be included in Oela Box. What made me decide to fork this role and include it was a bug in newer versions. The bug was caused by a hack written for one of the tasks. Essentially it tried to convert a dictionary to an array and Ansible wasn't liking that. I honestly forget which version this is forked from, but its fairly old now. Anyway, for predictability sake during development I forked this role and it has become included with Oela Box.

## Bash
Bash is the standard shell for Linux now days. With Oela Box we are interacting with Bash a lot to run programs and scripts. Oela Box uses Bash scripts to solve smaller problems and to prototype ansible playbooks. We can also use Bash scripts to aid in provisioning of our virtual machines. 

## Python
Python is the scripting language many of the tools we use are written in. The Koji services and Ansible are written in Python. It's good to have a decent understanding of Python, so we can extend these tools and debug them when necessary. For example Koji spits out a python stacktrace when it encounters some errors.

### Koji Error Example
Earlier I mentioned that Koji can spit out a Python stacktrace when an error is encountered. This example is a real error encountered when I was working on the Koji server. This error was logged in /var/log/kojid.log.

```
2024-02-06 16:29:32,357 [WARNING] koji.TaskManager: TRACEBACK: Traceback (most recent call last):
  File "/usr/lib/python3.6/site-packages/koji/daemon.py", line 1492, in runTask
    response = (handler.run(),)
  File "/usr/lib/python3.6/site-packages/koji/tasks.py", line 335, in run
    return koji.util.call_with_argcheck(self.handler, self.params, self.opts)
  File "/usr/lib/python3.6/site-packages/koji/util.py", line 271, in call_with_argcheck
    return func(*args, **kwargs)
  File "/usr/sbin/kojid", line 5644, in handler
    self.merge_repos(external_repos, arch, groupdata)
  File "/usr/sbin/kojid", line 5802, in merge_repos
    % parseStatus(status, format_shell_cmd(cmd)))
koji.GenericError: failed to merge repos: /usr/bin/mergerepo_c --koji -b \
/mnt/koji/repos/dist-rocky8-build/1/i386/blocklist -a i386 -o \
/tmp/koji/tasks/2/2/repo --arch-expand -g \
/mnt/koji/repos/dist-rocky8-build/1/groups/comps.xml -r \
file:///tmp/koji/tasks/2/2/repo_1_premerge/ -r \
http://dl.rockylinux.org/vault/rocky/8.8/devel/i386/os/ exited with status 1
```

Without a basic understanding of Python or stacktraces in general this error looks intimidating and impossible to read. Once we're familiar however it becomes quite easy to understand.

I typically read a stacktrace from the bottom up as that is usually where I find the problem. In some cases though there could be multiple issues which are best to diagnose one at a time bottom up.

In this specific example its just Koji telling us the mergerepo task went wrong. We can see this at the bottom of the stack trace.

```
koji.GenericError: failed to merge repos: /usr/bin/mergerepo_c --koji -b \
/mnt/koji/repos/dist-rocky8-build/1/i386/blocklist -a i386 -o \
/tmp/koji/tasks/2/2/repo --arch-expand -g \
/mnt/koji/repos/dist-rocky8-build/1/groups/comps.xml -r \
file:///tmp/koji/tasks/2/2/repo_1_premerge/ -r \
http://dl.rockylinux.org/vault/rocky/8.8/devel/i386/os/ exited with status 1
```

koji.GenericError is pretty self-explanatory. How we know it was a task that failed is actually at the top of the stacktrace.

```
2024-02-06 16:29:32,357 [WARNING] koji.TaskManager: TRACEBACK: Traceback (most recent call last):
```

koji.TaskManager is also fairly self-explanatory. It is part of the code which handles running tasks. The important part of this demonstration is the fact that Koji when an error is encountered gives us a Python stacktrace which we need to know how to read. The way Koji handles errors is more friendly to programmers than users or systems administrators.

It's also important to mention that when I refer to Koji I am reffering to the ecosystem of the tools behind Koji and the Koji python library. The entirety of Koji is mostly one big library written in Python. The different tools that make up the Koji ecosystem all utilize this library then implement their specific features.

To go into more detail about the error and why I believe it occurred: At the time this error occurred I was setting up an external repository to bootstrap my Koji for building RPMS. I set up the external repository to point to the Rocky Linux 8.8 devel repository. This repository is essentially a buildroot meant for Koji instances. It contains packages for 3 different architectures: `aarch64`, `i686`, and `x86_64`. I was mainly focused on the i686 portion as an `i686` buildroot is needed to build some packages for `x86_64`. In fact in the `x86_64` buildroot there are various `i686` packages. `x86_64` is a quirky architecture in general when it comes to multilib support. We need to build for 2 different architectures in order to achieve multilib support. Anyway, Koji has a quirk where when told to support packaging building and repo generation for `i686` it tries to do it for `i386` instead. Instead of looking for the `i686` directory in the external repo like I expect it to it looks for a `i386` directory. The `i386` directory does not exist, so Koji throws an error saying it cannot find `i386` on the external repository. This issue was solved by using the Rocky Linux Koji repository for the external repository.

## Enterprise Linux
Enterprise Linux development is what Oela Box is designed for. There is a lot of engineering and design choices which go into Enterprise Linux. Enterprise Linux is engineered to be stable and predictable for at least a decade for each release. It has become a standard and proven itself to be a reliable design. Many Linux distributions take note of the Enterprise Linux design and software.

In Oela Box each virtual machine runs some flavor of Enterprise Linux. Rocky Linux 9.3 runs the DNS and IPA servers. CentOS Stream 8 runs the Koji server. While it is preffered that all the virtual machines run the same flavor and version that is not always possible. This is due to a variety of reasons: Some tools are only available for a previous version of EL. Vagrant images aren't working correctly for an unknown reason. Some bugs in one version make development more difficult. These are just a few notable reasons.

Some readers may have noticed I reffered to CentOS Stream as a Enterprise Linux flavor. I will admit this is arguable on some very technically accurate grounds. CentOS Stream is the upstream of Enterprise Linux. It is designed to track just ahead and test updates before they're included in Enterprise Linux. CentOS Stream is still designed to be stable and predictable like Enterprise Linux. CentOS Stream in fact is ABI compatible with Enterprise Linux. I still consider it on a technical level to be Enterprise Linux, but on the edge.

CentOS Stream 8 is not my preffered choice for running the Koji server. I would have preffered to use Rocky Linux 8.8, but there's been some issues with those vagrant images. I also have a lot of experience prototyping Oela Box on CentOS Stream 8. Oela Box started from messing with the Kdreyer Koji playbooks. A Vagrant file was included which provisioned a CentOS Stream 8 virtual machine to run Koji. Writing tools, scripts, and playbooks to be ran on CentOS Stream 8 is how I got familiar with its quirks. It made a great control group and implementation reference. Any changes I made that caused issues I would know exactly what caused those issues. It also allowed me to figure out the Rocky Linux infrastructure playbooks by comparing the working reference to the development work.
