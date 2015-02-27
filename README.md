# monopaste
mono means one.  
paste means paste.  

## overview
monopaste will sit and stare at the copy buffers of configured
applications/window managers/GUIs and push the most recently
"copied" bytes to all the other applications/window managers/GUIs
it knows about. For example, this means you can stop converting
tmux copy buffers to xorg copy buffers.

## installation
`gem build monopaste.gemspec && gem install monopaste-*.gem`

## usage
`monopasted -C PATH_TO_CONFIG_FILE`  

Run `monopasted -h` for more information.

## configuration

```
#enable the tmux-cli plugin
[tmux-cli]
poll_interval = 500 #poll the tmux paste buffer every 500ms

#enable the osx-cli plugin
[osx-cli]
# no specific configurations needed

#enable the X11 paste buffer plugin (uses xclip)
[xclip]
poll_interval = 300
display = :0 # set the display ID to poll
```

## systemd unit example
The following unit is designed to run in the systemd
user service.
```
[Unit]
Description=monopaste daemon

[Service]
Type=simple
ExecStart=/usr/bin/sh -c 'exec /home/%u/bin/monopasted'
Restart=always
RestartSec=3

[Install]
WantedBy=main.target

```
