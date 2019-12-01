---
title: Next level dotfiles with Ansible
date: 2019-10-11
---

In the life of every linux enthusiast comes the point, where he has a lot of
individual configuration build up and wants to migrate these settings over to
another machine as seamlessly as possible. At this point a whole philosophy of
how to do this is coming into play. Today this philosophy is bundled under the
name: _dotfiles_. Historically dotfiles are the config files, which lie
in your home directory. Because they try to be invisible to the user they start
with a dot (which is the linux convention for invisible files).

I started the classical approach like many others and kept [a git
repository](https://github.com/snowiow/dotfiles) with all the important dotfiles
I want to share between my machines. A shell script lies in the root directory
which symlinks everything inside the _dotfiles_ sub directory to the _home_
directory. In the beginning this was great. All my important applications, like
vim, were configured after executing the shell script. From that point on I
could change my configuration files, which were synced back to the git
repository and I could sync the changes between my machines. My main concern
with this approach arised when more and more application implemented the
[xdg-user-dir](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/). Now
most of the dotfiles were located in my _.config_ directory and the
symlink linked to _/config_ itself. Now I had to differentiate a lot
between files I want to track and those I don’t before every commit. Long story
short: I found a new and better approach, which I want to present to you:
Ansible.

You might think now: “Ansible? Really? That’s total overkill for
syncing dotfiles!” That’s true, but on the other hand it’s much more than just
for syncing my dotfiles. But first of all for everyone, who never heard about
ansible. Ansible is a project written in python, which helps you create
reproducible systems. The normal use case for ansible is as a configuration
manager. Ansible projects mostly consist of yaml files, in which you define a
want to state of a system. Then you apply this state to a system and ansible
syncs everything between the system and your yaml files. So in many ways it can
be compared to terraform, which I talked a lot about in my previous posts. But I
see ansible on level lower than terraform. While terraform is about the big
picture representing your whole infrastructure, ansible takes care about each
and every system in this infrastructure. So it is more like docker, but you
install and configure stuff on the system itself. Ok, this should be enough of
an intro to ansible, let’s dive into my totally over engineered dotfiles!

# Getting a base structure built up
Normally you provision other systems from one operator system, mostly
via ssh. But we want to use ansible on the current system. Sure it would also be
cool, to provision a new system from a some sort of main machine, but in reality
it was never necessary for me. So the first thing we do, is to tell ansible we
want to execute everything on localhost. Therefore we create a
_hosts_ file in our new dotfiles directory, with the following line
of code:

```
[local] 
localhost ansible_connection=local
```

This will tell ansible which hosts to provision.

Now we need to talk
about two important concepts of ansible. The first one are playbooks. Playbooks
are ansible’s infrastructure as code so to say. They demonstrate the want to be
state of a system and are described in form of yaml files. The ansible docs
describe playbooks as the instruction manual for configuration, deployment and
orchestration.

The second important concept are roles. Ansible roles are
a form of structuring your playbooks and make them reproducible. We mainly use
roles to structure our dotfiles and keep different application configurations
separated. For example I reuse my roles in different forms for my Linux and OSX
machine, because the installation process is different, but the configuration is
the same. Roles dictate a special directory structure. This way ansible is able
to magically run those roles without setting too much manually. I will go into
more detail, when we create our first role. All roles are located in the
_roles_ sub directory.

# Create your first role
As an example we install neovim, but this can be any software you want to always
have installed. For this, we create a `nvim` sub directory in the `roles`
directory. In the `nvim` sub directory we create a `tasks` sub directory. So the
current directory structure should look like this:

```
- roles
|- nvim
|-- tasks
```

In the tasks directory we create a file called `main.yml`. This file is the
starting point of a role and will be called automatically. Here we add the
following instruction:

```yaml
- name: install neovim on linux
  package:
    name: neovim,
          python-neovim
    state: present
  become: yes
```

Basically everything in playbooks is defined in these YAML blocks. They follow a
common structure starting with an optional name.
