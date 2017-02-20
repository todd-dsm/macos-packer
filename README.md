# macos-packer
Build the macOS with Packer for testing.

This is a fork of Timothy Sutton's [osx-vm-templates]. He and his crew put a lot of hard work in to make this work. If you like this repo then check out the original and throw him a star and watch it too. 

I needed a throw-away Guest Machine with the macOS so I could test automation for configuring the environment. If you'd like to see that automation then check out the [mac-ops] repo; writing that automation was only possible because of Tim's project; i.e.: the macOS is now disposable.

## Modifications
This repo is largely the same as Tim's but I did write/re-write a few things to make the process easier and safer to run; [shellcheck] was not happy with the some of the scripting. 

Also, the files were reorganized to simplify the layout, if only in my mind. If you like the changes then watch my repo and throw me a star.

## Build Prep
1) Hardware: You need enough storage, processor and memory to build VMs. An old MacBook Pro/Air probably won't work. 

2) For now, and as far as I know, this only works from a macOS _host machine_. I haven't tried it on Linux with VMware Workstation although I would be interested in knowing the outcome of that experiment.

3) Download the OS source data. Open the App Store, on the 'Featured' page 'macOS Sierra' will be listed on the right-side towards the top. Clicking that link will navigate you to the Sierra page. At this point, just click the `Download` button. When the download is complete the installer will launch and await your approval; Quit the Sierra Installer program and you're done. 

4) Next, this project _requires_ that you have [VMware Fusion] to build the VM; that was $80 US. For now, sadly, VirtualBox cannot be used. Keep watching though; that could change at any time. If you figure it out then let me know.

5) Of course you will need to download and install [Packer]. Either install from the package on the Downloads page or, if you're like me and using [homebrew], install it by:

`brew install packer packer-completion`

## Automation Overview
To use this automation `git clone` this repo and start reviewing some files. These are the highlights:

* The `vars-build` file defines:
 * Variables common to all scripts
 * Where VMware stores its VMs, 
 * Where Packer will build them
 * Where Vagrant should look for packer boxes, assuming the Vagrant piece can/will work some day. and,
 * Some Ansible stuff, for when I get around to converting these scripts.
 
 These environment variables, except `common vars` should be set in `~/.bashrc` anyway.
 
 There are 2 parameters to watch:
 
 `inst_source='/Applications/Install macOS Sierra.app'`, and
 `isoDir="$HOME/Downloads/isos/osx"`

> The value for `inst_source` shouldn't change. The value for `isoDir` can be changed to wherever you store your ISO images. I keep them in `~/Downloads/isos` because the ISOs are too big and I don't want them caught up in my nightly [rsync-backups] process, which ignores the `~/Downloads` directory completely.  

You'll need a directory structure to support these variables:

```bash
mkdir -p ~/vms/{vagrant,packer,vmware}
mkdir -p ~/vms/vagrant/boxes
mkdir -p ~/vms/packer/builds
mkdir -p ~/Downloads/isos/{centos,debian,fedora,osx,ubuntu}
```

* The `create-iso.sh` script will convert the downloaded source files from Step 2 (above) to a `.dmg` image file used for macOS installations. 


* The `build-macos.sh` script does exactly what it sounds like.
 * It's designed to fail gracefully on `packer validate` and `packer inspect` steps.
 * Only if the validate and inspect steps succeed will the `packer build` step execute. No need to start a 12 minute process that will ultimately fail 10 minutes in; a huge time waste.

For everything else, you'll have to discover it as I did. Read it, know it, love it.

## Build a macOS VM
After setting/accepting the `isoDir` in the `vars-build` file then build the installer image:

`./create-iso.sh` 

This script runs and exits in 2 minutes and 7 seconds on a MBP with an i7 processor; if there's less processor it could take longer.  If this script runs longer than 8 minutes something's probably gone wrong; `CTRL+c` to kill it. When it does complete there are some important bits of information at the end; copy the MD5 value:

```bash
...
-- MD5: 7b915d37a35897296a56ea1bc22z52o6
-- Done. Built image is located at ~/Downloads/isos/osx/OSX_InstallESD_10.12.3_16D32.dmg. 
```

Edit the packer file, `macos-sierra-10.12.json`, and update the `"iso_checksum"` value (line 106) with the one displayed at the end of the script:
`"iso_checksum": "9c8b0d255c20d77b7addca97c21163a4"` (for example)

Verify these values behaved as expected

* Path to the image location `~/Downloads/isos/osx`
* Name of the installer: `OSX_InstallESD_10.12.3_16D32.dmg`
* The line with 'Done. Built image is located at' should look like it does above. 

Now you're ready to build; execute the script:

`./build-macos.sh`

This process takes approximately 18 minutes and 12 seconds on an MBP with an i7; again, less processor = more time. There will be a lot of output since debugging is turned on; also, I don't believe in magic so it's important you see what's happening on your system.

Continue reading until it completes...

***

### One-time Network Setup
This is an _**optional**_ step. You can do this while the VM is building. Since I login to this machine through the terminal (after it's built), I like to make sure the VM gets the same address every time. To do this for yourself:

1) Find the documentation for your DHCP source (likely your home WiFi device) 

2) Find the section on **DHCP Reservations**. This VM will get a MAC address of `00:0c:29:56:a1:41`. Reserve an IP for this hardware address and life will be sweet.

3) Edit your `/etc/hosts` file and add an entry to it that looks similar to this:

```bash
reservedIPAdd    macos.yourdomain.yourTLD    macos
```

For example:

```bash
192.168.0.200    macos.example.com    macos
```

If you don't have a domain then just:

```bash
192.168.0.200    macos
```

4) After that, all you should need to access this VM is open the terminal and:

`ssh vagrant@macos`

You will have to support yourself on the Networking piece. It's beyond the scope of this project. But, you should know that it's possible to do it.
***

## Post-Build Setup
At the end of the process, you will still have some configurations to make to the VM. I haven't been able to get them implemented reliably yet:

* Double-check the VMware Network Adaptor. Make sure it's set to 'Bridged (Autodetect)'. Then you'll be able to open a terminal and ssh right into this box.
* In VMware Fusion, click the 'Play' icon to boot the macOS VM. 
* While it's booting, attach your USB backup/restore storage device if it's necessary for your testing.
* Once it's booted log into the GUI. 

Since it's no fun to enter passwords every time I login through the terminal, I copy my public ssh key over to the VM. If you don't have them then you need to create [ssh keys]; ignore the rest of the AWS instructions and come back here. 

After that, copy the public key to the remote host:

`ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@macos`

The password is `vagrant`. Remember, it's a disposable box for testing, _NOT_ deployment.

If you opted NOT to perform the [One-time Network Setup](#One-time-network-setup), then you will have to go back to the VMware Fusion/macOS window, click on System Preferences (on the Dock) > Network > Ethernet (adapter) and check the DHCP address, then use that; e.g.:
`ssh-copy-id -i ~/.ssh/id_rsa.pub vagrant@192.168.0.200`

You will have to do this for every new build. Trust me, this will get annoying. 

Then, as the instructions indicate, it's now time to login to the VM:

`ssh vagrant@macos`

Prep this VM in any other way you need to. For example, I do these few things in the GUI:

* Eject the 'OS X Base System' image from the Desktop
* Set the Time Zone

These things are done from the Host Machine's termial:

* rsync my test ssh files back to the system so I can interact with Github; e.g.:

`rsync -aEv /Volumes/usb-storage-device/directory/user/current/directory/ "$HOME/local-directory/"`

`rsync -aEv /Volumes/storage/test/vagrant/current/.ssh/ "$HOME/.ssh/"`

After the prep work, shut down the VM and snapshot it. Call it 'fresh' or something.

Once you've booted again, you can (optionally) use [Install Prep] script to install any outstanding updates, snapshot some installed packages, etc. To run it:

`curl -fsSL https://goo.gl/j2y1Dn 2>&1 | bash | tee /tmp/install-prep.out`

This script takes approximately 3 minutes and 25 seconds to run. Afterwards, shut the machine down again. Create another snapshot called 'updated' or whatever. 

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