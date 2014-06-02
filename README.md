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
