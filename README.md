# macos-packer
Build the macOS with Packer for testing.

This is a fork of Timothy Sutton's [osx-vm-templates]. He and his crew put a lot of hard work in to make this work. If you like this repo then check out the original and throw him a star and watch it too. 

I needed a throw-away copy of the macOS so I could test automation for configuring that environment. If you'd like to see that automation then check out the [mac-ops] repo; writing that automation was only possible because of Tim's project; i.e.: the macOS is now disposable.

## Modifications
This repo is largely the same as Tim's but I did write/re-write a few things; [shellcheck] was not happy with the some of the scripting. Also, some of the files were reorganized to simplify the layout, if only in my mind. If you like the changes then watch my repo and throw me a star.

## Build Prep
1) Hardware: You need enough storage, processor and memory to build VMs. An old MacBook Pro/Air probably won't work.

2) Download the OS source data. Open the App Store, on the 'Featured' page 'macOS Sierra' will be listed on the right-side towards the top. Clicking the link will navigate you to the Sierra page. At this point, just click the `Download` button. When the download is complete the installer will launch and await your approval; Quit the Sierra Installer program and you're done. 

3) Next, this project _requires_ that you have [VMware Fusion] to build the VM; that was $80 US. For now, sadly, VirtualBox cannot be used. Keep watching though; that could change at any time. If you figure it out then let me know.

4) Of course you will need to download and install [Packer]. Either install from the package on the Downloads page or, if you're like me and using [homebrew], install it by:

`brew install packer packer-completion`

## Automation Overview
To use this automation `git clone` this repo and start reviewing some files. These are the highlights:

* The `vars-build` file defines:
 * Where VMware stores its VMs, 
 * Where Packer will build them
 * Where Vagrant should look for packer boxes, assuming the Vagrant piece can/will work some day. and,
 * Some Ansible stuff, for when I get around to converting these scripts.
 
 > If you already have these variables set elsewhere, like your `~/.bashrc` then remove the `vars-build` file. If you don't already have them set then leave them be and everything will "just work". 

You'll need a directory structure to support these variables; it's pretty simple, within your home directory:

```bash
mkdir -p ~/vms/{vagrant,packer,vmware}
mkdir -p ~/vms/vagrant/boxes
mkdir -p ~/vms/packer/builds
```


* The `create-iso.sh` script will convert the downloaded source files from Step 1 (above) to a `.dmg` image file used for macOS installations. There are 2 parameters to watch:
 * `inst_source='/Applications/Install macOS Sierra.app'`, and
 * `isoDir="$HOME/Downloads/isos/osx"`

> The value for `inst_source` shouldn't change. The value for `isoDir` can be changed to wherever you store your ISO images. I keep them in `~/Downloads/isos` because the ISOs are too big and I don't want them caught up in my nightly [rsync-backups] process, which ignores the `~/Downloads` directory completely.  

* The `build-macos.sh` script does exactly what it sounds like.
 * It's designed to fail gracefully on `packer validate` and `packer inspect` steps.
 * Only if the validate and inspect steps succeed will the `packer build` step execute. No need to start a 12 minute process that will ultimately fail 10 minutes in; a huge time waste.

For everything else, you'll have to discover it as I did. Read it, know it, love it.

## Build a macOS VM
After making the initial adjustments to the `vars-build` and `isoDir` files then build the installer:

`./create-iso.sh` 

This script runs and exits within a few minutes. If it goes longer than 5 something is terribly wrong, `CTRL+c` to kill it. When it does complete there are some important bits of information at the end. Record them in a text file or something:

* `iso_checksum_type: MD5`
* `iso_checksum: 25235d37a35897296a56ea1bc227cd9f` (for example)
* Path to the image location `~/Downloads/isos/osx`
* Name of the installer: OSX_InstallESD_10.12.3_16D32.dmg

Update the packer file, `macos-sierra-10.12.json`, with the new `iso_checksum`. Then update `osxISO` and `isoDir` in the `build-macos.sh` script.

Now you're ready to build; execute the script:

`./build-macos.sh`

This process can take between 8-12 minutes depending on hardware. Continue reading until it completes...

***

### On-time Network Setup (optional)
You can do this while the VM is building. Since I typically login to this machine through the terminal after it's built, I like to make sure it gets the same address every time. To do this for yourself:

1) Find the documentation for your DHCP source (likely your home WiFi device) 

2) Find the section on DHCP Reservations. This VM will get a MAC address of `00:0c:29:56:a1:41`. Reserve an IP for this hardware address and life will be sweet.

3) Edit your `/etc/hosts` file and add an entry to it that looks similar to this:

```bash
reservedIPAdd    macos.yourdomain.yourTLD    macos
```

For example:

```bash
192.168.0.200        macos.example.com        macos
```

4) After that, all you should need to access this VM is open the terminal and:

`ssh vagrant@macos`

The password is `vagrant`. Remember, it's a disposable box for testing, _NOT_ deployment.

You will have to support yourself on the Networking piece. It's beyond the scope of this project. But, you should know that it's possible to do it.
***


## Post-Build Setup
At the end of the process, you will still have some configurations to make to the VM. I haven't been able to get them implemented reliably yet:

* Double-check the VMware Network Adaptor. Make sure it's set to 'Bridged (Autodetect)'. Then you'll be able to open a terminal and ssh right into this box.
* Attach/configure your backup/restore storage device or network location if necessary for your testing.

In VMware Fusion, click the 'Play' icon to boot the macOS VM. Once it's booted up it's no fun to enter passwords every time so I copy my public ssh key over to the VM. If you don't have them then you need to create [ssh keys]; ignore the rest of the AWS instructions and come back here. 

After that, copy the public key to the remote host:

`ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@macos`

Now login to the VM:

`ssh vagrant@macos`

Prep this VM in any other way you need to. For example, I copy some test ssh keys to this system so I can access github repos via ssh.

After the prep work, shut down the VM and snapshot it. Call it 'fresh' or something.

Once you've booted again, you can (optionally) use [Install Prep] script to install any outstanding updates, snapshot some installed packaged, etc. To run it:

`curl -fsSL https://goo.gl/j2y1Dn 2>&1 | bash | tee /tmp/install-prep.out`

After this script completes, shut the machine down again. Create another snapshot called 'updated' or something. 

Then, boot the machine and you're ready to test whatever you like. Trashing the machine is as easy as rolling back to one of your snapshots. When rolling back, in the case of:

* The 'fresh' snapshot: you may want to save the current state.
* The 'updated' snapshot: you very likely do NOT want save the current state.

Also, if you're testing out backups and restores like I am, you will have to attach your USB storage device EVERY TIME you roll back to a previous snapshot. It's so irritating.

Good luck and have fun. Also...

Thanks Tim!

[osx-vm-templates]:https://github.com/timsutton/osx-vm-templates
[shellcheck]:https://github.com/koalaman/shellcheck
[mac-ops]:https://github.com/todd-dsm/mac-ops
[VMware Fusion]:http://store.vmware.com/store/vmware/en_US/DisplayProductDetailsPage/ThemeID.2485600/productID.323689100
[Packer]:https://www.packer.io/
[homebrew]:https://brew.sh/
[rsync-backups]:https://github.com/todd-dsm/rsync-backups
[ssh keys]:https://github.com/todd-dsm/mac-ops/wiki/Install-awscli#openssh-keys
[Install Prep]:https://github.com/todd-dsm/mac-ops/wiki/Install-Prep