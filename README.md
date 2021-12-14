## Pi-Hole and UniFi with a dynamic Nginx Proxy
----
This is a small repo containing a handful of files that can be edited and copied to setup a raspberry pi as both a Unifi controller and PiHole DNS server. You'll want to edit these files to match your personal needs, but compiling them here hopefully means you won't have to search the internet and write them all by scratch yourself.

Details on how this all came to be can be found on my blog:
* [Details on implementation process](https://crayzeigh.com/how-to-setup-pihole/)
* [Details on automatic updates](https://crayzeigh.com/automated-docker-image-package-updates-on-rasberry-pi)

## Docker Image Setup
----
Mainly you'll want to copy `docker-compose.yml` to wherever you want to house your docker configs, permanent files and logs. You can choose to store your permanent data elsewhere, but the aim was always dead simple for home setup so I wouldn't have to track down configs or do complicated resets if anything goes wrong. The file is annotated with areas you'll need to update with your personal preferences. Notes for each service below:

### jwilder-proxy

- **environment***.DEFAULT_HOST*: This is to fill in which host is answering your default domain requests to this server. I recommend pointing at the pihole.
- **restart**: always. As the nginx gatekeeper, I can't think of a scenario where I don't want this to come up automatically.

### pihole

- **environment:** All variables here are primarily used for initial setup. Some, like `WEBPASSWORD` are stored in the permanent file store afterward.  
    - *ServerIP*: The IP address for your DNS server for static IP. Highly recommended since you don't want to be hunting for your DNS server in the event of issues.  
    - *TZ*: your linux-annotated timezone. 
    - *PROXY_LOCATION*: hostname (pihole by default)
    - *VIRTUAL_HOST*: FQDN of your pihole (pihole.domain.tld). I use a bad TLD which is probably also bad practice if Windows Domain recommendations are anything to trust. I may eventually change this to using my public domain with appropriate local DNS entries.  
    - *WEBPASSWORD*: This is to set the initial web admin password for the pihole. I recommend putting on in yourself so you don't have to hunt the setup logs for it and changing it after setup so your password isn't stored in plain text.
- **volumes**: By default this will create permanent data stores rooted in the same directory as this docker-compose file. You're free to change this, but I find it makes it easiest to manage for a home setup, one folder to contain everything. You'll want to run a `mkdir` on the local `etc-dnsmasq.d`, `etc-pihole`, and `var-log` folders as well as `touch` on the `pihole.log` to avoid any missing directory/file errors. 
- **extra_hosts**: This is a list of any additional host entries, especially those running on docker on the same physical host. Include the FQDN and local IP address. This can probably also be used for other manual DNS entries, but I haven't tested this fact and it isn't clearly documetned in the source readme.
- **restart**: I choose to restart only if I haven't explicitly stopped this container. 

### unifi-controller

- **environment:** All variables used for initial setup processes and service configs
    - *PROXU_LOCATION*: local hostname
    - *VIRTUAL_HOST*: host FQDN
    - *VIRTUAL_PORT*: Default port for web access. Defaults are fine here
    - *VIRTUAL_PROTO*: Default protocol for web access. I wouldn't change unless necessary
- **volumes**: Like above, this creates the permanent data store within a subfolder of wherever the `docker-compose.yml` file is stored. You can move this if desired, but eitherway, be sure to run `mkdir` on the local end of the `config` location.
- **restart**: Also like above, I have this restarting automatically unless I explicitly down this container, do what makes the most sense for you.

## Automatic Updates
----
Since the goal is dead-simple operations and replacable containers, updates are handled simply by checking for changes to the existing containers, downloading new images and replacing the running containers updated ones. The `docker-updates.sh` is written to automate this and let you know when it replaces a container while minimizing disk writes. Consequently all logging is completed in a temporary string then sent off via email, never writing to disk.

### Requirements
You'll need to have some way to send emails via the `mail` command for this to work. I installed `mailx` and configured it to send through my personal gmail account. Details for that specific implementation are discussed in my [auto-updates blog entry](https://crayzeigh.com/automated-docker-image-package-updates-on-rasberry-pi).

### Config and Install
You'll need to enter your email address under the `email` variable. Personally I add a `+pi` to my address so I can filter all these messages into a folder and avoid inbox clutter.

You'll need to adjust the paths to your `docker-compose.yaml` file as noted in the "checking" and "updating" sections of the body, but otherwise the paths are absolute and generic.

Once it's all set you'll want to copy into whatever cron directory you prefer based on frequency and set ownership and permissions appropriately. e.g. if you want to check for updates daily:

```bash
sudo cp ./docker-updates.sh /etc/cron.daily/
sudo chown root: /etc/cron.daily/docker-updates.sh
sudo chmod 755 /etc/cron.daily/docker-updates.sh
```
